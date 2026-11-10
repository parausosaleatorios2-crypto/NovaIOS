//
//  Glitchify.swift
//  NovaEngine
//
//  O Glitchify (Cinema Spice) do APK: `model/Glitchify.kt` (com.novaeditor.model.Glitchify),
//  portado linha a linha. A conta roda na CPU sobre um buffer ARGB de 8 bits (como o
//  PF_Pixel8 do After Effects), de cima para baixo, alfa direto (sem pre-multiplicar).
//
//  Onde o JADX embaralhou o metodo (blend, subpixel, transformacao, particao, tempoDoAe) a
//  conta foi tirada do smali: o tempo e divisao em float, os modos 23..34 do blend nao
//  caem uns nos outros, o 26 e Difference.
//
//  Ordem (aplicar): Transform -> Transition -> Channel (Split + Scale) -> Color ->
//  Image (Pixel Streak + Glitch Block) -> Compression (DCT + Dither) -> mistura final.
//  O Glitch Slice (WebP de verdade no plugin) fica de fora, como no Android.
//

import Foundation
import Metal

public enum Glitchify {

    // MARK: - tabelas

    static let menuModos = [1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 35, 36, 37, 38, 40, 41, 42, 43, 45, 46]
    static let menuSplit = [1, 2, 3, 5, 6, 7, 9, 10, 11]
    static let menuScale = [1, 2, 3, 4, 6, 7, 8, 9]
    static let menuTransicao = [1, 2, 3, 4, 6, 7, 8, 9, 11]

    static let F3: Float = 0.33333334
    static let G3: Float = 0.16666667
    static let G3x2: Float = 0.33333334
    static let G3x3: Float = 0.5
    static let grad: [Float] = [1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1, 0, 1, 0, 1, -1, 0, 1, 1, 0, -1, -1, 0, -1, 0, 1, 1, 0, -1, 1, 0, 1, -1, 0, -1, -1]
    static let quant: [Double] = [16, 11, 10, 16, 24, 40, 51, 61, 12, 12, 14, 19, 26, 58, 60, 55, 14, 13, 16, 24, 40, 57, 69, 56, 14, 17, 22, 29, 51, 87, 80, 62, 18, 22, 37, 56, 68, 109, 103, 77, 49, 64, 78, 87, 103, 121, 120, 102, 72, 92, 95, 98, 112, 100, 103, 99, 0, 0, 0, 0, 0, 0, 0, 0]
    static let raiz12 = 0.707106781

    private static func bits(_ v: [Int64]) -> [Double] { v.map { Double(bitPattern: UInt64(bitPattern: $0)) } }
    static let cosIda: [Double] = bits([4607182418800017408, 4607182418800017408, 4607182418800017408, 4607182418800017408, 4607182418800017408, 4607182418800017408, 4607182418800017408, 4607182418800017408, 4607009347991985328, 4605664432017547683, 4603179351334086857, 4596196889902818829, -4627175146951956984, -4620192685520688954, -4617707604837228124, -4616362688862790480, 4606496786581982534, 4600565431771507044, -4622806605083268766, -4616875250272793274, -4616875250272793273, -4622806605083268755, 4600565431771507047, 4606496786581982532, 4605664432017547683, -4627175146951956984, -4616362688862790480, -4620192685520688952, 4603179351334086853, 4607009347991985328, 4596196889902818845, -4617707604837228126, 4604544271217802189, -4618827765636973620, -4618827765636973618, 4604544271217802187, 4604544271217802190, -4618827765636973627, -4618827765636973623, 4604544271217802180, 4603179351334086857, -4616362688862790480, 4596196889902818828, 4605664432017547686, -4617707604837228126, -4627175146951956990, 4607009347991985330, -4620192685520688958, 4600565431771507044, -4616875250272793273, 4606496786581982532, -4622806605083268763, -4622806605083268751, 4606496786581982534, -4616875250272793277, 4600565431771507039, 4596196889902818829, -4620192685520688952, 4605664432017547686, -4616362688862790478, 4607009347991985329, -4617707604837228127, 4603179351334086850, -4627175146951956970])
    static let cosVolta: [Double] = bits([4607182418800017408, 4607009347991985328, 4606496786581982534, 4605664432017547683, 4604544271217802189, 4603179351334086857, 4600565431771507044, 4596196889902818829, 4607182418800017408, 4605664432017547683, 4600565431771507044, -4627175146951956984, -4618827765636973620, -4616362688862790480, -4616875250272793273, -4620192685520688952, 4607182418800017408, 4603179351334086857, -4622806605083268766, -4616362688862790480, -4618827765636973618, 4596196889902818828, 4606496786581982532, 4605664432017547686, 4607182418800017408, 4596196889902818829, -4616875250272793274, -4620192685520688952, 4604544271217802187, 4605664432017547686, -4622806605083268763, -4616362688862790478, 4607182418800017408, -4627175146951956984, -4616875250272793273, 4603179351334086853, 4604544271217802190, -4617707604837228126, -4622806605083268751, 4607009347991985329, 4607182418800017408, -4620192685520688954, -4622806605083268755, 4607009347991985330, -4618827765636973627, -4627175146951956927, 4606496786581982540, -4617707604837228136, 4607182418800017408, -4617707604837228124, 4600565431771507047, 4596196889902818814, -4618827765636973623, 4607009347991985327, -4616875250272793271, 4603179351334086876, 4607182418800017408, -4616362688862790480, 4606496786581982532, -4617707604837228135, 4604544271217802180, -4620192685520688958, 4600565431771506980, -4627175146951957096])
    static let op8Tabela = [0, 3, 5, 8, 10, 13, 15, 18, 20, 23, 25, 27, 31, 33, 36, 38, 41, 43, 46, 48, 51, 54, 55, 59, 60, 64, 66, 69, 71, 74, 76, 78, 82, 83, 87, 88, 92, 93, 97, 99, 102, 105, 106, 110, 111, 115, 116, 120, 121, 125, 127, 129, 133, 134, 138, 139, 143, 144, 148, 149, 153, 154, 157, 161, 162, 166, 167, 171, 172, 176, 177, 180, 182, 185, 187, 190, 194, 195, 199, 200, 204, 205, 208, 210, 213, 215, 218, 220, 223, 227, 228, 231, 233, 236, 238, 241, 243, 246, 248, 251, 255]
    static let op8Quebrados: [(Double, Int)] = [(0.4, 1), (12.5, 32), (33.3, 85), (66.7, 169), (99.6, 252)]

    // MARK: - conversoes do Java

    /// (int) de um double no Java: trunca, NaN vira 0, satura.
    @inline(__always) static func jInt(_ d: Double) -> Int {
        if d.isNaN { return 0 }
        if d >= 2147483647 { return 2147483647 }
        if d <= -2147483648 { return -2147483648 }
        return Int(d)
    }
    @inline(__always) static func jInt(_ f: Float) -> Int { jInt(Double(f)) }
    @inline(__always) static func jLong(_ d: Double) -> Int64 {
        if d.isNaN { return 0 }
        if d >= 9.2233720368547758e18 { return Int64.max }
        if d <= -9.2233720368547758e18 { return Int64.min }
        return Int64(d)
    }
    /// Math.round(double) do Java.
    @inline(__always) static func jRound(_ d: Double) -> Int64 { jLong((d + 0.5).rounded(.down)) }
    @inline(__always) static func clampI(_ v: Int, _ a: Int, _ b: Int) -> Int { v < a ? a : (v > b ? b : v) }
    @inline(__always) static func b8(_ v: Int) -> UInt8 { UInt8(truncatingIfNeeded: v) }

    static func doMenu(_ m: [Int], _ i: Int) -> Int { m[clampI(i, 0, m.count - 1)] }

    // MARK: - controles

    public struct Controles {
        public var amount = 50.0, speed = 50.0
        public var seed = 0
        public var completion = 0.0, softness = 10.0
        public var transitionChannel = 7
        public var transformSpeed = 1.0
        public var position: [Double]? = nil
        public var positionWiggle = 0.0, scale = 100.0, scaleWiggle = 0.0
        public var cropTopLeft: [Double]? = nil, cropBottomRight: [Double]? = nil
        public var cropWiggle = 0.0, opacity = 100.0
        public var transferMode = 1
        public var compositeOver = false, channelEnable = true
        public var splitChannel = 10
        public var splitH = 50.0, splitV = 0.0, splitSpeed = 0.0, scaleAmount = 30.0
        public var scaleChannel = 1
        public var scaleVertical = false
        public var scaleOffset = 50.0, scaleSpeed = 3.0
        public var channelMode = 1
        public var colorEnable = true
        public var colorOffset = 20.0, colorAmount = 80.0, colorOpacity = 25.0
        public var colorMode = 1
        public var imageEnable = true
        public var streak = 25.0
        public var verticalSort = false
        public var sliceAmount = 50.0, blockAmount = 50.0, blockSpeed = 50.0, blockWidth = 150.0, blockHeight = 50.0
        public var blockDirection = 1, blockMode = 21
        public var compressionEnable = false
        public var compressionMultiplier = 50.0, ditherAmount = 50.0, jpegAmount = 50.0
        public var showNoise = false
        public var gain = 1.5, lacunarity = 10.0
        public var octaves = 2
        public var repeatEdge = true, sigmoid = false
        public var quantization = 2.0
        public var fillGaps = false, useNoise = true
        public var noiseCutoff = 50
        public var grouping = 5.0, wiggleSteps = 2.0

