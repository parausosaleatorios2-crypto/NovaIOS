//
//  LooksContas.swift
//  NovaEngine
//
//  As contas do motor do Looks (Magic Bullet Looks) do app Android, portadas
//  de com.novaeditor.model.ContasDoLooks: cada ferramenta transforma os
//  valores dela (na ordem de FerramentasDoLooks) nos uniforms e tabelas do
//  shader correspondente (Shaders/looks_*.metal, gerados de Resources/mblooks).
//
//  As contas seguem a ordem e os tipos do original (float onde ele usa float,
//  double onde usa double): `f(x)` e o (double)(float) do Java.
//
//  Ainda nao portado: o Colorista (`csta`, 228 parametros com curvas e rodas).
//

import Foundation

enum LooksContas {

    // MARK: - utilidades

    @inline(__always) static func f(_ d: Double) -> Double { Double(Float(d)) }
    @inline(__always) static func p(_ a: [Float], _ i: Int) -> Double { i < a.count ? Double(a[i]) : 0 }
    /// fx0.A / ru5.w do Android: (a - b) * t + c
    @inline(__always) static func lerpA(_ a: Double, _ b: Double, _ t: Double, _ c: Double) -> Double { (a - b) * t + c }

    static let TX: [Double] = [0.0, 0.01, 0.025, 0.05, 0.075, 0.1, 0.125, 0.15, 0.175, 0.2, 0.225, 0.25, 0.275, 0.3, 0.325, 0.35, 0.375, 0.4, 0.425, 0.45, 0.475, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0, 2.0, 4.0]
    static let TY: [Double] = [0.0, 0.00241, 0.004875000000000001, 0.0087, 0.013049999999999999, 0.0177, 0.022625, 0.02775, 0.031325, 0.0356, 0.040275, 0.045, 0.050050000000000004, 0.0549, 0.059475, 0.06405, 0.06862499999999999, 0.0736, 0.079475, 0.08595, 0.092625, 0.1015, 0.11165000000000001, 0.1152, 0.12480000000000001, 0.1351, 0.14625, 0.1592, 0.16915, 0.171, 0.1767, 0.185, 0.37, 0.74]

    static let PADROES_DO_HAZE: [Float] = [30, 10, 50, -1, 0, 1, 50, 75, 1, 0.7, 0.5]
    static let PADROES_DA_DIFFUSION: [Float] = [30, 3, 50, 75, 0, 0, 1, 1, 1]
    static let PADROES_DO_MOTOR_DO_SPOT_EXPOSURE: [Float] = [0, 0, 0, 1, 0.5, 0.5, 100, 0, 0, 0, 1, 0]

    /// Ferramentas que trabalham no sRGB codificado ("video"); as outras, no linear.
    static let VIDEO: Set<String> = ["lenv", "csm2", "cmix", "Clar", "cosm", "crv2", "huer", "csta", "duto", "huey",
                                     "husa", "pop2", "mjo2", "lgg2", "logc", "look", "mojo", "shad", "popt", "reno",
                                     "rhsl", "sspc", "test"]

    /// O "tamanho do blur" do Looks: a tabela TX -> TY (fracao da largura).
    static func tamanhoDoBlur(_ v: Float) -> Float {
        let m = min(4.0, v)
        for i in 1..<34 {
            let d = TX[i]
            if Float(d) > m {
                let d3 = TX[i - 1]
                let t = (Double(m) - d3) / (d - d3)
                return Float(lerpA(TY[i], TY[i - 1], t, TY[i - 1]))
            }
        }
        return 0.74
    }

    // MARK: - ferramentas simples

    static func exposure(_ a: [Float]) -> Float { Float(pow(2.0, p(a, 0))) }

    struct SCurva { var e, s, lo, k, g, invS, invUmMenosS, mistura: Float; var log: Bool }
    static func sCurve(_ a: [Float], _ d: Double = 1) -> SCurva {
        let dP = p(a, 0), dP2 = p(a, 1), dP3 = p(a, 2), dP4 = p(a, 3), dP5 = p(a, 4)
        let f2 = Float(dP * 0.1)
        var fe: Float = 1
        if f2 != 0 {
            fe = Float(f2 < 0 ? 1.0 / (1.0 - 4.0 * Double(f2)) : 4.0 * Double(f2) + 1.0)
        }
        let fMin = Float(min(0.99, max(0.01, dP2)))
        let fMin2 = Float(min(0.4, dP4))
        let f3 = Float(1.0 / ((dP3 * 2.3) * Double(f2) + 1.0))
        let d4 = Double(fMin)
        return SCurva(e: fe, s: fMin, lo: fMin2,
                      k: Float(1.0 / (Double(Float(max(0.6, dP5))) - Double(fMin2))),
                      g: f3, invS: Float(1.0 / d4), invUmMenosS: Float(1.0 / (1.0 - d4)),
                      mistura: Float(d), log: p(a, 5) == 1.0)
    }

    static func faixaDoDuotone(_ d: Double) -> (Float, Float) {
        var d2 = 0.0, d3 = 1.0
        if d < 0.5 {
            d2 = d > 0 ? 1.0 - 2.0 * d : 1.0
            d3 = d > 0 ? 1.05 - (d * 2.0) * 0.050000000000000044 : 1.05
        } else if d != 0.5 {
            let d4 = d >= 1.0 ? -0.05 : (-(d - 0.5)) * 2.0 * 0.05
            d3 = d < 1.0 ? 1.0 - (d - 0.5) * 2.0 : 0.0
            d2 = d4
        }
        return (Float(d2), Float(d3))
    }

