//
//  ParticleWorldExato.swift
//  NovaEngine
//
//  O CC Particle World do APK (model/ccparticleworld/MotorDoPw, o mesmo que bate com o AE):
//  a conta roda em C (Sources/PWCore, gerado do smali instrucao por instrucao). Aqui fica a
//  "fonte" dos parametros — como ParametrosDoPw.bruto do APK: cada parametro pelo indice do
//  plugin, no instante que o motor pedir (ele olha outros instantes para herdar o movimento).
//

import Foundation
import Metal
#if canImport(PWCore)
import PWCore
#endif

public enum ParticleWorldExato {

    enum Tipo { case fixo, inteiro, caixa, cor, menu([Int32]) }

    /// (indice no plugin, id no XML, tipo) — a tabela de ParametrosDoPw do APK.
    static let tabela: [(Int32, String, Tipo)] = [
        (14, "birthRate", .fixo), (15, "longevity", .fixo),
        (17, "posX", .fixo), (18, "posY", .fixo), (19, "posZ", .fixo),
        (20, "radX", .fixo), (21, "radY", .fixo), (22, "radZ", .fixo),
        (25, "animation", .menu([1, 2, 3, 5, 6, 7, 8, 9, 11, 13, 14])),
        (26, "velocity", .fixo), (27, "inheritVelocity", .fixo), (28, "gravity", .fixo),
        (29, "resistance", .fixo), (30, "extra", .fixo), (31, "extraAngle", .fixo),
        (33, "floorPosition", .fixo), (34, "particleVisibility", .menu([1, 2, 3])),
        (35, "renderAnimation", .menu([1, 2, 3])), (36, "floorAction", .menu([1, 2, 3, 4])),
        (37, "bounciness", .fixo), (38, "randomBounciness", .fixo), (39, "bounceSpread", .fixo),
        (42, "axisX", .fixo), (43, "axisY", .fixo), (44, "axisZ", .fixo),
        (47, "gravityX", .fixo), (48, "gravityY", .fixo), (49, "gravityZ", .fixo),
        (53, "particleType", .menu([1, 2, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 22, 24, 25, 26])),
        (56, "scatter", .fixo), (57, "textureTime", .menu([1, 2, 3])), (58, "alignToDirection", .caixa),
        (60, "rotationSpeed", .fixo), (61, "initialRotation", .fixo), (62, "rotationAxis", .menu([1, 2, 3, 4])),
        (63, "birthSize", .fixo), (64, "deathSize", .fixo), (65, "sizeVariation", .fixo), (66, "maxOpacity", .fixo),
        (69, "colorMap", .menu([1, 2, 3, 4, 5])), (70, "birthColor", .cor), (71, "deathColor", .cor),
        (73, "colorAtBirth", .cor), (74, "colorAt25", .cor), (75, "colorAt50", .cor),
        (76, "colorAt75", .cor), (77, "colorAtDeath", .cor),
        (79, "volumeShade", .fixo), (80, "transferMode", .menu([1, 2, 3, 4])),
        (84, "camDistance", .fixo), (85, "camRotX", .fixo), (86, "camRotY", .fixo),
        (87, "camRotZ", .fixo), (88, "fov", .fixo),
        (91, "depthCueType", .menu([1, 2, 3])), (92, "depthCueDistance", .fixo), (93, "fogColor", .cor),
        (96, "lightX", .fixo), (97, "lightY", .fixo), (98, "lightZ", .fixo),
        (100, "holdParticleRelease", .fixo), (101, "compositeWithOriginal", .caixa), (102, "randomSeed", .inteiro),
    ]

    /// Os parametros do efeito em qualquer instante, ja no formato bruto do plugin.
    final class Fonte {
        let fx: AppliedEffect
        let manifest: EffectManifest
        /// instante da comp = inicio + (t / escala) / velocidade (o motor fala em tempo da camada)
        let inicio: Float, velocidade: Float
        private var cache: [Int64: [Int32]] = [:]

        init(fx: AppliedEffect, manifest: EffectManifest, inicio: Float, velocidade: Float) {
            self.fx = fx; self.manifest = manifest; self.inicio = inicio; self.velocidade = velocidade
        }

