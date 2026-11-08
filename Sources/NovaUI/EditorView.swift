//
//  EditorView.swift
//  NovaUI
//
//  O editor no layout Nova: previa em cima, transporte, timeline e a barra de
//  baixo. A barra vem da string do APK: «O "Link" está na barra de baixo do
//  editor, ao lado de Biblioteca, Legendas e IA.» Drive e Layout tambem moram
//  nela, por outras duas strings. A ORDEM entre eles e reconstrucao.
//
//  Link, Drive e Achar fontes sao extensoes: so aparecem se instaladas
//  (Perfil › Extensões).
//

import SwiftUI
import MetalKit
import PhotosUI

public struct EditorView: View {
    @State private var project: NovaProject
    @State private var time: Float = 0
    @State private var playing = false
    @State private var selectedLayer: UUID?
    @State private var layout: EditorLayout = .nova
    @State private var sheet: EditorSheet?
    @State private var installedExtensions: Set<String> = []   // vazio: nenhuma instalada
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPicker = false
    @State private var importing = false
    @State private var aviso: String?
    @State private var novoTexto = ""
    @State private var pedindoTexto = false
    @State private var manifests: [String: EffectManifest] = [:]

    @Environment(\.dismiss) private var dismiss

    /// Pasta do projeto (project.json + media/).
    private let folder: URL
    private let onSave: (NovaProject) -> Void
    private var mediaRoot: URL { folder.appendingPathComponent(NovaProjectIO.mediaFolder) }

    public init(project: NovaProject, folder: URL, onSave: @escaping (NovaProject) -> Void) {
        _project = State(initialValue: project)
        self.folder = folder
        self.onSave = onSave
    }

    private var comp: Composition { project.mainComposition ?? Composition() }

    /// Altera uma camada. `save` false durante gestos e sliders (grava no fim).
    private func editLayer(_ id: UUID, _ save: Bool, _ change: (inout Layer) -> Void) {
        guard let ci = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first,
              let li = project.compositions[ci].layers.firstIndex(where: { $0.id == id }) else { return }
        change(&project.compositions[ci].layers[li])
        if save { onSave(project) }
    }

