//
//  CurveEditor.swift
//  NovaUI
//
//  Editor de curva do trecho entre dois keyframes (como no Alight Motion): grafico com duas alcas
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

    /// y da curva em x (0...1), do jeito que o motor vai aplicar.
    private func y(_ x: Float) -> Float {
        if segurar { return x >= 1 ? 1 : 0 }
        if let preset { return preset.apply(x) }
        return Easing.cubicBezierRaw(x, c1, c2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    dica
                    grafico
                        .aspectRatio(1.15, contentMode: .fit)
                        .padding(.horizontal, 2)
                    previa
                    HStack {
                        valor("Alça 1", c1)
                        Spacer()
                        valor("Alça 2", c2)
                    }
                    .padding(.horizontal, 4)
                    .opacity(segurar || preset != nil ? 0.35 : 1)

                    Toggle("Segurar (pula para o valor na próxima chave)".loc, isOn: $segurar)
                        .font(.system(size: 12))
                        .tint(NovaTheme.accent)

                    faixaDePresets("Presets") {
                        ForEach(Self.presetsBezier, id: \.0) { p in
                            tile(p.0, .bezier(p.1, p.2), ativo: !segurar && preset == nil && c1 == p.1 && c2 == p.2) {
                                withAnimation(.easeOut(duration: 0.2)) { preset = nil; segurar = false; c1 = p.1; c2 = p.2 }
                            }
                        }
                        ForEach(Self.presetsProntos, id: \.0) { p in
                            tile(p.0, p.1, ativo: !segurar && preset == p.1) { preset = p.1; segurar = false }
                        }
                    }

                    faixaDePresets("Minhas curvas") {
                        Button { pedindoNome = true } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "plus").font(.system(size: 18, weight: .semibold))
                                    .frame(width: 52, height: 40)
                                Text("Salvar esta".loc).font(.system(size: 10.5)).lineLimit(1)
                            }
                            .frame(width: 76, height: 78)
                            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(NovaTheme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                            .foregroundStyle(NovaTheme.accent)
                        }
                        .buttonStyle(.plain)
                        .disabled(segurar || preset != nil)
                        ForEach(minhas) { m in
                            tile(m.nome, .bezier(m.c1, m.c2), ativo: !segurar && preset == nil && c1 == m.c1 && c2 == m.c2, traduzir: false) {
                                withAnimation(.easeOut(duration: 0.2)) { preset = nil; segurar = false; c1 = m.c1; c2 = m.c2 }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    minhas.removeAll { $0.id == m.id }; MinhasCurvas.salvar(minhas)
                                } label: { Label("Apagar".loc, systemImage: "trash") }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(NovaTheme.background)
            .navigationTitle("Curva do trecho".loc)
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
                    minhas.append(CurvaSalva(nome: n.isEmpty ? "Curve \(minhas.count + 1)" : n, c1: c1, c2: c2))
                    MinhasCurvas.salvar(minhas)
                    nomeNova = ""
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .onAppear(perform: carregarInicial)
    }

    private var dica: some View {
        HStack(spacing: 8) {
            Image(systemName: "diamond.fill").font(.system(size: 9)).foregroundStyle(NovaTheme.accent)
            Rectangle().fill(NovaTheme.accent.opacity(0.6)).frame(width: 18, height: 2)
            Image(systemName: "diamond.fill").font(.system(size: 9)).foregroundStyle(NovaTheme.accent)
            Text("A curva vale para o trecho entre as duas chaves em volta do cursor".loc)
                .font(.system(size: 11.5)).foregroundStyle(NovaTheme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    // MARK: grafico com alcas (estilo Alight Motion: as duas chaves nos cantos, a curva entre elas)

    private var grafico: some View {
        GeometryReader { g in
            let pad: CGFloat = 26
            let W = g.size.width - pad * 2, H = g.size.height - pad * 2
            // y visivel de -0.5 a 1.5 (deixa as alcas passarem do ponto)
            let yMin: Float = -0.5, yMax: Float = 1.5
            let toPt = { (v: SIMD2<Float>) -> CGPoint in
                CGPoint(x: pad + CGFloat(v.x) * W, y: pad + H - CGFloat((v.y - yMin) / (yMax - yMin)) * H)
            }
            let fromPt = { (p: CGPoint) -> SIMD2<Float> in
                SIMD2(Float(min(max((p.x - pad) / W, 0), 1)),
                      Float(min(max(yMin + Float(1 - (p.y - pad) / H) * (yMax - yMin), yMin), yMax)))
            }
            let y0 = toPt(SIMD2(0, 0)).y, y1 = toPt(SIMD2(0, 1)).y
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(NovaTheme.surface2)
                // faixa 0..1 do valor
                Rectangle().fill(NovaTheme.accent.opacity(0.05))
                    .frame(width: W, height: y0 - y1)
                    .position(x: pad + W / 2, y: (y0 + y1) / 2)
                // grade
                Path { p in
                    for i in 0...8 {
                        let x = pad + CGFloat(i) / 8 * W
                        p.move(to: CGPoint(x: x, y: pad)); p.addLine(to: CGPoint(x: x, y: pad + H))
                    }
                    for i in 0...8 {
                        let yy = pad + CGFloat(i) / 8 * H
                        p.move(to: CGPoint(x: pad, y: yy)); p.addLine(to: CGPoint(x: pad + W, y: yy))
                    }
                }.stroke(NovaTheme.line, lineWidth: 0.7)
                Path { p in
                    for yy in [y0, y1] { p.move(to: CGPoint(x: pad, y: yy)); p.addLine(to: CGPoint(x: pad + W, y: yy)) }
                }.stroke(NovaTheme.line2, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                // area embaixo da curva
                Path { p in
                    let n = 90
                    p.move(to: CGPoint(x: pad, y: y0))
                    for i in 0...n {
                        let x = Float(i) / Float(n)
                        p.addLine(to: toPt(SIMD2(x, y(x))))
                    }
                    p.addLine(to: CGPoint(x: pad + W, y: y0))
                    p.closeSubpath()
                }.fill(LinearGradient(colors: [NovaTheme.accent.opacity(0.22), NovaTheme.accent.opacity(0.02)],
                                      startPoint: .top, endPoint: .bottom))
                // curva
                Path { p in
                    let n = 90
                    for i in 0...n {
                        let x = Float(i) / Float(n)
                        let pt = toPt(SIMD2(x, y(x)))
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                }.stroke(NovaTheme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: NovaTheme.accent.opacity(0.5), radius: 4)

                if !segurar && preset == nil {
                    Path { p in
                        p.move(to: toPt(SIMD2(0, 0))); p.addLine(to: toPt(c1))
                        p.move(to: toPt(SIMD2(1, 1))); p.addLine(to: toPt(c2))
                    }.stroke(NovaTheme.text.opacity(0.75), lineWidth: 1.4)
                    alca(toPt(c1)).gesture(DragGesture(minimumDistance: 0).onChanged { v in c1 = fromPt(v.location) })
                    alca(toPt(c2)).gesture(DragGesture(minimumDistance: 0).onChanged { v in c2 = fromPt(v.location) })
                }
                // as duas chaves do trecho
                chave(toPt(SIMD2(0, 0)))
                chave(toPt(SIMD2(1, 1)))
                Text("Tempo".loc).font(.system(size: 9.5)).foregroundStyle(NovaTheme.dim2)
                    .position(x: pad + W / 2, y: pad + H + 14)
                Text("Valor".loc).font(.system(size: 9.5)).foregroundStyle(NovaTheme.dim2)
                    .rotationEffect(.degrees(-90))
                    .position(x: 10, y: pad + H / 2)
            }
        }
    }

    private func chave(_ p: CGPoint) -> some View {
        Image(systemName: "diamond.fill").font(.system(size: 15))
            .foregroundStyle(NovaTheme.text)
            .shadow(color: .black.opacity(0.6), radius: 2)
            .position(p)
            .allowsHitTesting(false)
    }

    private func alca(_ p: CGPoint) -> some View {
        Circle().fill(NovaTheme.background)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(NovaTheme.accent, lineWidth: 3))
            .frame(width: 46, height: 46)          // area de toque maior
            .contentShape(Circle())
            .position(p)
    }

    /// A bolinha que anda com a curva (como a previa do Alight Motion), em loop.
    private var previa: some View {
        SwiftUI.TimelineView(.animation) { ctx in
            let ciclo = 1.6, pausa = 0.35
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: ciclo + pausa)
            let x = Float(min(t / ciclo, 1))
            let v = CGFloat(y(x))
            GeometryReader { g in
                let w = g.size.width - 28
                ZStack(alignment: .leading) {
                    Capsule().fill(NovaTheme.surface2).frame(height: 6).padding(.horizontal, 14)
                    Capsule().fill(NovaTheme.line2).frame(width: max(0, w * CGFloat(x)), height: 2)
                        .padding(.leading, 14)
                    Circle().fill(NovaTheme.accent).frame(width: 18, height: 18)
                        .shadow(color: NovaTheme.accent.opacity(0.7), radius: 6)
                        .offset(x: 5 + w * v)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(height: 28)
    }

    private func valor(_ t: String, _ v: SIMD2<Float>) -> some View {
        Text(String(format: "%@ (%.2f, %.2f)", t.loc, v.x, v.y))
            .font(.system(size: 11, design: .monospaced)).foregroundStyle(NovaTheme.dim)
    }

    private func faixaDePresets<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t.loc).font(.system(size: 13, weight: .semibold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { c() }.padding(.vertical, 2)
            }
        }
    }

    private func tile(_ t: String, _ e: Easing, ativo: Bool, traduzir: Bool = true, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(spacing: 6) {
                CurveGlyph(easing: e)
                    .stroke(ativo ? Color.black : NovaTheme.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                    .frame(width: 44, height: 30)
                    .padding(5)
                Text(traduzir ? t.loc : t).font(.system(size: 10.5, weight: ativo ? .semibold : .regular))
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            .frame(width: 76, height: 78)
            .background(RoundedRectangle(cornerRadius: 10).fill(ativo ? NovaTheme.accent : NovaTheme.chip))
            .foregroundStyle(ativo ? Color.black : NovaTheme.text)
        }.buttonStyle(.plain)
    }
}
