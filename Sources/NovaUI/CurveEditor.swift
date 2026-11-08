//
//  CurveEditor.swift
//  NovaUI
//
//  Editor de curva de interpolacao de um keyframe: grafico com duas alcas
//  Bezier arrastaveis (como o editor de graficos do AE e o CurvaAvancada /
//  GraphKey do APK), presets e curvas proprias salvas com nome.
//
//  A curva vai de (0,0) a (1,1): x = fracao do tempo entre as chaves,
//  y = fracao do valor. As alcas podem passar de 0..1 em y (antecipar e
//  passar do ponto, como "recuo" e "elastico").
//

import SwiftUI

// MARK: - Curvas salvas pela pessoa

struct CurvaSalva: Codable, Identifiable, Equatable {
    var id = UUID()
    var nome: String
    var c1: SIMD2<Float>
    var c2: SIMD2<Float>
}

enum MinhasCurvas {
    private static let chave = "nova.minhasCurvas"
    static func carregar() -> [CurvaSalva] {
        guard let d = UserDefaults.standard.data(forKey: chave),
              let v = try? JSONDecoder().decode([CurvaSalva].self, from: d) else { return [] }
        return v
    }
    static func salvar(_ v: [CurvaSalva]) {
        if let d = try? JSONEncoder().encode(v) { UserDefaults.standard.set(d, forKey: chave) }
    }
}

// MARK: - Botao que abre o editor

/// Icone de curva ao lado de um keyframe; abre o editor.
struct EasingMenu: View {
    var current: Easing? = nil
    let onPick: (Easing) -> Void
    @State private var aberto = false

    var body: some View {
        Button { aberto = true } label: {
            CurveGlyph(easing: current ?? .linear)
                .stroke(NovaTheme.accent, lineWidth: 1.4)
                .frame(width: 16, height: 12)
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 4).fill(NovaTheme.selectedFill))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $aberto) {
            CurveEditorSheet(initial: current ?? .linear, onApply: onPick)
        }
    }
}