        public init() {}

        /// Os valores do efeito (`c96.a` do APK). Pontos vem de 0 a 1 da camada.
        public init(valores v: [String: EffectValue], largura w: Int, altura h: Int) {
            func num(_ k: String) -> Double? {
                switch v[k] {
                case .float(let f)?: return Double(f)
                case .int(let i)?: return Double(i)
                default: return nil
                }
            }
            func d(_ k: String, _ p: inout Double) { if let x = num(k) { p = x } }
            func i(_ k: String, _ p: inout Int) { if let x = num(k) { p = Int(Glitchify.jRound(x)) } }
            func b(_ k: String, _ p: inout Bool) { if let x = num(k) { p = x != 0 } }
            func m(_ k: String, _ menu: [Int], _ p: inout Int) { if let x = num(k) { p = Glitchify.doMenu(menu, Glitchify.jInt(x)) } }
            func pt(_ k: String) -> [Double]? {
                guard case .vec2(let s)? = v[k] else { return nil }
                return [Double(Glitchify.jRound(Double(s.x) * Double(w) * 4096)) / 4096,
                        Double(Glitchify.jRound(Double(s.y) * Double(h) * 4096)) / 4096]
            }
            d("amount", &amount); d("speed", &speed); i("seed", &seed)
            d("completion", &completion); d("softness", &softness)
            m("transitionChannel", Glitchify.menuTransicao, &transitionChannel)
            d("transformSpeed", &transformSpeed)
            position = pt("position")
            d("scale", &scale); d("positionWiggle", &positionWiggle); d("scaleWiggle", &scaleWiggle)
            cropTopLeft = pt("cropTopLeft"); cropBottomRight = pt("cropBottomRight")
            d("cropWiggle", &cropWiggle); d("opacity", &opacity)
            m("transferMode", Glitchify.menuModos, &transferMode)
            b("compositeOver", &compositeOver); b("channelEnable", &channelEnable)
            m("splitChannel", Glitchify.menuSplit, &splitChannel)
            d("splitH", &splitH); d("splitV", &splitV); d("splitSpeed", &splitSpeed); d("scaleAmount", &scaleAmount)
            m("scaleChannel", Glitchify.menuScale, &scaleChannel)
            b("scaleVertical", &scaleVertical); d("scaleOffset", &scaleOffset); d("scaleSpeed", &scaleSpeed)
            m("channelMode", Glitchify.menuModos, &channelMode)
            b("colorEnable", &colorEnable); d("colorOffset", &colorOffset); d("colorAmount", &colorAmount)
            d("colorOpacity", &colorOpacity); m("colorMode", Glitchify.menuModos, &colorMode)
            b("imageEnable", &imageEnable); d("streak", &streak); b("verticalSort", &verticalSort)
            d("sliceAmount", &sliceAmount); d("blockAmount", &blockAmount); d("blockSpeed", &blockSpeed)
            d("blockWidth", &blockWidth); d("blockHeight", &blockHeight)
            if let x = num("blockDirection") { blockDirection = Glitchify.jInt(x) + 1 }
            m("blockMode", Glitchify.menuModos, &blockMode)
            b("compressionEnable", &compressionEnable); d("compressionMultiplier", &compressionMultiplier)
            d("ditherAmount", &ditherAmount); d("jpegAmount", &jpegAmount); b("showNoise", &showNoise)
            d("gain", &gain); d("lacunarity", &lacunarity); i("octaves", &octaves)
            b("repeatEdge", &repeatEdge); b("sigmoid", &sigmoid); d("quantization", &quantization)
            b("fillGaps", &fillGaps); b("useNoise", &useNoise); i("noiseCutoff", &noiseCutoff)
            d("grouping", &grouping); d("wiggleSteps", &wiggleSteps)
        }
    }

    // MARK: - ruido (simplex 3D do plugin)

    final class Ruido {
        let altura: Int
        let gain: Float
        let lacunarity: Float
        let oitavas: Int
        var p = [Int](repeating: 0, count: 512)
        let t: Float

        init(_ seed: Int, _ altura: Int, _ speed: Float, _ tempo: Float, _ gain: Float, _ lac: Float, _ oit: Int) {
            self.altura = altura
            self.gain = gain
            self.lacunarity = lac
            self.oitavas = oit
            self.t = tempo * 2.0 * speed
            var j = UInt64(UInt32(truncatingIfNeeded: seed))
            var a = [Int](0..<256)
            var i5 = 1
            while i5 < 256 {
                j = (j &* 214013 &+ 2531011) & 0xFFFF_FFFF
                let i6 = i5 + 1
                let i7 = Int((j >> 16) & 32767) % i6
                a.swapAt(i5, i7)
                i5 = i6
            }
            for k in 0..<512 { p[k] = a[k & 255] }
        }

        @inline(__always) private func canto(_ f: Float, _ f2: Float, _ f3: Float, _ i: Int) -> Float {
            let f4 = ((0.6 - (f * f)) - (f2 * f2)) - (f3 * f3)
            let i2 = i * 3
            let f5 = (f3 * Glitchify.grad[i2 + 2]) + (f * Glitchify.grad[i2]) + (f2 * Glitchify.grad[i2 + 1])
            let f6 = f4 * f4
            let f7 = f6 * f6
            if 0.0 > f4 { return 0 }
            return f5 * f7
        }

        @inline(__always) private func ff(_ f: Float) -> Int {
            let i = Glitchify.jInt(f)
            return f >= 0 ? i : i - 1
        }

        func amostra(_ i: Int, _ i2: Int, _ f: Float = 256, _ f2: Float = 1) -> Float {
            let f3 = 0.9 * f
            let f4: Float = 0.100000024 * f
            var v = fbm(i, i2, f2 * t) * f
            if v > f3 { v = (v * 0.2) + (f3 * 0.8) }
            if f4 > v { v = (v * 0.2) + (f4 * 0.8) }
            if v >= f { v = f - 1 }
            if 0 > v { return 0 }
            return v
        }

        func fbm(_ i: Int, _ i2: Int, _ f: Float) -> Float {
            let f2 = Float(i), f3 = Float(i2)
            var f5: Float = 1.0 / Float(altura)
            let f6 = Float(oitavas)
            var soma: Float = 0
            var amp: Float = 1
            var i3 = 0
            while f6 > Float(i3) {
                let f8 = f3 * f5
                let f9 = f2 * f5
                let f10 = f5 * f
                let f11 = (f8 + f9 + f10) * Glitchify.F3
                let a = ff(f8 + f11), b = ff(f9 + f11), c = ff(f11 + f10)
                let f13 = Float(a + b + c) * 0.16666667
                let f14 = (f8 - Float(a)) + f13
                let f15 = (f9 - Float(b)) + f13
                let f16 = (f10 - Float(c)) + f13
                let z = f14 >= f15, z2 = f15 >= f16, z3 = f14 >= f16
                let z4 = f16 > f15, z5 = f16 > f14
                let z6 = z && z2
                let z7 = z && !z2 && z3
                let z8 = z && !z2 && !z3
                let z9 = !z && z4
                let z10 = !z && !z4 && z5
                let z11 = !z && !z4 && !z5
                let i4 = (z6 || z7) ? 1 : 0
                let i5 = (z10 || z11) ? 1 : 0
                let i6 = (z8 || z9) ? 1 : 0
                let i7 = (z6 || z7 || z8 || z11) ? 1 : 0
                let i8 = (z6 || z9 || z10 || z11) ? 1 : 0
                let i9 = (z7 || z8 || z9 || z10) ? 1 : 0
                let f17 = (f14 - Float(i4)) + 0.16666667
                let f18 = (f15 - Float(i5)) + 0.16666667
                let f19 = (f16 - Float(i6)) + 0.16666667
                let f20 = Glitchify.G3x2 + (f14 - Float(i7))
                let f21 = Glitchify.G3x2 + (f15 - Float(i8))
                let f22 = Glitchify.G3x2 + (f16 - Float(i9))
                let f23 = Glitchify.G3x3 + (f14 - 1)
                let f25 = Glitchify.G3x3 + (f15 - 1)
                let f27 = Glitchify.G3x3 + (f16 - 1)
                let i17 = a & 255, i18 = b & 255, i19 = c & 255
                let g0 = p[i17 + p[i18 + p[i19]]] % 12
                let g1 = p[(i17 + i4) + p[(i18 + i5) + p[i19 + i6]]] % 12
                let g2 = p[(i17 + i7) + p[(i18 + i8) + p[i19 + i9]]] % 12
                let g3 = p[(i17 + 1) + p[(i18 + 1) + p[i19 + 1]]] % 12
                soma = ((canto(f17, f18, f19, g1) + canto(f14, f15, f16, g0) + canto(f20, f21, f22, g2)
                         + canto(f23, f25, f27, g3)) * amp) + soma
                amp = amp * gain
                f5 *= lacunarity
                i3 += 1
            }
            return soma * 8 * 2 + 0.5
        }
    }

    struct Transformacao {
        var s: Double, tx: Double, ty: Double
        var l: Int, t: Int, r: Int, b: Int
    }

