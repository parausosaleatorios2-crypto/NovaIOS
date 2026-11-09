//
//  LooksProntos.swift
//  NovaUI
//
//  Biblioteca de looks prontos, como a do Magic Bullet Looks: cada look e uma
//  receita (original da Nova) de ferramentas do motor do Looks com valores.
//  Aplicar poe a cabeca "Magic Bullet Looks" e as ferramentas na camada, como
//  uma instancia do efeito no After Effects; da para mexer em cada uma depois.
//

import SwiftUI

struct LookPronto: Identifiable {
    var id: String { nome }
    let nome: String
    let categoria: String
    /// (ferramenta = sufixo do id nova.effect.mblooks.*, valores por parametro)
    let ferramentas: [(String, [String: Float])]
    var forca: Float = 100
    /// Cores do cartao (so para a galeria).
    let cores: [Color]
}

enum LooksProntos {
    static let categorias = ["Cinema", "Vintage", "P&B", "Estilo", "Cor", "Retrato"]

    static let todos: [LookPronto] = [
        LookPronto(nome: "Blockbuster", categoria: "Cinema",
                   ferramentas: [("mojo2", ["mojo": 65, "tint": 60, "punch": 45, "fade": 5]),
                                 ("lensvignette", ["vignette": 60, "amount": 40])],
                   cores: [Color(red: 0.05, green: 0.35, blue: 0.4), Color(red: 0.95, green: 0.55, blue: 0.25)]),
        LookPronto(nome: "Teal & Laranja Suave", categoria: "Cinema",
                   ferramentas: [("mojo2", ["mojo": 40, "tint": 40, "punch": 20, "skinSqueeze": 30])],
                   cores: [Color(red: 0.15, green: 0.45, blue: 0.5), Color(red: 0.85, green: 0.6, blue: 0.4)]),
        LookPronto(nome: "Cinema Frio", categoria: "Cinema",
                   ferramentas: [("mojo2", ["mojo": 35, "coolWarm": -40, "punch": 30]),
                                 ("scurve", ["contrast": 1, "midpoint": 0.5])],
                   cores: [Color(red: 0.1, green: 0.2, blue: 0.4), Color(red: 0.55, green: 0.7, blue: 0.85)]),
        LookPronto(nome: "Bleach Bypass", categoria: "Cinema",
                   ferramentas: [("printbleachbypass", ["silverRetention": 60, "exposure": 0.3]),
                                 ("scurve", ["contrast": 1.5, "midpoint": 0.5])],
                   cores: [Color(red: 0.3, green: 0.32, blue: 0.3), Color(red: 0.8, green: 0.78, blue: 0.7)]),
        LookPronto(nome: "Negativo Lavado", categoria: "Cinema",
                   ferramentas: [("negbleachbypass", ["silverRetention": 55, "exposure": 0])],
                   cores: [Color(red: 0.25, green: 0.3, blue: 0.32), Color(red: 0.7, green: 0.72, blue: 0.75)]),
        LookPronto(nome: "Filme Antigo", categoria: "Vintage",
                   ferramentas: [("twostrip", ["greenSensitivity": 45, "exposure": 0.2]),
                                 ("mojo2", ["mojo": 10, "fade": 35, "punch": -10]),
                                 ("lensvignette", ["vignette": 70, "amount": 60])],
                   cores: [Color(red: 0.55, green: 0.35, blue: 0.2), Color(red: 0.4, green: 0.6, blue: 0.55)]),
        LookPronto(nome: "Desbotado 70s", categoria: "Vintage",
                   ferramentas: [("mojo2", ["mojo": 20, "fade": 50, "coolWarm": 40, "punch": -20]),
                                 ("diffusion", ["size": 20, "glow": 30])],
                   cores: [Color(red: 0.75, green: 0.6, blue: 0.45), Color(red: 0.5, green: 0.55, blue: 0.5)]),
        LookPronto(nome: "Noir", categoria: "P&B",
                   ferramentas: [("channelmixer", ["monochrome": 1, "monoRed": 0.4, "monoGreen": 0.5, "monoBlue": 0.1]),
                                 ("scurve", ["contrast": 3, "midpoint": 0.5]),
                                 ("lensvignette", ["vignette": 60, "amount": 70])],
                   cores: [Color(white: 0.05), Color(white: 0.85)]),
        LookPronto(nome: "P&B Suave", categoria: "P&B",
                   ferramentas: [("channelmixer", ["monochrome": 1]),
                                 ("diffusion", ["size": 25, "glow": 25])],
                   cores: [Color(white: 0.25), Color(white: 0.75)]),
        LookPronto(nome: "Sonho", categoria: "Estilo",
                   ferramentas: [("diffusion", ["size": 60, "glow": 70, "highlightsOnly": 40]),
                                 ("pop", ["pop": -30])],
                   cores: [Color(red: 0.85, green: 0.75, blue: 0.9), Color(red: 1, green: 0.95, blue: 0.85)]),
        LookPronto(nome: "Clipe Musical", categoria: "Estilo",
                   ferramentas: [("pop", ["pop": 60]),
                                 ("chromab", ["redCyan": 12, "blueYellow": -8]),
                                 ("mojo2", ["mojo": 45, "punch": 60])],
                   cores: [Color(red: 0.8, green: 0.1, blue: 0.5), Color(red: 0.1, green: 0.7, blue: 0.9)]),
        LookPronto(nome: "Brilho de Lente", categoria: "Estilo",
                   ferramentas: [("hazeflare", ["spillage": 45, "exposure": 0, "reach": 60]),
                                 ("opticaldiffusion", ["density": 35, "size": 300])],
                   cores: [Color(red: 0.95, green: 0.7, blue: 0.4), Color(red: 1, green: 0.95, blue: 0.8)]),
        LookPronto(nome: "Duotone Pôr do Sol", categoria: "Estilo",
                   ferramentas: [("duotone", ["highlightR": 1.2, "highlightG": 0.75, "highlightB": 0.35, "highlightTint": 40,
                                              "shadowR": 0.5, "shadowG": 0.3, "shadowB": 0.8, "shadowTint": 50])],
                   cores: [Color(red: 0.4, green: 0.2, blue: 0.6), Color(red: 1, green: 0.7, blue: 0.35)]),
        LookPronto(nome: "Verão Dourado", categoria: "Cor",
                   ferramentas: [("mojo2", ["mojo": 30, "coolWarm": 50, "tint": 30]),
                                 ("exposure", ["stops": 0.2])],
                   cores: [Color(red: 0.95, green: 0.75, blue: 0.3), Color(red: 0.6, green: 0.45, blue: 0.2)]),
        LookPronto(nome: "Noite Azul", categoria: "Cor",
                   ferramentas: [("liftgammagain", ["liftBlue": 1.08, "gainRed": 0.85, "gainGreen": 0.92, "gainBlue": 1.15]),
                                 ("exposure", ["stops": -0.8]),
                                 ("lensvignette", ["vignette": 50, "amount": 50])],
                   cores: [Color(red: 0.05, green: 0.1, blue: 0.3), Color(red: 0.3, green: 0.45, blue: 0.8)]),
        LookPronto(nome: "Pop Forte", categoria: "Cor",
                   ferramentas: [("pop", ["pop": 70]),
                                 ("huesaturation", ["saturation": 125])],
                   cores: [Color(red: 0.9, green: 0.2, blue: 0.2), Color(red: 0.2, green: 0.8, blue: 0.3)]),
        LookPronto(nome: "Pele Bonita", categoria: "Retrato",
                   ferramentas: [("mojo2", ["mojo": 25, "skinSqueeze": 60, "skinYellowPink": 10]),
                                 ("opticaldiffusion", ["density": 20, "size": 200])],
                   cores: [Color(red: 0.95, green: 0.75, blue: 0.65), Color(red: 0.6, green: 0.45, blue: 0.4)]),
        LookPronto(nome: "Luz no Rosto", categoria: "Retrato",
                   ferramentas: [("spotexposure", ["stops": 0.6, "radius": 0.8, "spread": 0.6]),
                                 ("lensvignette", ["vignette": 60, "amount": 60])],
                   cores: [Color(red: 0.2, green: 0.15, blue: 0.12), Color(red: 1, green: 0.9, blue: 0.8)]),
    ]

