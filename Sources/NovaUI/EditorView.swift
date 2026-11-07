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

public struct EditorView: View {
    @State private var project: NovaProject
    @State private var time: Float = 0
    @State private var playing = false
    @State private var selectedLayer: UUID?
    @State private var layout: EditorLayout = .nova
    @State private var sheet: EditorSheet?
    @State private var installedExtensions: Set<String> = []   // vazio: nenhuma instalada

    @Environment(\.dismiss) private var dismiss

    public init(project: NovaProject) { _project = State(initialValue: project) }

    private var comp: Composition { project.mainComposition ?? Composition() }

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
            case .efeitos:  EffectBrowserView { _ in sheet = nil }
            case .layout:   LayoutPickerSheet(selected: $layout)
            case .exportar: ExportSheet(composition: comp)
            case .info(let t, let m): InfoSheet(titulo: t, mensagem: m)
            }
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
            PreviewSurface(composition: comp, time: time)
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
    case info(String, String)
    var id: String {
        switch self {
        case .efeitos: return "efeitos"; case .layout: return "layout"
        case .exportar: return "exportar"; case .info(let t, _): return "info-\(t)"
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
