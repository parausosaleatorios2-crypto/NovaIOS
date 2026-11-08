//
//  MarketplaceView.swift
//  NovaUI
//
//  Aba Marketplace: a comunidade (presets e efeitos), a Biblioteca NovaVision e
//  o que ja foi baixado. Textos do APK: «Comunidade», «Em alta na comunidade»,
//  «Mais baixados», «Buscar efeitos da comunidade», «Curtir», «Baixadas»,
//  «Biblioteca NovaVision», «Entre na sua conta para curtir»,
//  «Nada para “{0}” na comunidade.»
//

import SwiftUI

struct MarketplaceView: View {
    enum Aba: String, CaseIterable, Identifiable {
        case presets = "Presets", efeitos = "Efeitos", biblioteca = "Biblioteca", baixadas = "Baixadas"
        var id: String { rawValue }
    }

    @ObservedObject private var conta = NovaConta.shared
    @State private var aba: Aba = .presets
    @State private var busca = ""
    @State private var categoria: String?
    @State private var populares = false
    @State private var itens: [ItemDaComunidade] = []
    @State private var biblioteca: [ItemDaBiblioteca] = []
    @State private var baixados: [Baixados.Item] = []
    @State private var carregando = false
    @State private var erro: String?
    @State private var detalhe: ItemDaComunidade?

    private static let categoriasDePreset: [(String, String)] = [
        ("cc", "CC"), ("shake", "Shakes"), ("text", "Texto"), ("transition", "Transições"),
        ("other", "Outros")
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Marketplace".loc).font(.system(size: 19, weight: .bold))
                Spacer()
            }.padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 6)

            Picker("", selection: $aba) {
                ForEach(Aba.allCases) { Text($0.rawValue.loc).tag($0) }
            }
            .pickerStyle(.segmented).padding(.horizontal, 16).padding(.bottom, 8)

            if aba == .presets || aba == .efeitos || aba == .biblioteca {
                barraDeBusca
            }
            if aba == .presets { chipsDeCategoria }

            conteudo
        }
        .task(id: chave) { await carregar() }
        .sheet(item: $detalhe) { item in
            DetalheDaComunidade(item: item, tipo: aba == .efeitos ? .efeitos : .presets) { atualizado in
                if let i = itens.firstIndex(where: { $0.id == atualizado.id }) { itens[i] = atualizado }
            }
        }
    }

    private var chave: String { "\(aba.rawValue)|\(categoria ?? "")|\(populares)|\(conta.entrou)" }

    // MARK: busca e filtros

    private var barraDeBusca: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(NovaTheme.dim2)
            TextField(aba == .efeitos ? "Buscar efeitos da comunidade".loc : "Procurar".loc, text: $busca)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .onSubmit { Task { await carregar() } }
            if !busca.isEmpty {
                Button { busca = ""; Task { await carregar() } } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(NovaTheme.dim2)
                }
            }
            if aba != .biblioteca {
                Button { populares.toggle() } label: {
                    Text(populares ? "Mais baixados".loc : "Recentes".loc)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Capsule().fill(NovaTheme.surface2))
                        .foregroundStyle(populares ? NovaTheme.accent : NovaTheme.dim)
                }
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface))
        .padding(.horizontal, 16).padding(.bottom, 6)
    }

    private var chipsDeCategoria: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                chip("Tudo", nil)
                ForEach(Self.categoriasDePreset, id: \.0) { chip($0.1, $0.0) }
            }.padding(.horizontal, 16).padding(.bottom, 8)
        }
    }

    private func chip(_ titulo: String, _ valor: String?) -> some View {
        Button { categoria = valor } label: {
            Text(titulo.loc).font(.system(size: 11.5, weight: .medium))
                .padding(.horizontal, 11).padding(.vertical, 5)
                .background(Capsule().fill(categoria == valor ? NovaTheme.accent.opacity(0.16) : NovaTheme.surface))
                .overlay(Capsule().strokeBorder(categoria == valor ? NovaTheme.accent.opacity(0.4) : NovaTheme.line))
                .foregroundStyle(categoria == valor ? NovaTheme.accent : NovaTheme.dim)
        }
    }

    // MARK: conteudo

    @ViewBuilder private var conteudo: some View {
        if carregando && itens.isEmpty && biblioteca.isEmpty && aba != .baixadas {
            VStack(spacing: 10) {
                ProgressView().tint(NovaTheme.accent)
                Text("O servidor pode levar alguns segundos para acordar.".loc)
                    .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let erro, aba != .baixadas {
            aviso("exclamationmark.triangle", erro, botao: "Tentar de novo")
        } else {
            switch aba {
            case .presets, .efeitos: gradeDaComunidade
            case .biblioteca: gradeDaBiblioteca
            case .baixadas: listaDeBaixadas
            }
        }
    }

    private let colunas = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    @ViewBuilder private var gradeDaComunidade: some View {
        if itens.isEmpty {
            aviso("sparkles", busca.isEmpty ? "Nada aqui ainda.".loc
                  : "Nada para “{0}” na comunidade.".loc.replacingOccurrences(of: "{0}", with: busca))
        } else {
            ScrollView {
                LazyVGrid(columns: colunas, spacing: 12) {
                    ForEach(itens) { item in
                        Button { detalhe = item } label: { CartaoDaComunidade(item: item) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, NovaTheme.Metrics.tabBarHeight + 16)
            }
            .refreshable { await carregar() }
        }
    }

    @ViewBuilder private var gradeDaBiblioteca: some View {
        if !conta.entrou {
            aviso("person.crop.circle.badge.exclamationmark",
                  "Entre para usar a nuvem, a IA e a biblioteca".loc)
        } else if biblioteca.isEmpty {
            aviso("tray", "Nada aqui ainda.".loc)
        } else {
            ScrollView {
                LazyVGrid(columns: colunas, spacing: 12) {
                    ForEach(biblioteca) { a in CartaoDaBiblioteca(item: a) }
                }
                .padding(.horizontal, 16).padding(.bottom, NovaTheme.Metrics.tabBarHeight + 16)
            }
            .refreshable { await carregar() }
        }
    }

    @ViewBuilder private var listaDeBaixadas: some View {
        if baixados.isEmpty {
            aviso("arrow.down.circle", "Nenhum download ainda. Baixe presets e efeitos da comunidade.".loc)
        } else {
            List {
                ForEach(baixados) { b in
                    HStack(spacing: 10) {
                        Miniatura(url: b.miniatura.flatMap(URL.init(string:)))
                            .frame(width: 54, height: 40).clipShape(RoundedRectangle(cornerRadius: 6))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(b.nome).font(.system(size: 13, weight: .medium))
                            Text("\(b.tipo == "efeitos" ? "Efeito".loc : "Preset".loc) · \(b.autor ?? "")")
                                .font(.system(size: 10.5)).foregroundStyle(NovaTheme.dim)
                        }
                    }
                    .listRowBackground(NovaTheme.surface)
                }
                .onDelete { idx in
                    for i in idx { Baixados.apagar(baixados[i]) }
                    baixados = Baixados.todos()
                }
            }
            .listStyle(.plain).scrollContentBackground(.hidden)
        }
    }

    private func aviso(_ icone: String, _ texto: String, botao: String? = nil) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icone).font(.system(size: 30)).foregroundStyle(NovaTheme.dim2)
            Text(texto).font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                .multilineTextAlignment(.center).padding(.horizontal, 36)
            if let botao {
                Button(botao.loc) { Task { await carregar() } }
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.accent)
            }
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    // MARK: carregar

    private func carregar() async {
        erro = nil
        if aba == .baixadas { baixados = Baixados.todos(); return }
        carregando = true
        defer { carregando = false }
        do {
            switch aba {
            case .presets:
                itens = try await NovaHub.shared.comunidade(.presets, busca: busca, categoria: categoria,
                                                            populares: populares)
            case .efeitos:
                itens = try await NovaHub.shared.comunidade(.efeitos, busca: busca, populares: populares)
            case .biblioteca:
                if conta.entrou { biblioteca = try await NovaHub.shared.biblioteca(busca: busca) }
            case .baixadas: break
            }
        } catch is CancellationError {
        } catch let e as URLError where e.code == .cancelled {
        } catch {
            erro = error.localizedDescription
        }
    }
}