    struct Duotone { var corA: [Float]; var forcaA: Float; var corB: [Float]; var forcaB, lo, hi: Float }
    static func duotone(_ a: [Float]) -> Duotone {
        let fx = faixaDoDuotone(p(a, 8) * 0.01)
        return Duotone(corA: [Float(p(a, 0)), Float(p(a, 1)), Float(p(a, 2))], forcaA: Float(p(a, 3) * 0.01),
                       corB: [Float(p(a, 4)), Float(p(a, 5)), Float(p(a, 6))], forcaB: Float(p(a, 7) * 0.01),
                       lo: fx.0, hi: fx.1)
    }

    static func chromAb(_ a: [Float]) -> [Float] {
        func lado(_ d: Double) -> Float { max(0.001, 1.0 - Float(d) * 0.003) }
        let l1 = lado(p(a, 0)), l2 = lado(p(a, 1)), l3 = lado(p(a, 2))
        var x = l1 / (l2 * l3), y = l2 / (l1 * l3), z = l3 / (l1 * l2)
        let m = min(x, min(y, z))
        if m != 0 { x /= m; y /= m; z /= m }
        return [1 / max(1, x), 1 / max(1, y), 1 / max(1, z)]
    }

    struct ChannelMixer { var mono: Bool; var r, g, b: [Float]; var k: Float }
    static func channelMixer(_ a: [Float]) -> ChannelMixer {
        let fP = Float(p(a, 0)) * 0.01
        let fP2 = Float(p(a, 1)) * 0.01
        func linha(_ i: Int) -> [Float] {
            let x = Float(p(a, i)), y = Float(p(a, i + 1)), z = Float(p(a, i + 2))
            let f2 = ((x + y + z) - 1) / 3
            return [x, y, z].map { (($0 - f2) - $0) * fP + $0 }
        }
        if Int(p(a, 2) + 0.5) == 0 {
            return ChannelMixer(mono: false, r: linha(7), g: linha(10), b: linha(13), k: fP2)
        }
        return ChannelMixer(mono: true, r: linha(4), g: [0, 0, 0], b: [0, 0, 0], k: fP2)
    }

    struct LiftGammaGain { var f, a, invG, gain, m1: [Float] }
    static func liftGammaGain(_ a: [Float]) -> LiftGammaGain {
        var fMaxs = Float(max(0.1, p(a, 0)))
        if 0.1 > fMaxs { fMaxs = 0.1 }
        let lift = (0..<3).map { Float(p(a, $0 + 3)) - 1 }
        let f = [fMaxs, 1 / fMaxs, Float(p(a, 1)) * 0.01, Float(pow(2.0, Double(Float(p(a, 2)))))]
        let invG: [Float] = (0..<3).map { i in
            var g = Float(max(0.001, p(a, i + 6)))
            if 0.1 > g { g = 0.1 }
            return 1 / g
        }
        let gain = (0..<3).map { Float(p(a, $0 + 9)) }
        return LiftGammaGain(f: f, a: lift, invG: invG, gain: gain, m1: lift.map { 1 - $0 })
    }

    struct BleachBypass { var k: Float; var negativo: Bool; var e: Float }
    static func bleachBypass(_ a: [Float], negativo: Bool) -> BleachBypass {
        BleachBypass(k: Float(1.0 - p(a, 0) * 0.01), negativo: negativo, e: Float(pow(2.0, p(a, 1))))
    }

    static func twoStrip(_ a: [Float]) -> (r: [Float], gb: [Float]) {
        let dP = p(a, 0) * 0.01
        let e = pow(2.0, p(a, 1))
        return ([Float(e), 0, 0], [0, Float(e * dP), Float((1 - dP) * e)])
    }

    struct HueSaturation { var rot: Bool; var rotV: Float; var sat: Bool; var satV: Float; var pesos: [Float] }
    static func hueSaturation(_ a: [Float]) -> HueSaturation {
        HueSaturation(rot: p(a, 0) != 0, rotV: Float(p(a, 0)) / 360,
                      sat: a.count <= 1 || p(a, 1) != 100, satV: Float(max(0.001, p(a, 1) * 0.01)),
                      pesos: (0..<3).map { Float(p(a, $0 + 2)) })
    }

    struct Vinheta { var cx, cy, aspecto, invRaio, expoente, altas, quantidade: Float }
    static func lensVignette(_ a: [Float], _ w: Int, _ h: Int, _ d: Double = 1) -> Vinheta {
        let fP = Float(p(a, 3) * 0.01 + 0.5)
        let fP2 = Float(p(a, 4) * 0.01 + 0.5)
        let dP = p(a, 5)
        var asp = Float((dP == 0 || dP == 1) ? d : d / dP)
        if p(a, 6) == 1 { asp *= 0.5 }
        let fP3 = Float(p(a, 0)) * 0.01
        let f2 = 0.99 * fP3 + 0.01
        let fP4 = Float(p(a, 2)) * 0.01
        var fP5 = Float(p(a, 1)) * 0.01
        if 0.05 > fP3 && fP3 > 0 { fP5 *= fP3 / 0.05 }
        let d2 = Double(asp) * (fP < 0.5 ? 1.0 : 0.0) - Double(asp * fP)
        let d3 = Double(w)
        let d4 = Double(h) / d3
        let d5 = (fP2 < 0.5 ? 1.0 : 0.0) * d4 - Double(fP2) * d4
        return Vinheta(cx: Float(w) * fP, cy: Float(h) * fP2, aspecto: asp,
                       invRaio: Float(1.0 / (sqrt(d5 * d5 + d2 * d2) * d3)),
                       expoente: f2, altas: fP4, quantidade: fP5)
    }