    // MARK: - entrada

    /// Tempo do AE a partir do tempo e da duracao do quadro (s): quadros / fps, em float.
    public static func tempoDoAe(_ tempo: Double, _ duracaoDoQuadro: Double) -> Float {
        guard duracaoDoQuadro > 0 else { return Float(tempo) }
        let q = Int(jRound(tempo / duracaoDoQuadro))
        let fps = 1.0 / duracaoDoQuadro
        let r = Int(jRound(fps))
        if abs(fps - Double(r)) < 0.001 { return Float(q) / Float(r) }
        return Float(q * 1001) / Float(Int(jRound(fps * 1001 / 1000)) * 1000)
    }

    /// ARGB 8 bits, de cima para baixo. Devolve o resultado no mesmo formato.
    public static func aplicar(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ tempo: Float) -> [UInt8] {
        guard src.count == w * h * 4, w > 0, h > 0 else { return src }
        let ruido = Ruido(c.seed, h, Float(c.speed), tempo, Float(c.gain), Float(c.lacunarity), c.octaves)
        if c.showNoise { return imagemDoRuido(ruido, w, h) }
        var a = transform(src, w, h, c, ruido)
        if c.completion > 0 { a = transition(a, w, h, c, ruido) }
        let base = c.compositeOver ? src : a
        if c.channelEnable {
            a = misturar(a, channelScale(channelSplit(a, w, h, c, ruido), w, h, c, ruido), w, h, c.channelMode, 100)
        }
        if c.colorEnable {
            a = misturar(a, colorGlitch(a, c, ruido), w, h, c.colorMode, c.colorOpacity)
        }
        if c.imageEnable {
            let ps = pixelStreak(a, w, h, c, ruido)
            a = misturar(ps, glitchBlock(ps, w, h, c, ruido), w, h, c.blockMode, 100)
        }
        if c.compressionEnable {
            a = compressionDither(compressionDct(a, w, h, c), w, h, c)
        }
        return misturar(base, a, w, h, c.transferMode, c.opacity)
    }

    /// RGBA 8 bits pre-multiplicado (o que sai da GPU) -> conta -> RGBA pre-multiplicado.
    public static func aplicarRGBA(_ rgba: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ tempo: Float) -> [UInt8] {
        let n = w * h
        var argb = [UInt8](repeating: 0, count: n * 4)
        for i in 0..<n {
            let a = Int(rgba[i * 4 + 3])
            argb[i * 4] = UInt8(a)
            if a > 0 {
                for k in 0..<3 { argb[i * 4 + 1 + k] = UInt8(min(255, (Int(rgba[i * 4 + k]) * 255 + a / 2) / a)) }
            }
        }
        let r = aplicar(argb, w, h, c, tempo)
        var out = [UInt8](repeating: 0, count: n * 4)
        for i in 0..<n {
            let a = Int(r[i * 4])
            guard a != 0 else { continue }
            for k in 0..<3 { out[i * 4 + k] = UInt8((Int(r[i * 4 + 1 + k]) * a + 127) / 255) }
            out[i * 4 + 3] = UInt8(a)
        }
        return out
    }

    /// Le `leitura` (rgba8, compartilhada), roda e grava em `escrita`.
    public static func rodar(leitura: MTLTexture, escrita: MTLTexture, controles: Controles, tempo: Float) {
        let w = leitura.width, h = leitura.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        px.withUnsafeMutableBytes { b in
            leitura.getBytes(b.baseAddress!, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        }
        let r = aplicarRGBA(px, w, h, controles, tempo)
        r.withUnsafeBytes { b in
            escrita.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: b.baseAddress!, bytesPerRow: w * 4)
        }
    }

    // MARK: - paralelo por faixas de linhas

    static let nucleos = max(1, min(ProcessInfo.processInfo.activeProcessorCount, 8))

    static func porFaixas(_ linhas: Int, _ largura: Int, _ f: (Int, Int) -> Void) {
        let n = linhas * largura < 65536 ? 1 : min(nucleos, linhas)
        if n <= 1 { f(0, linhas); return }
        DispatchQueue.concurrentPerform(iterations: n) { k in
            f((linhas * k) / n, ((k + 1) * linhas) / n)
        }
    }

    /// Ponteiro cru (as faixas escrevem linhas diferentes do mesmo buffer).
    final class Buf: @unchecked Sendable {
        let p: UnsafeMutablePointer<UInt8>
        let n: Int
        init(_ a: [UInt8]) {
            n = a.count
            p = .allocate(capacity: max(n, 1))
            a.withUnsafeBufferPointer { b in if n > 0 { p.initialize(from: b.baseAddress!, count: n) } }
        }
        init(zeros n: Int) {
            self.n = n
            p = .allocate(capacity: max(n, 1))
            p.initialize(repeating: 0, count: max(n, 1))
        }
        deinit { p.deallocate() }
        var array: [UInt8] { Array(UnsafeBufferPointer(start: p, count: n)) }
        @inline(__always) func u(_ i: Int) -> Int { Int(p[i]) }
    }

    // MARK: - helpers

    @inline(__always) static func e(_ i: Int, _ i2: Int, _ i3: Int, _ i4: Int) -> Int { ((i * i2) + i3) * i4 }
    @inline(__always) static func meio255(_ i: Int) -> Int { ((i * 2) + 255) / 510 }
    @inline(__always) static func tetoDe(_ i: Int, _ i2: Int) -> Int { ((i + i2) - 1) / i2 }
    @inline(__always) static func ctrunc(_ i: Int, _ i2: Int) -> Int { i / i2 }
    @inline(__always) static func luma(_ i: UInt32) -> Int {
        (Int(i & 255) * 114 + (Int((i >> 16) & 255) * 299 + Int((i >> 8) & 255) * 587)) / 1000
    }
    @inline(__always) static func fb(_ i: Int) -> Float { Float(Double(i) / 255.0) }
    static func cvttsd2si(_ d: Double) -> Int {
        if !d.isFinite || d <= -2.147483649e9 || d >= 2.147483648e9 { return Int(Int32.min) }
        return Int(d)
    }
    static func byteDoPlugin(_ d: Double) -> Int {
        if 0 > d { return 0 }
        if d > 255 { return 255 }
        return Int(d)
    }
    static func byte64(_ d: Double) -> Int {
        if !d.isFinite || abs(d) >= 9.2e18 { return 0 }
        return Int(Int64(d) & 255)
    }
    static func fixo(_ d: Double) -> Int64 { jLong((65536.0 * d) + (d < 0 ? -0.5 : 0.5)) }
    static func pixelDoCrop(_ d: Double) -> Int { Int(truncatingIfNeeded: (fixo(d) + 32768) >> 16) }

    static func op8(_ d: Double) -> Int {
        if d >= 100 { return 255 }
        if d <= 0 { return 0 }
        for (k, v) in op8Quebrados where abs(k - d) < 1e-6 { return v }
        return op8Tabela[clampI(Int(jRound(d)), 0, 100)]
    }

    static func xferDoMenu(_ i: Int) -> Int {
        switch i {
        case 2: return 0
        case 3: return 1
        case 6: return 10
        case 7: return 5
        case 8: return 28
        case 9: return 24
        case 10: return 30
        case 11: return 36
        case 13: return 4
        case 14: return 11
        case 15: return 6
        case 16: return 27
        case 17: return 23
        case 18: return 29
        case 19: return 35
        case 21: return 7
        case 22: return 8
        case 23: return 9
        case 24: return 31
        case 25: return 32
        case 26: return 33
        case 27: return 34
        case 29: return 26
        case 30: return 12
        case 31: return 25
        case 32: return 37
        case 33: return 38
        case 35: return 13
        case 36: return 14
        case 37: return 15
        case 38: return 16
        case 40: return 17
        case 41: return 18
        case 42: return 19
        case 43: return 20
        case 45: return 21
        case 46: return 22
        default: return 2
        }
    }

    static func valorDoCanal(_ b: Buf, _ i: Int, _ canal: Int) -> Int {
        valorDoCanal(b.u(i), b.u(i + 1), b.u(i + 2), b.u(i + 3), canal)
    }

    static func valorDoCanal(_ a: Int, _ r: Int, _ g: Int, _ bl: Int, _ canal: Int) -> Int {
        switch canal {
        case 2: return (r + g + bl) / 3
        case 3:
            let i3 = r * 100, i4 = g * 100, i5 = bl * 100
            var mx = i4 > i3 ? i4 : i3
            if i5 > mx { mx = i5 }
            var mn = i4 < i3 ? i4 : i3
            if i5 < mn { mn = i5 }
            var d = mx - mn
            if d == 0 { d = 1 }
            var h = ((i4 - i5) / d) + (i4 < i5 ? 600 : 0)
            let h2 = ((i5 - i3) / d) + 200
            let h3 = ((i3 - i4) / d) + 400
            if mx != i3 {
                if mx == i4 { h = h2 } else { h = mx == i5 ? h3 : 0 }
            }
            return ((mx != mn ? h : 0) * 255) / 600
        case 4:
            var mx = g > r ? g : r
            if bl > mx { mx = bl }
            let mn0 = g < r ? g : r
            let mn = bl >= mn0 ? mn0 : bl
            if mx == 0 { return 0 }
            return ((mx - mn) * 255) / mx
        case 6: return r
        case 7: return g
        case 8: return bl
        case 9: return a
        default: return ((bl * 114) + ((r * 299) + (g * 587))) / 1000
        }
    }

