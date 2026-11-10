//
//  LooksMotor.swift
//  NovaEngine
//
//  O motor do Looks (Magic Bullet Looks) no iPhone — o PasseDoLooks do app
//  Android (m96 no APK) em Metal. Uma instancia do Looks e UMA passada:
//
//    entrada (sRGB 8 bits -> linear float16)
//    -> cada ferramenta, no espaco dela (linear ou "video"/sRGB; o motor
//       converte so quando a proxima pede o outro espaco)
//    -> volta ao linear
//    -> Strength (mistura com a saida da entrada)
//    -> saida (linear -> sRGB, 8 bits)
//
//  Os shaders sao os do app Android (Resources/mblooks/*.frag) convertidos por
//  Tools/looks_glsl2msl.py; as contas de cada ferramenta estao em
//  LooksContas.swift. O blur gaussiano usa o MPSImageGaussianBlur (no Android
//  e um compute shader proprio, `gauss.comp`).
//

import Foundation
import Metal
import MetalPerformanceShaders

/// Uma ferramenta do Looks dentro da passada: o codigo (como no AE: "mjo2",
/// "lggn"...), os valores na ordem de FerramentasDoLooks e o LUT escolhido.
public struct LooksPasso {
    public var codigo: String
    public var valores: [Float]
    public var lut: String?
    public init(codigo: String, valores: [Float], lut: String? = nil) {
        self.codigo = codigo; self.valores = valores; self.lut = lut
    }
}

public enum LooksFerramentas {
    public static let cabeca = "nova.effect.mblooks"

    /// Ordem do menu "Adicionar ferramenta": a do Looks (Subject, Matte, Lens, Camera, Post).
    public static let ordem: [String] = [
        "exposure", "scurve", "liftgammagain", "hslcolors", "huesaturation", "channelmixer", "mojo2",
        "duotone", "pop", "spotexposure", "lut", "diffusion", "hazeflare", "edgesoftness",
        "lensvignette", "chromab", "opticaldiffusion", "negbleachbypass", "printbleachbypass", "twostrip",
    ].map { "nova.effect.mblooks." + $0 }

    /// Nome da ferramenta sem o prefixo "Looks: ".
    public static func nome(_ id: String, _ doManifesto: String?) -> String {
        if let n = doManifesto {
            return n.hasPrefix("Looks: ") ? String(n.dropFirst(7)) : n
        }
        let curtos: [String: String] = [
            "exposure": "Exposure", "scurve": "S Curve", "liftgammagain": "Lift-Gamma-Gain",
            "hslcolors": "HSL Colors", "huesaturation": "Hue/Saturation", "channelmixer": "Channel Mixer",
            "mojo2": "Mojo II", "duotone": "Duotone", "pop": "Pop", "spotexposure": "Spot Exposure",
            "lut": "LUT", "diffusion": "Diffusion", "hazeflare": "Haze/Flare", "edgesoftness": "Edge Softness",
            "lensvignette": "Lens Vignette", "chromab": "Chromatic Aberration",
            "opticaldiffusion": "Optical Diffusion", "negbleachbypass": "Neg Bleach Bypass",
            "printbleachbypass": "Print Bleach Bypass", "twostrip": "2-Strip Process",
        ]
        return curtos[String(id.split(separator: ".").last ?? "")] ?? id
    }