    struct SpotExposure { var cx, cy, aspecto, invRaio, invSpread: Float; var curva: [Float]; var k: Float; var tint: [Float]; var inverte: Bool }
    static func spotExposure(_ a0: [Float], _ w: Int, _ h: Int, _ d: Double = 1) -> SpotExposure {
        var a = a0
        if a.count < 12 { a = (0..<12).map { $0 < a0.count ? a0[$0] : PADROES_DO_MOTOR_DO_SPOT_EXPOSURE[$0] } }
        let dPow = pow(2.0, p(a, 0))
        let tint = (0..<3).map { Float(p(a, $0 + 7) * dPow) }
        let d2 = Double(w)
        let fP = Float((p(a, 1) * 0.01 + 0.5) * d2)
        let d3 = Double(h)
        let fP2 = Float((p(a, 2) * 0.01 + 0.5) * d3)
        let d4 = d2 * d
        var fP3 = Float(p(a, 3) * 0.5 * sqrt(d4 * d4 + d3 * d3))
        let dP = p(a, 10)
        let d5 = (dP == 0 || dP == 1) ? d : d / dP
        var fP4 = Float(p(a, 4))
        let fP5 = Float(p(a, 5))
        if fP3 <= 0.1 { fP3 = 0.1 }
        if fP4 <= 0.01 { fP4 = 0.01 }
        let fMin = Float(min(Double(Float(max(Double(fP5), 0.001))), 0.999))
        let fm1 = fMin - 1
        return SpotExposure(cx: fP, cy: fP2, aspecto: Float(d5), invRaio: 1 / fP3,
                            invSpread: 1 > fP4 ? 1 / fP4 : 1,
                            curva: [fMin, 1 / fMin, fm1, 1 / fm1],
                            k: abs(fMin - 0.5) * 5 + 2.5, tint: tint, inverte: p(a, 11) == 1)
    }

    struct Lut { var escala, desloc, s: Float }
    static func lut(_ a: [Float], _ n: Int) -> Lut {
        let fn = Float(n)
        return Lut(escala: (fn - 1) / fn, desloc: 1 / Float(n + n), s: (a.count > 1 ? a[1] : 100) * 0.01)
    }

    // MARK: - ferramentas de espaco

    struct Pop { var positivo: Bool; var sigma, k: Float; var raio: Int; var ks, kr, inclinacao: Float }
    static func pop(_ a: [Float], _ w: Int) -> Pop? {
        let dP = a.count > 1 ? p(a, 1) : 100
        let dP2 = a.count > 2 ? p(a, 2) : 30
        let dP3 = p(a, 0) * 0.009999999776482582
        if dP3 > 0 {
            let s = tamanhoDoBlur(Float(dP * 0.01 * (dP3 * 0.015 + 0.015) * 200.0 * 0.01)) * Float(w)
            return Pop(positivo: true, sigma: s, k: Float(dP3) * 0.9, raio: 0, ks: 0, kr: 0, inclinacao: 0)
        }
        if dP3 >= 0 { return nil }
        let dF = Double(Float(f(dP * 0.01 * f((Double(w) / 1080.0) * f(5.0 - 20.0 * dP3))))) * 0.5
        let fMin = Float(1.0 <= dF ? min(100.0, dF) : 1.0)
        return Pop(positivo: false, sigma: 0, k: Float((-dP3) * 0.9700000286102295),
                   raio: Int(ceil(fMin)), ks: (4.5 / (fMin * fMin)) * -1.442695, kr: -18.033686,
                   inclinacao: Float(pow(Double(Float(dP2) * 0.01), 2.5) * 50.0))
    }

    struct Diffusion { var k: Float?; var sigma, a, hl, c, d, e: Float; var tint: [Float] }
    static func diffusion(_ a: [Float], _ w: Int) -> Diffusion {
        func q(_ i: Int) -> Double { i < a.count ? Double(a[i]) : Double(PADROES_DA_DIFFUSION[i]) }
        let dq = q(4)
        var k: Float? = nil
        var e: Float = 1
        if dq != 0 {
            k = Float(dq < 0 ? 1.0 / (1.0 - dq) : dq + 1.0)
            e = Float((-dq) < 0 ? 1.0 / (dq + 1.0) : 1.0 - dq)
        }
        let dq2 = q(1) * 0.16666666666666666
        return Diffusion(k: k, sigma: Float(w) * tamanhoDoBlur(Float(q(0) * 0.01)), a: Float(dq2),
                         hl: Float(q(3) * 0.01), c: Float(min(1.0, dq2) * (1.0 - q(2) * 0.01)),
                         d: Float(pow(2.0, q(5))), e: e, tint: [Float(q(6)), Float(q(7)), Float(q(8))])
    }

