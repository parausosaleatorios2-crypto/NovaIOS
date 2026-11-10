//
//  OpticalFlaresMotor.swift
//  NovaEngine
//
//  O Optical Flares do APK (model/opticalflares/MotorDoOf, o PasseDoOpticalFlares): a conta
//  roda em C (Sources/OFCore, gerado do smali instrucao por instrucao) sobre a camada em
//  RGBA 8 bits. Aqui ficam as tabelas (opticalflares/tabelas.bin), o flare padrao
//  (opticalflares/padrao.ofp) e os controles tirados dos parametros do efeito, como o
//  `ba6.a` do APK.
//

import Foundation
import Metal
#if canImport(OFCore)
import OFCore
#endif

public enum OpticalFlaresMotor {

    private static func recurso(_ nome: String, _ ext: String) -> Data? {
        for b in [Bundle.main] + Bundle.allBundles {
            if let u = b.url(forResource: nome, withExtension: ext, subdirectory: "opticalflares"),
               let d = try? Data(contentsOf: u) { return d }
        }
        return nil
    }

    /// Carrega as tabelas uma vez; sem elas o efeito cai no shader do XML.
    public static let pronto: Bool = {
        guard let t = recurso("tabelas", "bin") else { return false }
        return t.withUnsafeBytes { b in
            of_carregar_tabelas(b.bindMemory(to: UInt8.self).baseAddress, b.count) == 1
        }
    }()

    /// O flare que o AE poe ao aplicar o efeito (o "Options" padrao).
    public static let padrao: Data? = recurso("padrao", "ofp")

    /// O flare guardado no efeito (import de .ffx/.aep) ou o padrao.
    public static func flare(de fx: AppliedEffect) -> Data? {
        if let s = fx.luts?["flare"], s.hasPrefix("ofp64:"), let d = Data(base64Encoded: String(s.dropFirst(6))) {
            return d
        }
        return padrao
    }

    /// Controles do motor a partir dos valores do efeito (`ba6.a`): pontos de 0 a 1 viram
    /// px da camada (arredondados a 1/4096, como o `c96.f`), cor de 0 a 255, menus 1-based.
    public static func controles(_ v: [String: EffectValue], largura w: Int, altura h: Int, tempo: Float) -> OFControles {
        func num(_ k: String, _ p: Float) -> Float {
            switch v[k] {
            case .float(let f)?: return f
            case .int(let i)?: return Float(i)
            default: return p
            }
        }
        func ponto(_ k: String, _ px: Float, _ py: Float) -> (Float, Float) {
            var x = px, y = py
            if case .vec2(let s)? = v[k] { x = s.x; y = s.y }
            func q(_ a: Float, _ n: Int) -> Float {
                Float((Double(a) * Double(n) * 4096).rounded(.toNearestOrAwayFromZero) / 4096)
            }
            return (q(x, w), q(y, h))
        }
        func menu(_ k: String, _ maximo: Int32) -> Int32 {
            let i: Int32
            switch v[k] { case .int(let n)?: i = n; case .float(let f)?: i = Int32(f); default: i = 0 }
            return min(max(i, 0), maximo) + 1
        }
        func byte(_ f: Float) -> Int32 { Int32(min(max((f * 255).rounded(.toNearestOrAwayFromZero), 0), 255)) }
        let (px, py) = ponto("positionXY", 0.35, 0.35)
        let (cx, cy) = ponto("centerPosition", 0.5, 0.5)
        var r: Int32 = 255, g: Int32 = 255, b: Int32 = 255
        if case .vec4(let c)? = v["color"] { r = byte(c.x); g = byte(c.y); b = byte(c.z) }
        return OFControles(posX: px, posY: py, centroX: cx, centroY: cy,
                           brilho: num("brightness", 100), escala: num("scale", 100),
                           rotacao: Double(num("rotationOffset", 0)),
                           corR: r, corG: g, corB: b,
                           modoCor: menu("colorMode", 1), render: menu("renderMode", 2),
                           evolucao: num("animationEvolution", 0), tempo: tempo, semente: 0)
    }

    /// RGBA 8 bits (de cima para baixo) -> flare -> RGBA. false quando nao desenhou.
    public static func desenhar(_ entrada: [UInt8], _ w: Int, _ h: Int, flare: Data, controles c: OFControles) -> [UInt8]? {
        guard pronto, entrada.count == w * h * 4 else { return nil }
        var saida = [UInt8](repeating: 0, count: w * h * 4)
        var ctl = c
        let n = Int32(min(max(ProcessInfo.processInfo.activeProcessorCount, 1), 16))
        let ok: Int32 = flare.withUnsafeBytes { f in
            entrada.withUnsafeBufferPointer { e in
                saida.withUnsafeMutableBufferPointer { s in
                    of_render(f.bindMemory(to: UInt8.self).baseAddress, Int32(f.count), &ctl, Int32(w), Int32(h), n,
                              e.baseAddress, s.baseAddress)
                }
            }
        }
        return ok == 1 ? saida : nil
    }

    /// Le `leitura` (rgba8), desenha e grava em `escrita`; sem o motor copia a entrada.
    public static func rodar(leitura: MTLTexture, escrita: MTLTexture, flare: Data, controles c: OFControles) {
        let w = leitura.width, h = leitura.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        px.withUnsafeMutableBytes { b in
            leitura.getBytes(b.baseAddress!, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        }
        let r = desenhar(px, w, h, flare: flare, controles: c) ?? px
        r.withUnsafeBytes { b in
            escrita.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: b.baseAddress!, bytesPerRow: w * 4)
        }
    }
}
