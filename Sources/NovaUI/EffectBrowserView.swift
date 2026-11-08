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
            // So os efeitos cujo shader esta na metallib do app (os outros nao
            // compilaram e aplicar daria erro).
            let todos = await reg.all
            entries = todos.filter { EffectRenderer.isAvailable("fx_\($0.slug)") && EffectVerification.isUsable($0.id) }
            var cont: [String: Int] = [:]
            for e in entries { cont[e.category ?? "other", default: 0] += 1 }
            categorias = cont.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
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
