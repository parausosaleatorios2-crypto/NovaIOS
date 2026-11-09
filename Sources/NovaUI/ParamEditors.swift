//
//  ParamEditors.swift
//  NovaUI
//
//  Editores dos parametros de efeito que nao sao numero: curva (pontos por
//  canal) e LUT (looks do app ou .cube importado).
//

import SwiftUI
import UniformTypeIdentifiers
import CoreImage

// MARK: - Curvas (efeito Curvas)

struct CurvesParamEditor: View {
    let curves: CurveSet
    let onChange: (CurveSet, Bool) -> Void   // (curvas, gravar)

    enum Canal: String, CaseIterable { case master = "Mestre", red = "R", green = "G", blue = "B" }
    @State private var canal: Canal = .master
    @State private var arrastando: Int?

    private func pontos(_ c: CurveSet) -> [SIMD2<Float>] {
        switch canal { case .master: return c.master; case .red: return c.red
        case .green: return c.green; case .blue: return c.blue }
    }
    private func com(_ c: CurveSet, _ p: [SIMD2<Float>]) -> CurveSet {
        var c = c
        let ord = p.sorted { $0.x < $1.x }
        switch canal { case .master: c.master = ord; case .red: c.red = ord
        case .green: c.green = ord; case .blue: c.blue = ord }
        return c
    }
    private var cor: Color {
        switch canal { case .master: return .white; case .red: return .red
        case .green: return .green; case .blue: return Color(red: 0.3, green: 0.5, blue: 1) }
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker("", selection: $canal) {
                ForEach(Canal.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            GeometryReader { g in
                let W = g.size.width, H = g.size.height
                let pts = pontos(curves)
                let toPt = { (v: SIMD2<Float>) in CGPoint(x: CGFloat(v.x) * W, y: (1 - CGFloat(v.y)) * H) }
                let fromPt = { (p: CGPoint) in SIMD2<Float>(Float(min(max(p.x / W, 0), 1)), Float(min(max(1 - p.y / H, 0), 1))) }
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(NovaTheme.surface)
                    Path { p in
                        for i in 1..<4 {
                            let f = CGFloat(i) / 4
                            p.move(to: CGPoint(x: f * W, y: 0)); p.addLine(to: CGPoint(x: f * W, y: H))
                            p.move(to: CGPoint(x: 0, y: f * H)); p.addLine(to: CGPoint(x: W, y: f * H))
                        }
                        p.move(to: CGPoint(x: 0, y: H)); p.addLine(to: CGPoint(x: W, y: 0))
                    }.stroke(NovaTheme.line, lineWidth: 1)
                    Path { p in
                        for i in 0...64 {
                            let x = Float(i) / 64
                            let pt = toPt(SIMD2(x, CurveSet.evaluate(pts, x)))
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }.stroke(cor, lineWidth: 2)
                    ForEach(Array(pts.enumerated()), id: \.offset) { i, v in
                        Circle().fill(cor).frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1))
                            .frame(width: 34, height: 34).contentShape(Circle())
                            .position(toPt(v))
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { d in
                                    var p = pts
                                    guard p.indices.contains(i) else { return }
                                    var n = fromPt(d.location)
                                    // as pontas ficam presas nas bordas em x
                                    if i == 0 { n.x = 0 } else if i == p.count - 1 { n.x = 1 }
                                    p[i] = n
                                    onChange(com(curves, p), false)
                                }
                                .onEnded { _ in onChange(curves, true) })
                            .onTapGesture(count: 2) {
                                guard i != 0 && i != pts.count - 1 else { return }
                                var p = pts; p.remove(at: i)
                                onChange(com(curves, p), true)
                            }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { loc in
                    var p = pts; p.append(fromPt(loc))
                    onChange(com(curves, p), true)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            HStack {
                Text("Toque para pôr ponto · dois toques para tirar".loc)
                    .font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
                Spacer()
                Button("Zerar canal".loc) { onChange(com(curves, [SIMD2(0, 0), SIMD2(1, 1)]), true) }
                    .font(.system(size: 11)).foregroundStyle(NovaTheme.accent)
            }
        }
    }
}

// MARK: - LUT (galeria de Looks no estilo do Magic Bullet Looks)

/// Miniaturas dos looks: a imagem de amostra com o LUT aplicado (CoreImage
/// CIColorCube), feitas uma vez e guardadas.
enum LooksMiniaturas {
    private static let cache = NSCache<NSString, UIImage>()
    private static let ciContext = CIContext(options: [.workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])

    static let amostra: CIImage? = {
        guard let u = Bundle.main.resourceURL?.appendingPathComponent("presets/amostra.jpg"),
              let img = CIImage(contentsOf: u) else { return nil }
        // reduz para ~180 px de lado (miniatura)
        let lado = max(img.extent.width, img.extent.height)
        let k = 180 / max(lado, 1)
        return img.transformed(by: CGAffineTransform(scaleX: k, y: k))
    }()

    static func cubo(_ url: URL) -> (Int, Data)? {
        guard let lido = try? (url.pathExtension.lowercased() == "cube"
                               ? EffectParamTextures.parseCube(url)
                               : EffectParamTextures.parseStrip(url)) else { return nil }
        let (n, rgba) = lido
        var f = [Float](repeating: 1, count: n * n * n * 4)
        for i in 0..<(n * n * n) {
            f[i * 4] = Float(rgba[i * 4]) / 255
            f[i * 4 + 1] = Float(rgba[i * 4 + 1]) / 255
            f[i * 4 + 2] = Float(rgba[i * 4 + 2]) / 255
        }
        return (n, f.withUnsafeBufferPointer { Data(buffer: $0) })
    }

    static func imagem(_ caminho: String?, url: URL?) async -> UIImage? {
        let chave = (caminho ?? "nenhum") as NSString
        if let c = cache.object(forKey: chave) { return c }
        let feito: UIImage? = await Task.detached(priority: .utility) {
            guard let base = amostra else { return nil }
            var saida = base
            if let url, let cb = cubo(url), let f = CIFilter(name: "CIColorCube") {
                let (n, dados) = cb
                f.setValue(n, forKey: "inputCubeDimension")
                f.setValue(dados, forKey: "inputCubeData")
                f.setValue(base, forKey: kCIInputImageKey)
                if let o = f.outputImage { saida = o }
            }
            guard let cg = ciContext.createCGImage(saida, from: base.extent) else { return nil }
            return UIImage(cgImage: cg)
        }.value
        if let feito { cache.setObject(feito, forKey: chave) }
        return feito
    }
}

struct LutParamEditor: View {
    let title: String
    let current: String?
    let mediaRoot: URL?
    let onChange: (String?) -> Void
    @State private var importando = false
    @State private var categoria = "Todos"
    @State private var importados: [String] = []

    /// Looks que vem no app (Resources/looks, LUT 33^3 em tira).
    static var bundled: [String] {
        guard let dir = Bundle.main.resourceURL?.appendingPathComponent("looks"),
              let f = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return f.filter { $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".cube") }
            .sorted().map { "looks/" + $0 }
    }

    /// Categorias como as gavetas do Looks (pelo nome do arquivo).
    static func categoria(de p: String) -> String {
        let n = (p as NSString).lastPathComponent.lowercased()
        if p.hasPrefix("projeto/") { return "Meus" }
        if n.contains("-cc") { return "Nova" }
        if n.hasPrefix("noir") { return "P&B" }
        for k in ["vintage", "retro", "desbotado", "matte", "sepia", "pastel"] where n.contains(k) { return "Vintage" }
        for k in ["cinema", "bleach", "drama", "classico", "cross", "noite"] where n.contains(k) { return "Cinema" }
        return "Estilo"
    }
    static let categorias = ["Todos", "Cinema", "Vintage", "Estilo", "P&B", "Nova", "Meus"]

    static func nome(_ p: String) -> String {
        let base = (p as NSString).lastPathComponent.replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: ".cube", with: "")
        return base.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private func url(_ p: String) -> URL? {
        if p.hasPrefix("projeto/") { return mediaRoot?.appendingPathComponent(String(p.dropFirst(8))) }
        return Bundle.main.resourceURL?.appendingPathComponent(p)
    }

    private var lista: [String] {
        let todos = Self.bundled + importados
        return categoria == "Todos" ? todos : todos.filter { Self.categoria(de: $0) == categoria }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(current.map(Self.nome) ?? "Nenhum".loc)
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(NovaTheme.accent)
            }
            // gavetas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Self.categorias, id: \.self) { c in
                        Button { categoria = c } label: {
                            Text(c.loc).font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(categoria == c ? NovaTheme.accent.opacity(0.18) : NovaTheme.chip))
                                .overlay(Capsule().strokeBorder(categoria == c ? NovaTheme.accent.opacity(0.6) : Color.clear))
                                .foregroundStyle(categoria == c ? NovaTheme.accent : NovaTheme.dim)
                        }.buttonStyle(.plain)
                    }
                }
            }
            // miniaturas com o look aplicado
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    LookTile(nome: "Nenhum".loc, caminho: nil, url: nil, selecionado: current == nil) { onChange(nil) }
                    ForEach(lista, id: \.self) { p in
                        LookTile(nome: Self.nome(p), caminho: p, url: url(p), selecionado: current == p) { onChange(p) }
                    }
                    Button { importando = true } label: {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 10).fill(NovaTheme.button)
                                .frame(width: 78, height: 78)
                                .overlay(Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(NovaTheme.accent))
                            Text("Importar .cube".loc).font(.system(size: 10)).foregroundStyle(NovaTheme.dim)
                        }
                    }.buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
            .frame(height: 104)
        }
        .onAppear {
            guard let root = mediaRoot,
                  let f = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return }
            importados = f.filter { $0.lowercased().hasSuffix(".cube") }.sorted().map { "projeto/" + $0 }
        }
        .fileImporter(isPresented: $importando,
                      allowedContentTypes: [UTType(filenameExtension: "cube") ?? .data, .data]) { r in
            guard case .success(let u) = r, let root = mediaRoot else { return }
            let ok = u.startAccessingSecurityScopedResource()
            defer { if ok { u.stopAccessingSecurityScopedResource() } }
            try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let dst = root.appendingPathComponent(u.lastPathComponent)
            try? FileManager.default.removeItem(at: dst)
            if (try? FileManager.default.copyItem(at: u, to: dst)) != nil {
                let p = "projeto/" + u.lastPathComponent
                if !importados.contains(p) { importados.append(p) }
                onChange(p)
            }
        }
    }
}

/// Um look da galeria: miniatura com o LUT aplicado, nome embaixo.
struct LookTile: View {
    let nome: String
    let caminho: String?
    let url: URL?
    let selecionado: Bool
    let acao: () -> Void
    @State private var img: UIImage?

    var body: some View {
        Button(action: acao) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface2)
                    if let img {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        ProgressView().scaleEffect(0.6)
                    }
                }
                .frame(width: 78, height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(selecionado ? NovaTheme.accent : NovaTheme.line, lineWidth: selecionado ? 2.5 : 1))
                Text(nome).font(.system(size: 10, weight: selecionado ? .semibold : .regular))
                    .foregroundStyle(selecionado ? NovaTheme.accent : NovaTheme.text)
                    .lineLimit(1).frame(width: 80)
            }
        }
        .buttonStyle(.plain)
        .task(id: caminho) { img = await LooksMiniaturas.imagem(caminho, url: url) }
    }
}