    static func yccDe(_ f: Float, _ f2: Float, _ f3: Float) -> [Float] {
        let d = Double(f), d2 = Double(f2), d3 = Double(f3)
        return [Float((0.114 * d3) + (0.299 * d) + (0.587 * d2)),
                Float((d3 * 0.5) - ((d2 * 0.331264) + (d * 0.168736))),
                Float(((d * 0.5) - (d2 * 0.418688)) - (d3 * 0.081312))]
    }

    static func rgbDeYcc(_ f: Float, _ f2: Float, _ f3: Float) -> [Int] {
        let d = Double(f), d2 = Double(f2), d3 = Double(f3)
        let d4 = (1.402 * d3) + Double(f2 * 0.0) + d
        let d5 = (d - (0.344136 * d2)) - (d3 * 0.714136)
        let dc = (d2 * 1.772) + d + Double(0.0 * f3)
        return [byte64(d4 * 255), byte64(d5 * 255), byte64(dc * 255)]
    }

    static func hsvDe(_ f: Float, _ f2: Float, _ f3: Float) -> [Float] {
        var mn = f > f2 ? f2 : f
        if mn > f3 { mn = f3 }
        var mx = f2 > f ? f2 : f
        if f3 > mx { mx = f3 }
        let d = mx - mn
        var h: Float
        if f == mx { h = (f2 - f3) / d }
        else { h = f2 == mx ? ((f3 - f) / d) + 2 : ((f - f2) / d) + 4 }
        var f7 = h * 60
        if 0 > f7 { f7 += 360 }
        if mx == 0 { f7 = -1 }
        return [f7, mx != 0 ? d / mx : 0, mx]
    }

    static func rgbDeHsv(_ h: Float, _ s: Float, _ v: Float) -> [Int] {
        let f4 = h / 60
        let ok = abs(f4) <= Float.greatestFiniteMagnitude
        var i = ok ? jInt(f4) : Int(Int32.min)
        if ok && f4 < 0 { i -= 1 }
        let f5 = f4 - Float(i)
        let p = (1 - s) * v
        let q = ((1 - (f5 * s)) * v)
        let t = (1 - ((1 - f5) * s)) * v
        var r: Float, g: Float, b: Float
        switch i {
        case 0: (r, g, b) = (v, t, p)
        case 1: (r, g, b) = (q, v, p)
        case 2: (r, g, b) = (p, v, t)
        case 3: (r, g, b) = (p, q, v)
        case 4: (r, g, b) = (t, p, v)
        default: (r, g, b) = (v, p, q)
        }
        if s == 0 { (r, g, b) = (v, v, v) }
        return [byte64(Double(r * 255)), byte64(Double(g * 255)), byte64(Double(b * 255))]
    }

    // MARK: - ruido como imagem

    static func imagemDoRuido(_ r: Ruido, _ w: Int, _ h: Int) -> [UInt8] {
        let out = Buf(zeros: w * h * 4)
        porFaixas(h, w) { a, z in
            for y in a..<z {
                for x in 0..<w {
                    let v = b8(jInt(r.amostra(x, y)))
                    let i = e(y, w, x, 4)
                    out.p[i] = 255; out.p[i + 1] = v; out.p[i + 2] = v; out.p[i + 3] = v
                }
            }
        }
        return out.array
    }

    // MARK: - transform

    static func wiggle(_ r: Ruido, _ i: Int, _ f: Float, _ f2: Float) -> Float {
        let t = r.t * f2
        var s: Float = 0
        for k in 0..<12 { s += r.fbm(i, (k * 30) + i, t) }
        return Float(jInt(((s - 6) / 6) * f)) / f
    }

    static func transformacao(_ c: Controles, _ r: Ruido, _ w: Int, _ h: Int) -> Transformacao {
        let ts = Float(c.transformSpeed * c.speed * 0.1)
        let st = Float(c.wiggleSteps)
        let amt = c.amount / 100
        let pw = (c.positionWiggle / 100) * amt
        let px = c.position?[0] ?? Double(w) / 2
        let fx = fixo(px)
        let py = c.position?[1] ?? Double(h) / 2
        let fy = fixo(py)
        let wd = Double(w), hd = Double(h)
        let dxw = Double(wiggle(r, 3338, st, ts)) * pw * wd
        let dyw = Double(wiggle(r, 8333, st, ts)) * pw * hd
        let tx0 = -((Double(-fx) * 1.52587890625e-5 + dxw) + wd * 0.5)
        let ty0 = -((Double(-fy) * 1.52587890625e-5 + dyw) + 0.5 * hd)
        let cw = ((c.cropWiggle / 100) * wd) * amt
        let l0 = pixelDoCrop(c.cropTopLeft?[0] ?? 0) + jInt(Double(wiggle(r, 1987, st, ts)) * cw)
        let t0 = pixelDoCrop(c.cropTopLeft?[1] ?? 0) + jInt(Double(wiggle(r, 3987, st, ts)) * cw)
        let r0 = pixelDoCrop(c.cropBottomRight?[0] ?? wd) + jInt(Double(wiggle(r, 5987, st, ts)) * cw)
        let b0 = pixelDoCrop(c.cropBottomRight?[1] ?? hd) + jInt(Double(wiggle(r, 7987, st, ts)) * cw)
        let s = ((c.scaleWiggle / 100) * amt) * Double(wiggle(r, -551, st, ts)) + c.scale / 100
        let sm1 = s - 1
        return Transformacao(s: s, tx: tx0 - (wd * 0.5) * sm1, ty: ty0 - sm1 * (0.5 * hd),
                             l: min(l0, r0), t: min(t0, b0), r: max(l0, r0), b: max(t0, b0))
    }

    static func subpixel(_ src: Buf, _ w: Int, _ h: Int, _ j: Int64, _ j2: Int64, _ dst: Buf, _ i3: Int) {
        let x0 = j >> 16, y0 = j2 >> 16
        var w10 = Float(j & 0xFFFF) / 65536
        var w01 = Float(j2 & 0xFFFF) / 65536
        let w11 = w10 * w01
        w10 -= w11
        w01 -= w11
        let w00 = ((1 - w10) - w01) - w11
        let inX0 = x0 >= 0 && x0 < Int64(w)
        let inX1 = x0 + 1 >= 0 && x0 + 1 < Int64(w)
        let inY0 = y0 >= 0 && y0 < Int64(h)
        let inY1 = y0 + 1 >= 0 && y0 + 1 < Int64(h)
        let W = Int64(w)
        let i00 = inX0 && inY0 ? Int((W * y0 + x0) * 4) : -1
        let i10 = inX1 && inY0 ? Int((y0 * W + x0 + 1) * 4) : -1
        let i01 = inX0 && inY1 ? Int((W * (y0 + 1) + x0) * 4) : -1
        let i11 = inX1 && inY1 ? Int(((y0 + 1) * W + x0 + 1) * 4) : -1
        let a00 = i00 < 0 ? 0 : src.u(i00)
        let a10 = i10 < 0 ? 0 : src.u(i10)
        let a01 = i01 < 0 ? 0 : src.u(i01)
        let a11 = i11 < 0 ? 0 : src.u(i11)
        let igual = a10 == a00 && a01 == a00 && a11 == a00 && a00 > 0
        let fa00 = Float(a00) * w00, fa10 = Float(a10) * w10, fa01 = Float(a01) * w01, fa11 = Float(a11) * w11
        let soma = (fa01 + fa11) + (fa00 + fa10)
        dst.p[i3] = b8(clampI(jInt(soma + 0.5), 0, 255))
        for k in 1..<4 {
            let c00 = Float(i00 < 0 ? 0 : src.u(i00 + k))
            let c10 = Float(i10 < 0 ? 0 : src.u(i10 + k))
            let c01 = Float(i01 < 0 ? 0 : src.u(i01 + k))
            let c11 = Float(i11 < 0 ? 0 : src.u(i11 + k))
            var v: Float
            if igual {
                v = (w11 * c11 + w01 * c01) + (c10 * w10 + c00 * w00)
            } else {
                v = (fa11 * c11 + fa01 * c01) + (c10 * fa10 + fa00 * c00)
                v *= 1 / soma
            }
            let iv = soma > 0 && abs(v) <= Float.greatestFiniteMagnitude ? jInt(v + 0.5) : 0
            dst.p[i3 + k] = b8(clampI(iv, 0, 255))
        }
    }