    /// Altera a composicao principal e grava o projeto.
    private func editComp(_ change: (inout Composition) -> Void) {
        guard let i = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first else { return }
        change(&project.compositions[i])
        onSave(project)
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topBar
                Divider().overlay(NovaTheme.line)

                if layout == .afterEffects && geo.size.width < layout.minimumSize.width {
                    janelaPequena(geo.size)
                } else {
                    preview
                    transport
                    TimelineView(composition: comp, time: $time, selected: $selectedLayer)
                        .frame(height: 190)
                }

                bottomBar
            }
            .background(NovaTheme.background)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { s in
            switch s {
            case .efeitos:  EffectBrowserView { e in aplicarEfeito(e); sheet = nil }
            case .layout:   LayoutPickerSheet(selected: $layout)
            case .exportar: ExportSheet(composition: comp, mediaRoot: mediaRoot, manifests: manifests)
            case .propriedades(let id):
                LayerPropertiesSheet(comp: comp, layerID: id, time: time, manifests: manifests,
                                     edit: { id, save, change in editLayer(id, save, change) })
            case .info(let t, let m): InfoSheet(titulo: t, mensagem: m)
            }
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItems,
                      maxSelectionCount: nil, selectionBehavior: .ordered,
                      matching: .any(of: [.images, .videos]),
                      preferredItemEncoding: .current)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importar(items) }
        }
        .alert("Texto".loc, isPresented: $pedindoTexto) {
            TextField("Digite o texto".loc, text: $novoTexto)
            Button("Cancelar".loc, role: .cancel) {}
            Button("Adicionar".loc) { adicionarTexto(novoTexto) }
        }
        .task(id: playing) { await tocar() }
        .task(id: effectIDs) { await carregarManifestos() }
        .overlay(alignment: .top) {
            if importing || aviso != nil {
                Text(importing ? "Carregando mídia…".loc : (aviso ?? ""))
                    .font(.system(size: 11)).foregroundStyle(NovaTheme.text)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(NovaTheme.surface))
                    .padding(.top, 48)
                    .onTapGesture { aviso = nil }
            }
        }
    }

    // MARK: acoes

    private func importar(_ items: [PhotosPickerItem]) async {
        importing = true
        let start = time
        let r = await MediaImporter.importItems(items, into: mediaRoot,
                                                composition: comp, start: start)
        pickerItems = []
        importing = false
        guard !r.layers.isEmpty else {
            aviso = r.failures.first ?? "Nada foi adicionado".loc
            return
        }
        editComp { c in
            for l in r.layers { c.add(l) }
            // «A composicao termina onde a ultima camada termina» (Alight Motion).
            let fim = c.layers.map(\.endTime).max() ?? c.duration
            c.duration = max(c.duration, fim)
        }
        selectedLayer = r.layers.last?.id
        if r.failures.isEmpty {
            aviso = "Adicionar {0} mídias".loc.replacingOccurrences(of: "{0}", with: "\(r.layers.count)")
        } else {
            aviso = "Entraram {0} de {1}: {2}".loc
                .replacingOccurrences(of: "{0}", with: "\(r.layers.count)")
                .replacingOccurrences(of: "{1}", with: "\(items.count)")
                .replacingOccurrences(of: "{2}", with: r.failures.first ?? "")
        }
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); aviso = nil }
    }

    private func adicionarTexto(_ t: String) {
        let texto = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return }
        var l = Layer(name: String(texto.prefix(24)), kind: .text)
        l.text = texto
        let fs = Float(comp.height) / 10
        l.fontSize = fs
        l.textColor = SIMD4(1, 1, 1, 1)
        let m = MediaContentProvider.measureText(texto, fontName: nil, size: CGFloat(fs))
        let size = SIMD2(Float(m.width), Float(m.height))
        l.size = size
        l.transform.anchorPoint = Animated(size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, min(5, comp.duration - time))
        novoTexto = ""
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func adicionarSolido() {
        var l = Layer(name: "Sólido".loc, kind: .solid)
        l.solidColor = SIMD4(0.39, 0.33, 0.95, 1)
        l.size = comp.size
        l.transform.anchorPoint = Animated(comp.size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func excluirSelecionada() {
        guard let id = selectedLayer else { return }
        editComp { $0.remove(id: id) }
        selectedLayer = nil
    }

    private func aplicarEfeito(_ e: EffectIndexEntry) {
        guard let id = selectedLayer ?? comp.layers.first?.id else {
            aviso = "Adicione uma camada antes do efeito.".loc
            return
        }
        editComp { c in
            if let i = c.layers.firstIndex(where: { $0.id == id }) {
                c.layers[i].effects.append(AppliedEffect(effectID: e.id))
            }
        }
        selectedLayer = id
        // Abre as propriedades para ajustar o efeito na hora.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            sheet = .propriedades(id)
        }
    }

    private var effectIDs: [String] {
        Array(Set(comp.layers.flatMap { $0.effects.map(\.effectID) })).sorted()
    }

    private func carregarManifestos() async {
        var out: [String: EffectManifest] = [:]
        for id in effectIDs {
            if let m = try? await EffectRegistry.shared.manifest(id: id) { out[id] = m }
        }
        manifests = out
    }

    /// Avanca o tempo enquanto toca, no ritmo da composicao.
    private func tocar() async {
        guard playing else { return }
        if time >= comp.duration { time = 0 }
        let inicio = Date()
        let t0 = time
        while playing && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / max(comp.frameRate, 1)))
            let t = t0 + Float(Date().timeIntervalSince(inicio))
            if t >= comp.duration { time = comp.duration; playing = false; break }
            time = t
        }
    }

    // MARK: topo

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                    Text("Projetos".loc).font(.system(size: 12))
                }.foregroundStyle(NovaTheme.dim)
            }
            Spacer()
            Text(project.name).font(.system(size: 13, weight: .semibold))
            Spacer()
            Button { sheet = .exportar } label: {
                Text("Exportar".loc)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(NovaTheme.accent)
            }
        }
        .padding(.horizontal, 12).frame(height: 42)
        .background(NovaTheme.surface)
    }

    // MARK: previa

    private var preview: some View {
        ZStack {
            CheckerboardBackground()
            PreviewSurface(composition: comp, time: time, mediaRoot: mediaRoot, manifests: manifests)
                .overlay {
                    TransformGizmo(comp: comp, time: time, selected: $selectedLayer,
                                   edit: { id, save, change in editLayer(id, save, change) })
                }
                .aspectRatio(CGFloat(comp.width) / CGFloat(comp.height), contentMode: .fit)
                .overlay(Rectangle().strokeBorder(NovaTheme.selection, lineWidth: 1))
                .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var transport: some View {
        HStack(spacing: 22) {
            botao("backward.end.fill") { time = 0 }
            botao("backward.frame.fill") { time = max(0, time - comp.frameDuration) }
            Button { playing.toggle() } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(NovaTheme.accent)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(NovaTheme.accent.opacity(0.16)))
            }
            botao("forward.frame.fill") { time = min(comp.duration, time + comp.frameDuration) }
            botao("forward.end.fill") { time = comp.duration }
            Spacer()
            if let id = selectedLayer {
                Button { sheet = .propriedades(id) } label: {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 13))
                        .foregroundStyle(NovaTheme.accent)
                }
                Button(role: .destructive) { excluirSelecionada() } label: {
                    Image(systemName: "trash").font(.system(size: 13))
                        .foregroundStyle(NovaTheme.warning)
                }
            }
            Menu {
                Button { showPicker = true } label: {
                    Label("Mídia".loc, systemImage: "photo.on.rectangle")
                }
                Button { pedindoTexto = true } label: {
                    Label("Texto".loc, systemImage: "textformat")
                }
                Button { adicionarSolido() } label: {
                    Label("Sólido".loc, systemImage: "square.fill")
                }
            } label: {
                Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NovaTheme.accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(NovaTheme.accent.opacity(0.16)))
            }
            Text(timecode(time)).font(.system(size: 11, design: .monospaced))
                .foregroundStyle(NovaTheme.dim)
        }
        .padding(.horizontal, 16)
        .frame(height: NovaTheme.Metrics.transportHeight)
        .background(NovaTheme.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .top)
    }

    private func botao(_ icon: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(NovaTheme.dim)
        }
    }

    func timecode(_ t: Float) -> String {
        let total = Int(t * comp.frameRate)
        let f = total % Int(comp.frameRate)
        let s = total / Int(comp.frameRate)
        return String(format: "%d:%02d:%02d.%02d", s/3600, (s/60)%60, s%60, f)
    }

    // MARK: barra de baixo

    private struct BottomItem: Identifiable {
        let id: String, label: String, icon: String, requiresExtension: String?
    }

    private var bottomItems: [BottomItem] {
        [
            .init(id: "biblioteca", label: "Biblioteca", icon: "books.vertical", requiresExtension: nil),
            .init(id: "legendas",   label: "Legendas",   icon: "captions.bubble", requiresExtension: nil),
            .init(id: "ia",         label: "IA",         icon: "sparkles",        requiresExtension: nil),
            .init(id: "link",       label: "Link",       icon: "link",            requiresExtension: "link"),
            .init(id: "drive",      label: "Drive",      icon: "externaldrive",   requiresExtension: "drive"),
            .init(id: "efeitos",    label: "Efeitos",    icon: "wand.and.stars",  requiresExtension: nil),
            .init(id: "layout",     label: "Layout",     icon: "rectangle.3.group", requiresExtension: nil),
        ]
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            ForEach(bottomItems) { item in
                let locked = item.requiresExtension.map { !installedExtensions.contains($0) } ?? false
                Button {
                    switch item.id {
                    case "efeitos": sheet = .efeitos
                    case "biblioteca": showPicker = true
                    case "layout":  sheet = .layout
                    default:
                        sheet = .info(item.label.loc, locked
                            ? "Instale a extensão em Perfil › Extensões.".loc
                            : "Este painel ainda não foi escrito. Veja Docs/PENDENCIAS.md.".loc)
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon).font(.system(size: 15))
                        Text(item.label.loc).font(.system(size: 8.5))
                    }
                    .foregroundStyle(locked ? NovaTheme.dim2
                                     : (item.id == "ia" ? NovaTheme.accent : NovaTheme.dim))
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: NovaTheme.Metrics.bottomBarHeight)
        .background(NovaTheme.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .top)
    }

    // MARK: janela pequena

    private func janelaPequena(_ size: CGSize) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "rectangle.landscape.rotate")
                .font(.system(size: 30)).foregroundStyle(NovaTheme.warning)
            Text(String(format: "Esta janela tem %.0f × %.0f pt. O layout %@ precisa de pelo menos %.0f × %.0f.",
                        size.width, size.height, layout.label,
                        layout.minimumSize.width, layout.minimumSize.height))
                .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button("Voltar para o layout Nova".loc) { layout = .nova }
                .font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sheets