    struct Difusao { var lo, hi, c: Float; var sigmas: [Float?]; var pesos: [Float]; var ganho: Float }
    static func opticalDiffusion(_ a: [Float], _ w: Int) -> Difusao {
        let fP = Float(p(a, 0)), fP2 = Float(p(a, 1)), fP3 = Float(p(a, 2)), fP4 = Float(p(a, 3))
        let fP5 = Float(p(a, 4)), fP6 = Float(p(a, 5))
        var m2 = max(Float(p(a, 6)), 0.001)
        let m3 = max(Float(p(a, 7)), 0.001), m4 = max(Float(p(a, 8)), 0.001)
        let z = m2 == m3 && m3 == m4 && Int(p(a, 9)) != 1 && p(a, 11) != 1
        var n = 10
        switch Int(p(a, 10)) { case 0: n = 5; case 2: n = 15; case 3: n = 20; default: n = 10 }
        let fMax5 = max(fP2, 0.1)
        var f5 = 0.01 * fP
        let fMax6 = max(m2, max(m3, m4))
        let f6 = f5 / fMax6
        if !z { m2 = fMax6 }
        let f7 = f6 * m2
        if fP6 <= 0 { f5 = f7 } else if fP6 < 100 { f5 = ((fP6 - 0) / 100) * (f5 - f7) + f7 }
        var lo: Float, hi: Float, c: Float
        if fP5 > 0 {
            lo = max(0, fP5 - 50) * fP5 * 1.0e-4
            c = fP5 >= 50 ? 0 : 1 - fP5 / 50
            hi = lo + 1
        } else {
            lo = -0.01; hi = 0; c = 1
        }
        var f4: Float = 0.1
        if 100 <= fP3 {
            f4 = fP3 >= 200 ? 5 : 2 + ((fP3 - 100) / 100) * 3
        } else if fP3 > 0 {
            f4 += (fP3 / 100) * 1.9
        }
        let f9 = Float(w)
        let f10 = f9 / 1920
        var sigmas: [Float?] = [], pesos: [Float] = []
        var fPow: Float = 1
        for i3 in 0..<n {
            let i4 = i3 + 1
            let f11: Float = i4 < n ? Float(i4) / Float(n) : fPow
            if f11 != fPow { fPow = Float(pow(Double(f11), Double(f4))) }
            let fMin = min((fPow >= fPow ? fMax5 : fPow * fMax5) * f10, 0.7 * f9)
            let i5 = n - i3
            let fMin2 = min(fPow, max(0, (fPow / Float(i4)) * (i5 < n ? Float(i5) / Float(n) : fPow) * f5))
            sigmas.append(fMin >= 0.5 ? fMin : nil)
            pesos.append(fMin2)
        }
        return Difusao(lo: lo, hi: hi, c: c, sigmas: sigmas, pesos: pesos, ganho: Float(pow(2.0, Double(fP4))))
    }

    /// A elipse do Looks (Edge Softness / Haze): colunas de u e v, o "interno" e a escala.
    static func elipse(_ d: Double, _ d2: Double, _ d3: Double, _ d4: Double, _ d5: Double, _ d6: Double,
                       _ d7: Double) -> [[Float]] {
        let d8 = Double(Float(d)), d9 = Double(Float(d2)), d10 = Double(Float(d6))
        let dMax = max(2.0, Double(Float(d4)) * d10)
        let d11 = (d8 + d8) * 0.5
        let d12 = (Double(Float(d3)) + d9) * 0.5
        let d13 = (d8 - d11) * d10
        let d14 = d9 - d12
        let dMax2 = max(2.0, sqrt(d14 * d14 + d13 * d13))
        let dMax3 = max(1.0, Double(Float(d5)) * 4.0 * min(dMax, dMax2))
        let d15 = dMax3 * 0.5
        let d16 = d7 * d15
        let d17 = (dMax - d15) + d16
        let d18 = (dMax2 - d15) + d16
        let dMax4 = 1.0 / max(1.0, d17 + dMax3)
        let dMax5 = 1.0 / max(1.0, d18 + dMax3)
        let dMin = min(0.999, max(0.001, max(0.0, d17) * dMax4))
        let dMin2 = min(0.999, max(0.001, max(0.0, d18) * dMax5))
        let ang = atan2(d13, d14)
        let co = cos(ang), si = sin(ang)
        let d19 = -si
        let d20 = (-d11) * d10
        let d21 = -d12
        // c10.a(a, b, c, d) = ((a * b) + c) * d
        func c10(_ a: Double, _ b: Double, _ c: Double, _ dd: Double) -> Double { ((a * b) + c) * dd }
        return [[Float(d10 * co * dMax4), Float(d19 * dMax4), Float(c10(d21, d19, d20 * co, dMax4))],
                [Float(d10 * si * dMax5), Float(co * dMax5), Float(c10(d21, co, d20 * si, dMax5))],
                [Float(dMin), Float(dMin2)],
                [Float(1.0 / (1.0 - dMin)), Float(1.0 / (1.0 - dMin2))]]
    }

    struct Haze {
        var fim, invB, b, k, sigmaSuave, sigmaAlcance: Float
        var colunaU, colunaV, interno, escala: [Float]
        var shade, expo: Float; var reflexo: Bool; var expoDoReflexo: Float; var tint: [Float]
    }
    static func haze(_ a: [Float], _ w: Int, _ h: Int, _ d: Double = 1) -> Haze {
        func q(_ i: Int) -> Double { i < a.count ? Double(a[i]) : Double(PADROES_DO_HAZE[i]) }
        let fMax = max(0.01, Float(q(0)) * 0.01)
        let fw = Float(w)
        let f2 = 0.1 * fMax * fw
        let suave = tamanhoDoBlur(Float(f(f((q(1) * 0.14 * 0.01 + 0.01) * 2.5) * 100.0) * 0.01)) * fw
        let alcance = Float(f(f((q(2) * 0.85 * 0.01 + 0.15) * 2.5) * 100.0)) * 0.0016 * fw
        let dF = f(f(50.0 - q(6) * 0.1) * 0.01)
        let d2 = Double(w), d3 = Double(h)
        let d4 = 0.5 * d3
        let d5 = d3 * dF
        let e = elipse(f(d2 * 0.5), f(d4 - d5), f(d5 + d4), f(dF * d2), 0.20000000298023224, d, 0.5)
        return Haze(fim: fw - 1, invB: 1 / f2, b: f2, k: -1 / ((fMax * 0.5 * fw) - f2),
                    sigmaSuave: suave, sigmaAlcance: alcance,
                    colunaU: e[0], colunaV: e[1], interno: e[2], escala: e[3],
                    shade: Float(q(7) * 0.01), expo: Float(pow(2.0, q(3))), reflexo: q(5) == 1,
                    expoDoReflexo: Float(pow(2.0, q(4))), tint: [Float(q(8)), Float(q(9)), Float(q(10))])
    }