    static func amostrar(_ src: [UInt8], _ w: Int, _ h: Int, _ s: Double, _ tx: Double, _ ty: Double) -> [UInt8] {
        let dst = Buf(zeros: src.count)
        guard s != 0, s.isFinite, tx.isFinite, ty.isFinite else { return dst.array }
        let fonte = Buf(src)
        if s == 1 && tx == tx.rounded(.down) && ty == ty.rounded(.down) {
            let jp = jLong(min(max(tx, -1e9), 1e9)), jp2 = jLong(min(max(ty, -1e9), 1e9))
            for y in 0..<h {
                let sy = Int64(y) - jp2
                guard sy >= 0 && sy < Int64(h) else { continue }
                for x in 0..<w {
                    let sx = Int64(x) - jp
                    guard sx >= 0 && sx < Int64(w) else { continue }
                    let o = Int((Int64(w) * sy + sx) * 4), d = e(y, w, x, 4)
                    dst.p[d] = fonte.p[o]; dst.p[d + 1] = fonte.p[o + 1]
                    dst.p[d + 2] = fonte.p[o + 2]; dst.p[d + 3] = fonte.p[o + 3]
                }
            }
            return dst.array
        }
        porFaixas(h, w) { a, z in
            for y in a..<z {
                let jy = jLong(((((Double(y) + 0.5) - ty) / s - 0.5) * 65536 + 0.5).rounded(.down))
                for x in 0..<w {
                    let jx = jLong(((((Double(x) + 0.5) - tx) / s - 0.5) * 65536 + 0.5).rounded(.down))
                    subpixel(fonte, w, h, jx, jy, dst, e(y, w, x, 4))
                }
            }
        }
        return dst.array
    }

    static func transform(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        let t = transformacao(c, r, w, h)
        let z = c.transferMode == 1 || c.transferMode == 4
        if t.s == 1 && t.tx == 0 && t.ty == 0 && t.l == 0 && t.t == 0 && t.r == w && t.b == h && z && c.opacity >= 100 {
            return src
        }
        var am = amostrar(src, w, h, t.s, t.tx, t.ty)
        let l = max(t.l, 0), rr = max(min(t.r, w), 0), tt = max(t.t, 0), bb = max(min(t.b, h), 0)
        for y in 0..<h {
            for x in 0..<w where x < l || x >= rr || y < tt || y >= bb {
                let i = e(y, w, x, 4)
                am[i] = 0; am[i + 1] = 0; am[i + 2] = 0; am[i + 3] = 0
            }
        }
        var m = misturar([UInt8](repeating: 0, count: src.count), am, w, h, c.transferMode, c.opacity)
        if !z, tt < bb {
            for y in tt..<bb {
                for x in l..<max(l, rr) {
                    let i = e(y, w, x, 4)
                    if m[i] == 0 { m[i + 1] = 255; m[i + 2] = 255; m[i + 3] = 255 }
                }
            }
        }
        return m
    }

    // MARK: - transition

    static func transition(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        let comp = c.completion / 100
        let soft = (c.softness / 100) * 255
        let canal: Int
        switch c.transitionChannel {
        case 1: canal = 6
        case 2: canal = 7
        case 3: canal = 8
        case 4: canal = 9
        case 6: canal = 1
        case 8: canal = 3
        case 9: canal = 4
        default: canal = 2
        }
        let fonte = Buf(src)
        let out = Buf(src)
        porFaixas(h, w) { a, z in
            for y in a..<z {
                for x in 0..<w {
                    let i = e(y, w, x, 4)
                    let v = c.transitionChannel == 11 ? jInt(r.amostra(x, y, 255, 1)) : valorDoCanal(fonte, i, canal)
                    var k = cvttsd2si((((Double(v) - (soft + 255) * comp) * 255) / soft) + 255)
                    if k <= 0 { k = 0 } else if k >= 255 { k = 255 }
                    out.p[i] = b8(k)
                }
            }
        }
        return out.array
    }

    // MARK: - channel

    static func deslocamentoDoSplit(_ c: Controles, _ r: Ruido) -> (Int, Int) {
        let amt = c.amount / 100
        let t = r.t * Float(c.splitSpeed * 0.4)
        let f1 = Double(r.fbm(1234, 5678, t))
        let f2 = Double(r.fbm(5678, 1234, t))
        let ex = 1 - exp((c.splitSpeed * 0.4) * -1)
        return (jInt(c.splitH * (1 - (((f1 - 0.5) * 2) * ex)) * amt),
                jInt(c.splitV * (1 - (ex * ((f2 - 0.5) * 2))) * amt))
    }

    static func channelSplit(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        let (dx, dy) = deslocamentoDoSplit(c, r)
        let fonte = Buf(src)
        let out = Buf(src)
        let canal = c.splitChannel
        porFaixas(h, w) { a, z in
            for y in a..<z {
                for x in 0..<w {
                    let sx = x + dx, sy = y + dy
                    guard c.repeatEdge || (sx >= 0 && sx < w && sy >= 0 && sy < h) else { continue }
                    let ir = clampI(sx, 0, w - 1), ir2 = clampI(sy, 0, h - 1)
                    let ie = e(y, w, x, 4), ie2 = e(ir2, w, ir, 4)
                    switch canal {
                    case 2: out.p[ie + 2] = fonte.p[ie2 + 2]
                    case 3: out.p[ie + 3] = fonte.p[ie2 + 3]
                    case 5, 6, 7:
                        var d = yccDe(fb(fonte.u(ie + 1)), fb(fonte.u(ie + 2)), fb(fonte.u(ie + 3)))
                        let o = yccDe(fb(fonte.u(ie2 + 1)), fb(fonte.u(ie2 + 2)), fb(fonte.u(ie2 + 3)))
                        d[canal - 5] = o[canal - 5]
                        let rgb = rgbDeYcc(d[0], d[1], d[2])
                        out.p[ie + 1] = b8(rgb[0]); out.p[ie + 2] = b8(rgb[1]); out.p[ie + 3] = b8(rgb[2])
                    case 9, 10, 11:
                        var d = hsvDe(fb(fonte.u(ie + 1)), fb(fonte.u(ie + 2)), fb(fonte.u(ie + 3)))
                        let o = hsvDe(fb(fonte.u(ie2 + 1)), fb(fonte.u(ie2 + 2)), fb(fonte.u(ie2 + 3)))
                        d[canal - 9] = o[canal - 9]
                        let rgb = rgbDeHsv(d[0], d[1], d[2])
                        out.p[ie + 1] = b8(rgb[0]); out.p[ie + 2] = b8(rgb[1]); out.p[ie + 3] = b8(rgb[2])
                    default: out.p[ie + 1] = fonte.p[ie2 + 1]
                    }
                }
            }
        }
        return out.array
    }

    static func ruidoDoScale(_ c: Controles, _ r: Ruido) -> Float {
        var q = c.quantization
        if q >= 64 { q = 512 }
        let f = Float(q)
        var v = r.fbm(13, 13, r.t * Float(c.scaleSpeed))
        if c.sigmoid { v = Float(tanh((Double(v) - 0.5) * 4)) }
        return Float(jInt(v * f)) / f
    }

    static func channelScale(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        let amt = c.amount / 100
        let dr = 1 - (((Double(ruidoDoScale(c, r)) - 0.5) * 2) * (1 - exp(c.scaleSpeed * -3)))
        let vert = c.scaleVertical
        let len = vert ? h : w
        let off = jInt((c.scaleOffset * Double(len)) / 100)
        let sa = jInt(c.scaleAmount * amt * dr)
        let linhas = vert ? w : h
        let fonte = Buf(src)
        let out = Buf(zeros: src.count)
        if c.fillGaps {
            scaleComFill(fonte, out, w, linhas, len, vert, off, sa, c.scaleChannel)
            return out.array
        }
        porFaixas(linhas, len) { a, z in
            var maior = [Int](repeating: -1, count: len)
            for l in a..<z {
                for k in 0..<len { maior[k] = -1 }
                for k in 0..<len {
                    let ie = vert ? e(k, w, l, 4) : e(l, w, k, 4)
                    let v = valorDoCanal(fonte, ie, c.scaleChannel)
                    let d = (((k - off) * (255 - ((sa * v) / 100))) / 255) + off
                    if d >= 0 && d < len && v >= maior[d] {
                        maior[d] = v
                        let ie2 = vert ? e(d, w, l, 4) : e(l, w, d, 4)
                        out.p[ie2] = fonte.p[ie]; out.p[ie2 + 1] = fonte.p[ie + 1]
                        out.p[ie2 + 2] = fonte.p[ie + 2]; out.p[ie2 + 3] = fonte.p[ie + 3]
                    }
                }
            }
        }
        return out.array
    }

    static func scaleComFill(_ fonte: Buf, _ out: Buf, _ w: Int, _ linhas: Int, _ len: Int, _ vert: Bool,
                             _ off: Int, _ sa: Int, _ canal: Int) {
        let zero = valorDoCanal(0, 0, 0, 0, canal)
        porFaixas(linhas, len) { a, z in
            var marca = [Int](repeating: zero, count: len)
            for l in a..<z {
                for k in 0..<len { marca[k] = zero }
                var anterior = 0
                var ultimo = 0
                for k in 0..<len {
                    let ie = vert ? e(k, w, l, 4) : e(l, w, k, 4)
                    let v = valorDoCanal(fonte, ie, canal)
                    let d = (((255 - ((sa * v) / 100)) * (k - off)) / 255) + off
                    if d >= 0 && d < len {
                        if marca[d] <= v {
                            let o = vert ? e(d, w, l, 4) : e(l, w, d, 4)
                            for q in 0..<4 { out.p[o + q] = fonte.p[ie + q] }
                            marca[d] = v
                            var de = d < ultimo ? d : ultimo + 1
                            if d >= ultimo { ultimo = d }
                            if de < ultimo {
                                let i16 = (vert ? ((k - 1) * w) + l : ((l * w) + k) - 1) * 4
                                let tem = k >= 1 && fonte.p[i16] != 0
                                while de < ultimo {
                                    let o2 = vert ? e(de, w, l, 4) : e(l, w, de, 4)
                                    for q in 0..<4 { out.p[o2 + q] = tem ? fonte.p[i16 + q] : 0 }
                                    marca[de] = tem ? anterior : zero
                                    de += 1
                                }
                            }
                        }
                        ultimo = d
                    }
                    anterior = v
                }
            }
        }
    }

