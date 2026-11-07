//
//  Animated.swift
//  NovaEngine
//
//  Keyframes e interpolacao. Porte direto de com.novaeditor.model.Animated e
//  com.novaeditor.model.Easing / CurvaAvancada do app Android.
//
//  A busca por keyframe e binaria: uma propriedade pode ter centenas de chaves e
//  o avaliador roda para cada camada, a cada quadro.
//

import Foundation
import simd

// MARK: - Interpolacao

public enum Easing: Codable, Sendable, Equatable {
    case linear
    case hold                                   // segura o valor ate a proxima chave
    case bezier(SIMD2<Float>, SIMD2<Float>)     // dois pontos de controle, como no AE
    case named(String)                          // ease, quadIn, bounce... (presets do Flow)

    /// Curva cubica de Bezier resolvida por Newton com queda para bisseccao.
    /// t de entrada e a fracao de tempo (0..1); a saida e a fracao de valor.
    public func apply(_ t: Float) -> Float {
        let x = min(max(t, 0), 1)
        switch self {
        case .linear:            return x
        case .hold:              return x >= 1 ? 1 : 0
        case .named(let n):      return Easing.preset(n, x)
        case .bezier(let c1, let c2):
            return Easing.cubicBezier(x, c1.x, c1.y, c2.x, c2.y)
        }
    }

    static func cubicBezier(_ x: Float, _ x1: Float, _ y1: Float,
                            _ x2: Float, _ y2: Float) -> Float {
        if abs(x1 - y1) < 1e-6 && abs(x2 - y2) < 1e-6 { return x }   // e a reta
        func bx(_ t: Float) -> Float {
            let u = 1 - t
            return 3*u*u*t*x1 + 3*u*t*t*x2 + t*t*t
        }
        func by(_ t: Float) -> Float {
            let u = 1 - t
            return 3*u*u*t*y1 + 3*u*t*t*y2 + t*t*t
        }
        func dbx(_ t: Float) -> Float {
            let u = 1 - t
            return 3*u*u*x1 + 6*u*t*(x2 - x1) + 3*t*t*(1 - x2)
        }
        // Newton: converge em 4 passos no caso tipico.
        var t = x
        for _ in 0..<8 {
            let e = bx(t) - x
            if abs(e) < 1e-5 { return by(t) }
            let d = dbx(t)
            if abs(d) < 1e-6 { break }
            t -= e / d
        }
        // Bisseccao, para curvas quase verticais onde Newton nao converge.
        var lo: Float = 0, hi: Float = 1
        t = x
        for _ in 0..<24 {
            let v = bx(t)
            if abs(v - x) < 1e-5 { break }
            if v < x { lo = t } else { hi = t }
            t = (lo + hi) * 0.5
        }
        return by(t)
    }

    /// Os presets do painel Flow do app.
    static func preset(_ name: String, _ t: Float) -> Float {
        switch name {
        case "linear":    return t
        case "ease":      return cubicBezier(t, 0.25, 0.1, 0.25, 1)
        case "easeIn":    return cubicBezier(t, 0.42, 0, 1, 1)
        case "easeOut":   return cubicBezier(t, 0, 0, 0.58, 1)
        case "easeInOut": return cubicBezier(t, 0.42, 0, 0.58, 1)
        case "quadIn":    return t*t
        case "quadOut":   return 1 - (1-t)*(1-t)
        case "quad":      return t < 0.5 ? 2*t*t : 1 - pow(-2*t + 2, 2)/2
        case "cubicIn":   return t*t*t
        case "cubicOut":  return 1 - pow(1-t, 3)
        case "cubic":     return t < 0.5 ? 4*t*t*t : 1 - pow(-2*t + 2, 3)/2
        case "quartIn":   return t*t*t*t
        case "quartOut":  return 1 - pow(1-t, 4)
        case "quintIn":   return pow(t, 5)
        case "quintOut":  return 1 - pow(1-t, 5)
        case "expoIn":    return t <= 0 ? 0 : pow(2, 10*t - 10)
        case "expoOut":   return t >= 1 ? 1 : 1 - pow(2, -10*t)
        case "circIn":    return 1 - sqrt(max(0, 1 - t*t))
        case "circOut":   return sqrt(max(0, 1 - pow(t-1, 2)))
        case "backIn":    return 2.70158*t*t*t - 1.70158*t*t
        case "backOut":   return 1 + 2.70158*pow(t-1, 3) + 1.70158*pow(t-1, 2)
        case "elastic":
            if t <= 0 { return 0 }; if t >= 1 { return 1 }
            return pow(2, -10*t) * sin((t*10 - 0.75) * (2 * .pi / 3)) + 1
        case "bounce":
            let n: Float = 7.5625, d: Float = 2.75
            var x = t
            if x < 1/d { return n*x*x }
            if x < 2/d { x -= 1.5/d; return n*x*x + 0.75 }
            if x < 2.5/d { x -= 2.25/d; return n*x*x + 0.9375 }
            x -= 2.625/d; return n*x*x + 0.984375
        default:
            return t
        }
    }
}