// MARK: - Cartoes

struct Miniatura: View {
    let url: URL?
    var body: some View {
        ZStack {
            NovaTheme.surface2
            if let url {
                AsyncImage(url: url) { fase in
                    switch fase {
                    case .success(let img): img.resizable().scaledToFill()
                    case .failure: Image(systemName: "photo").foregroundStyle(NovaTheme.dim2)
                    default: ProgressView().tint(NovaTheme.dim2)
                    }
                }
            } else {
                Image(systemName: "sparkles").foregroundStyle(NovaTheme.dim2)
            }
        }
        .clipped()
    }
}

struct CartaoDaComunidade: View {
    let item: ItemDaComunidade
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Miniatura(url: item.thumbnailUrl.flatMap(URL.init(string:)))
                .aspectRatio(16 / 10, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .overlay(alignment: .topTrailing) {
                    if Baixados.contem(item.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(NovaTheme.accent).padding(5)
                    }
                }
            Text(item.name).font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
            HStack(spacing: 6) {
                Text(item.author?.name ?? "—").lineLimit(1)
                Spacer(minLength: 2)
                Label("\(item.downloads ?? 0)", systemImage: "arrow.down")
                Label("\(item.likes ?? 0)", systemImage: (item.liked ?? false) ? "heart.fill" : "heart")
                    .foregroundStyle((item.liked ?? false) ? NovaTheme.danger : NovaTheme.dim)
            }
            .labelStyle(CompactLabel())
            .font(.system(size: 10)).foregroundStyle(NovaTheme.dim)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface))
    }
}

struct CompactLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) { configuration.icon.font(.system(size: 9)); configuration.title }
    }
}