/// Desenho pequeno da curva.
struct CurveGlyph: Shape {
    let easing: Easing
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 24
        for i in 0...n {
            let x = Float(i) / Float(n)
            let y = easing.apply(x)
            let pt = CGPoint(x: r.minX + CGFloat(x) * r.width, y: r.maxY - CGFloat(y) * r.height)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

// MARK: - Editor

struct CurveEditorSheet: View {
    let initial: Easing
    let onApply: (Easing) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var c1 = SIMD2<Float>(0.33, 0.0)
    @State private var c2 = SIMD2<Float>(0.67, 1.0)
    @State private var segurar = false
    @State private var preset: Easing?
    @State private var minhas: [CurvaSalva] = MinhasCurvas.carregar()
    @State private var nomeNova = ""
    @State private var pedindoNome = false

    /// Presets que viram alcas editaveis (equivalentes Bezier dos do APK).
    static let presetsBezier: [(String, SIMD2<Float>, SIMD2<Float>)] = [
        ("Linear", SIMD2(0.33, 0.33), SIMD2(0.67, 0.67)),
        ("Suave", SIMD2(0.25, 0.1), SIMD2(0.25, 1)),
        ("Entrada suave", SIMD2(0.42, 0), SIMD2(1, 1)),
        ("Saída suave", SIMD2(0, 0), SIMD2(0.58, 1)),
        ("Entrada e saída", SIMD2(0.42, 0), SIMD2(0.58, 1)),
        ("Forte", SIMD2(0.85, 0), SIMD2(0.15, 1)),
        ("Exponencial", SIMD2(0.19, 1), SIMD2(0.22, 1)),
        ("Antecipar", SIMD2(0.36, -0.4), SIMD2(0.66, 1)),
        ("Passar do ponto", SIMD2(0.34, 0), SIMD2(0.64, 1.4)),
        ("Recuo", SIMD2(0.68, -0.55), SIMD2(0.27, 1.55)),
    ]
    /// Presets que nao cabem numa Bezier so (usam a curva pronta do motor).
    static let presetsProntos: [(String, Easing)] = [
        ("Elástico", .named("elastic")), ("Quicar", .named("bounce")),
    ]

    private var curvaAtual: Easing {
        if segurar { return .hold }
        if let preset { return preset }
        return .bezier(c1, c2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    grafico
                        .frame(height: 280)
                        .padding(.horizontal, 4)
                    HStack {
                        valor("Alça 1", c1)
                        Spacer()
                        valor("Alça 2", c2)
                    }
                    .padding(.horizontal, 6)

                    Toggle("Segurar (pula para o valor na próxima chave)".loc, isOn: $segurar)
                        .font(.system(size: 12))

                    secao("Presets") {
                        ForEach(Self.presetsBezier, id: \.0) { p in
                            chip(p.0, .bezier(p.1, p.2)) { preset = nil; segurar = false; c1 = p.1; c2 = p.2 }
                        }
                        ForEach(Self.presetsProntos, id: \.0) { p in
                            chip(p.0, p.1) { preset = p.1; segurar = false }
                        }
                    }

                    secao("Minhas curvas") {
                        ForEach(minhas) { m in
                            chip(m.nome, .bezier(m.c1, m.c2)) { preset = nil; segurar = false; c1 = m.c1; c2 = m.c2 }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        minhas.removeAll { $0.id == m.id }; MinhasCurvas.salvar(minhas)
                                    } label: { Label("Apagar".loc, systemImage: "trash") }
                                }
                        }
                        Button { pedindoNome = true } label: {
                            Label("Salvar esta".loc, systemImage: "plus")
                                .font(.system(size: 11.5, weight: .medium))
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(Capsule().strokeBorder(NovaTheme.accent.opacity(0.5)))
                                .foregroundStyle(NovaTheme.accent)
                        }.disabled(segurar || preset != nil)
                    }
                }
                .padding(16)
            }
            .background(NovaTheme.background)
            .navigationTitle("Curva do keyframe".loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar".loc) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar".loc) { onApply(curvaAtual); dismiss() }.foregroundStyle(NovaTheme.accent)
                }
            }
            .alert("Nome da curva".loc, isPresented: $pedindoNome) {
                TextField("Minha curva".loc, text: $nomeNova)
                Button("Cancelar".loc, role: .cancel) {}
                Button("Salvar".loc) {
                    let n = nomeNova.trimmingCharacters(in: .whitespaces)
                    minhas.append(CurvaSalva(nome: n.isEmpty ? "Curva \(minhas.count + 1)" : n, c1: c1, c2: c2))
                    MinhasCurvas.salvar(minhas)
                    nomeNova = ""
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: carregarInicial)
    }

    private func carregarInicial() {
        switch initial {
        case .bezier(let a, let b): c1 = a; c2 = b
        case .hold: segurar = true
        case .linear: c1 = SIMD2(0.33, 0.33); c2 = SIMD2(0.67, 0.67)
        case .named(let n):
            let mapa: [String: (SIMD2<Float>, SIMD2<Float>)] = [
                "ease": (SIMD2(0.25, 0.1), SIMD2(0.25, 1)), "easeIn": (SIMD2(0.42, 0), SIMD2(1, 1)),
                "easeOut": (SIMD2(0, 0), SIMD2(0.58, 1)), "easeInOut": (SIMD2(0.42, 0), SIMD2(0.58, 1)),
                "cubic": (SIMD2(0.65, 0), SIMD2(0.35, 1)), "expoOut": (SIMD2(0.19, 1), SIMD2(0.22, 1)),
                "backOut": (SIMD2(0.34, 1.56), SIMD2(0.64, 1)),
            ]
            if let m = mapa[n] { c1 = m.0; c2 = m.1 } else { preset = initial }
        }
    }

    // MARK: grafico com alcas

    private var grafico: some View {
        GeometryReader { g in
            let W = g.size.width, H = g.size.height
            // y visivel de -0.6 a 1.6 (deixa as alcas passarem do ponto)
            let yMin: Float = -0.6, yMax: Float = 1.6
            let toPt = { (v: SIMD2<Float>) -> CGPoint in
                CGPoint(x: CGFloat(v.x) * W, y: H - CGFloat((v.y - yMin) / (yMax - yMin)) * H)
            }
            let fromPt = { (p: CGPoint) -> SIMD2<Float> in
                SIMD2(Float(min(max(p.x / W, 0), 1)),
                      Float(min(max(yMin + Float(1 - p.y / H) * (yMax - yMin), yMin), yMax)))
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface2)
                // grade
                Path { p in
                    for i in 0...4 {
                        let x = CGFloat(i) / 4 * W
                        p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: x, y: H))
                    }
                    for v: Float in [0, 0.5, 1] {
                        let y = toPt(SIMD2(0, v)).y
                        p.move(to: CGPoint(x: 0, y: y)); p.addLine(to: CGPoint(x: W, y: y))
                    }
                }.stroke(NovaTheme.line, lineWidth: 1)
                // curva
                Path { p in
                    let n = 80
                    for i in 0...n {
                        let x = Float(i) / Float(n)
                        let y: Float
                        if segurar { y = x >= 1 ? 1 : 0 }
                        else if let preset { y = preset.apply(x) }
                        else { y = Easing.cubicBezierRaw(x, c1, c2) }
                        let pt = toPt(SIMD2(x, y))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }.stroke(NovaTheme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                if !segurar && preset == nil {
                    // bracos das alcas
                    Path { p in
                        p.move(to: toPt(SIMD2(0, 0))); p.addLine(to: toPt(c1))
                        p.move(to: toPt(SIMD2(1, 1))); p.addLine(to: toPt(c2))
                    }.stroke(NovaTheme.dim, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    alca(toPt(c1)).gesture(DragGesture(minimumDistance: 0).onChanged { v in c1 = fromPt(v.location) })
                    alca(toPt(c2)).gesture(DragGesture(minimumDistance: 0).onChanged { v in c2 = fromPt(v.location) })
                }
                Circle().fill(NovaTheme.text).frame(width: 7, height: 7).position(toPt(SIMD2(0, 0)))
                Circle().fill(NovaTheme.text).frame(width: 7, height: 7).position(toPt(SIMD2(1, 1)))
            }
        }
    }

    private func alca(_ p: CGPoint) -> some View {
        Circle().fill(NovaTheme.accent)
            .frame(width: 18, height: 18)
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .frame(width: 44, height: 44)          // area de toque maior
            .contentShape(Circle())
            .position(p)
    }

    private func valor(_ t: String, _ v: SIMD2<Float>) -> some View {
        Text(String(format: "%@ (%.2f, %.2f)", t.loc, v.x, v.y))
            .font(.system(size: 11, design: .monospaced)).foregroundStyle(NovaTheme.dim)
    }

    private func secao<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t.loc).font(.system(size: 13, weight: .semibold))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) { c() }
        }
    }

    private func chip(_ t: String, _ e: Easing, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 6) {
                CurveGlyph(easing: e).stroke(NovaTheme.accent, lineWidth: 1.3).frame(width: 18, height: 13)
                Text(t.loc).font(.system(size: 11)).lineLimit(1)
            }
            .padding(.horizontal, 9).padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(NovaTheme.chip))
            .foregroundStyle(NovaTheme.text)
        }.buttonStyle(.plain)
    }
}