    struct PassoDaBorda { var sigma: Float; var colunaU, colunaV: [Float]; var internoX, internoY: Float; var inverte: Bool }
    static func edgeSoftness(_ a: [Float], _ w: Int, _ h: Int, _ d: Double = 1) -> [PassoDaBorda] {
        let dP = p(a, 0)
        if dP <= 0 { return [] }
        let n = max(2, Int(p(a, 1)))
        let d2 = Double(n)
        let dMin = min(1.0, dP / d2)
        let dLog = log(dP / dMin) / log(2.0)
        let d4 = Double(w)
        let dP2 = (p(a, 2) * 0.01 + 0.5) * d4
        let d6 = Double(h)
        let dP3 = (p(a, 3) * 0.01 + 0.5) * d6
        let d7 = d4 * d
        let dMax = max(1.0, (sqrt(d7 * d7 + d6 * d6) / d7) * p(a, 4) * 50.0)
        var dP4 = dMax - p(a, 5) * dMax
        let d8 = (dMax - dP4) / d2
        var out: [PassoDaBorda] = []
        for i4 in 0..<n {
            let i5 = i4 + 1
            let sigma = tamanhoDoBlur(Float(Double(Float(pow(2.0, (Double(i5) * dLog) / d2) * dMin)) * 0.01)) * Float(w)
            let d9 = dP4 + d8
            let d10 = (d9 / 100.0) * d7
            let e = elipse(dP2, dP3 - d10, dP3 + d10, (d10 / d) * p(a, 6), (d8 / d9) * 0.75, d, -1.0)
            out.append(PassoDaBorda(sigma: sigma, colunaU: e[0], colunaV: e[1], internoX: e[2][0], internoY: e[2][1],
                                    inverte: i4 != n - 1))
            dP4 = d9
        }
        return out
    }

    // MARK: - curvas do Looks (Mojo)

    static func puxar(_ d: Double, _ d2: Double, _ d3: Double, _ d4: Double, _ d5: Double, _ d6: Double) -> Double {
        if d > 0 { return pow(pow(2.0, -d), d5) * (d2 - d3) + d3 }
        if d >= 0 { return d2 }
        return pow(pow(2.0, d), d6) * (d2 - d4) + d4
    }

    static func pontos(_ d: Double, _ d2: Double, _ d3: Double, _ d4: Double, _ a: [Double]) -> [Double] {
        func prender(_ x: Double) -> Double { x < 0 ? 0 : (x > 1 ? 1 : x) }
        return [
            prender(puxar(d2, puxar(d3, puxar(d, 0.16666666666666666, 0, 0.5, 1, 0.4), 1, 0, 0.2, 0.4), 1, 0, 0.2, 1) + a[0]),
            prender(puxar(d2, puxar(d3, puxar(d, 0.3333333333333333, 0, 0.5, 0.5, 0.8), 1, 0, 0.7, 0.8), 1, 0, 0.2, 0.5) + a[1]),
            prender(puxar(d4, puxar(d2, puxar(d3, 0.5, 1, 0, 1, 0.8), 1, 0, 0.08, 0.05), 1, 0, 0.05, 0.08) + a[2]),
            prender(puxar(d4, puxar(d3, puxar(d, 0.6666666666666666, 1, 0.5, 0.5, 0.8), 1, 0, 0.7, 0.5), 1, 0, 0.5, 0.2) + a[3]),
            prender(puxar(d4, puxar(d3, puxar(d, 0.8333333333333334, 1, 0.5, 1, 0.4), 1, 0, 0.4, 0.1), 1, 0, 1, 0.2) + a[4]),
            1.0,
        ]
    }

    static func amostras(_ d: [Double]) -> [Double] {
        [d[0] * 0.5, d[0], (d[1] + d[0]) * 0.5, d[1], (d[2] + d[1]) * 0.5, d[2],
         (d[3] + d[2]) * 0.5, d[3], (d[4] + d[3]) * 0.5, d[4], (d[5] + d[4]) * 0.5, d[5]]
    }

    static func comMestre(_ d: [Double], _ m: [Double]) -> [Double] {
        var c = d
        for (i, k) in [(1, 0.16666666666666666), (3, 0.3333333333333333), (7, 0.6666666666666666), (9, 0.8333333333333334)] {
            c[i] = min(1.0, (m[i] / k) * c[i])
        }
        let d3 = min(1.0, (m[5] + m[5]) * c[5])
        c[5] = d3
        c[11] = 1
        c[0] = c[1] * 0.5
        c[2] = (c[1] + c[3]) * 0.5
        c[4] = (c[3] + d3) * 0.5
        c[6] = (d3 + c[7]) * 0.5
        c[8] = (c[7] + c[9]) * 0.5
        c[10] = (c[9] + 1) * 0.5
        return c
    }

    struct Curva { var tabela: [Float]; var fim: [Float]; var inclinacao: [Float] }
    static func curvaLooks(_ entrada: [Double]) -> Curva {
        var d2 = [Double](repeating: 0, count: 36)
        for i in 0..<36 where i < entrada.count { d2[i] = entrada[i] }
        var lista: [[Double]] = []
        for k in 0..<4 {
            let b = k * 9
            lista.append(amostras(pontos(d2[b], d2[b + 1], d2[b + 2], d2[b + 3], Array(d2[(b + 4)..<(b + 9)]))))
        }
        let mestre = lista[0]
        let ks = [comMestre(lista[1], mestre), comMestre(lista[2], mestre), comMestre(lista[3], mestre)]
        let fim: [Float] = [Float(ks[0][11]), Float(ks[1][11]), Float(ks[2][11]), 1]
        let incl: [Float] = (0..<4).map { $0 == 3 ? 1 : Float((ks[$0][11] - ks[$0][10]) / 0.08333333333333333) }
        var tab = [Float](repeating: 0, count: 4096)
        var d5 = 0.0
        for i7 in 0..<1024 {
            for ch in 0..<3 {
                let arr = ks[ch]
                var dA: Double
                if d5 < 0.5 {
                    dA = (d5 + d5) * arr[0]
                } else if d5 < 5.5 {
                    let d6 = d5 - 0.5
                    let fl = floor(d6)
                    let d7 = d6 - fl
                    let d8 = 1 - d7
                    let i10 = Int(fl) * 2
                    dA = d7 * d7 * arr[i10 + 2] + d8 * d8 * arr[i10] + (d7 + d7) * d8 * arr[i10 + 1]
                } else {
                    let d9 = d5 - 5.5
                    dA = lerpA(arr[11], arr[10], d9 + d9, arr[10])
                }
                tab[i7 * 4 + ch] = Float(dA)
            }
            d5 += 0.005865102639296188
        }
        return Curva(tabela: tab, fim: fim, inclinacao: incl)
    }