    /// manifesto -> (codigo, parametros na ordem do motor). De FerramentasDoLooks.
    public static let porManifesto: [String: (codigo: String, params: [String])] = {
        func cores(_ pre: [String]) -> [String] {
            pre.flatMap { p in ["Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Magenta"].map { p + $0 } }
        }
        func rgb(_ pre: [String], _ c: [String] = ["Red", "Green", "Blue"]) -> [String] {
            pre.flatMap { p in c.map { p + $0 } }
        }
        return [
            "nova.effect.mblooks.exposure": ("expo", ["stops"]),
            "nova.effect.mblooks.scurve": ("logc", ["contrast", "midpoint", "brightness", "blackPoint", "whitePoint", "logMode"]),
            "nova.effect.mblooks.duotone": ("duto", ["highlightR", "highlightG", "highlightB", "highlightTint", "shadowR", "shadowG", "shadowB", "shadowTint", "balance"]),
            "nova.effect.mblooks.mojo2": ("mjo2", ["mojo", "tint", "punch", "bleach", "fade", "blueSqueeze", "skinSqueeze", "exposure", "coolWarm", "greenMagenta", "skinYellowPink", "strength"]),
            "nova.effect.mblooks.chromab": ("chab", ["redCyan", "greenMagenta", "blueYellow"]),
            "nova.effect.mblooks.opticaldiffusion": ("odif", ["density", "size", "falloff", "glow", "highlightsOnly", "luster", "red", "green", "blue", "filterOn", "quality", "previewHighlights", "filterType"]),
            "nova.effect.mblooks.edgesoftness": ("edgs", ["blurSize", "quality", "centerX", "centerY", "radius", "spread", "aspect"]),
            "nova.effect.mblooks.lensvignette": ("lenv", ["vignette", "amount", "highlights", "centerX", "centerY", "aspect", "anamorphic"]),
            "nova.effect.mblooks.hslcolors": ("rhsl", ["masterHue", "masterSat", "masterLum"] + cores(["hue", "sat", "lum"])),
            "nova.effect.mblooks.huesaturation": ("husa", ["hue", "saturation", "lumaRed", "lumaGreen", "lumaBlue"]),
            "nova.effect.mblooks.pop": ("pop2", ["pop", "size", "preserveDetail"]),
            "nova.effect.mblooks.liftgammagain": ("lggn", ["gammaSpace", "strength", "exposure"] + rgb(["lift", "gamma", "gain"])),
            "nova.effect.mblooks.negbleachbypass": ("nbby", ["silverRetention", "exposure"]),
            "nova.effect.mblooks.printbleachbypass": ("blby", ["silverRetention", "exposure"]),
            "nova.effect.mblooks.twostrip": ("2stp", ["greenSensitivity", "exposure"]),
            "nova.effect.mblooks.spotexposure": ("spex", ["stops", "centerX", "centerY", "radius", "spread", "falloff", "strength", "red", "green", "blue", "aspect", "invert"]),
            "nova.effect.mblooks.channelmixer": ("cmix", ["normalizeAmount", "strength", "monochrome", "reserved", "monoRed", "monoGreen", "monoBlue"] + rgb(["red", "green", "blue"])),
            "nova.effect.mblooks.lut": ("lutc", ["menu", "strength"]),
            "nova.effect.mblooks.hazeflare": ("haze", ["spillage", "softness", "reach", "exposure", "reflectionExposure", "reflection", "matteBoxSize", "matteBoxShade", "tintRed", "tintGreen", "tintBlue"]),
            "nova.effect.mblooks.diffusion": ("diff", ["size", "grade", "glow", "highlightsOnly", "highlightBias", "exposureCompensation", "tintRed", "tintGreen", "tintBlue"]),
        ]
    }()

    /// Os valores de uma ferramenta na ordem do motor.
    public static func valores(_ params: [String], de v: [String: EffectValue]) -> [Float] {
        params.map { id in
            switch v[id] {
            case .float(let f)?: return f
            case .int(let i)?: return Float(i)
            case .vec2(let s)?: return s.x
            case .vec3(let s)?: return s.x
            case .vec4(let s)?: return s.x
            case nil: return 0
            }
        }
    }
}

final class LooksMotor {
    private let device: MTLDevice
    private let library: MTLLibrary
    private let pool: TexturePool
    private let formato: MTLPixelFormat = .rgba16Float
    private var pipelines: [String: MTLRenderPipelineState] = [:]
    private var luts: [String: (MTLTexture, Int)] = [:]
    private let lock = NSLock()
    /// Avisos da ultima passada (ferramenta sem porte, LUT que nao abriu...).
    var avisos: [String] = []