    // MARK: - color

    static func colorGlitch(_ src: [UInt8], _ c: Controles, _ r: Ruido) -> [UInt8] {
        let amt = ((c.amount * (c.colorAmount / 100)) / 100) * ((Double(r.fbm(50, 50, r.t)) * 0.2) + 0.8)
        let off = jInt(c.colorOffset * 80)
        var a = src
        let n = a.count
        if off >= 0 && n - off > 0 {
            a.withUnsafeMutableBufferPointer { p in
                for i in 0..<(n - off) {
                    let s = Int(Int8(bitPattern: p[i]))
                    let d = Int(Int8(bitPattern: p[i + off]))
                    p[i + off] = b8(d + jInt(Double(s) * amt))
                }
            }
        }
        return a
    }

    // MARK: - image

    static func streakLinha(_ a: inout [UInt32], _ d: Double) {
        let n = a.count
        var i2 = 0
        while i2 < n {
            var i3 = i2
            var i = i3 + 1
            while i < n {
                let p = a[i3], q = a[i]
                if (p >> 24) < 1 || (q >> 24) < 1 || Double(abs(luma(p) - luma(q))) > d { break }
                i3 = i
                i = i3 + 1
            }
            sortMsvc(&a, i2, i3, i3 - i2)
            i2 = i
        }
    }

    static func pixelStreak(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        let amt = Double(Float((c.amount * ((c.streak * 40) / 100)) / 100))
        if 0 >= amt { return src }
        var out = src
        let vert = c.verticalSort
        let len = vert ? h : w
        let linhas = vert ? w : h
        var linha = [UInt32](repeating: 0, count: len)
        for l in 0..<linhas {
            if c.useNoise {
                let v = vert ? r.fbm(l, 1, r.t) : r.fbm(1, l, r.t)
                if jInt(v * 100) < c.noiseCutoff { continue }
            }
            for k in 0..<len {
                let i = vert ? e(k, w, l, 4) : e(l, w, k, 4)
                linha[k] = (UInt32(src[i + 1]) << 16) | (UInt32(src[i]) << 24) | (UInt32(src[i + 2]) << 8) | UInt32(src[i + 3])
            }
            streakLinha(&linha, amt)
            for k in 0..<len {
                let i = vert ? e(k, w, l, 4) : e(l, w, k, 4)
                let v = linha[k]
                out[i] = UInt8(truncatingIfNeeded: v >> 24)
                out[i + 1] = UInt8(truncatingIfNeeded: v >> 16)
                out[i + 2] = UInt8(truncatingIfNeeded: v >> 8)
                out[i + 3] = UInt8(truncatingIfNeeded: v)
            }
        }
        return out
    }