    /// Os efeitos (cabeca + ferramentas) do look, com os valores nos tipos certos do manifesto.
    static func efeitos(_ look: LookPronto) async -> [AppliedEffect] {
        try? await EffectRegistry.shared.load()
        var cabeca = AppliedEffect(effectID: LooksFerramentas.cabeca)
        cabeca.floats["strength"] = Animated(look.forca)
        var out = [cabeca]
        for (ferr, valores) in look.ferramentas {
            let id = "nova.effect.mblooks." + ferr
            var fx = AppliedEffect(effectID: id)
            let man = try? await EffectRegistry.shared.manifest(id: id)
            for (p, v) in valores {
                if let k = man?.param(p)?.kind, k.isInteger { fx.ints[p] = Int32(v.rounded()) }
                else { fx.floats[p] = Animated(v) }
            }
            out.append(fx)
        }
        return out
    }
}

/// Galeria dos looks prontos (no navegador de efeitos).
struct LooksProntosGaleria: View {
    let onLook: (LookPronto) -> Void
    @State private var categoria = "Cinema"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(LooksProntos.categorias, id: \.self) { c in
                        Button { categoria = c } label: {
                            Text(c.loc).font(.system(size: 11.5, weight: .medium))
                                .padding(.horizontal, 11).padding(.vertical, 5)
                                .background(Capsule().fill(categoria == c ? NovaTheme.accent.opacity(0.18) : NovaTheme.chip))
                                .foregroundStyle(categoria == c ? NovaTheme.accent : NovaTheme.dim)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 14)
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 12) {
                    ForEach(LooksProntos.todos.filter { $0.categoria == categoria }) { l in
                        Button { onLook(l) } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LinearGradient(colors: l.cores, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 74)
                                    .overlay(alignment: .bottomLeading) {
                                        Image(systemName: "camera.filters").font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.85)).padding(7)
                                    }
                                Text(l.nome).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(NovaTheme.text)
                                    .lineLimit(1)
                                Text(l.ferramentas.map { nomeDaFerramenta($0.0) }.joined(separator: " · "))
                                    .font(.system(size: 9)).foregroundStyle(NovaTheme.dim2).lineLimit(2)
                            }
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 20)
            }
        }
        .padding(.top, 8)
    }

    private func nomeDaFerramenta(_ f: String) -> String {
        [
            "mojo2": "Mojo II", "lensvignette": "Lens Vignette", "scurve": "S-Curve", "printbleachbypass": "Bleach Bypass",
            "negbleachbypass": "Neg Bleach", "twostrip": "2-Strip", "diffusion": "Diffusion", "channelmixer": "Channel Mixer",
            "pop": "Pop", "chromab": "Chromatic Ab.", "hazeflare": "Haze/Flare", "opticaldiffusion": "Optical Diffusion",
            "duotone": "Duotone", "exposure": "Exposure", "liftgammagain": "Lift-Gamma-Gain", "huesaturation": "Hue/Sat",
            "spotexposure": "Spot Exposure",
        ][f] ?? f
    }
}
