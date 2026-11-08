//
//  ParamEditors.swift
//  NovaUI
//
//  Editores dos parametros de efeito que nao sao numero: curva (pontos por
//  canal) e LUT (looks do app ou .cube importado).
//

import SwiftUI
import UniformTypeIdentifiers

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

// MARK: - LUT

struct LutParamEditor: View {
    let title: String
    let current: String?
    let mediaRoot: URL?
    let onChange: (String?) -> Void
    @State private var importando = false

    /// Looks que vem no app (Resources/looks, LUT 33^3 em tira).
    static var bundled: [String] {
        guard let dir = Bundle.main.resourceURL?.appendingPathComponent("looks"),
              let f = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return [] }
        return f.filter { $0.lowercased().hasSuffix(".png") || $0.lowercased().hasSuffix(".cube") }
            .sorted().map { "looks/" + $0 }
    }

    private func nome(_ p: String) -> String {
        (p as NSString).lastPathComponent.replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: ".cube", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Menu {
                Button("Nenhum (sem mudança)".loc) { onChange(nil) }
                ForEach(Self.bundled, id: \.self) { p in Button(nome(p)) { onChange(p) } }
                Divider()
                Button { importando = true } label: { Label("Importar .cube…".loc, systemImage: "square.and.arrow.down") }
            } label: {
                HStack {
                    Text(title).font(.system(size: 11.5))
                    Spacer()
                    Text(current.map(nome) ?? "Nenhum".loc).font(.system(size: 11)).foregroundStyle(NovaTheme.accent)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 9)).foregroundStyle(NovaTheme.dim)
                }
            }
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
                onChange("projeto/" + u.lastPathComponent)
            }
        }
    }
}
