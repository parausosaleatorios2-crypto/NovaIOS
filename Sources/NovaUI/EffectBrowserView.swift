//
//  EffectBrowserView.swift
//  NovaUI
//
//  Navegador de efeito no layout do APK (0.70–0.93 nas Novidades):
//  X, titulo e lupa no topo; chips de origem (Todos, After Effects, Alight
//  Motion…); Destaques (seis cartoes com o efeito aplicado na vitrine);
//  Usados recentemente (os nove ultimos, antes/depois); e as categorias em
//  faixas largas, duas por linha, com o banner do APK ou o degrade dela.
//

import SwiftUI

public struct EffectBrowserView: View {
    @State private var busca = ""
    @State private var buscando = false
    @State private var fonte: String?
    @State private var categoria: String?
    @State private var entries: [EffectIndexEntry] = []
    @State private var recentes: [String] = EffectThumbs.recentes
    @State private var carregando = true
    @State private var erro: String?
    @FocusState private var focoBusca: Bool
    @Environment(\.dismiss) private var dismiss

    let onPick: (EffectIndexEntry) -> Void
    /// Looks prontos (Magic Bullet Looks): nil esconde a galeria.
    var onLook: ((LookPronto) -> Void)? = nil
    public init(onPick: @escaping (EffectIndexEntry) -> Void) { self.onPick = onPick }
    init(onPick: @escaping (EffectIndexEntry) -> Void, onLook: @escaping (LookPronto) -> Void) {
        self.onPick = onPick
        self.onLook = onLook
    }

