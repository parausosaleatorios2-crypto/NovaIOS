//
//  TemplatesView.swift
//  NovaUI
//
//  Templates do app (Resources/templates/*.novatemplate, os mesmos do APK),
//  importar .nova feito no Android e acoes de projeto (duplicar, exportar .nova,
//  apagar).
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Carrossel de templates (Inicio)

struct TemplatesCarrossel: View {
    @ObservedObject var store: ProjectStore
    @State private var templates: [TemplateDoApp] = []
    @State private var aberto: TemplateDoApp?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Templates".loc).font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(templates.count)").font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
            }.padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templates) { t in
                        Button { aberto = t } label: { CartaoDeTemplate(template: t) }
                            .buttonStyle(.plain)
                    }
                }.padding(.horizontal, 16)
            }
        }
        .task { if templates.isEmpty { templates = TemplateDoApp.todos() } }
        .sheet(item: $aberto) { t in TemplateSheet(template: t, store: store) }
    }
}

struct CartaoDeTemplate: View {
    let template: TemplateDoApp
    private var cores: [Color] {
        let h = Double(abs(template.id.hashValue % 360)) / 360
        return [Color(hue: h, saturation: 0.55, brightness: 0.35),
                Color(hue: (h + 0.12).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.18)]
    }
    var body: some View {
        let vertical = template.altura > template.largura
        VStack(alignment: .leading, spacing: 5) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: cores, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 112, height: vertical ? 150 : 72)
                .overlay {
                    Text(template.campos.first(where: { $0.tipo == "texto" })?.padrao ?? template.nome)
                        .font(.system(size: 13, weight: .heavy)).foregroundStyle(.white)
                        .multilineTextAlignment(.center).lineLimit(3).padding(6)
                }
                .overlay(alignment: .topTrailing) {
                    Text(vertical ? "9:16" : "16:9").font(.system(size: 8.5, weight: .bold))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(Capsule().fill(.black.opacity(0.4))).padding(5)
                }
            Text(template.nome).font(.system(size: 11.5, weight: .medium)).lineLimit(1)
            Text(String(format: "%.1fs", template.duracao)).font(.system(size: 10))
                .foregroundStyle(NovaTheme.dim)
        }
        .frame(width: 112)
    }
}

struct TemplateSheet: View {
    let template: TemplateDoApp
    @ObservedObject var store: ProjectStore
    @State private var valores: [String: String] = [:]
    @State private var cores: [String: Color] = [:]
    @State private var trabalhando = false
    @State private var mensagem: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(template.descricao).font(.system(size: 12.5)).foregroundStyle(NovaTheme.dim)
                    LabeledContent("Tamanho".loc, value: "\(template.largura)×\(template.altura)")
                    LabeledContent("Duração".loc, value: String(format: "%.1fs", template.duracao))
                }
                if !template.campos.isEmpty {
                    Section("Personalizar".loc) {
                        ForEach(template.campos, id: \.id) { c in campo(c) }
                    }
                }
                Section {
                    Button {
                        Task { await criar() }
                    } label: {
                        HStack {
                            if trabalhando { ProgressView() }
                            Text("Usar template".loc).font(.system(size: 15, weight: .semibold))
                        }.frame(maxWidth: .infinity)
                    }.disabled(trabalhando)
                    if let mensagem {
                        Text(mensagem).font(.system(size: 11.5)).foregroundStyle(NovaTheme.dim)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(NovaTheme.background)
            .navigationTitle(template.nome).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar".loc) { dismiss() } } }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            for c in template.campos {
                valores[c.id] = c.padrao
                if c.tipo == "cor", let rgba = ConversorAndroid.hex(c.padrao) {
                    cores[c.id] = Color(.sRGB, red: Double(rgba.x), green: Double(rgba.y),
                                        blue: Double(rgba.z), opacity: Double(rgba.w))
                }
            }
        }
    }

    @ViewBuilder private func campo(_ c: TemplateDoApp.Campo) -> some View {
        switch c.tipo {
        case "cor":
            ColorPicker(c.rotulo, selection: Binding(
                get: { cores[c.id] ?? .white },
                set: { cores[c.id] = $0; valores[c.id] = Self.hex($0) }))
        case "numero":
            let lo = c.min ?? 0, hi = c.max ?? max(lo + 1, (Double(c.padrao) ?? 1) * 2)
            VStack(alignment: .leading) {
                Text(c.rotulo)
                Slider(value: Binding(
                    get: { Double(valores[c.id] ?? c.padrao) ?? lo },
                    set: { valores[c.id] = String(format: "%.3f", $0) }), in: lo...hi)
            }
        default:
            TextField(c.rotulo, text: Binding(get: { valores[c.id] ?? c.padrao },
                                              set: { valores[c.id] = $0 }), axis: .vertical)
        }
    }

    static func hex(_ c: Color) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X", Int(a * 255), Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private func criar() async {
        trabalhando = true; defer { trabalhando = false }
        guard let r = await template.composicao(valores: valores) else {
            mensagem = "Não consegui ler esse template.".loc; return
        }
        var comp = r.composicao
        comp.name = store.nomeLivre(comp.name)
        if store.create(composition: comp) != nil {
            dismiss()
        } else {
            mensagem = store.lastError ?? "Não consegui criar o projeto.".loc
        }
    }
}

