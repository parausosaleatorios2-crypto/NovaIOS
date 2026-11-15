//
//  WiggleEditor.swift
//  NovaUI
//
//  O botao Wiggle de cada propriedade do transformar (posicao, rotacao, escala, opacidade)
//  e a folha que o configura. E o wiggle(freq, amp, octaves, amp_mult) do After Effects
//  (o motor e o WiggleAE), com nomes faceis: "Velocidade", "Forca" e "Detalhe", uma previa
//  ao vivo e a expressao equivalente do AE embaixo.
//

import SwiftUI

struct IdWiggle: Identifiable { let id: String }

/// O botao pequeno ao lado dos valores: aceso quando o wiggle esta ligado.
struct BotaoWiggle: View {
    let ligado: Bool
    /// So o icone (quando a fileira esta apertada).
    var compacto = false
    let tocar: () -> Void
    var body: some View {
        Button(action: tocar) {
            HStack(spacing: 5) {
                OndaWiggle().stroke(ligado ? Color.black : NovaTheme.accent,
                                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 10)
                if !compacto {
                    Text("Wiggle").font(.system(size: 12.5, weight: .semibold)).lineLimit(1)
                }
            }
            .foregroundStyle(ligado ? Color.black : NovaTheme.text)
            .frame(height: 18)
            .padding(.horizontal, compacto ? 9 : 10).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(ligado ? NovaTheme.accent : CoresPainel.pilula.opacity(0.8)))
        }
        .buttonStyle(.plain)
        .fixedSize()
        .accessibilityLabel("Wiggle".loc)
    }
}

