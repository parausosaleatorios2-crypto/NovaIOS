//
//  LayoutsDoEditor.swift
//  NovaUI
//
//  A troca de layout do editor (como no app Android): o botao "Nova ▾" na previa abre o menu
//  Layout (Nova, CapCut, Blurrr, Motion, After Effects), cada um com a miniatura e a fileira de
//  icones das barras dele; ao trocar, a transicao "Montando o layout" desenha em verde as areas
//  do layout novo e embaralha o nome ate ele aparecer.
//

import SwiftUI

extension EditorLayout {
    /// Icones da barra de baixo de cada layout (a fileira que aparece no menu).
    var icones: [String] {
        switch self {
        case .nova: return ["square.3.layers.3d", "scope", "sparkles", "icloud.and.arrow.down.fill", "captions.bubble", "link"]
        case .capcut: return ["scissors", "music.note", "textformat", "star", "square.stack", "captions.bubble"]
        case .blurrr: return ["rectangle.on.rectangle", "music.note", "sparkles", "textformat", "triangle.circle", "viewfinder"]
        case .motion: return ["square.3.layers.3d", "scope", "sparkles", "icloud.and.arrow.down.fill", "captions.bubble", "link"]
        case .afterEffects: return ["cursorarrow", "hand.raised", "magnifyingglass", "move.3d", "pin", "pencil"]
        }
    }
}

/// O botao da previa: o layout atual e a setinha.
struct ChipDoLayout: View {
    let layout: EditorLayout
    let tocar: () -> Void
    var body: some View {
        Button(action: tocar) {
            HStack(spacing: 4) {
                Image(systemName: "square.grid.2x2").font(.system(size: 10, weight: .semibold))
                Text(layout.label).font(.system(size: 11.5, weight: .medium))
                Image(systemName: "chevron.down").font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(NovaTheme.text.opacity(0.9))
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.55)))
        }
        .buttonStyle(.plain)
    }
}

/// O menu "Layout" que desce do botao.
struct MenuDeLayout: View {
    let atual: EditorLayout
    let telaGrande: Bool
    let escolher: (EditorLayout) -> Void
    let maisOpcoes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Layout".loc).font(.system(size: 13, weight: .semibold)).foregroundStyle(NovaTheme.text)
                .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 4)
            ForEach(EditorLayout.allCases) { l in
                Button { escolher(l) } label: { linha(l) }.buttonStyle(.plain)
            }
            Divider().overlay(NovaTheme.line).padding(.horizontal, 10)
            Button(action: maisOpcoes) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3").font(.system(size: 12))
                    Text("Mais opções de layout".loc).font(.system(size: 12.5))
                }
                .foregroundStyle(NovaTheme.text.opacity(0.85))
                .padding(.horizontal, 12).padding(.vertical, 10)
            }.buttonStyle(.plain)
        }
        .frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.09, green: 0.10, blue: 0.13)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(NovaTheme.line, lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
    }

    private func linha(_ l: EditorLayout) -> some View {
        let sel = l == atual
        return HStack(spacing: 12) {
            MiniaturaDoLayout(layout: l, ativo: sel).frame(width: 46, height: 34)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(l.label).font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(sel ? NovaTheme.accent : NovaTheme.text)
                    if l == .afterEffects {
                        Text("Precisa de tela grande".loc).font(.system(size: 10.5))
                            .foregroundStyle(telaGrande ? NovaTheme.dim : NovaTheme.warning)
                    }
                }
                HStack(spacing: 9) {
                    ForEach(l.icones, id: \.self) { i in
                        Image(systemName: i).font(.system(size: 10))
                            .foregroundStyle(sel ? NovaTheme.accent : NovaTheme.text.opacity(0.6))
                    }
                }
            }
            Spacer(minLength: 0)
            if sel { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(NovaTheme.accent) }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(sel ? NovaTheme.accent.opacity(0.16) : Color.clear))
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