    /// Ordem e tipo dos uniforms e texturas de cada shader (Resources/mblooks/uniformes.json).
    private lazy var esquema: [String: (texturas: [String], uniforms: [(String, String)])] = {
        var out: [String: (texturas: [String], uniforms: [(String, String)])] = [:]
        let raiz = EffectRenderer.resourceRoot ?? Bundle.main.resourceURL
        guard let u = raiz?.appendingPathComponent("mblooks/uniformes.json"),
              let d = try? Data(contentsOf: u),
              let j = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { return out }
        for (nome, v) in j {
            guard let e = v as? [String: Any] else { continue }
            let tex = e["texturas"] as? [String] ?? []
            let uni = (e["uniforms"] as? [[String]] ?? []).compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }
            out[nome] = (tex, uni)
        }
        return out
    }()

    init(device: MTLDevice, library: MTLLibrary, pool: TexturePool) {
        self.device = device; self.library = library; self.pool = pool
    }

    // MARK: - passada

    /// Roda uma instancia do Looks sobre `entrada` (a camada, sRGB) e devolve uma
    /// textura do pool, do mesmo tamanho, no formato de trabalho.
    func render(entrada: MTLTexture, passos: [LooksPasso], forca: Float, mediaRoot: URL?,
                cb: MTLCommandBuffer) throws -> MTLTexture {
        avisos = []
        let w = entrada.width, h = entrada.height
        let base = try passe("entrada", w, h, ["uEntrada": entrada], ["uOrigem": [0, 0]], cb)
        var atual = base
        var video = false
        func trocar(_ t: MTLTexture) {
            if atual !== base { pool.recycle(atual) }
            atual = t
        }
        for p in passos {
            if p.codigo == "lutc" {
                guard let path = p.lut, let lt = lut3d(path, mediaRoot: mediaRoot) else { continue }
                let (t3, n) = lt
                if video { trocar(try converter(atual, w, h, paraVideo: false, cb)); video = false }
                let l = LooksContas.lut(p.valores, n)
                trocar(try passe("lutc", w, h, ["uEntrada": atual, "uLut": t3],
                                 ["uN": [Float(n)], "uEscala": [l.escala], "uDesloc": [l.desloc], "uS": [l.s]], cb))
                continue
            }
            if p.codigo == "csta" {
                avisos.append("Looks: Colorista ainda não está no iPhone")
                continue
            }
            let pede = LooksContas.VIDEO.contains(p.codigo)
            if pede != video { trocar(try converter(atual, w, h, paraVideo: pede, cb)); video = pede }
            if let r = try ferramenta(p, atual, w, h, cb) { trocar(r) }
        }
        if video { trocar(try converter(atual, w, h, paraVideo: false, cb)) }
        if forca < 1 {
            trocar(try passe("forca", w, h, ["uEntrada": atual, "uOriginal": base],
                             ["uForca": [max(0, min(1, forca))]], cb))
        }
        let saida = try passe("saida", w, h, ["uEntrada": atual, "uOriginal8": entrada], ["uOrigem": [0, 0]], cb)
        if atual !== base { pool.recycle(atual) }
        pool.recycle(base)
        return saida
    }

    private func converter(_ t: MTLTexture, _ w: Int, _ h: Int, paraVideo: Bool, _ cb: MTLCommandBuffer) throws -> MTLTexture {
        try passe("converter", w, h, ["uEntrada": t], ["uParaVideo": [paraVideo ? 1 : 0]], cb)
    }

    // MARK: - ferramentas

    private func ferramenta(_ p: LooksPasso, _ x: MTLTexture, _ w: Int, _ h: Int,
                            _ cb: MTLCommandBuffer) throws -> MTLTexture? {
        let a = p.valores
        let E = ["uEntrada": x]
        switch p.codigo {
        case "expo":
            return try passe("expo", w, h, E, ["uGanho": [LooksContas.exposure(a)]], cb)
        case "logc":
            let s = LooksContas.sCurve(a)
            return try passe("logc", w, h, E, ["uE": [s.e], "uS": [s.s], "uLo": [s.lo], "uK": [s.k], "uG": [s.g],
                                               "uInvS": [s.invS], "uInvUmMenosS": [s.invUmMenosS],
                                               "uMistura": [s.mistura], "uLog": [s.log ? 1 : 0]], cb)
        case "duto":
            let d = LooksContas.duotone(a)
            return try passe("duto", w, h, E, ["uCorA": d.corA, "uForcaA": [d.forcaA], "uCorB": d.corB,
                                               "uForcaB": [d.forcaB], "uLo": [d.lo], "uHi": [d.hi]], cb)
        case "chab":
            return try passe("chab", w, h, E, ["uEscala": LooksContas.chromAb(a)], cb)
        case "cmix":
            let c = LooksContas.channelMixer(a)
            return try passe("cmix", w, h, E, ["uR": c.r, "uG": c.g, "uB": c.b, "uMono": [c.mono ? 1 : 0], "uK": [c.k]], cb)
        case "lggn":
            let l = LooksContas.liftGammaGain(a)
            return try passe("lggn", w, h, E, ["uF": l.f, "uA": l.a, "uInvG": l.invG, "uGain": l.gain, "uM1": l.m1], cb)
        case "nbby", "blby":
            let b = LooksContas.bleachBypass(a, negativo: p.codigo == "nbby")
            return try passe("nbby", w, h, E, ["uK": [b.k], "uNeg": [b.negativo ? 1 : 0], "uE": [b.e]], cb)
        case "2stp":
            let t = LooksContas.twoStrip(a)
            return try passe("stp2", w, h, E, ["uR": t.r, "uGB": t.gb], cb)
        case "husa":
            let s = LooksContas.hueSaturation(a)
            guard s.rot || s.sat else { return nil }
            return try passe("husa", w, h, E, ["uRot": [s.rot ? 1 : 0], "uRotV": [s.rotV], "uSat": [s.sat ? 1 : 0],
                                               "uSatV": [s.satV], "uPesos": s.pesos], cb)
        case "lenv":
            let v = LooksContas.lensVignette(a, w, h)
            return try passe("lenv", w, h, E, ["uCentro": [v.cx, v.cy], "uAspecto": [v.aspecto], "uInvRaio": [v.invRaio],
                                               "uExpoente": [v.expoente], "uAltas": [v.altas],
                                               "uQuantidade": [v.quantidade]], cb)
        case "spex":
            let s = LooksContas.spotExposure(a, w, h)
            return try passe("spex", w, h, E, ["uCentro": [s.cx, s.cy], "uAspecto": [s.aspecto], "uInvRaio": [s.invRaio],
                                               "uInvSpread": [s.invSpread], "uCurva": s.curva, "uK": [s.k],
                                               "uTint": s.tint, "uInverte": [s.inverte ? 1 : 0]], cb)
        case "mjo2":
            let m = LooksContas.mojo2(a, w, h)
            let curvas = try tabela(m.curvas, largura: 1024, linhas: 5)
            return try passe("mjo2", w, h, ["uEntrada": x, "uCurvas": curvas],
                             ["uExpoFim": m.expoFim, "uExpoIncl": m.expoIncl, "uVinheta": m.vinheta,
                              "uP8": [m.p8], "uP9": [m.p9], "uTomSombra": m.tomSombra, "uTomLuz": m.tomLuz,
                              "uSaturacao": [m.saturacao], "uAzul": m.azul, "uPele": m.pele,
                              "uContFim": m.contFim, "uContIncl": m.contIncl, "uCor": [m.cor],
                              "uSaida": m.saida, "uForca": [m.forca]], cb)
        case "rhsl":
            let s = LooksContas.hslColors(a)
            guard !s.vazia else { return nil }
            let t = try tabela(s.tabela, largura: 1024, linhas: 1)
            return try passe("rhsl", w, h, ["uEntrada": x, "uHsl": t],
                             ["uMatiz": [s.matiz ? 1 : 0], "uSaturacao": [s.saturacao ? 1 : 0],
                              "uLuminancia": [s.luminancia ? 1 : 0]], cb)
        case "pop2":
            guard let pp = LooksContas.pop(a, w) else { return nil }
            if pp.positivo {
                let l = try passe("pop2luz", w, h, E, [:], cb)
                let b = try blur(l, pp.sigma, cb)
                if b !== l { pool.recycle(l) }
                let r = try passe("pop2pos", w, h, ["uEntrada": x, "uBorrado": b], ["uK": [pp.k]], cb)
                pool.recycle(b)
                return r
            }
            let red = try passe("pop2reduz", w, h, E, [:], cb)
            let bil = try passe("pop2bilateral", w, h, ["uEntrada": red, "uOriginal": x],
                                ["uRaio": [Float(pp.raio)], "uKs": [pp.ks], "uKr": [pp.kr]], cb)
            pool.recycle(red)
            let amp = try passe("pop2amplia", w, h, ["uEntrada": bil], [:], cb)
            pool.recycle(bil)
            let r = try passe("pop2neg", w, h, ["uEntrada": x, "uBil": amp], ["uK": [pp.k], "uInclinacao": [pp.inclinacao]], cb)
            pool.recycle(amp)
            return r
        case "diff":
            let d = LooksContas.diffusion(a, w)
            var fonte = x
            if let k = d.k { fonte = try passe("diffpot", w, h, E, ["uK": [k]], cb) }
            let b = try blur(fonte, d.sigma, cb)
            let r = try passe("diff", w, h, ["uEntrada": fonte, "uBorrado": b],
                              ["uA": [d.a], "uHl": [d.hl], "uC": [d.c], "uD": [d.d], "uE": [d.e], "uTint": d.tint], cb)
            if b !== fonte { pool.recycle(b) }
            if fonte !== x { pool.recycle(fonte) }
            return r
        case "odif":
            let d = LooksContas.opticalDiffusion(a, w)
            let realce = try passe("realces", w, h, E, ["uLo": [d.lo], "uHi": [d.hi], "uC": [d.c]], cb)
            var acc: MTLTexture? = nil
            for (i, s) in d.sigmas.enumerated() {
                var cam: MTLTexture = realce
                if let sg = s { cam = try blur(realce, sg, cb) }
                let novo = try passe("camada", w, h, ["uEntrada": acc ?? realce, "uCamada": cam],
                                     ["uPeso": [d.pesos[i]], "uPrimeira": [acc == nil ? 1 : 0]], cb)
                if cam !== realce { pool.recycle(cam) }
                if let o = acc { pool.recycle(o) }
                acc = novo
            }
            pool.recycle(realce)
            guard let soma = acc else { return nil }
            let r = try passe("difusao", w, h, ["uEntrada": x, "uAcumulador": soma], ["uGanho": [d.ganho]], cb)
            pool.recycle(soma)
            return r
        case "haze":
            let z = LooksContas.haze(a, w, h)
            let lado = try passe("hazelado", w, h, E, ["uFim": [z.fim], "uInvB": [z.invB], "uB": [z.b], "uK": [z.k]], cb)
            let b1 = try blur(lado, z.sigmaSuave, cb)
            if b1 !== lado { pool.recycle(lado) }
            let b2 = try blur(b1, z.sigmaAlcance, cb)
            if b2 !== b1 { pool.recycle(b1) }
            let caixa = try passe("hazecaixa", w, h, ["uEntrada": b2],
                                  ["uColunaU": z.colunaU, "uColunaV": z.colunaV, "uInterno": z.interno,
                                   "uEscala": z.escala], cb)
            pool.recycle(b2)
            let r = try passe("hazeflare", w, h, ["uEntrada": x, "uHaze": caixa],
                              ["uShade": [z.shade], "uExpo": [z.expo], "uRefl": [z.reflexo ? 1 : 0],
                               "uReflExpo": [z.expoDoReflexo], "uTint": z.tint], cb)
            pool.recycle(caixa)
            return r
        case "edgs":
            let passos = LooksContas.edgeSoftness(a, w, h)
            guard !passos.isEmpty else { return nil }
            var acc = x
            for pb in passos {
                let b = try blur(x, pb.sigma, cb)
                let (u0, u1) = pb.inverte ? (acc, b) : (b, acc)
                let r = try passe("elipse", w, h, ["uU0": u0, "uU1": u1],
                                  ["uColunaU": pb.colunaU, "uColunaV": pb.colunaV, "uInternoX": [pb.internoX],
                                   "uInternoY": [pb.internoY], "uInverte": [pb.inverte ? 1 : 0]], cb)
                if b !== x { pool.recycle(b) }
                if acc !== x { pool.recycle(acc) }
                acc = r
            }
            return acc
        default:
            avisos.append("Looks: ferramenta \(p.codigo) ainda não está no iPhone")
            return nil
        }
    }

    // MARK: - utilidades da GPU

    private func pipeline(_ nome: String) throws -> MTLRenderPipelineState {
        lock.lock(); defer { lock.unlock() }
        if let p = pipelines[nome] { return p }
        let fn = "looks_" + nome
        guard let frag = library.makeFunction(name: fn) else {
            throw RenderError.functionMissing(fn, effect: "Magic Bullet Looks")
        }
        guard let vert = library.makeFunction(name: "nova_fullscreen_vertex") else {
            throw RenderError.functionMissing("nova_fullscreen_vertex", effect: "Magic Bullet Looks")
        }
        let d = MTLRenderPipelineDescriptor()
        d.label = fn
        d.vertexFunction = vert
        d.fragmentFunction = frag
        d.colorAttachments[0].pixelFormat = formato
        let p = try device.makeRenderPipelineState(descriptor: d)
        pipelines[nome] = p
        return p
    }

    /// Um passe de tela cheia: `nome` e o shader (sem o prefixo looks_).
    private func passe(_ nome: String, _ w: Int, _ h: Int, _ tex: [String: MTLTexture],
                       _ u: [String: [Float]], _ cb: MTLCommandBuffer) throws -> MTLTexture {
        guard let e = esquema[nome] else { throw RenderError.functionMissing("looks_" + nome, effect: "Magic Bullet Looks (esquema)") }
        let alvo = try pool.obtain(width: w, height: h, format: formato)
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = alvo
        rp.colorAttachments[0].loadAction = .dontCare
        rp.colorAttachments[0].storeAction = .store
        guard let enc = cb.makeRenderCommandEncoder(descriptor: rp) else {
            pool.recycle(alvo)
            throw RenderError.encoderFailed("Looks \(nome)")
        }
        enc.label = "looks \(nome)"
        enc.setRenderPipelineState(try pipeline(nome))
        var valores = u
        valores["uTamanho"] = [Float(w), Float(h)]
        valores["uDePe"] = [0]
        let bytes = empacotar(e.uniforms, valores)
        bytes.withUnsafeBytes { enc.setFragmentBytes($0.baseAddress!, length: bytes.count, index: 0) }
        for (k, n) in e.texturas.enumerated() {
            enc.setFragmentTexture(tex[n] ?? tex["uEntrada"], index: k)
        }
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
        return alvo
    }

    /// Empacota os uniforms com o alinhamento do MSL (float3 ocupa 16 bytes).
    private func empacotar(_ campos: [(String, String)], _ v: [String: [Float]]) -> [UInt8] {
        var b: [UInt8] = []
        var maior = 4
        func alinhar(_ n: Int) { maior = max(maior, n); while b.count % n != 0 { b.append(0) } }
        func f(_ x: Float) { withUnsafeBytes(of: x) { b.append(contentsOf: $0) } }
        func i(_ x: Int32) { withUnsafeBytes(of: x) { b.append(contentsOf: $0) } }
        for (nome, tipo) in campos {
            let x = v[nome] ?? []
            func c(_ k: Int) -> Float { k < x.count ? x[k] : 0 }
            switch tipo {
            case "float": alinhar(4); f(c(0))
            case "float2": alinhar(8); f(c(0)); f(c(1))
            case "float3": alinhar(16); f(c(0)); f(c(1)); f(c(2)); f(0)
            case "float4": alinhar(16); f(c(0)); f(c(1)); f(c(2)); f(c(3))
            case "int", "bool": alinhar(4); i(Int32(c(0).rounded()))
            case "int2": alinhar(8); i(Int32(c(0).rounded())); i(Int32(c(1).rounded()))
            case "int3": alinhar(16); i(Int32(c(0).rounded())); i(Int32(c(1).rounded())); i(Int32(c(2).rounded())); i(0)
            default: alinhar(4); f(c(0))
            }
        }
        alinhar(maior)
        if b.isEmpty { b = [UInt8](repeating: 0, count: 16) }
        return b
    }

    /// Gaussiano com o sigma em px (o `b()` do Android). Sigma minusculo: a propria textura.
    private func blur(_ t: MTLTexture, _ sigma: Float, _ cb: MTLCommandBuffer) throws -> MTLTexture {
        guard sigma > 0.05 else { return t }
        let alvo = try pool.obtain(width: t.width, height: t.height, format: formato)
        let g = MPSImageGaussianBlur(device: device, sigma: sigma)
        g.edgeMode = .clamp
        g.encode(commandBuffer: cb, sourceTexture: t, destinationTexture: alvo)
        return alvo
    }

    /// Tabela float RGBA (curvas do Mojo, HSL) como textura RGBA32F.
    private func tabela(_ v: [Float], largura: Int, linhas: Int) throws -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba32Float, width: largura,
                                                         height: linhas, mipmapped: false)
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: largura, height: linhas)
        }
        var dados = v
        if dados.count < largura * linhas * 4 { dados += [Float](repeating: 0, count: largura * linhas * 4 - dados.count) }
        dados.withUnsafeBytes { buf in
            t.replace(region: MTLRegionMake2D(0, 0, largura, linhas), mipmapLevel: 0,
                      withBytes: buf.baseAddress!, bytesPerRow: largura * 16)
        }
        return t
    }

    /// O LUT 3D da ferramenta LUT (looks/x.png do app ou projeto/x.cube), RGBA32F.
    private func lut3d(_ path: String, mediaRoot: URL?) -> (MTLTexture, Int)? {
        lock.lock()
        if let l = luts[path] { lock.unlock(); return l }
        lock.unlock()
        let url: URL?
        if path.hasPrefix("projeto/") {
            url = mediaRoot?.appendingPathComponent(String(path.dropFirst("projeto/".count)))
        } else {
            url = (EffectRenderer.resourceRoot ?? Bundle.main.resourceURL)?.appendingPathComponent(path)
        }
        guard let u = url,
              let lido = try? (u.pathExtension.lowercased() == "cube"
                               ? EffectParamTextures.parseCube(u) : EffectParamTextures.parseStrip(u))
        else {
            avisos.append("Looks: LUT \(path) não abriu")
            return nil
        }
        let (n, rgba) = lido
        var f = [Float](repeating: 1, count: n * n * n * 4)
        for i in 0..<(n * n * n) {
            f[i * 4] = Float(rgba[i * 4]) / 255
            f[i * 4 + 1] = Float(rgba[i * 4 + 1]) / 255
            f[i * 4 + 2] = Float(rgba[i * 4 + 2]) / 255
        }
        let d = MTLTextureDescriptor()
        d.textureType = .type3D
        d.pixelFormat = .rgba32Float
        d.width = n; d.height = n; d.depth = n
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else { return nil }
        f.withUnsafeBytes { buf in
            t.replace(region: MTLRegionMake3D(0, 0, 0, n, n, n), mipmapLevel: 0, slice: 0,
                      withBytes: buf.baseAddress!, bytesPerRow: n * 16, bytesPerImage: n * n * 16)
        }
        lock.lock(); luts[path] = (t, n); lock.unlock()
        return (t, n)
    }
}