/// O icone: uma linha tremida.
struct OndaWiggle: Shape {
    func path(in r: CGRect) -> Path {
        let ys: [CGFloat] = [0.5, 0.1, 0.8, 0.25, 0.95, 0.35, 0.6]
        var p = Path()
        for (i, y) in ys.enumerated() {
            let pt = CGPoint(x: r.minX + r.width * CGFloat(i) / CGFloat(ys.count - 1), y: r.minY + r.height * y)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}

struct WiggleSheet: View {
    let chave: String
    let titulo: String
    let unidade: String
    let inicial: WiggleAE?
    let aplicar: (WiggleAE) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var w = WiggleAE(freq: 2, amp: 50)
    @State private var ligado = true

    private var ehPosicao: Bool { chave == "posicao" }
    private var ehEscala: Bool { chave == "escala" }
    private var faixaForca: ClosedRange<Float> {
        switch chave {
        case "posicao": return 0...600
        case "escala": return 0...100
        case "opacidade": return 0...100
        default: return 0...180
        }
    }
    private var forcas: [Float] {
        switch chave {
        case "posicao": return [10, 30, 60, 150]
        case "escala", "opacidade": return [5, 10, 25, 50]
        default: return [5, 15, 45, 90]
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Toggle(isOn: $ligado) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wiggle").font(.system(size: 16, weight: .semibold))
                            Text("Faz a propriedade tremer sozinha, sem keyframes, em cima do valor e das chaves.".loc)
                                .font(.system(size: 11.5)).foregroundStyle(NovaTheme.dim)
                        }
                    }
                    .tint(NovaTheme.accent)

                    previa
                        .frame(height: 150)
                        .opacity(ligado ? 1 : 0.35)

                    controle("Velocidade", "Quantas vezes por segundo ela muda de direção",
                             valor: String(format: "%g×/s", w.freq)) {
                        Slider(value: $w.freq, in: 0.1...20).tint(NovaTheme.accent)
                        atalhos([0.5, 1, 2, 5, 10], atual: w.freq, sufixo: "×") { w.freq = $0 }
                    }

                    controle("Força", "O quanto ela pode se afastar do valor normal",
                             valor: String(format: "%g %@", (w.amp * 10).rounded() / 10, unidade)) {
                        Slider(value: $w.amp, in: faixaForca).tint(NovaTheme.accent)
                        atalhos(forcas, atual: w.amp, sufixo: unidade) { w.amp = $0 }
                    }

                    controle("Detalhe", "Mais detalhe = tremor mais nervoso, com pequenas variações por cima",
                             valor: nomeDetalhe) {
                        Picker("", selection: Binding(get: { w.oitavas ?? 1 }, set: { w.oitavas = $0 })) {
                            Text("Suave".loc).tag(1)
                            Text("Médio".loc).tag(2)
                            Text("Áspero".loc).tag(4)
                        }
                        .pickerStyle(.segmented)
                    }

                    if ehPosicao {
                        controle("Direção", "Para onde ela treme", valor: "") {
                            Picker("", selection: Binding(get: { w.eixos ?? 0 }, set: { w.eixos = $0 })) {
                                Text("X e Y".loc).tag(0)
                                Text("Só X (lados)".loc).tag(1)
                                Text("Só Y (cima/baixo)".loc).tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    if ehEscala {
                        Toggle("Manter a proporção (X e Y juntos)".loc,
                               isOn: Binding(get: { w.uniforme ?? true }, set: { w.uniforme = $0 }))
                            .font(.system(size: 13)).tint(NovaTheme.accent)
                    }

                    Button {
                        w.semente = UInt32.random(in: 1...UInt32.max)
                    } label: {
                        Label("Sortear outro tremor".loc, systemImage: "dice")
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(Capsule().fill(NovaTheme.chip))
                            .foregroundStyle(NovaTheme.text)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("No After Effects".loc).font(.system(size: 11, weight: .semibold)).foregroundStyle(NovaTheme.dim2)
                        Text(expressao).font(.system(size: 12.5, design: .monospaced)).foregroundStyle(NovaTheme.accent)
                            .textSelection(.enabled)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface2))
                }
                .padding(16)
            }
            .background(NovaTheme.background)
            .navigationTitle("Wiggle · " + titulo.loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar".loc) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar".loc) {
                        var r = w; r.ligado = ligado
                        aplicar(r); dismiss()
                    }.foregroundStyle(NovaTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .onAppear {
            if let inicial { w = inicial; ligado = inicial.ligado }
            else {
                w = WiggleAE(freq: 2, amp: forcas[1])
                ligado = true
            }
        }
    }

    private var nomeDetalhe: String {
        switch w.oitavas ?? 1 { case 1: return "Suave".loc; case 2, 3: return "Médio".loc; default: return "Áspero".loc }
    }

    private var expressao: String {
        let o = w.oitavas ?? 1
        let base = o > 1 ? String(format: "wiggle(%g, %g, %d, %g)", w.freq, (w.amp * 10).rounded() / 10, o, w.ampMult ?? 0.5)
                         : String(format: "wiggle(%g, %g)", w.freq, (w.amp * 10).rounded() / 10)
        if ehPosicao, let e = w.eixos, e != 0 {
            return "w = \(base);\n" + (e == 1 ? "[w[0], value[1]]" : "[value[0], w[1]]")
        }
        if ehEscala, w.uniforme ?? true { return "w = \(base);\n[w[0], w[0]]" }
        return base
    }

    // MARK: previa ao vivo

    private var previa: some View {
        SwiftUI.TimelineView(.animation) { ctx in
            let t = Float(ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10_000))
            GeometryReader { g in
                let W = g.size.width, H = g.size.height
                ZStack {
                    RoundedRectangle(cornerRadius: 14).fill(NovaTheme.surface2)
                    desenho(t, W, H)
                }
            }
        }
    }

    @ViewBuilder
    private func desenho(_ t: Float, _ W: CGFloat, _ H: CGFloat) -> some View {
        let n = faixaForca.upperBound
        let dx = CGFloat(w.valor(t, eixo: 0) / max(n, 1))
        let dy = CGFloat(w.valor(t, eixo: 1) / max(n, 1))
        switch chave {
        case "posicao":
            // o rastro: os ultimos instantes
            Path { p in
                for i in 0...40 {
                    let tt = t - Float(40 - i) * 0.02
                    let pt = CGPoint(x: W / 2 + CGFloat(w.valor(tt, eixo: 0) / max(n, 1)) * W * 0.9,
                                     y: H / 2 + CGFloat(w.valor(tt, eixo: 1) / max(n, 1)) * H * 0.9)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
            }
            .stroke(NovaTheme.accent.opacity(0.35), lineWidth: 2)
            RoundedRectangle(cornerRadius: 6).fill(NovaTheme.accent)
                .frame(width: 34, height: 34)
                .position(x: W / 2 + dx * W * 0.9, y: H / 2 + dy * H * 0.9)
        case "escala":
            let sx = 1 + dx * 2
            let sy = (w.uniforme ?? true) ? sx : 1 + dy * 2
            RoundedRectangle(cornerRadius: 8).fill(NovaTheme.accent)
                .frame(width: 64, height: 64)
                .scaleEffect(x: max(sx, 0.05), y: max(sy, 0.05))
                .position(x: W / 2, y: H / 2)
        case "opacidade":
            RoundedRectangle(cornerRadius: 8).fill(NovaTheme.accent)
                .frame(width: 70, height: 70)
                .opacity(Double(min(max(0.6 + dx * 1.2, 0.05), 1)))
                .position(x: W / 2, y: H / 2)
        default:
            let graus = Double(w.valor(t, eixo: 0))
            RoundedRectangle(cornerRadius: 6).fill(NovaTheme.accent)
                .frame(width: 90, height: 14)
                .rotation3DEffect(.degrees(graus), axis: chave == "rotacaoX" ? (1, 0, 0) : chave == "rotacaoY" ? (0, 1, 0) : (0, 0, 1))
                .position(x: W / 2, y: H / 2)
        }
    }

    // MARK: pecas

    private func controle<C: View>(_ t: String, _ dica: String, valor: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(t.loc).font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(valor).font(.system(size: 13, weight: .medium, design: .rounded)).foregroundStyle(NovaTheme.accent)
            }
            Text(dica.loc).font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
            c()
        }
    }

    private func atalhos(_ v: [Float], atual: Float, sufixo: String, _ f: @escaping (Float) -> Void) -> some View {
        HStack(spacing: 8) {
            ForEach(v, id: \.self) { n in
                let ativo = abs(atual - n) < 0.001
                Button { f(n) } label: {
                    Text(String(format: "%g%@", n, sufixo)).font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(ativo ? NovaTheme.accent : NovaTheme.chip))
                        .foregroundStyle(ativo ? Color.black : NovaTheme.text)
                }.buttonStyle(.plain)
            }
        }
    }
}