/// O desenho pequeno de cada layout (as faixas das barras).
struct MiniaturaDoLayout: View {
    let layout: EditorLayout
    var ativo = false
    var body: some View {
        let cor = ativo ? NovaTheme.accent : NovaTheme.text.opacity(0.55)
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06))
                switch layout {
                case .afterEffects:
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.9)).frame(width: w * 0.22, height: h * 0.62).offset(x: 2, y: 2)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.5)).frame(width: w * 0.5, height: h * 0.62).offset(x: w * 0.26, y: 2)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.9)).frame(width: w * 0.18, height: h * 0.62).offset(x: w * 0.78, y: 2)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.7)).frame(width: w - 4, height: h * 0.26).offset(x: 2, y: h * 0.7)
                default:
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.35)).frame(width: w - 4, height: h * 0.1).offset(x: 2, y: 2)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.75)).frame(width: w - 4, height: h * 0.4).offset(x: 2, y: h * 0.16)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(0.45)).frame(width: w - 4, height: h * 0.2).offset(x: 2, y: h * 0.6)
                    RoundedRectangle(cornerRadius: 1.5).fill(cor.opacity(layout == .capcut ? 0.9 : 0.6))
                        .frame(width: w - 4, height: h * 0.12).offset(x: 2, y: h * 0.84)
                }
            }
        }
    }
}

/// A transicao "Montando o layout": as areas do layout novo em contorno verde, uma grade
/// pontilhada e o nome embaralhado que se acerta letra por letra.
struct TransicaoDeLayout: View {
    let layout: EditorLayout
    @State private var progresso: Double = 0
    @State private var texto = ""
    private let verde = Color(red: 0.2, green: 0.95, blue: 0.55)

    var body: some View {
        GeometryReader { g in
            let h = g.size.height, w = g.size.width
            ZStack {
                Color.black.opacity(0.82)
                // grade de pontos
                Canvas { ctx, s in
                    var y: CGFloat = 6
                    while y < s.height {
                        var x: CGFloat = 6
                        while x < s.width {
                            ctx.fill(Path(CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(verde.opacity(0.18)))
                            x += 14
                        }
                        y += 14
                    }
                }
                ForEach(Array(areas(h).enumerated()), id: \.offset) { i, a in
                    let atraso = Double(i) * 0.08
                    let p = min(max((progresso - atraso) / 0.5, 0), 1)
                    RoundedRectangle(cornerRadius: 6)
                        .trim(from: 0, to: p)
                        .stroke(verde, lineWidth: 2)
                        .shadow(color: verde.opacity(0.7), radius: 6)
                        .frame(width: w - 10, height: a.1)
                        .position(x: w / 2, y: a.0 + a.1 / 2)
                }
                VStack(spacing: 6) {
                    Text(texto).font(.system(size: 30, weight: .heavy, design: .monospaced))
                        .foregroundStyle(verde).shadow(color: verde.opacity(0.8), radius: 8)
                    Text("Montando o layout".loc).font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(verde.opacity(0.85)).tracking(2)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .task {
            let alvo = layout.label.uppercased()
            let sopa = Array("ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#&>=<%$")
            withAnimation(.easeOut(duration: 0.75)) { progresso = 1 }
            for passo in 0...12 {
                let certas = Int(Double(alvo.count) * Double(passo) / 12)
                texto = String(alvo.enumerated().map { i, c in
                    c == " " ? " " : (i < certas ? c : sopa.randomElement()!)
                })
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            texto = alvo
        }
    }

    /// (y, altura) das faixas: barra de cima, previa, botoes, timeline e barra de baixo.
    private func areas(_ h: CGFloat) -> [(CGFloat, CGFloat)] {
        let topo: CGFloat = 50, pr = h * 0.34, bt: CGFloat = 44, baixo: CGFloat = 80
        let tl = max(60, h - topo - pr - bt - baixo - 40)
        var y: CGFloat = 8
        var out: [(CGFloat, CGFloat)] = []
        for a in [topo, pr, bt, tl, baixo] { out.append((y, a)); y += a + 6 }
        return out
    }
}