    struct Mojo {
        var expoFim, expoIncl, vinheta: [Float]
        var p8, p9: Float
        var tomSombra, tomLuz: [Float]
        var saturacao: Float
        var azul, pele, contFim, contIncl: [Float]
        var cor: Float
        var saida: [Float]
        var forca: Float
        var curvas: [Float]   // 5 linhas de 1024 RGBA
    }

    static func mojo2(_ a: [Float], _ w: Int, _ h: Int) -> Mojo {
        let v = (0..<12).map { Double(Float(p(a, $0))) }
        let dF15 = f(v[11] * 0.01)
        let d12 = v[0]
        let f5 = Float(d12 - 0) / 15
        var dF: Double
        if d12 <= 0 { dF = 1 }
        else if d12 >= 15 { dF = f(1.2000000476837158) }
        else { let d14 = Double(f5); dF = f(1.0 - ((d14 - 2.0) * (0.20000004768371582 * d14))) }
        let dF16 = f(pow(d12 / 200.0, 0.8) * 200.0 + 0.0)
        let d15 = dF16 / 50.0
        let dF17 = f(4.0 * d15 + 0.0)
        let f6 = Float(dF16 - 0) / 15
        var dF2 = 0.0
        if dF16 > 0 {
            if dF16 >= 15 { dF2 = 3 }
            else {
                let d16 = Double(f6)
                let d17 = d16 + d16
                if d17 < 1 { dF2 = f(d17 * 1.5 * d17 + 0.0) }
                else { let d18 = d17 - 1; dF2 = f(0.0 - (((d18 - 2.0) * d18) - 1.0) * 1.5) }
            }
        }
        let f7 = Float(v[2]) * 0.1 + Float(dF17) + Float(dF2)
        let d19 = v[4]
        let f8 = Float(d19) * 0.18 + f7
        let d20 = d19 / 100.0
        let dF18 = f(d20 * 0.2 + 0.0)
        let dF19 = f(1.0 - d20 * 0.09999999999999998)
        let d21 = dF16 / 300.0
        let dF20 = f(100.0 - 15.0 * d21)
        let d = v[3]
        let d2 = d > 0 ? 1.0 - d / 200.0 : (d / -100.0) * 0.75 + 1.0
        let dF21 = f(dF20 * d2)
        let d3 = v[7]
        let d4 = d3 > 0 ? (d3 / 5.0) * 0.09999999999999998 : (d3 / -5.0) * 0.4
        let dF22 = f(dF21 * (1.0 - d4))
        let d5 = v[8]
        let dPow = d5 < 0 ? d5 / -200.0 : pow(d5 / 200.0, 0.7)
        let dF23 = f((1.0 - dPow * 0.5) * dF22)
        let d22 = v[9]
        let sat = Float(f(dF23 * (1.0 - ((d22 / (d22 >= 0 ? 200.0 : -200.0)) * 0.19999999999999996)))) * Float(dF)
        let dMax = max(-1.0, Double(sat))
        let dF3 = f(1.0 - 0.3999999761581421 * d15)
        let dF4 = f(1.0 - d15 * 0.10000002384185791)
        let d23 = dF16 / 40.0
        let dF5 = f(0.3799999952316284 * d23 + 1.0)
        let dF24 = f(0.10000002384185791 * d23 + 1.0)
        let dF6 = f(1.0 - d15 * 0.5)
        let dF7 = f(1.0 - 0.07999999999999996 * d15)
        let dF8 = f(0.3999999999999999 * d23 + 1.0)
        let dF9 = f(d23 * 0.10000000000000009 + 1.0)
        let dF10 = f(1.0 - 0.32999999999999996 * d15)
        let dF11 = f(1.0 - d15 * 0.19999999999999996)
        let dF12 = f(0.29000000000000004 * d23 + 1.0)
        let dF13 = f(d23 * 0.19999999999999996 + 1.0)
        let d6 = v[1]
        var F: Float, F2: Float, F3: Float, F4: Float
        var dMin2: Double
        let d7 = dF5
        if d6 > 0 {
            let d11 = Double(Float(d6 - 0) / 100)
            dMin2 = d11 >= 0 ? min(1.0, d11) : 0
            let f9 = Float(dMin2)
            F = (Float(dF6) - Float(dF3)) * f9
            F2 = (Float(dF7) - Float(dF4)) * f9
            F3 = (Float(dF8) - Float(d7)) * f9
            F4 = Float(dF9)
        } else {
            let d8 = Double(Float(d6 - 0) / -100)
            let dMin = d8 >= 0 ? min(1.0, d8) : 0
            let f10 = Float(dMin)
            F = (Float(dF10) - Float(dF3)) * f10
            F2 = (Float(dF11) - Float(dF4)) * f10
            F3 = (Float(dF12) - Float(d7)) * f10
            F4 = Float(dF13)
            dMin2 = dMin
        }
        let f12 = Float(dF24)
        let f13 = (F4 - f12) * Float(dMin2)
        let f14 = Float(d21 * 0.4 + 0.0)
        let tomSombra: [Float] = [F + Float(dF3) + f14, F2 + Float(dF4) + f14, f14 + 1]
        let tomLuz: [Float] = [F3 + Float(d7), f13 + f12, 1]
        let d25 = dF16 / 200.0
        let dPow2 = pow(d25, 0.5)
        var dF14 = f(50.0 * dPow2 + 0.0)
        let d9 = dF14 == 100 ? dF14 : (v[5] / 100.0) * (100.0 - dF14) + dF14
        let dF25 = f(d9)
        if dF14 != 100 { dF14 = (v[6] / 100.0) * (100.0 - dF14) + dF14 }
        let dF26 = f(dF14)
        let dF27 = f(dPow2 * 100.0 + 0.0)
        var dArr3 = [Double](repeating: 0, count: 36)
        dArr3[0] = Double(f8) * 0.1
        var dArr = [Double](repeating: 0, count: 36)
        dArr[0] = 0.0 - d25 * 0.2
        let d10 = v[7]
        if d10 < 0 {
            let p3 = pow(d10 / -5.0, 1.2)
            dArr[1] = 0.0 - (p3 + p3); dArr[2] = 0.0 - p3 * 1.5; dArr[3] = 0.0 - p3
        } else {
            let p4 = pow(d10 / 5.0, 1.2)
            dArr[1] = p4 + 0.0; dArr[2] = p4 * 1.5 + 0.0; dArr[3] = p4 * 1.4 + 0.0
        }
        let d26 = dF26 / 100.0
        let f15 = Float(d26 * 0.17 + 0.0)
        let f16 = Float(v[10] * -0.0018)
        var dArr4 = [Double](repeating: 0, count: 36)
        dArr4[14] = Double(f16 + f15)
        dArr4[15] = Double(Float(1.1 - d26 * 0.10000000000000009) * f16)
        dArr4[16] = Double(f16 - f15)
        let dF28 = f(Double(Float(0.5458329916000366 - v[1] * 3.0e-4)) - 0.03)
        let f17 = Float((dF25 / 100.0) * 0.17 + 0.0)
        var dArr5 = [Double](repeating: 0, count: 36)
        dArr5[14] = Double(f17 + 0)
        dArr5[16] = Double(0 - f17)
        let c1 = curvaLooks(dArr3), c2 = curvaLooks(dArr), c3 = curvaLooks(dArr4), c4 = curvaLooks(dArr5)
        let d27 = Double(w)
        let dPow5 = 1.0 / (pow(pow((Double(h) / d27) * 0.5, 2.0) + 0.25, 0.5) * d27)
        let curvas = c2.tabela + c1.tabela + c1.tabela + c3.tabela + c4.tabela
        return Mojo(expoFim: Array(c2.fim.prefix(3)), expoIncl: Array(c2.inclinacao.prefix(3)),
                    vinheta: [0.01, 0.19999999, Float(dPow5)], p8: Float(v[8]), p9: Float(v[9]),
                    tomSombra: tomSombra, tomLuz: tomLuz, saturacao: Float(dMax),
                    azul: [Float(dF25) * 0.01, 0.5, Float(dF28)],
                    pele: [Float(dF26) * 0.01, Float(v[10]) * 0.01, 0.35, 0.069224],
                    contFim: Array(c1.fim.prefix(3)), contIncl: Array(c1.inclinacao.prefix(3)),
                    cor: Float(dF27) * 0.01, saida: [Float(dF18), Float(dF19)], forca: Float(dF15),
                    curvas: curvas)
    }