    public var body: some View {
        VStack(spacing: 0) {
            cabecalho
            chips
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
                } else if buscando && !busca.trimmingCharacters(in: .whitespaces).isEmpty {
                    ScrollView { grade(resultadosDaBusca).padding(.top, 8) }
                } else if let categoria {
                    paginaDaCategoria(categoria)
                } else {
                    inicio
                }
            }
        }
        .background(NovaTheme.background.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .task { await carregar() }
    }

    // MARK: topo

    private var cabecalho: some View {
        HStack(spacing: 10) {
            Button {
                if buscando { buscando = false; busca = "" }
                else if categoria != nil { withAnimation(.easeOut(duration: 0.18)) { categoria = nil } }
                else { dismiss() }
            } label: {
                Image(systemName: categoria != nil && !buscando ? "chevron.left" : "xmark")
                    .font(.system(size: 20, weight: .medium)).foregroundStyle(NovaTheme.text)
                    .frame(width: 44, height: 44)
            }
            if buscando {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(NovaTheme.dim2)
                    TextField("Procurar efeito".loc, text: $busca)
                        .focused($focoBusca)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .foregroundStyle(NovaTheme.text)
                    if !busca.isEmpty {
                        Button { busca = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(NovaTheme.dim2)
                        }
                    }
                }
                .padding(.horizontal, 12).frame(height: 40)
                .background(Capsule().fill(NovaTheme.surface2))
            } else {
                Spacer()
                Text(categoria.map { Self.nomeDaCategoria($0) } ?? "Navegador de efeito".loc)
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(NovaTheme.text)
                    .lineLimit(1)
                Spacer()
                Button {
                    buscando = true
                    focoBusca = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .medium)).foregroundStyle(NovaTheme.text)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 60)
        .background(NovaTheme.surface)
    }

    // MARK: chips de origem

    /// Origens, com a cor do pontinho do chip.
    static let fontes: [(id: String, nome: String, cor: Color)] = [
        ("ae", "After Effects", Color(red: 0.62, green: 0.58, blue: 1.0)),
        ("am", "Alight Motion", Color(red: 0.0, green: 0.86, blue: 0.55)),
        ("gm", "Gold Motion", Color(red: 1.0, green: 0.48, blue: 0.1)),
        ("sapphire", "Sapphire", Color(red: 0.3, green: 0.62, blue: 1.0)),
        ("nodevideo", "NodeVideo", Color(red: 1.0, green: 0.36, blue: 0.62)),
        ("nova", "Nova", Color(red: 0.69, green: 0.3, blue: 1.0)),
    ]

    static func fonte(de e: EffectIndexEntry) -> String {
        let f = e.fileName.lowercased(), id = e.id.lowercased()
        if f.hasPrefix("ae-") || id.contains(".ae.") || id.hasPrefix("nova.effect.ae") { return "ae" }
        if f.hasPrefix("sapphire-") || id.contains("sapphire") { return "sapphire" }
        if f.hasPrefix("nv-") || id.contains("nodevideo") { return "nodevideo" }
        if f.hasPrefix("gm-") || id.hasPrefix("gm.") { return "gm" }
        if f.hasPrefix("am-") || f.hasPrefix("toji-") || id.hasPrefix("com.alightcreative")
            || id.hasPrefix("alightcreative") || id.hasPrefix("636f6d2e616c") { return "am" }
        return "nova"
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, "Todos".loc, nil, entries.count)
                ForEach(Self.fontes, id: \.id) { f in
                    let n = entries.filter { Self.fonte(de: $0) == f.id }.count
                    if n > 0 { chip(f.id, f.nome, f.cor, n) }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
        }
        .background(NovaTheme.background)
    }

    private func chip(_ id: String?, _ nome: String, _ cor: Color?, _ n: Int) -> some View {
        let ativo = fonte == id
        return Button { fonte = id } label: {
            HStack(spacing: 7) {
                if let cor { Circle().fill(cor).frame(width: 9, height: 9) }
                Text(nome).font(.system(size: 15, weight: ativo ? .semibold : .medium))
                Text("\(n)").font(.system(size: 14))
                    .foregroundStyle(ativo ? Color.black.opacity(0.6) : NovaTheme.dim2)
            }
            .foregroundStyle(ativo ? Color.black : NovaTheme.text.opacity(0.85))
            .padding(.horizontal, 16).frame(height: 40)
            .background(Capsule().fill(ativo ? NovaTheme.accent : NovaTheme.surface2))
        }
        .buttonStyle(EncolheAoTocar())
    }

    private var filtrados: [EffectIndexEntry] {
        guard let fonte else { return entries }
        return entries.filter { Self.fonte(de: $0) == fonte }
    }

    // MARK: inicio

    /// Os seis Destaques do APK (0.72/0.73): o que a Nova tem e o Alight Motion nao.
    static let destaques = ["deep-glow.xml", "liquid-glass.xml", "energy-beam.xml",
                            "lightning.xml", "blob-tracker-v2.xml", "anamorphic-streak.xml"]

    private var inicio: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                let dest = Self.destaques.compactMap { f in filtrados.first { $0.fileName == f } }
                if !dest.isEmpty {
                    titulo("sparkles", "Destaques".loc)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 10) {
                        ForEach(dest) { e in
                            Button { escolher(e) } label: { cartaoDestaque(e) }
                                .buttonStyle(EncolheAoTocar())
                        }
                    }
                    .padding(.horizontal, 8)
                }

                titulo("clock", "Usados recentemente".loc)
                let rec = recentes.compactMap { id in filtrados.first { $0.id == id } }
                if rec.isEmpty {
                    Text("Os efeitos que você usar aparecem aqui. Escolha uma categoria e experimente.".loc)
                        .font(.system(size: 13)).foregroundStyle(NovaTheme.dim2)
                        .padding(.horizontal, 20).padding(.bottom, 6)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(rec) { e in
                                Button { escolher(e) } label: {
                                    VStack(spacing: 6) {
                                        MiniaturaEfeito(id: e.id, dividida: true)
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 14))
                                        Text(e.name).font(.system(size: 13)).foregroundStyle(NovaTheme.text)
                                            .multilineTextAlignment(.center).lineLimit(2)
                                            .frame(width: 104)
                                    }
                                }
                                .buttonStyle(EncolheAoTocar())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)], spacing: 5) {
                    ForEach(categorias, id: \.0) { c in
                        Button { withAnimation(.easeOut(duration: 0.18)) { categoria = c.0 } } label: {
                            FaixaDeCategoria(id: c.0, nome: Self.nomeDaCategoria(c.0), n: c.1)
                        }
                        .buttonStyle(EncolheAoTocar())
                    }
                }
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
    }

    private func titulo(_ icone: String, _ t: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icone).font(.system(size: 14))
            Text(t).font(.system(size: 16, weight: .medium))
        }
        .foregroundStyle(NovaTheme.dim)
        .padding(.horizontal, 18).padding(.top, 14).padding(.bottom, 10)
    }

    private func cartaoDestaque(_ e: EffectIndexEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            MiniaturaEfeito(id: e.id, base: .personagem)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(3)
            Text(e.name).font(.system(size: 14, weight: .medium)).foregroundStyle(NovaTheme.text)
                .lineLimit(1)
                .padding(.horizontal, 8).padding(.top, 6).padding(.bottom, 10)
        }
        .background(RoundedRectangle(cornerRadius: 13).fill(NovaTheme.surface2))
    }

    // MARK: categorias

    static func grupo(_ c: String?) -> String {
        let k = (c ?? "other").lowercased()
        switch k {
        case "distortion", "warp": return "distort"
        case "generative": return "generate"
        case "light", "lighting": return "color"
        default: return k
        }
    }

    /// Nomes do APK (u46: "Meus efeitos", "Magic Bullet Looks", "Desfoque"…).
    static func nomeDaCategoria(_ c: String) -> String {
        switch c {
        case "meus": return "Meus efeitos".loc
        case "looks": return "Magic Bullet Looks"
        case "time": return "Tempo".loc
        case "color": return "Cor".loc
        case "blur": return "Desfoque".loc
        case "distort": return "Distorção".loc
        case "stylize": return "Estilizar".loc
        case "matte": return "Recorte".loc
        case "procedural": return "Procedural".loc
        case "repeat": return "Repetição".loc
        case "transform": return "Transformação".loc
        case "3d": return "3D"
        case "drawing": return "Desenho".loc
        case "text": return "Texto".loc
        case "audio": return "Áudio".loc
        case "opacity": return "Opacidade".loc
        case "transition": return "Transição".loc
        case "other": return "Outros".loc
        case "custom": return "Custom"
        case "expressao": return "Expressão".loc
        case "generate": return "Gerar".loc
        case "motion": return "Motion"
        case "nodevideo": return "Nodevideo"
        case "cc": return "CCs"
        default: return c.prefix(1).uppercased() + c.dropFirst()
        }
    }

    static let ordem = ["meus", "looks", "time", "color", "blur", "distort", "stylize", "matte",
                        "procedural", "repeat", "transform", "3d", "drawing", "text", "audio",
                        "opacity", "transition", "other", "custom", "expressao", "generate",
                        "motion", "nodevideo", "cc"]

    private var categorias: [(String, Int)] {
        var cont: [String: Int] = [:]
        for e in filtrados { cont[Self.grupo(e.category), default: 0] += 1 }
        var out: [(String, Int)] = [("meus", 0)]
        for k in Self.ordem.dropFirst() where (cont[k] ?? 0) > 0 { out.append((k, cont[k]!)) }
        for (k, n) in cont.sorted(by: { $0.key < $1.key }) where !Self.ordem.contains(k) { out.append((k, n)) }
        return out
    }

    @ViewBuilder
    private func paginaDaCategoria(_ c: String) -> some View {
        let lista = filtrados.filter { Self.grupo($0.category) == c }
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if c == "looks", let onLook {
                    Text("Looks prontos".loc).font(.system(size: 15, weight: .medium))
                        .foregroundStyle(NovaTheme.dim).padding(.horizontal, 16).padding(.top, 10)
                    LooksProntosGaleria(onLook: onLook).frame(height: 250)
                    Text("Ferramentas".loc).font(.system(size: 15, weight: .medium))
                        .foregroundStyle(NovaTheme.dim).padding(.horizontal, 16).padding(.top, 6)
                }
                if lista.isEmpty {
                    Text(c == "meus"
                         ? "Os efeitos que você salvar ou importar do After Effects aparecem aqui.".loc
                         : "Nenhum efeito nesta categoria.".loc)
                        .font(.system(size: 13)).foregroundStyle(NovaTheme.dim2)
                        .frame(maxWidth: .infinity).padding(.top, 40).padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                } else {
                    grade(lista)
                }
            }
            .padding(.top, 6).padding(.bottom, 24)
        }
    }

    private func grade(_ lista: [EffectIndexEntry]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 14) {
            ForEach(lista) { e in
                Button { escolher(e) } label: {
                    VStack(spacing: 6) {
                        MiniaturaEfeito(id: e.id)
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        Text(e.name).font(.system(size: 12.5)).foregroundStyle(NovaTheme.text)
                            .multilineTextAlignment(.center).lineLimit(2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(EncolheAoTocar())
            }
        }
        .padding(.horizontal, 12)
    }

    private var resultadosDaBusca: [EffectIndexEntry] {
        let q = busca.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return [] }
        return filtrados.filter {
            let n = $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            if n.contains(q) { return true }
            if let e = $0.nameEn, e.lowercased().contains(q) { return true }
            return $0.tags.contains { $0.lowercased().contains(q) }
        }
    }

    private func escolher(_ e: EffectIndexEntry) {
        EffectThumbs.usar(e.id)
        recentes = EffectThumbs.recentes
        onPick(e)
    }

    private func carregar() async {
        let reg = EffectRegistry.shared
        do {
            try await reg.load()
            // So os efeitos cujo shader esta na metallib do app (os outros nao
            // compilaram e aplicar daria erro).
            let todos = await reg.all
            entries = todos.filter { EffectRenderer.isAvailable("fx_\($0.slug)") && EffectVerification.isUsable($0.id) }
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

/// Faixa larga de categoria: o banner do APK (res/A1, ag, BJ…) ou o degrade
/// dela, com o nome no meio e a contagem no canto.
struct FaixaDeCategoria: View {
    let id: String
    let nome: String
    let n: Int

    private static var banners: [String: UIImage] = [:]
    static func banner(_ id: String) -> UIImage? {
        if let b = banners[id] { return b }
        guard let u = Bundle.main.resourceURL?.appendingPathComponent("effects/banners/\(id).webp"),
              let i = UIImage(contentsOfFile: u.path) else { return nil }
        banners[id] = i
        return i
    }

    private var degrade: [Color] {
        switch id {
        case "looks": return [Color(red: 0.86, green: 0.5, blue: 0.16), Color(red: 0.1, green: 0.42, blue: 0.45)]
        case "time": return [Color(red: 0.86, green: 0.3, blue: 0.22), Color(red: 0.5, green: 0.12, blue: 0.22)]
        case "audio": return [Color(red: 0.05, green: 0.47, blue: 0.5), Color(red: 0.22, green: 0.25, blue: 0.32)]
        default: return [Color(red: 0.25, green: 0.27, blue: 0.34), Color(red: 0.2, green: 0.22, blue: 0.29)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: degrade, startPoint: .leading, endPoint: .trailing)
            if let b = Self.banner(id) {
                GeometryReader { g in
                    Image(uiImage: b).resizable().scaledToFill()
                        .frame(width: g.size.width, height: g.size.height).clipped()
                }
                Color.black.opacity(0.12)
            }
            Text(nome).font(.system(size: 21, weight: .semibold)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 4)
                .lineLimit(1).minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(n)").font(.system(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.6), radius: 2)
                }
            }
            .padding(.horizontal, 7).padding(.bottom, 3)
        }
        .frame(height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