enum EditorSheet: Identifiable {
    case efeitos, layout, exportar
    case propriedades(UUID)
    case info(String, String)
    var id: String {
        switch self {
        case .efeitos: return "efeitos"; case .layout: return "layout"
        case .exportar: return "exportar"; case .info(let t, _): return "info-\(t)"
        case .propriedades(let u): return "prop-\(u.uuidString)"
        }
    }
}

struct InfoSheet: View {
    let titulo: String, mensagem: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Spacer()
                Text(mensagem).font(.system(size: 13)).foregroundStyle(NovaTheme.dim)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NovaTheme.background)
            .navigationTitle(titulo).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Fechar".loc) { dismiss() } } }
        }
        .presentationDetents([.height(240)])
        .preferredColorScheme(.dark)
    }
}

struct LayoutPickerSheet: View {
    @Binding var selected: EditorLayout
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(EditorLayout.allCases) { l in
                Button {
                    selected = l; dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.label).font(.system(size: 14, weight: .medium))
                            Text(l.note.loc).font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                        }
                        Spacer()
                        if selected == l {
                            Image(systemName: "checkmark").foregroundStyle(NovaTheme.accent)
                        }
                    }
                }.foregroundStyle(NovaTheme.text).listRowBackground(NovaTheme.surface)
            }
            .scrollContentBackground(.hidden).background(NovaTheme.background)
            .navigationTitle("Layout do editor".loc).navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Fundo xadrez

struct CheckerboardBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let s: CGFloat = 8
            let a = Color(red: 0.04, green: 0.05, blue: 0.09)
            let b = Color(red: 0.03, green: 0.04, blue: 0.07)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(b))
            var y: CGFloat = 0, row = 0
            while y < size.height {
                var x: CGFloat = (row % 2 == 0) ? 0 : s
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(a))
                    x += s * 2
                }
                y += s; row += 1
            }
        }
    }
}