// MARK: - Importar .nova

struct ImportarNovaBotao: View {
    @ObservedObject var store: ProjectStore
    @State private var escolhendo = false
    @State private var trabalhando = false
    @State private var aviso: String?

    var body: some View {
        Button { escolhendo = true } label: {
            HStack(spacing: 4) {
                if trabalhando { ProgressView().scaleEffect(0.7) }
                Image(systemName: "square.and.arrow.down")
                Text("Importar .nova".loc)
            }
            .font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.accent)
        }
        .disabled(trabalhando)
        .fileImporter(isPresented: $escolhendo, allowedContentTypes: ImportadorNova.tipos) { r in
            guard case .success(let url) = r else { return }
            Task { await importar(url) }
        }
        .alert("Importar .nova".loc, isPresented: Binding(get: { aviso != nil }, set: { if !$0 { aviso = nil } })) {
            Button("OK") { aviso = nil }
        } message: { Text(aviso ?? "") }
    }

    private func importar(_ url: URL) async {
        trabalhando = true; defer { trabalhando = false }
        do {
            var (comp, midias, avisos) = try await ImportadorNova.importar(url)
            comp.name = store.nomeLivre(comp.name)
            defer { try? FileManager.default.removeItem(at: midias) }
            guard let p = store.create(composition: comp) else {
                aviso = store.lastError ?? "Não consegui criar o projeto.".loc; return
            }
            let destino = store.folder(for: p).appendingPathComponent(NovaProjectIO.mediaFolder)
            try? FileManager.default.createDirectory(at: destino, withIntermediateDirectories: true)
            for f in (try? FileManager.default.contentsOfDirectory(at: midias, includingPropertiesForKeys: nil)) ?? [] {
                try? FileManager.default.moveItem(at: f, to: destino.appendingPathComponent(f.lastPathComponent))
            }
            aviso = avisos.isEmpty ? "Projeto \"\(p.name)\" importado.".loc
                : "Projeto importado, com avisos:\n".loc + avisos.prefix(6).joined(separator: "\n")
        } catch {
            aviso = error.localizedDescription
        }
    }
}

// MARK: - Acoes de projeto

struct AcoesDoProjeto: ViewModifier {
    let project: NovaProject
    @ObservedObject var store: ProjectStore
    @State private var apagar = false
    @State private var pacote: URL?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button { duplicar() } label: { Label("Duplicar".loc, systemImage: "plus.square.on.square") }
                Button { exportarNova() } label: { Label("Exportar .nova".loc, systemImage: "square.and.arrow.up") }
                Button(role: .destructive) { apagar = true } label: { Label("Apagar".loc, systemImage: "trash") }
            }
            .confirmationDialog("Apagar \"\(project.name)\"?".loc, isPresented: $apagar, titleVisibility: .visible) {
                Button("Apagar".loc, role: .destructive) { store.delete(project) }
                Button("Cancelar".loc, role: .cancel) {}
            } message: { Text("O projeto e as mídias dele somem deste aparelho.".loc) }
            .sheet(item: Binding(get: { pacote.map(ArquivoParaCompartilhar.init) },
                                 set: { if $0 == nil { pacote = nil } })) { a in
                ShareSheet(url: a.url)
            }
    }

    private func duplicar() {
        guard var comp = project.mainComposition else { return }
        comp.id = UUID()
        comp.name = store.nomeLivre(project.name + " (cópia)".loc)
        guard let novo = store.create(composition: comp) else { return }
        // «Duplicar um projeto leva a capa junto» — e as midias.
        let de = store.folder(for: project).appendingPathComponent(NovaProjectIO.mediaFolder)
        let para = store.folder(for: novo).appendingPathComponent(NovaProjectIO.mediaFolder)
        try? FileManager.default.createDirectory(at: para, withIntermediateDirectories: true)
        for f in (try? FileManager.default.contentsOfDirectory(at: de, includingPropertiesForKeys: nil)) ?? [] {
            try? FileManager.default.copyItem(at: f, to: para.appendingPathComponent(f.lastPathComponent))
        }
    }

    private func exportarNova() {
        let safe = project.name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
        let destino = FileManager.default.temporaryDirectory.appendingPathComponent("\(safe).nova")
        try? FileManager.default.removeItem(at: destino)
        do {
            try NovaProjectIO.pack(folder: store.folder(for: project), to: destino)
            pacote = destino
        } catch {
            pacote = nil
        }
    }
}

struct ArquivoParaCompartilhar: Identifiable {
    let url: URL
    var id: String { url.path }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension ProjectStore {
    /// O ProjectStore usa o nome como pasta: dois projetos com o mesmo nome se
    /// sobrescreveriam. Devolve "Nome", "Nome 2", "Nome 3"...
    func nomeLivre(_ base: String) -> String {
        let usados = Set(projects.map { $0.name.lowercased() })
        guard usados.contains(base.lowercased()) else { return base }
        var n = 2
        while usados.contains("\(base) \(n)".lowercased()) { n += 1 }
        return "\(base) \(n)"
    }
}

extension View {
    func acoesDoProjeto(_ p: NovaProject, store: ProjectStore) -> some View {
        modifier(AcoesDoProjeto(project: p, store: store))
    }
}