        func valor(_ idx: Int32, _ t: Int32, _ escala: Int32) -> Int32 {
            let chave = (Int64(t) << 20) ^ Int64(escala)
            if let c = cache[chave] { return idx >= 0 && Int(idx) < c.count ? c[Int(idx)] : 0 }
            let seg = Float(Double(t) / Double(max(escala, 1)))
            let v = fx.values(at: inicio + seg / max(velocidade, 0.01), manifest: manifest)
            var out = [Int32](repeating: 0, count: 104)
            for (i, id, tipo) in ParticleWorldExato.tabela { out[Int(i)] = Self.bruto(v[id], tipo, manifest.param(id)) }
            cache[chave] = out
            return idx >= 0 && Int(idx) < out.count ? out[Int(idx)] : 0
        }

        private static func numero(_ e: EffectValue?, _ p: EffectParam?) -> Double {
            switch e {
            case .float(let f)?: return Double(f)
            case .int(let i)?: return Double(i)
            default: return Double(p?.defaultValue.first ?? 0)
            }
        }

        static func bruto(_ e: EffectValue?, _ tipo: Tipo, _ p: EffectParam?) -> Int32 {
            switch tipo {
            case .fixo: return Int32(clamping: Int64((numero(e, p) * 65536).rounded(.toNearestOrEven)))
            case .inteiro: return Int32(numero(e, p).rounded())
            case .caixa: return numero(e, p) != 0 ? 1 : 0
            case .menu(let valores):
                let i = Int(numero(e, p).rounded())
                return i >= 0 && i < valores.count ? valores[i] : valores[0]
            case .cor:
                var c = SIMD3<Float>(1, 1, 1)
                switch e {
                case .vec4(let v)?: c = SIMD3(v.x, v.y, v.z)
                case .vec3(let v)?: c = v
                default:
                    if let d = p?.defaultValue, d.count >= 3 { c = SIMD3(d[0], d[1], d[2]) }
                }
                func b(_ x: Float) -> UInt32 { UInt32((min(max(x, 0), 1) * 255).rounded()) }
                return Int32(bitPattern: (b(c.x) << 8) | 255 | (b(c.y) << 16) | (b(c.z) << 24))
            }
        }
    }

    /// Desenha o Particle World da camada (leitura -> escrita, rgba8). Devolve false quando o
    /// motor exato nao rodou (o chamador usa a versao aproximada).
    public static func rodar(leitura: MTLTexture, escrita: MTLTexture, fx: AppliedEffect, manifest: EffectManifest,
                             tempoDaCamada: Float, inicioDaCamada: Float, velocidade: Float, fps: Float) -> Bool {
        let w = leitura.width, h = leitura.height
        var src = [UInt8](repeating: 0, count: w * h * 4)
        src.withUnsafeMutableBytes { b in
            leitura.getBytes(b.baseAddress!, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        }
        var out = [UInt8](repeating: 0, count: w * h * 4)
        let escala = Int32(max(1, (Double(max(fps, 1)) * 1000).rounded()))
        let t = Int32((Double(max(tempoDaCamada, 0)) * Double(escala)).rounded())
        let fonte = Fonte(fx: fx, manifest: manifest, inicio: inicioDaCamada, velocidade: velocidade)
        let ctx = Unmanaged.passUnretained(fonte).toOpaque()
        let fn: PWFonteFn = { ctx, idx, t, _, escala in
            guard let ctx else { return 0 }
            return Unmanaged<Fonte>.fromOpaque(ctx).takeUnretainedValue().valor(idx, t, escala)
        }
        let ok = withExtendedLifetime(fonte) {
            src.withUnsafeBytes { s in
                out.withUnsafeMutableBytes { o in
                    pw_render(s.bindMemory(to: UInt8.self).baseAddress, Int32(w), Int32(h),
                              o.bindMemory(to: UInt8.self).baseAddress, t, escala, 1000, fn, ctx, nil, 0, 0)
                }
            }
        }
        guard ok == 1 else { return false }
        out.withUnsafeBytes { b in
            escrita.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: b.baseAddress!, bytesPerRow: w * 4)
        }
        return true
    }
}