    // MARK: - HSL Colors

    static let FAIXAS_DO_DLL: [[Double]] = [[0.907, 0.963, 1.007, 1.048], [0.007, 0.048, 0.12, 0.152],
                                            [0.12, 0.152, 0.176, 0.229], [0.176, 0.229, 0.37, 0.445],
                                            [0.37, 0.445, 0.545, 0.613], [0.545, 0.613, 0.713, 0.753],
                                            [0.713, 0.753, 0.777, 0.823], [0.777, 0.823, 0.907, 0.963]]
    static let ZERO_HSL = Float(bitPattern: 813694973)

    static func vizinha(_ a: [Double], _ b0: [Double]) -> [Double] {
        let b = a[2] - b0[0] > 0.5 ? b0.map { $0 + 1 } : b0
        let d = a[2]
        let d2 = (d - a[1]) * 0.5
        let d3 = (b[2] - b[1]) * 0.5
        let dMins = min(2.200000047683716, ((d3 + d2) / (a[3] - d)) + 1.0)
        let d4 = (dMins - 1.0) * (a[3] - a[2]) * 0.5
        return [dMins, min(max(0.0, d4 - d2), d3 - d4)]
    }

    static let FAIXAS: [[Double]] = {
        var out: [[Double]] = []
        let F = FAIXAS_DO_DLL
        for i in 0..<8 {
            let a3 = F[i]
            let v1 = vizinha(F[(i + 7) % 8], a3)
            let v2 = vizinha(a3, F[(i + 1) % 8])
            let d = a3[2]
            let dd2 = (d + a3[3]) * 0.5
            let d3 = a3[0]
            let d4 = (d3 + a3[1]) * 0.5
            let d5 = (dd2 - d) * v2[0]
            let d6 = (d4 - d3) * v1[0]
            let d7 = (d4 - d6) + v1[1]
            let m1 = max(d6 + d4 + v1[1], d7 + 1e-6)
            let m2 = max((dd2 - d5) + v2[1], m1 + 1e-6)
            let m3 = max(d5 + dd2 + v2[1], 1e-6 + m2)
            out.append([d7, m1, m2, m3])
        }
        return out
    }()

