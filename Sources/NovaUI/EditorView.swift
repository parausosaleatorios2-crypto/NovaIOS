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
import AVFoundation
import UniformTypeIdentifiers

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
    @State private var importandoAudio = false
    @State private var manifests: [String: EffectManifest] = [:]
    /// Desfazer/refazer (UndoHistory no APK): um passo por gravacao.
    @State private var undoStack: [NovaProject] = []
    @State private var importandoFFX = false
    @State private var redoStack: [NovaProject] = []
    @State private var lastSaved: NovaProject?

    @Environment(\.dismiss) private var dismiss

    /// Pasta do projeto (project.json + media/).
    private let folder: URL
    private let onSave: (NovaProject) -> Void
    private var mediaRoot: URL { folder.appendingPathComponent(NovaProjectIO.mediaFolder) }

    /// Modo demonstracao (capturas do CI): roda o roteiro de DemoMode.swift.
    private let demo: Bool

    public init(project: NovaProject, folder: URL, onSave: @escaping (NovaProject) -> Void,
                demo: Bool = false) {
        self.demo = demo
        _project = State(initialValue: project)
        _lastSaved = State(initialValue: project)
        self.folder = folder
        self.onSave = onSave
    }

    private var comp: Composition { project.mainComposition ?? Composition() }

    /// Grava e registra um passo de desfazer (so se algo mudou).
    private func commit() {
        if let last = lastSaved, last != project {
            undoStack.append(last)
            if undoStack.count > 60 { undoStack.removeFirst() }
            redoStack.removeAll()
        }
        lastSaved = project
        onSave(project)
    }

    private func desfazer() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(project)
        project = prev
        lastSaved = prev
        onSave(prev)
        if let id = selectedLayer, comp.layer(id: id) == nil { selectedLayer = nil }
    }

    private func refazer() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(project)
        project = next
        lastSaved = next
        onSave(next)
    }

    /// Altera uma camada. `save` false durante gestos e sliders (grava no fim).
    private func editLayer(_ id: UUID, _ save: Bool, _ change: (inout Layer) -> Void) {
        guard let ci = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first,
              let li = project.compositions[ci].layers.firstIndex(where: { $0.id == id }) else { return }
        change(&project.compositions[ci].layers[li])
        if save { commit() }
    }

    /// Altera a composicao principal e grava o projeto.
    private func editComp(_ change: (inout Composition) -> Void) {
        guard let i = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first else { return }
        change(&project.compositions[i])
        commit()
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
                    TimelineView(composition: comp, time: $time, selected: $selectedLayer,
                                 editLayer: { id, save, change in editLayer(id, save, change) },
                                 editComp: { change in editComp(change) })
                        .frame(height: 190)
                }

                bottomBar
            }
            .background(NovaTheme.background)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { s in
            Group {
            switch s {
            case .efeitos:  EffectBrowserView { e in aplicarEfeito(e); sheet = nil }
            case .layout:   LayoutPickerSheet(selected: $layout)
            case .exportar: ExportSheet(composition: comp, mediaRoot: mediaRoot, manifests: manifests, time: time)
            case .propriedades(let id):
                LayerPropertiesSheet(comp: comp, layerID: id, time: time, manifests: manifests,
                                     edit: { id, save, change in editLayer(id, save, change) },
                                     mediaRoot: mediaRoot)
            case .info(let t, let m): InfoSheet(titulo: t, mensagem: m)
            }
            }
            .novaPainel()
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItems,
                      maxSelectionCount: nil, selectionBehavior: .ordered,
                      matching: .any(of: [.images, .videos]),
                      preferredItemEncoding: .current)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importar(items) }
        }
        .fileImporter(isPresented: $importandoAudio, allowedContentTypes: [.audio],
                      allowsMultipleSelection: true) { r in
            if case .success(let urls) = r { Task { await importarAudio(urls) } }
        }
        .alert("Texto".loc, isPresented: $pedindoTexto) {
            TextField("Digite o texto".loc, text: $novoTexto)
            Button("Cancelar".loc, role: .cancel) {}
            Button("Adicionar".loc) { adicionarTexto(novoTexto) }
        }
        .task(id: playing) { await tocar() }
        .task { if demo { await roteiroDemo() } }
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

    private func importarAudio(_ urls: [URL]) async {
        importing = true
        defer { importing = false }
        try? FileManager.default.createDirectory(at: mediaRoot, withIntermediateDirectories: true)
        var cursor = time
        var novas: [Layer] = []
        for u in urls {
            let ok = u.startAccessingSecurityScopedResource()
            defer { if ok { u.stopAccessingSecurityScopedResource() } }
            var name = u.lastPathComponent
            var n = 2
            while FileManager.default.fileExists(atPath: mediaRoot.appendingPathComponent(name).path) {
                name = "\(u.deletingPathExtension().lastPathComponent)-\(n).\(u.pathExtension)"; n += 1
            }
            let dst = mediaRoot.appendingPathComponent(name)
            do { try FileManager.default.copyItem(at: u, to: dst) } catch { aviso = error.localizedDescription; continue }
            let secs = Float((try? await AVURLAsset(url: dst).load(.duration).seconds) ?? 0)
            var l = Layer(name: u.deletingPathExtension().lastPathComponent, kind: .audio)
            l.mediaPath = name
            l.duration = max(0.1, secs)
            l.sourceDuration = secs
            l.startTime = cursor
            cursor += l.duration
            novas.append(l)
        }
        guard !novas.isEmpty else { return }
        editComp { c in
            for l in novas { c.add(l) }
            c.duration = max(c.duration, c.layers.map(\.endTime).max() ?? c.duration)
        }
        selectedLayer = novas.last?.id
    }

    private func adicionarForma(_ f: MaskShape) {
        var l = Layer(name: f.label.loc, kind: .shape)
        let lado = min(comp.size.x, comp.size.y) * 0.4
        let size = SIMD2<Float>(lado, lado)
        l.size = size
        l.shapeStyle = ShapeStyle(shape: f)
        l.transform.anchorPoint = Animated(size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func adicionarNulo() {
        var l = Layer(name: "Nulo".loc, kind: .null)
        l.size = SIMD2(100, 100)
        l.transform.anchorPoint = Animated(SIMD2(50, 50))
        l.transform.position = Animated(comp.size / 2)
        l.startTime = 0
        l.duration = comp.duration
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func adicionarAjuste() {
        var l = Layer(name: "Ajuste".loc, kind: .adjustment)
        l.size = comp.size
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
        aviso = "Aplique efeitos nesta camada: valem para tudo que está embaixo.".loc
    }

    private func adicionarMarcador() {
        editComp { c in
            var m = c.markers ?? []
            if !m.contains(where: { abs($0 - time) < 0.01 }) { m.append(time) }
            c.markers = m.sorted()
        }
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

    /// Roteiro das capturas do CI (tempos em DemoMode.swift).
    private func roteiroDemo() async {
        func esperar(_ s: Double) async { try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000)) }
        try? await EffectRegistry.shared.load()
        let todos = await EffectRegistry.shared.all
        let efeito = todos.first { $0.id.lowercased().contains("gaussian") && EffectRenderer.isAvailable("fx_\($0.slug)") }
            ?? todos.first { EffectRenderer.isAvailable("fx_\($0.slug)") && EffectVerification.isUsable($0.id) }
        time = 1
        await esperar(4); selectedLayer = comp.layers.first?.id          // texto (camada de cima)
        await esperar(2); sheet = .efeitos                              // 6 s
        await esperar(3)                                                 // 9 s: aplica como o toque no navegador
        if let efeito { aplicarEfeito(efeito); sheet = nil }
        await esperar(5); sheet = nil                                    // 14 s
        await esperar(4); sheet = .exportar                              // 18 s
        await esperar(4); sheet = nil                                    // 22 s
    }

    /// Avanca o tempo enquanto toca, no ritmo da composicao.
    private func tocar() async {
        guard playing else { return }
        if time >= comp.duration { time = 0 }
        // Som da previa: video e audio da composicao, a partir do cursor.
        var player: AVPlayer?
        if let item = await AudioMux.previewItem(composition: comp, mediaRoot: mediaRoot) {
            let p = AVPlayer(playerItem: item)
            await p.seek(to: CMTime(seconds: Double(time), preferredTimescale: 600),
                         toleranceBefore: .zero, toleranceAfter: .zero)
            p.play()
            player = p
        }
        defer { player?.pause() }
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

    /// Faixa de transporte do APK (x02.E): 52 dp, cor de superficie, botoes de
    /// largura igual — Desfazer, Refazer, Ponto anterior (J), Reproduzir/Pausar,
    /// Proximo ponto (K), Copiar e colar camada, Vista da previa / acoes.
    private var transport: some View {
        HStack(spacing: 0) {
            botaoFaixa("arrow.uturn.backward", habilitado: !undoStack.isEmpty) { desfazer() }
            botaoFaixa("arrow.uturn.forward", habilitado: !redoStack.isEmpty) { refazer() }
            botaoFaixa("backward.frame.fill") { irPara(pontoAnterior()) }
            Button { playing.toggle() } label: {
                RoundedRectangle(cornerRadius: 12).fill(NovaTheme.accent)
                    .frame(width: 40, height: 34)
                    .overlay(Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Color.black))
            }
            .frame(maxWidth: .infinity)
            botaoFaixa("forward.frame.fill") { irPara(proximoPonto()) }
            botaoFaixa("plus.square.on.square", habilitado: selectedLayer != nil) { duplicarSelecionada() }
            Menu {
                Button { adicionarMarcador() } label: { Label("Marcador".loc, systemImage: "bookmark") }
                if let id = selectedLayer {
                    Button { sheet = .propriedades(id) } label: { Label("Propriedades".loc, systemImage: "slider.horizontal.3") }
                    Button(role: .destructive) { excluirSelecionada() } label: { Label("Apagar camada".loc, systemImage: "trash") }
                }
                Button { sheet = .exportar } label: { Label("Exportar".loc, systemImage: "square.and.arrow.up") }
            } label: {
                Image(systemName: "ellipsis.circle").font(.system(size: 17)).foregroundStyle(NovaTheme.dim)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 4)
        .frame(height: 52)
        .background(NovaTheme.surface)
        .fileImporter(isPresented: $importandoFFX, allowedContentTypes: AEImportador.tipos) { r in
            guard case .success(let url) = r else { return }
            Task { await aplicarFFX(url) }
        }
        .overlay(alignment: .bottomTrailing) {
            Text(timecode(time)).font(.system(size: 9, design: .monospaced))
                .foregroundStyle(NovaTheme.dim2).padding(.trailing, 8).padding(.bottom, 1)
        }
    }

    private func botaoFaixa(_ icon: String, habilitado: Bool = true, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Image(systemName: icon).font(.system(size: 17))
                .foregroundStyle(habilitado ? NovaTheme.dim : NovaTheme.dim2.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .disabled(!habilitado)
        .frame(maxWidth: .infinity)
    }

    /// Pontos de navegacao (J/K do APK): inicio/fim das camadas, keyframes e marcadores.
    private var pontos: [Float] {
        var p: [Float] = [0, comp.duration]
        for l in comp.layers {
            p.append(l.startTime); p.append(l.endTime)
            for k in l.transform.position.keyframes { p.append(k.time) }
            for k in l.transform.scale.keyframes { p.append(k.time) }
            for k in l.transform.rotationZ.keyframes { p.append(k.time) }
            for k in l.transform.opacity.keyframes { p.append(k.time) }
        }
        p.append(contentsOf: comp.markers ?? [])
        return Array(Set(p.map { ($0 * 1000).rounded() / 1000 })).sorted()
    }
    private func pontoAnterior() -> Float { pontos.last { $0 < time - 0.001 } ?? 0 }
    private func proximoPonto() -> Float { pontos.first { $0 > time + 0.001 } ?? comp.duration }
    private func irPara(_ t: Float) { playing = false; time = min(max(0, t), comp.duration) }

    /// Preset .ffx do After Effects: os efeitos vao para a camada selecionada.
    private func aplicarFFX(_ url: URL) async {
        guard let id = selectedLayer ?? comp.layers.first?.id, let l = comp.layer(id: id) else {
            aviso = "Adicione uma camada antes do efeito.".loc; return
        }
        do {
            let tam = l.size ?? SIMD2(Float(comp.width), Float(comp.height))
            let (efeitos, animacao, avisos) = try await AEImportador.efeitosDoPreset(url, tamanho: tam)
            var chaves = 0
            let t0 = time
            editComp { c in
                if let i = c.layers.firstIndex(where: { $0.id == id }) {
                    c.layers[i].effects += efeitos
                    if !animacao.isEmpty { chaves = AEImportador.aplicarAnimacao(animacao, em: &c.layers[i], aPartirDe: t0) }
                }
            }
            if !efeitos.isEmpty { await carregarManifestos() }
            var ok = String(format: "%d efeito(s) do preset aplicados em \"%@\".".loc, efeitos.count, l.name)
            if chaves > 0 { ok += " " + String(format: "Animação: %d chaves a partir do cursor.".loc, chaves) }
            aviso = avisos.isEmpty ? ok : ok + "\n\n" + avisos.prefix(8).joined(separator: "\n")
            if !efeitos.isEmpty { selectedLayer = id; sheet = .propriedades(id) }
        } catch {
            aviso = error.localizedDescription
        }
    }

    /// "Copiar e colar camada" do APK: duplica a camada selecionada logo acima.
    private func duplicarSelecionada() {
        guard let id = selectedLayer, let l = comp.layer(id: id) else { return }
        var copia = l
        copia.id = UUID()
        copia.name = l.name + " " + "cópia".loc
        editComp { c in
            if let i = c.layers.firstIndex(where: { $0.id == id }) { c.layers.insert(copia, at: i) }
        }
        selectedLayer = copia.id
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

    /// Ferramentas da barra de baixo, na ordem do enum do APK (s22, lido do
    /// Compose descompilado): (id, rotulo, icone, precisa de camada).
    /// As de camada ficam apagadas sem camada selecionada, como no Android.
    private struct Ferramenta: Identifiable {
        let id: String, label: String, icon: String, precisaCamada: Bool
    }

    private var ferramentas: [Ferramenta] {
        [
            .init(id: "camada", label: "Camada", icon: "square.3.layers.3d", precisaCamada: true),
            .init(id: "animar", label: "Animar", icon: "diamond", precisaCamada: true),
            .init(id: "efeitos", label: "Efeitos", icon: "wand.and.stars", precisaCamada: true),
            .init(id: "ia", label: "IA", icon: "sparkles", precisaCamada: false),
            .init(id: "biblioteca", label: "Biblioteca", icon: "books.vertical", precisaCamada: false),
            .init(id: "legendas", label: "Legendas", icon: "captions.bubble", precisaCamada: false),
            .init(id: "link", label: "Link", icon: "link", precisaCamada: false),
            .init(id: "drive", label: "Drive", icon: "externaldrive", precisaCamada: false),
            .init(id: "layout", label: "Layout", icon: "rectangle.3.group", precisaCamada: false),
            .init(id: "removerFundo", label: "Remover BG", icon: "person.crop.rectangle", precisaCamada: true),
            .init(id: "separar", label: "Separar partes", icon: "square.split.2x2", precisaCamada: true),
            .init(id: "upscale", label: "Aumentar resolução", icon: "sparkle.magnifyingglass", precisaCamada: true),
            .init(id: "colorizar", label: "Colorizar", icon: "paintpalette", precisaCamada: true),
            .init(id: "profundidade", label: "Profundidade (nuvem)", icon: "cube.transparent", precisaCamada: true),
        ]
    }

    /// Barra de baixo do editor do APK (x02.c): divisoria, faixa de 76 dp na cor
    /// de superficie, "+ Adicionar" (quadrado 36 dp, cantos 12, gradiente) e a
    /// fileira rolavel de ferramentas (icone 24 em caixa 46x34 de cantos 11,
    /// rotulo 11 sp; realce verde a 18% quando ativa; 28% quando desabilitada).
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(NovaTheme.line).frame(height: 1)
            HStack(spacing: 0) {
                Menu {
                    Button { showPicker = true } label: { Label("Mídia".loc, systemImage: "photo.on.rectangle") }
                    Button { pedindoTexto = true } label: { Label("Texto".loc, systemImage: "textformat") }
                    Menu {
                        Button { adicionarForma(.rectangle) } label: { Label("Retângulo".loc, systemImage: "rectangle") }
                        Button { adicionarForma(.ellipse) } label: { Label("Elipse".loc, systemImage: "circle") }
                        Button { adicionarForma(.star) } label: { Label("Estrela".loc, systemImage: "star") }
                        Button { adicionarForma(.polygon) } label: { Label("Polígono".loc, systemImage: "hexagon") }
                    } label: { Label("Forma".loc, systemImage: "square.on.circle") }
                    Button { adicionarSolido() } label: { Label("Sólido".loc, systemImage: "square.fill") }
                    Button { importandoAudio = true } label: { Label("Áudio".loc, systemImage: "music.note") }
                    Button { adicionarAjuste() } label: { Label("Camada de ajuste".loc, systemImage: "slider.horizontal.below.rectangle") }
                    Button { adicionarNulo() } label: { Label("Nulo".loc, systemImage: "scope") }
                    Divider()
                    Button { importandoFFX = true } label: {
                        Label("Preset do After Effects (.ffx)".loc, systemImage: "wand.and.rays")
                    }
                } label: {
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [NovaTheme.accent, Color(red: 0, green: 0.78, blue: 0.62)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .opacity(0.9)
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(Color.black))
                        Text("Adicionar".loc).font(.system(size: 11)).foregroundStyle(NovaTheme.accent)
                    }
                    .frame(width: 70)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(ferramentas) { f in
                            let habilitada = !f.precisaCamada || selectedLayer != nil
                            FerramentaBotao(label: f.label.loc, icon: f.icon,
                                            ativa: ferramentaAtiva == f.id, habilitada: habilitada) {
                                tocarFerramenta(f.id)
                            }
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 76)
            .background(NovaTheme.surface)
        }
    }

    private var ferramentaAtiva: String? {
        switch sheet {
        case .efeitos: return "efeitos"
        case .layout: return "layout"
        case .propriedades: return "camada"
        default: return nil
        }
    }

    private func tocarFerramenta(_ id: String) {
        switch id {
        case "camada", "animar":
            if let s = selectedLayer { sheet = .propriedades(s) }
        case "efeitos": sheet = .efeitos
        case "layout": sheet = .layout
        case "biblioteca": showPicker = true
        default:
            let precisaConta = ["ia", "legendas", "removerFundo", "separar", "upscale", "colorizar", "profundidade"]
            sheet = .info(ferramentas.first { $0.id == id }?.label.loc ?? id,
                          precisaConta.contains(id)
                            ? "No Android esta ferramenta roda no servidor da Nova (com a sua conta). Entre em Perfil › Conta para usar.".loc
                            : "Instale a extensão em Perfil › Extensões.".loc)
        }
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

/// Botao de ferramenta da barra do editor, com as medidas do APK (x02.D).
struct FerramentaBotao: View {
    let label: String
    let icon: String
    let ativa: Bool
    let habilitada: Bool
    let acao: () -> Void
    @State private var pressionado = false

    var body: some View {
        let cor: Color = !habilitada ? NovaTheme.text.opacity(0.28) : (ativa ? NovaTheme.accent : NovaTheme.text)
        Button(action: acao) {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(NovaTheme.accent.opacity(ativa ? 0.18 : 0))
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .stroke(NovaTheme.accent.opacity(ativa ? 0.9 : 0), lineWidth: ativa ? 0.9 : 0))
                    .frame(width: 46, height: 34)
                    .overlay(Image(systemName: icon).font(.system(size: 19)).foregroundStyle(cor))
                Text(label).font(.system(size: 11)).foregroundStyle(cor)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .padding(.horizontal, 2)
            }
            .frame(width: 66)
            .scaleEffect(pressionado ? 0.94 : 1)
            .animation(.easeOut(duration: 0.09), value: pressionado)
        }
        .buttonStyle(.plain)
        .disabled(!habilitada)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressionado = true }
            .onEnded { _ in pressionado = false })
    }
}