    static func glitchBlock(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles, _ r: Ruido) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: src.count)
        let amount = (c.amount * c.blockAmount) / 100
        if amount == 0 { return out }
        let dd = amount / 100
        let lim = (1 - (dd * dd)) * 100
        let wd = Double(w), hd = Double(h)
        let bw = jInt(wd > c.blockWidth ? c.blockWidth : wd)
        let bh = jInt(hd > c.blockHeight ? c.blockHeight : hd)
        guard bw > 0 && bh > 0 else { return out }
        let nx = jInt((wd / Double(bw)).rounded(.up))
        let ny = jInt((hd / Double(bh)).rounded(.up))
        let vel = Float(c.blockSpeed / 25)
        for k in 0..<(nx * ny) {
            let by = k / nx
            let x0 = (k % nx) * bw
            let y0 = by * bh
            let am = Double(r.amostra(jInt(Double(x0) * c.grouping), jInt(Double(y0) * c.grouping), 100, vel))
            guard lim <= am else { continue }
            let sx: Int
            if c.blockDirection == 1 || c.blockDirection == 3 {
                sx = (((k - 3) + (jInt(am / 5) % 6)) % nx) * bw
            } else { sx = x0 }
            let sy: Int
            if c.blockDirection == 2 || c.blockDirection == 3 {
                sy = ((by - 3) + (jInt((am / 5) + 4) % 6)) * bh
            } else { sy = y0 }
            let a15 = bw + sx >= w ? w - sx : bw
            let a16 = bh + sy >= h ? h - sy : bh
            let a17 = bw + x0 >= w ? w - x0 : bw
            let a19 = bh + y0 >= h ? h - y0 : bh
            let mw = min(a17, a15), mh = min(a19, a16)
            guard mw >= 0 && mh >= 0 else { continue }
            for yy in 0..<mh {
                let ry = sy + yy
                for xx in 0..<mw {
                    let rx = sx + xx
                    let o = (((y0 + yy) * w) + x0 + xx) * 4
                    if rx < 0 || rx >= w || ry < 0 || ry >= h {
                        out[o] = 0; out[o + 1] = 0; out[o + 2] = 0; out[o + 3] = 0
                    } else {
                        let s = e(ry, w, rx, 4)
                        out[o] = src[s]; out[o + 1] = src[s + 1]; out[o + 2] = src[s + 2]; out[o + 3] = src[s + 3]
                    }
                }
            }
        }
        return out
    }

    // MARK: - compression

    static func blocoDct(_ a: [Double], _ d: Double, _ saida: inout [Double], _ q: inout [Double]) {
        for i in 0..<8 {
            for i2 in 0..<8 {
                var s = 0.0
                for i3 in 0..<8 {
                    let c3 = cosIda[(i2 * 8) + i3]
                    for i4 in 0..<8 { s = (a[(i4 * 8) + i3] * c3) * cosIda[(i * 8) + i4] + s }
                }
                let d4 = (((i == 0 ? raiz12 : 1.0) * (i2 == 0 ? raiz12 : 1.0)) * 0.25) * s
                let k = (i * 8) + i2
                let d5 = quant[k] * d
                q[k] = d5 * Double(cvttsd2si(d4 / d5))
            }
        }
        for i6 in 0..<8 {
            for i7 in 0..<8 {
                var s = 0.0
                for i8 in 0..<8 {
                    let d7 = cosVolta[(i6 * 8) + i8]
                    let d8 = i8 == 0 ? raiz12 : 1.0
                    for i9 in 0..<8 {
                        s = (d8 * (i9 == 0 ? raiz12 : 1.0)) * ((cosVolta[(i7 * 8) + i9] * q[(i8 * 8) + i9]) * d7) + s
                    }
                }
                saida[(i6 * 8) + i7] = s * 0.25
            }
        }
    }

    static func compressionDct(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles) -> [UInt8] {
        let amount = 100 - ((c.amount * ((c.compressionMultiplier * c.jpegAmount) / 100)) / 100)
        if 0 > amount || amount >= 100 { return src }
        let d2 = 50 > amount ? 300 / (amount + 16) : 9.1 - (amount * 0.091)
        let n = w * h
        var Y = [Int](repeating: 0, count: n), Cb = Y, Cr = Y
        for i in 0..<n {
            let r = Double(src[i * 4 + 1]), g = Double(src[i * 4 + 2]), b = Double(src[i * 4 + 3])
            Y[i] = byteDoPlugin((0.114 * b) + (0.299 * r) + (0.587 * g))
            Cb[i] = byteDoPlugin((b * 0.5) + ((128 - (0.16874 * r)) - (0.33126 * g)))
            Cr[i] = byteDoPlugin((((r * 0.5) + 128) - (0.41869 * g)) - (b * 0.08131))
        }
        var bloco = [Double](repeating: 0, count: 64), saida = bloco, qq = bloco
        for by in 0..<(h / 8) {
            for bx in 0..<(w / 8) {
                let x0 = bx * 8, y0 = by * 8
                let iU = (y0 + 8 >= h || x0 + 8 >= w) ? 0 : Int(src[e(y0 + 8, w, x0 + 8, 4)])
                if src[e(y0, w, x0, 4)] == 0 && iU == 0 { continue }
                for yy in 0..<8 { for xx in 0..<8 { bloco[(yy * 8) + xx] = Double(Y[((y0 + yy) * w) + x0 + xx]) - 128 } }
                blocoDct(bloco, d2, &saida, &qq)
                for yy in 0..<8 { for xx in 0..<8 { Y[((y0 + yy) * w) + x0 + xx] = byteDoPlugin(saida[(yy * 8) + xx] + 128) } }
            }
        }
        var out = src
        for i in 0..<n {
            let d4 = Double(Y[i]), d5 = Double(Cb[i] - 128), d6 = Double(Cr[i] - 128)
            out[i * 4 + 1] = b8(byteDoPlugin((1.402 * d6) + d4))
            out[i * 4 + 2] = b8(byteDoPlugin((d4 - (0.34414 * d5)) - (d6 * 0.71414)))
            out[i * 4 + 3] = b8(byteDoPlugin((d5 * 1.772) + d4))
        }
        return out
    }

    static func compressionDither(_ src: [UInt8], _ w: Int, _ h: Int, _ c: Controles) -> [UInt8] {
        let amount = jInt((c.amount * ((c.compressionMultiplier * c.ditherAmount) / 100)) / 100)
        if amount <= 0 { return src }
        var a = src
        let n = w * h
        let i5 = amount & 255
        let derrama = (w * 4) % 64 == 0
        var err = [0, 0, 0]
        func soma(_ px: Int, _ peso: Int) {
            guard px >= 0 && px < n else { return }
            for k in 0..<3 {
                let i = (px * 4) + 1 + k
                a[i] = b8(min(255, Int(a[i]) + ((err[k] * peso) >> 4)))
            }
        }
        for y in 0..<h {
            for x in 0..<w {
                let p = (y * w) + x
                for k in 0..<3 {
                    let i = (p * 4) + 1 + k
                    let u = Int(a[i])
                    let v = (((u / amount) & 255) * i5) & 255
                    a[i] = b8(v)
                    err[k] = (u - v) & 255
                }
                if x + 1 < w || derrama { soma(p + 1, 7) }
                if y < h - 1 {
                    if x > 0 { soma((p + w) - 1, 3) }
                    soma(p + w, 5)
                    if x < w - 1 { soma(p + w + 1, 1) }
                }
            }
        }
        return a
    }

    // MARK: - mistura (Transfer Mode)

    static func misturar(_ base: [UInt8], _ top: [UInt8], _ w: Int, _ h: Int, _ modo: Int, _ opacidade: Double) -> [UInt8] {
        let o8 = op8(opacidade)
        let i4 = (o8 * 128) + (o8 >> 1)
        let x = xferDoMenu(modo)
        let B = Buf(base), T = Buf(top), O = Buf(base)
        if x == 0 {
            porFaixas(h, w) { a, z in
                for i in (a * w * 4)..<(z * w * 4) {
                    let u = B.u(i)
                    O.p[i] = b8(u + ctrunc(((T.u(i) - u) * i4) + 16384, 32768))
                }
            }
            return O.array
        }
        let zz = x == 2 || x == 7 || x == 38
        porFaixas(h, w) { a, z in
            for y in a..<z {
                for xx in 0..<w {
                    misturaPixel(e(y, w, xx, 4), T, B, O, zz, x, i4, o8, w, xx, y)
                }
            }
        }
        gruposMistos(B, T, O, w, h, x)
        return O.array
    }

    @inline(__always)
    static func misturaPixel(_ ie: Int, _ top: Buf, _ base: Buf, _ out: Buf, _ z: Bool, _ x: Int, _ i9: Int, _ o8: Int,
                             _ w: Int, _ px: Int, _ py: Int) {
        let aT = top.u(ie)
        if aT == 0 { return }
        let aB = base.u(ie)
        if aB == 0 && z {
            for k in 1..<4 {
                var v = top.u(ie + k)
                if x == 7 { v = ctrunc(((v - 128) * i9) + 16384, 32768) + 128 }
                out.p[ie + k] = b8(v)
            }
            out.p[ie] = b8(ctrunc((aT * i9) + 16384, 32768))
            return
        }
        if aT == 255 && (aB == 255 || x == 2) {
            if x == 2 {
                if o8 == 255 && grupoOpaco(top, w, px, py) {
                    for k in 0..<4 { out.p[ie + k] = top.p[ie + k] }
                } else {
                    for k in 0..<4 {
                        let b = base.u(ie + k)
                        out.p[ie + k] = b8(b + ctrunc(((top.u(ie + k) - b) * i9) + 16384, 32768))
                    }
                }
                return
            }
            if x == 7 {
                for k in 1..<4 {
                    let b = base.u(ie + k), t = top.u(ie + k)
                    let ov = b < 128 ? (((t * 2) * b) + 127) / 255 : 255 - ((((255 - b) * ((255 - t) * 2)) + 127) / 255)
                    out.p[ie + k] = b8(b + ((((ov - b) * i9) + 16384) >> 15))
                }
                return
            }
            if x == 38 {
                for k in 1..<4 {
                    let b = base.u(ie + k), t = top.u(ie + k)
                    var m = 255
                    if t == 0 { if b == 0 { m = 0 } } else { m = min(255, ((b * 510) + t) / (t * 2)) }
                    if o8 != 255 { m = b + ((((m - b) * i9) + 16384) >> 15) }
                    out.p[ie + k] = b8(m)
                }
                return
            }
            compor(base, top, out, ie, x, Double(i9) / 32768)
            return
        }
        if x == 2 { normalParcial(base, top, out, ie, i9) }
        else { compor(base, top, out, ie, x, Double(i9) / 32768) }
    }

    static func grupoOpaco(_ b: Buf, _ w: Int, _ x: Int, _ y: Int) -> Bool {
        let g = x & ~3
        if g + 4 > w { return b.u(e(y, w, x, 4)) == 255 }
        let i = e(y, w, g, 4)
        return b.u(i) == 255 && b.u(i + 4) == 255 && b.u(i + 8) == 255 && b.u(i + 12) == 255
    }

    static func normalParcial(_ base: Buf, _ top: Buf, _ out: Buf, _ i: Int, _ i2: Int) {
        let at = ctrunc((top.u(i) * i2) + 16384, 32768)
        let ab = base.u(i)
        if ab == 255 {
            let k4 = (at * 128) + (at >> 1)
            out.p[i] = 255
            for k in 1..<4 {
                let b = base.u(i + k)
                out.p[i + k] = b8(b + ctrunc(((top.u(i + k) - b) * k4) + 16384, 32768))
            }
            return
        }
        let inv = 255 - at
        let a = meio255(ab * inv) + at
        out.p[i] = b8(a)
        if a == 0 { return }
        for k in 1..<4 {
            out.p[i + k] = b8(min(255, tetoDe((meio255(top.u(i + k) * at) + meio255(meio255(base.u(i + k) * ab) * inv)) * 255, a)))
        }
    }

    static func gruposMistos(_ base: Buf, _ top: Buf, _ out: Buf, _ w: Int, _ h: Int, _ x: Int) {
        let i2 = (w / 4) * 4
        porFaixas(h, w) { a, z in
            for y in a..<z {
                var i8 = 0
                while i8 < w {
                    let fim = i8 < i2 ? i8 + 4 : w
                    var algum = false, todos = true
                    for k in i8..<fim {
                        let u = top.u(e(y, w, k, 4))
                        if u > 0 { algum = true }
                        if u != 255 { todos = false }
                    }
                    if i8 < i2 && algum && !todos {
                        for k in i8..<fim {
                            let ie = e(y, w, k, 4)
                            guard top.u(ie) == 0 else { continue }
                            let ab = base.u(ie)
                            if ab == 0 {
                                out.p[ie + 1] = 255; out.p[ie + 2] = 255; out.p[ie + 3] = 255
                            } else if ab < 255 && x == 2 {
                                for q in 1..<4 {
                                    out.p[ie + q] = b8(min(255, tetoDe(meio255(base.u(ie + q) * ab) * 255, ab)))
                                }
                            }
                        }
                    }
                    i8 = fim
                }
            }
        }
    }

    // MARK: - compor (modos com conta em double)

    static func lum(_ d: [Double]) -> Double { (d[2] * 0.11) + (d[1] * 0.59) + (d[0] * 0.3) }
    static func sat(_ d: [Double]) -> Double { max(d[0], max(d[1], d[2])) - min(d[0], min(d[1], d[2])) }

    static func comLum(_ d: [Double], _ l: Double) -> [Double] {
        let dA = l - ((d[2] * 0.11) + ((d[1] * 0.59) + (d[0] * 0.3)))
        var o = [d[0] + dA, d[1] + dA, d[2] + dA]
        let L = (0.11 * o[2]) + (0.59 * o[1]) + (0.3 * o[0])
        let mn = min(o[0], min(o[1], o[2]))
        let mx = max(o[0], max(o[1], o[2]))
        for k in 0..<3 {
            if mn < 0 { o[k] = (((o[k] - L) * L) / (L - mn)) + L }
            if mx > 1 { o[k] = (((1 - L) * (o[k] - L)) / (mx - L)) + L }
        }
        return o
    }

    static func comSat(_ d: [Double], _ s: Double) -> [Double] {
        let mx = max(d[0], max(d[1], d[2]))
        let mn = min(d[0], min(d[1], d[2]))
        var o = [0.0, 0.0, 0.0]
        if mx > mn { for k in 0..<3 { o[k] = ((d[k] - mn) * s) / (mx - mn) } }
        return o
    }

    /// `blend` com os casos lidos no smali (d = fundo, s = de cima).
    static func blend(_ m: Int, _ dd: [Double], _ ss: [Double]) -> [Double] {
        switch m {
        case 35: return lum(ss) > lum(dd) ? ss : dd
        case 36: return lum(ss) < lum(dd) ? ss : dd
        case 13: return comLum(comSat(ss, sat(dd)), lum(dd))
        case 14: return comLum(comSat(dd, sat(ss)), lum(dd))
        case 15: return comLum(ss, lum(dd))
        case 16: return comLum(dd, lum(ss))
        default: break
        }
        var o = [0.0, 0.0, 0.0]
        for k in 0..<3 {
            let d = dd[k]
            let s = ss[k]
            var r = s
            switch m {
            case 37: r = max(0, d - s)
            case 38: r = s > 0 ? min(1, d / s) : (d <= 0 ? 0 : 1)
            case 4, 29: r = min(1, d + s)
            case 5: r = s * d
            case 6: r = (s + d) - (s * d)
            case 7: r = d < 0.5 ? 2 * s * d : 1 - ((1 - d) * ((1 - s) * 2))
            case 8:
                let s2 = 2 * s
                if s <= 0.5 { r = d - ((1 - d) * ((1 - s2) * d)) }
                else {
                    let g = d <= 0.25 ? ((((16 * d) - 12) * d) + 4) * d : d.squareRoot()
                    r = ((g - d) * (s2 - 1)) + d
                }
            case 9: r = s <= 0.5 ? 2 * s * d : 1 - ((1 - d) * ((1 - s) * 2))
            case 10: r = min(d, s)
            case 11: r = max(d, s)
            case 12, 26: r = abs(d - s)
            case 23, 27: r = s >= 1 ? 1 : min(1, d / (1 - s))
            case 24, 28: r = s > 0 ? max(0, 1 - ((1 - d) / s)) : (d >= 1 ? 1 : 0)
            case 25: r = (d + s) - ((2 * d) * s)
            case 30: r = max(0, (d + s) - 1)
            case 31: r = min(max(((2 * s) + d) - 1, 0), 1)
            case 32:
                if s <= 0.5 { r = s <= 0 ? 0 : max(0, 1 - ((1 - d) / (2 * s))) }
                else { r = s >= 1 ? 1 : min(1, d / ((1 - s) * 2)) }
            case 33: r = s <= 0.5 ? min(d, s * 2) : max(d, (2 * s) - 1)
            case 34: r = d + s >= 1 ? 1 : 0
            default: r = s
            }
            o[k] = r
        }
        return o
    }

    static func compor(_ base: Buf, _ top: Buf, _ out: Buf, _ i: Int, _ modo: Int, _ d: Double) {
        var dU = (Double(top.u(i)) / 255) * d
        let dU2 = Double(base.u(i)) / 255
        let cs = [Double(top.u(i + 1)) / 255, Double(top.u(i + 2)) / 255, Double(top.u(i + 3)) / 255]
        let cd = [Double(base.u(i + 1)) / 255, Double(base.u(i + 2)) / 255, Double(base.u(i + 3)) / 255]
        var r = [0.0, 0.0, 0.0]
        var a: Double
        switch modo {
        case 1:
            let inv = 1 - dU2
            a = (dU * inv) + dU2
            for k in 0..<3 { r[k] = ((cs[k] * dU) * inv) + (cd[k] * dU2) }
        case 17, 18, 19, 20:
            let l = (cs[2] * 0.114) + (cs[1] * 0.587) + (cs[0] * 0.299)
            switch modo {
            case 17: break
            case 18: dU *= l
            case 19: dU = 1 - dU
            default: dU = 1 - (l * dU)
            }
            a = dU2 * dU
            for k in 0..<3 { r[k] = cd[k] * a }
        case 21:
            a = min(1, dU2 + dU)
            for k in 0..<3 { r[k] = min(1, (cs[k] * dU) + (cd[k] * dU2)) }
        case 22:
            a = min(1, dU2 + dU)
            for k in 0..<3 { r[k] = (cs[k] * dU) + ((1 - dU) * cd[k] * dU2) }
        default:
            let d7 = dU * dU2
            a = (dU + dU2) - d7
            let b = blend(modo, cd, cs)
            for k in 0..<3 {
                r[k] = (b[k] * d7) + (((1 - dU) * (cd[k] * dU2)) + ((1 - dU2) * cs[k] * dU))
            }
        }
        out.p[i] = b8(clampI(jInt((a * 255) + 0.5), 0, 255))
        for k in 0..<3 {
            let v = a > 0 ? r[k] / a : 0
            out.p[i + 1 + k] = b8(clampI(jInt((v * 255) + 0.5), 0, 255))
        }
    }

    // MARK: - ordenacao do MSVC (std::sort), para o Pixel Streak

    @inline(__always) static func antes(_ a: UInt32, _ b: UInt32) -> Bool { luma(a) > luma(b) }

    static func sortMsvc(_ a: inout [UInt32], _ lo0: Int, _ hi0: Int, _ ideal0: Int) {
        var lo = lo0, hi = hi0, ideal = ideal0
        while true {
            let n = hi - lo
            if n <= 32 {
                if n > 1 { insercao(&a, lo, hi) }
                return
            }
            if ideal <= 0 { heap(&a, lo, hi); return }
            let (pf, pl) = particao(&a, lo, hi)
            let m = ideal / 2
            ideal = m + (m / 2)
            if pf - lo < hi - pl {
                sortMsvc(&a, lo, pf, ideal)
                lo = pl
            } else {
                sortMsvc(&a, pl, hi, ideal)
                hi = pf
            }
        }
    }

    static func insercao(_ a: inout [UInt32], _ lo: Int, _ hi: Int) {
        guard lo + 1 < hi else { return }
        for i in (lo + 1)..<hi {
            let v = a[i]
            if antes(v, a[lo]) {
                var k = i
                while k > lo { a[k] = a[k - 1]; k -= 1 }
                a[lo] = v
            } else {
                var k = i
                while antes(v, a[k - 1]) { a[k] = a[k - 1]; k -= 1 }
                a[k] = v
            }
        }
    }

    static func ajustaHeap(_ a: inout [UInt32], _ off: Int, _ hole0: Int, _ bottom: Int, _ v: UInt32) {
        let top = hole0
        var hole = hole0
        var idx = (hole * 2) + 2
        while idx < bottom {
            if antes(a[off + idx], a[off + idx - 1]) { idx -= 1 }
            a[off + hole] = a[off + idx]
            hole = idx
            idx = (idx * 2) + 2
        }
        if idx == bottom {
            a[off + hole] = a[off + bottom - 1]
            hole = bottom - 1
        }
        var pai = (hole - 1) / 2
        while top < hole {
            if !antes(a[off + pai], v) { break }
            a[off + hole] = a[off + pai]
            hole = pai
            pai = (pai - 1) / 2
        }
        a[off + hole] = v
    }

    static func heap(_ a: inout [UInt32], _ lo: Int, _ hi: Int) {
        let n = hi - lo
        if n > 1 {
            var i = n / 2
            while i > 0 {
                i -= 1
                ajustaHeap(&a, lo, i, n, a[lo + i])
            }
        }
        var fim = hi
        while fim - lo > 1 {
            let k = fim - 1
            let v = a[k]
            a[k] = a[lo]
            ajustaHeap(&a, lo, 0, k - lo, v)
            fim -= 1
        }
    }

    static func med3(_ a: inout [UInt32], _ f: Int, _ m: Int, _ l: Int) {
        if antes(a[m], a[f]) { a.swapAt(m, f) }
        if antes(a[l], a[m]) {
            a.swapAt(l, m)
            if antes(a[m], a[f]) { a.swapAt(m, f) }
        }
    }

    static func mediana(_ a: inout [UInt32], _ f: Int, _ m: Int, _ l: Int) {
        let n = l - f
        if 40 >= n { med3(&a, f, m, l); return }
        let st = (n + 1) / 8
        let st2 = st * 2
        med3(&a, f, f + st, f + st2)
        med3(&a, m - st, m, m + st)
        med3(&a, l - st2, l - st, l)
        med3(&a, f + st, m, l - st)
    }

    /// _Partition_by_median_guess_unchecked do MSVC.
    static func particao(_ a: inout [UInt32], _ first: Int, _ last: Int) -> (Int, Int) {
        let mid = first + ((last - first) / 2)
        mediana(&a, first, mid, last - 1)
        var pf = mid
        var pl = pf + 1
        while first < pf && !antes(a[pf - 1], a[pf]) && !antes(a[pf], a[pf - 1]) { pf -= 1 }
        while pl < last && !antes(a[pl], a[pf]) && !antes(a[pf], a[pl]) { pl += 1 }
        var gf = pl
        var gl = pf
        while true {
            while gf < last {
                if antes(a[pf], a[gf]) {
                } else if antes(a[gf], a[pf]) {
                    break
                } else if pl != gf {
                    a.swapAt(pl, gf); pl += 1
                } else {
                    pl += 1
                }
                gf += 1
            }
            while first < gl {
                if antes(a[gl - 1], a[pf]) {
                } else if antes(a[pf], a[gl - 1]) {
                    break
                } else {
                    pf -= 1
                    if pf != gl - 1 { a.swapAt(pf, gl - 1) }
                }
                gl -= 1
            }
            if gl == first && gf == last { return (pf, pl) }
            if gl == first {
                if pl != gf { a.swapAt(pf, pl) }
                pl += 1
                a.swapAt(pf, gf)
                pf += 1
                gf += 1
            } else if gf == last {
                gl -= 1
                pf -= 1
                if gl != pf { a.swapAt(gl, pf) }
                pl -= 1
                a.swapAt(pf, pl)
            } else {
                gl -= 1
                a.swapAt(gf, gl)
                gf += 1
            }
        }
    }
}
