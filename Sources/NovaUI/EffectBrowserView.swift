//
//  EffectBrowserView.swift
//  NovaUI
//
//  Navegador dos 1.490 efeitos: busca, categorias e os parametros de cada um,
//  lidos do mesmo XML que o app Android usa.
//

import SwiftUI

public struct EffectBrowserView: View {
    @State private var busca = ""
    @State private var categoria: String?
    @State private var entries: [EffectIndexEntry] = []
    @State private var categorias: [(String, Int)] = []
    @State private var carregando = true
    @State private var erro: String?
    @Environment(\.dismiss) private var dismiss

    let onPick: (EffectIndexEntry) -> Void
    public init(onPick: @escaping (EffectIndexEntry) -> Void) { self.onPick = onPick }

    public var body: some View {
        NavigationStack {
            Group {
                if carregando {
                    VStack(spacing: 10) {
                        ProgressView().tint(NovaTheme.accent)
                        Text("Lendo o catálogo de efeitos".loc)
                            .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let erro {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28)).foregroundStyle(NovaTheme.warning)
                        Text(erro).font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                            .multilineTextAlignment(.center).padding(.horizontal, 30)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    lista
                }
            }
            .background(NovaTheme.background)
            .navigationTitle("Efeitos".loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Fechar".loc) { dismiss() } } }
        }
        .preferredColorScheme(.dark)
        .task { await carregar() }
    }

    private var lista: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    chip("Tudo", nil, entries.count)
                    ForEach(categorias, id: \.0) { c in chip(c.0, c.0, c.1) }
                }.padding(.horizontal, 14).padding(.vertical, 9)
            }
            Divider().overlay(NovaTheme.line)
            List(resultados) { e in
                Button { onPick(e) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(e.name).font(.system(size: 13, weight: .medium))
                        HStack(spacing: 6) {
                            if let c = e.category {
                                Text(c).font(.system(size: 9))
                                    .padding(.horizontal, 5).padding(.vertical, 1.5)
                                    .background(Capsule().fill(NovaTheme.surface2))
                                    .foregroundStyle(NovaTheme.dim)
                            }
                            if let en = e.nameEn, en != e.name {
                                Text(en).font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
                            }
                        }
                    }
                }
                .foregroundStyle(NovaTheme.text)
                .listRowBackground(NovaTheme.surface)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $busca, prompt: "Procurar efeito".loc)
        }
    }

    private func chip(_ titulo: String, _ valor: String?, _ n: Int) -> some View {
        Button { categoria = valor } label: {
            HStack(spacing: 4) {
                Text(titulo).font(.system(size: 11.5, weight: .medium))
                Text("\(n)").font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
            }
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(categoria == valor
                                       ? NovaTheme.accent.opacity(0.16) : NovaTheme.surface))
            .overlay(Capsule().strokeBorder(categoria == valor
                                            ? NovaTheme.accent.opacity(0.4) : NovaTheme.line))
            .foregroundStyle(categoria == valor ? NovaTheme.accent : NovaTheme.dim)
        }
    }

    private var resultados: [EffectIndexEntry] {
        // A busca de verdade esta no EffectRegistry (actor); aqui filtramos o
        // indice ja carregado para nao cruzar o ator a cada tecla.
        var out = entries
        if let c = categoria { out = out.filter { $0.category == c } }
        let q = busca.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return out }
        return out.filter {
            let n = $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            if n.contains(q) { return true }
            if let e = $0.nameEn, e.lowercased().contains(q.lowercased()) { return true }
            return $0.tags.contains { $0.lowercased().contains(q.lowercased()) }
        }
    }

    private func carregar() async {
        let reg = EffectRegistry.shared
        do {
            try await reg.load()
            entries = await reg.all
            categorias = await reg.categories.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
            let errs = await reg.indexErrors
            if !errs.isEmpty && entries.isEmpty {
                erro = errs.prefix(3).joined(separator: "\n")
            }
        } catch {
            erro = error.localizedDescription
        }
        carregando = false
    }
}

// MARK: - Exportar

public struct ExportSheet: View {
    let composition: Composition
    @State private var settings = ExportSettings()
    @Environment(\.dismiss) private var dismiss

    public init(composition: Composition) {
        self.composition = composition
        var s = ExportSettings()
        s.width = composition.width; s.height = composition.height
        s.frameRate = composition.frameRate
        _settings = State(initialValue: s)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Qualidade do vídeo".loc) {
                    LabeledContent("Tamanho".loc, value: "\(settings.width)×\(settings.height)")
                    LabeledContent("Quadros por segundo".loc, value: "\(Int(settings.frameRate))")
                    Picker("Formato".loc, selection: $settings.codec) {
                        Text("H.264").tag(ExportSettings.Codec.h264)
                        Text("HEVC").tag(ExportSettings.Codec.hevc)
                    }
                    Picker("Contêiner".loc, selection: $settings.container) {
                        Text("MP4").tag(ExportSettings.Container.mp4)
                        Text("MOV").tag(ExportSettings.Container.mov)
                    }
                }
                Section {
                    Toggle("Exportar com fundo transparente".loc,
                           isOn: $settings.transparentBackground)
                    if settings.transparentBackground {
                        Text("Fundo transparente exige HEVC com alfa, em .mov. O MP4 não guarda alfa.".loc)
                            .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                    }
                }
                Section {
                    Text("A exportação precisa do Compositor ligado ao provedor de conteúdo das camadas, que ainda não está escrito. Veja Docs/PENDENCIAS.md.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.warning)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NovaTheme.background)
            .navigationTitle("Exportar".loc).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar".loc) { dismiss() } }
            }
        }
        .preferredColorScheme(.dark)
    }
}
