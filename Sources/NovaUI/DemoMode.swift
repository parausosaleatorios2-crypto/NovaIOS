//
//  DemoMode.swift
//  NovaUI
//
//  Modo demonstracao para as capturas de tela do CI (simulador do iPhone).
//  Com NOVA_DEMO=1 no ambiente, o app abre direto o editor com um projeto de
//  teste e segue um roteiro com tempos fixos; o workflow tira as capturas nos
//  mesmos tempos. Fora do CI ninguem passa essa variavel.
//
//  Roteiro (segundos desde a abertura do editor):
//    0  editor com solido, forma e texto          -> captura 1 (5 s)
//    6  abre o navegador de efeitos               -> captura 2 (8 s)
//    9  aplica um efeito no texto (como o toque)  -> captura 3 (12 s): painel aberto
//   14  fecha o painel                            -> captura 4 (16 s): editor com efeito
//   18  abre exportar                             -> captura 5 (20 s)
//   22  fecha                                     -> captura 6 (24 s)
//

import SwiftUI
import os

public enum DemoMode {
    static let log = Logger(subsystem: "com.novavision.editor", category: "Demo")
    public static var ativo: Bool { ProcessInfo.processInfo.environment["NOVA_DEMO"] == "1" }

    /// Projeto de teste numa pasta temporaria.
    public static func projeto() -> (NovaProject, URL) {
        var c = Composition(name: "Demonstração", width: 1080, height: 1920, frameRate: 30, duration: 8)
        c.backgroundColor = SIMD4(0.05, 0.05, 0.09, 1)

        var solido = Layer(name: "Fundo", kind: .solid)
        solido.solidColor = SIMD4(0.12, 0.10, 0.30, 1)
        solido.size = c.size
        solido.transform.anchorPoint = Animated(c.size / 2)
        solido.transform.position = Animated(c.size / 2)
        solido.duration = 8

        var forma = Layer(name: "Estrela", kind: .shape)
        forma.size = SIMD2(600, 600)
        forma.shapeStyle = ShapeStyle(shape: .star)
        forma.transform.anchorPoint = Animated(SIMD2(300, 300))
        forma.transform.position = Animated(SIMD2(540, 760))
        forma.duration = 8
        // O Glitchify roda na CPU no meio da cadeia: as capturas mostram se ele funciona.
        forma.effects.append(AppliedEffect(effectID: "nova.effect.glitchify"))

        var texto = Layer(name: "NOVA EDITOR", kind: .text)
        texto.text = "NOVA EDITOR"
        texto.fontSize = 140
        texto.textColor = SIMD4(1, 1, 1, 1)
        let m = MediaContentProvider.measureText("NOVA EDITOR", fontName: nil, size: 140)
        texto.size = SIMD2(Float(m.width), Float(m.height))
        texto.transform.anchorPoint = Animated(texto.size! / 2)
        texto.transform.position = Animated(SIMD2(540, 1300))
        texto.duration = 8
        // O Optical Flares (motor do APK em C) no texto: as capturas mostram o flare de verdade.
        texto.effects.append(AppliedEffect(effectID: "nova.effect.aeopticalflares"))

        c.add(solido); c.add(forma); c.add(texto)
        let p = NovaProject(name: "Demonstração", composition: c)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nova-demo", isDirectory: true)
        try? NovaProjectIO.saveFolder(p, to: dir)
        return (p, dir)
    }
}

/// Raiz do app no modo demonstracao.
public struct DemoRoot: View {
    @State private var dados = DemoMode.projeto()
    public init() {}
    public var body: some View {
        NavigationStack {
            EditorView(project: dados.0, folder: dados.1, onSave: { _ in }, demo: true)
        }
    }
}