    static func peso(_ d: Double, _ a: [Double]) -> Double {
        var i = 0
        var d2 = a[0]
        var d3 = 0.0
        while true {
            var d4 = d - d2
            if -0.5 > d4 { d4 += 1 } else if d4 > 0.5 { d4 -= 1 }
            if 0 > d4 { break }
            i += 1
            let d5 = a[i]
            let d6 = d4 / (d5 - d2)
            if 1 < d6 {
                d3 += 1
                if i >= 3 { break }
                d2 = d5
            } else {
                d3 += d6
                break
            }
        }
        if 0 > d3 { return 0 }
        if 1 > d3 { return d3 * d3 * (3 - (d3 + d3)) }
        if 2 > d3 { return 1 }
        if 3 <= d3 { return 0 }
        let d7 = 3 - d3
        return d7 * d7 * (3 - (d7 + d7))
    }

    static func volta(_ f: Float) -> Float {
        if f > 0.5 { return f - 1 }
        if -0.5 <= f { return f }
        return f + 1
    }

    static func vale(_ a: [Float], _ i0: Int) -> Int {
        var i = i0
        let f = a[i]
        var f2 = Float(i)
        var f3 = f
        for _ in 0..<1024 {
            let f4 = a[i]
            if Double(volta(f4 - f)) > 1.0e-6 { return Int(f2) }
            if volta(f3 - f4) > 0 { f2 = Float(i); f3 = f4 }
            i = (i + 1) & 1023
        }
        return Int(f2)
    }

    static func achatar(_ a: inout [Float], _ i: Int, _ i2: Int) {
        var f = a[i]
        let f2 = a[i2]
        if f2 > f { f += 1 }
        var f3 = (f2 + f) * 0.5
        if f3 >= 1 { f3 -= 1 }
        var i3 = i + 1024
        var i4 = i
        while i3 > i {
            let i5 = i3 & 1023
            if volta(f3 - a[i5]) > 1.0e-6 { break }
            i3 -= 1
            i4 = i5
        }
        var i6 = i2
        var i7 = i6
        while i6 < i2 + 1024 {
            let i8 = i6 & 1023
            if volta(a[i8] - f3) > 1.0e-6 { break }
            i6 += 1
            i7 = i8
        }
        if i7 < i4 { i7 += 1024 }
        if i4 > i7 { return }
        while true {
            a[i4 & 1023] = f3
            if i4 == i7 { return }
            i4 += 1
        }
    }

    static func desdobrar(_ a: inout [Float]) {
        var f = a[0]
        var i = 1
        var i2 = 0
        var i3 = 0
        while true {
            if i2 >= 1024 { i3 = 0; break }
            let f2 = a[i]
            if volta(f2 - f) > 1.0e-6 { break }
            i2 += 1
            i3 = i
            i = (i + 1) & 1023
            f = f2
        }
        var i4 = -1
        var i5 = 0
        while i5 < 12 {
            var f3 = a[i3]
            var i6 = (i3 + 1) & 1023
            var i7 = 0
            var mudou = false
            while i7 < 1024 {
                let f4 = a[i6]
                if volta(f4 - f3) * -1 <= 1.0e-6 {
                    i7 += 1
                    i3 = i6
                    i6 = (i6 + 1) & 1023
                    f3 = f4
                } else {
                    if i3 <= i4 { return }
                    let iVale = vale(a, i3)
                    achatar(&a, i3, iVale)
                    i5 += 1
                    i4 = i3
                    i3 = iVale
                    mudou = true
                    break
                }
            }
            if !mudou { return }
        }
    }

    struct HslColors { var tabela: [Float]; var matiz, saturacao, luminancia: Bool
        var vazia: Bool { !(matiz || saturacao || luminancia) } }
    static func hslColors(_ a: [Float]) -> HslColors {
        func faixa(_ ini: Int) -> [Float] {
            var out = [Float](repeating: 0, count: 8)
            for k in 0..<8 where ini + k < a.count { out[k] = a[ini + k] * 0.01 }
            return out
        }
        let h = faixa(3), s = faixa(11), l = faixa(19)
        let faixas = FAIXAS
        var desloc = [Double](repeating: 0, count: 8)
        for i in 0..<8 {
            let d3 = Double(h[i])
            var neg: Bool
            var dm: Double
            if -1.0 > d3 { neg = true; dm = -1 }
            else { dm = min(1.0, d3); neg = 0 > dm }
            let fx = faixas[i]
            desloc[i] = (neg ? ((fx[1] + fx[2]) * 0.5) - fx[0] : fx[3] - ((fx[1] + fx[2]) * 0.5)) * dm
        }
        var tab = [Float](repeating: 0, count: 4096)
        for i9 in 0..<1024 {
            let d5 = Double(i9) * 9.765625e-4
            var d6 = d5, d9 = 0.0, d8 = 0.0
            for k in 0..<8 {
                let pe = peso(d5, faixas[k])
                d6 = desloc[k] * pe + d6
                d9 += Double(s[k]) * pe
                d8 += pe * Double(l[k])
            }
            if 0 > d6 { d6 += 1 }
            if d6 >= 1 { d6 -= 1 }
            tab[i9 * 4] = Float(d6)
            tab[i9 * 4 + 1] = Float(d9)
            tab[i9 * 4 + 2] = Float(d8)
        }
        var matiz = (0..<1024).map { tab[$0 * 4] }
        desdobrar(&matiz)
        for i in 0..<1024 { tab[i * 4] = matiz[i] }
        for i in 0..<4096 where abs(tab[i]) < ZERO_HSL { tab[i] = 0 }
        return HslColors(tabela: tab, matiz: h.contains { $0 != 0 }, saturacao: s.contains { $0 != 0 },
                         luminancia: l.contains { $0 != 0 })
    }
}