struct CartaoDaBiblioteca: View {
    let item: ItemDaBiblioteca
    private static let r2 = "https://pub-dbf9d9f66a884022bfd45a42eae81cbc.r2.dev/"
    private var miniatura: URL? {
        if let p = item.posterKey ?? item.previewKey { return URL(string: Self.r2 + p) }
        if let u = item.url, ["jpg", "jpeg", "png", "webp", "gif"].contains(URL(string: u)?.pathExtension.lowercased() ?? "") {
            return URL(string: u)
        }
        return nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Miniatura(url: miniatura).aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            Text(item.displayName ?? "—").font(.system(size: 12, weight: .medium)).lineLimit(1)
            Text([item.category, item.mediaKind].compactMap { $0 }.joined(separator: " · "))
                .font(.system(size: 10)).foregroundStyle(NovaTheme.dim).lineLimit(1)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface))
    }
}

// MARK: - Detalhe

struct DetalheDaComunidade: View {
    @State var item: ItemDaComunidade
    let tipo: NovaHub.Tipo
    let onChange: (ItemDaComunidade) -> Void
    @ObservedObject private var conta = NovaConta.shared
    @State private var trabalhando = false
    @State private var mensagem: String?
    @State private var baixado = false
    @Environment(\.dismiss) private var dismiss

    init(item: ItemDaComunidade, tipo: NovaHub.Tipo, onChange: @escaping (ItemDaComunidade) -> Void) {
        _item = State(initialValue: item)
        self.tipo = tipo
        self.onChange = onChange
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Miniatura(url: item.thumbnailUrl.flatMap(URL.init(string:)))
                        .aspectRatio(16 / 9, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(item.name).font(.system(size: 18, weight: .bold))
                    HStack(spacing: 8) {
                        Miniatura(url: item.author?.avatarUrl.flatMap(URL.init(string:)))
                            .frame(width: 24, height: 24).clipShape(Circle())
                        Text(item.author?.name ?? "—").font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                        Spacer()
                        Label("\(item.downloads ?? 0)", systemImage: "arrow.down.circle")
                        Label("\(item.likes ?? 0)", systemImage: "heart")
                    }.font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                    if let d = item.description, !d.isEmpty {
                        Text(d).font(.system(size: 13)).foregroundStyle(NovaTheme.text)
                    }
                    if let tags = item.tags, !tags.isEmpty {
                        Text(tags.prefix(12).map { "#\($0)" }.joined(separator: "  "))
                            .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
                    }

                    HStack(spacing: 10) {
                        Button { Task { await baixar() } } label: {
                            Label(baixado ? "Baixado".loc : "Baixar".loc,
                                  systemImage: baixado ? "checkmark" : "arrow.down")
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.accent.opacity(0.18)))
                                .foregroundStyle(NovaTheme.accent)
                        }.disabled(trabalhando)
                        Button { Task { await curtir() } } label: {
                            Label((item.liked ?? false) ? "Descurtir".loc : "Curtir".loc,
                                  systemImage: (item.liked ?? false) ? "heart.fill" : "heart")
                                .frame(maxWidth: .infinity).padding(.vertical, 11)
                                .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface2))
                                .foregroundStyle((item.liked ?? false) ? NovaTheme.danger : NovaTheme.text)
                        }.disabled(trabalhando)
                    }
                    .font(.system(size: 13, weight: .semibold))

                    if trabalhando { ProgressView().tint(NovaTheme.accent).frame(maxWidth: .infinity) }
                    if let mensagem {
                        Text(mensagem).font(.system(size: 11.5)).foregroundStyle(NovaTheme.dim)
                    }
                    if !conta.entrou {
                        Text("Entre na sua conta (Perfil) para baixar e curtir.".loc)
                            .font(.system(size: 11)).foregroundStyle(NovaTheme.warning)
                    }
                }
                .padding(16)
            }
            .background(NovaTheme.background)
            .navigationTitle(tipo == .efeitos ? "Efeito".loc : "Preset".loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fechar".loc) { dismiss() } } }
        }
        .preferredColorScheme(.dark)
        .onAppear { baixado = Baixados.contem(item.id) }
    }

    private func baixar() async {
        guard conta.entrou else { mensagem = "Entre na sua conta (Perfil) para baixar e curtir.".loc; return }
        trabalhando = true; defer { trabalhando = false }
        do {
            _ = try await NovaHub.shared.baixar(tipo, item: item)
            baixado = true
            item.downloads = (item.downloads ?? 0) + 1
            onChange(item)
            mensagem = "Baixado. Fica em Marketplace › Baixadas.".loc
        } catch {
            mensagem = error.localizedDescription
        }
    }

    private func curtir() async {
        guard conta.entrou else { mensagem = "Entre na sua conta para curtir".loc; return }
        trabalhando = true; defer { trabalhando = false }
        do {
            let r = try await NovaHub.shared.curtir(tipo, id: item.id)
            item.liked = r.liked
            item.likes = r.likes ?? max(0, (item.likes ?? 0) + (r.liked ? 1 : -1))
            onChange(item)
        } catch {
            mensagem = error.localizedDescription
        }
    }
}