// MARK: - Valor interpolavel

public protocol Interpolatable: Equatable, Sendable, Codable {
    static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self
}

extension Float: Interpolatable {
    public static func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float { a + (b - a) * t }
}
extension SIMD2<Float>: Interpolatable {
    public static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self { a + (b - a) * t }
}
extension SIMD3<Float>: Interpolatable {
    public static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self { a + (b - a) * t }
}
extension SIMD4<Float>: Interpolatable {
    public static func lerp(_ a: Self, _ b: Self, _ t: Float) -> Self { a + (b - a) * t }
}

// MARK: - Keyframe

public struct Keyframe<T: Interpolatable>: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    /// Tempo em segundos, relativo ao inicio da composicao.
    public var time: Float
    public var value: T
    /// Interpolacao da SAIDA desta chave ate a proxima.
    public var easing: Easing

    public init(id: UUID = UUID(), time: Float, value: T, easing: Easing = .linear) {
        self.id = id; self.time = time; self.value = value; self.easing = easing
    }
}

// MARK: - Propriedade animada

public struct Animated<T: Interpolatable>: Codable, Sendable, Equatable {
    /// Valor quando nao ha chave nenhuma.
    public var staticValue: T
    /// Sempre ordenado por tempo. Use os metodos; nao mexa direto.
    public private(set) var keyframes: [Keyframe<T>] = []

    public var isAnimated: Bool { keyframes.count > 1 }

    public init(_ value: T) { self.staticValue = value }

    public init(_ value: T, keyframes: [Keyframe<T>]) {
        self.staticValue = value
        self.keyframes = keyframes.sorted { $0.time < $1.time }
    }

    // MARK: avaliacao

    public func value(at time: Float) -> T {
        guard !keyframes.isEmpty else { return staticValue }
        if keyframes.count == 1 { return keyframes[0].value }
        if time <= keyframes[0].time { return keyframes[0].value }
        if let last = keyframes.last, time >= last.time { return last.value }

        let i = indexBefore(time)
        let a = keyframes[i], b = keyframes[i + 1]
        let span = b.time - a.time
        guard span > 1e-6 else { return b.value }
        let raw = (time - a.time) / span
        return T.lerp(a.value, b.value, a.easing.apply(raw))
    }

    /// Ultimo keyframe com time <= t. Busca binaria.
    func indexBefore(_ t: Float) -> Int {
        var lo = 0, hi = keyframes.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if keyframes[mid].time <= t { lo = mid } else { hi = mid - 1 }
        }
        return min(lo, keyframes.count - 2)
    }

    // MARK: edicao

    @discardableResult
    public mutating func setKeyframe(time: Float, value: T,
                                     easing: Easing = .linear) -> UUID {
        if let i = keyframes.firstIndex(where: { abs($0.time - time) < 1e-4 }) {
            keyframes[i].value = value
            keyframes[i].easing = easing
            return keyframes[i].id
        }
        let k = Keyframe(time: time, value: value, easing: easing)
        let at = keyframes.firstIndex { $0.time > time } ?? keyframes.count
        keyframes.insert(k, at: at)
        return k.id
    }

    public mutating func removeKeyframe(id: UUID) {
        keyframes.removeAll { $0.id == id }
    }

    public mutating func removeKeyframe(at time: Float, tolerance: Float = 1e-4) {
        keyframes.removeAll { abs($0.time - time) < tolerance }
    }

    /// Move uma chave no tempo, mantendo a lista ordenada.
    public mutating func moveKeyframe(id: UUID, to time: Float) {
        guard let i = keyframes.firstIndex(where: { $0.id == id }) else { return }
        var k = keyframes.remove(at: i)
        k.time = time
        let at = keyframes.firstIndex { $0.time > time } ?? keyframes.count
        keyframes.insert(k, at: at)
    }

    public mutating func setEasing(id: UUID, _ e: Easing) {
        guard let i = keyframes.firstIndex(where: { $0.id == id }) else { return }
        keyframes[i].easing = e
    }

    /// Inverte as chaves no tempo, dentro do proprio intervalo.
    public mutating func reverse() {
        guard let first = keyframes.first?.time, let last = keyframes.last?.time,
              last > first else { return }
        for i in keyframes.indices {
            keyframes[i].time = first + (last - keyframes[i].time)
        }
        keyframes.sort { $0.time < $1.time }
    }

    /// Multiplica os tempos por um fator, ancorado no primeiro keyframe.
    public mutating func scaleTime(by factor: Float) {
        guard factor > 0, let first = keyframes.first?.time else { return }
        for i in keyframes.indices {
            keyframes[i].time = first + (keyframes[i].time - first) * factor
        }
    }

    public mutating func clearKeyframes(keepingValueAt time: Float? = nil) {
        if let t = time { staticValue = value(at: t) }
        keyframes.removeAll()
    }
}
