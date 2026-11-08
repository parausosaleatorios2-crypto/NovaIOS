//
//  EffectParamTextures.swift
//  NovaEngine
//
//  Parametros de efeito que viram TEXTURA no shader:
//    curve         -> tabela 256x1 (r, g, b), mestre ja aplicado antes do canal
//    lut           -> LUT 3D (.cube ou PNG em tiras 33x33x33 de Resources/looks)
//    node-grading  -> LUT 3D da gradacao (identidade por enquanto)
//
//  Do XML de curves: «A curva mora no projeto como uma lista de pontos, e
//  avaliada com interpolacao monotonica ... e sai como uma TABELA de 256
//  entradas. A ordem mestre -> canal tambem ja vem assada na tabela.»
//
//  Convencao com os shaders: as texturas destes parametros entram depois das
//  texturas declaradas no XML, na ordem dos parametros no manifesto.
//

import Foundation
import Metal
import MetalKit
import ImageIO
import simd

// MARK: - Curvas

public struct CurveSet: Codable, Sendable, Equatable {
    /// Pontos (entrada, saida) de 0 a 1, ordenados por entrada.
    public var master: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 1)]
    public var red: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 1)]
    public var green: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 1)]
    public var blue: [SIMD2<Float>] = [SIMD2(0, 0), SIMD2(1, 1)]
    public init() {}

    public var isIdentity: Bool { self == CurveSet() }

    /// Interpolacao cubica monotonica (Fritsch-Carlson): a curva nunca
    /// desobedece a ordem dos pontos nem passa do valor de um ponto ao proximo.
    public static func evaluate(_ pts: [SIMD2<Float>], _ x: Float) -> Float {
        let p = pts.sorted { $0.x < $1.x }
        guard p.count >= 2 else { return p.first?.y ?? x }
        if x <= p[0].x { return p[0].y }
        if x >= p[p.count - 1].x { return p[p.count - 1].y }
        let n = p.count
        var d = [Float](repeating: 0, count: n - 1)
        for i in 0..<(n - 1) { d[i] = (p[i + 1].y - p[i].y) / max(p[i + 1].x - p[i].x, 1e-6) }
        var m = [Float](repeating: 0, count: n)
        m[0] = d[0]; m[n - 1] = d[n - 2]
        for i in 1..<(n - 1) { m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2 }
        for i in 0..<(n - 1) where d[i] == 0 { m[i] = 0; m[i + 1] = 0 }
        for i in 0..<(n - 1) where d[i] != 0 {
            let a = m[i] / d[i], b = m[i + 1] / d[i]
            let s = a * a + b * b
            if s > 9 { let t = 3 / sqrt(s); m[i] = t * a * d[i]; m[i + 1] = t * b * d[i] }
        }
        var k = 0
        while k < n - 2 && x > p[k + 1].x { k += 1 }
        let h = p[k + 1].x - p[k].x
        let t = (x - p[k].x) / max(h, 1e-6)
        let t2 = t * t, t3 = t2 * t
        let h00 = 2 * t3 - 3 * t2 + 1, h10 = t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2, h11 = t3 - t2
        return h00 * p[k].y + h10 * h * m[k] + h01 * p[k + 1].y + h11 * h * m[k + 1]
    }

    /// Tabela RGBA8 de 256 entradas: canal(mestre(x)).
    public func table() -> [UInt8] {
        var out = [UInt8](repeating: 255, count: 256 * 4)
        for i in 0..<256 {
            let x = Float(i) / 255
            let mm = CurveSet.evaluate(master, x)
            let r = CurveSet.evaluate(red, mm), g = CurveSet.evaluate(green, mm), b = CurveSet.evaluate(blue, mm)
            out[i * 4] = UInt8(max(0, min(255, r * 255 + 0.5)))
            out[i * 4 + 1] = UInt8(max(0, min(255, g * 255 + 0.5)))
            out[i * 4 + 2] = UInt8(max(0, min(255, b * 255 + 0.5)))
        }
        return out
    }
}

// MARK: - Valores complexos no efeito aplicado

public extension AppliedEffect {
    /// Curvas por parametro (id do XML).
    var curveSets: [String: CurveSet] {
        get { curves ?? [:] }
        set { curves = newValue.isEmpty ? nil : newValue }
    }
    /// LUT escolhido por parametro: "looks/x.png" (do app) ou "projeto/x.cube" (da midia).
    var lutPaths: [String: String] {
        get { luts ?? [:] }
        set { luts = newValue.isEmpty ? nil : newValue }
    }
}

// MARK: - Texturas

public final class EffectParamTextures {
    private let device: MTLDevice
    private var cache: [String: MTLTexture] = [:]
    private let lock = NSLock()
    /// Pasta media/ do projeto, para LUTs importados ("projeto/...").
    public var mediaRoot: URL?

    public init(device: MTLDevice) { self.device = device }

    public static func isTextureParam(_ k: EffectParamKind) -> Bool {
        switch k { case .curve, .lut, .nodeGrading, .gradacao: return true; default: return false }
    }

    /// Texturas dos parametros-textura do efeito, na ordem do manifesto.
    public func textures(for fx: AppliedEffect, manifest m: EffectManifest) -> [MTLTexture] {
        var out: [MTLTexture] = []
        for p in m.params where Self.isTextureParam(p.kind) {
            switch p.kind {
            case .curve:
                if let t = try? curve(fx.curveSets[p.id] ?? CurveSet()) { out.append(t) }
            default:
                if let path = fx.lutPaths[p.id], let t = try? lut(path) { out.append(t) }
                else if let t = try? identity3D() { out.append(t) }
            }
        }
        return out
    }

    func curve(_ c: CurveSet) throws -> MTLTexture {
        let key = "curve|\(c)"
        lock.lock(); if let t = cache[key] { lock.unlock(); return t }; lock.unlock()
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 256, height: 1, mipmapped: false)
        d.usage = [.shaderRead]; d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else { throw RenderError.textureAllocFailed(width: 256, height: 1) }
        let bytes = c.table()
        t.replace(region: MTLRegionMake2D(0, 0, 256, 1), mipmapLevel: 0, withBytes: bytes, bytesPerRow: 256 * 4)
        lock.lock(); if cache.count > 64 { cache.removeAll() }; cache[key] = t; lock.unlock()
        return t
    }

    func identity3D() throws -> MTLTexture {
        if let t = cache["identity3d"] { return t }
        let n = 17
        var data = [UInt8](repeating: 255, count: n * n * n * 4)
        for b in 0..<n { for g in 0..<n { for r in 0..<n {
            let i = ((b * n + g) * n + r) * 4
            data[i] = UInt8(r * 255 / (n - 1)); data[i + 1] = UInt8(g * 255 / (n - 1)); data[i + 2] = UInt8(b * 255 / (n - 1))
        } } }
        let t = try make3D(n, data)
        cache["identity3d"] = t
        return t
    }

    func make3D(_ n: Int, _ rgba: [UInt8]) throws -> MTLTexture {
        let d = MTLTextureDescriptor()
        d.textureType = .type3D
        d.pixelFormat = .rgba8Unorm
        d.width = n; d.height = n; d.depth = n
        d.usage = [.shaderRead]; d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else { throw RenderError.textureAllocFailed(width: n, height: n) }
        t.replace(region: MTLRegionMake3D(0, 0, 0, n, n, n), mipmapLevel: 0, slice: 0,
                  withBytes: rgba, bytesPerRow: n * 4, bytesPerImage: n * n * 4)
        return t
    }

    /// Caminho do LUT: "looks/x.png" no bundle; "projeto/x.cube" na midia do projeto.
    public func url(for path: String) -> URL? {
        if path.hasPrefix("projeto/") {
            return mediaRoot?.appendingPathComponent(String(path.dropFirst("projeto/".count)))
        }
        return Bundle.main.resourceURL?.appendingPathComponent(path)
    }

    func lut(_ path: String) throws -> MTLTexture {
        let key = "lut|\(path)"
        lock.lock(); if let t = cache[key] { lock.unlock(); return t }; lock.unlock()
        guard let u = url(for: path) else { throw RenderError.missingInput(path, effect: "LUT") }
        let t: MTLTexture
        if u.pathExtension.lowercased() == "cube" {
            let (n, data) = try Self.parseCube(u)
            t = try make3D(n, data)
        } else {
            let (n, data) = try Self.parseStrip(u)
            t = try make3D(n, data)
        }
        lock.lock(); cache[key] = t; lock.unlock()
        return t
    }

    /// .cube (Adobe/Resolve): LUT_3D_SIZE N e N^3 linhas "r g b", vermelho mais rapido.
    static func parseCube(_ u: URL) throws -> (Int, [UInt8]) {
        let text = try String(contentsOf: u, encoding: .utf8)
        var n = 0
        var vals: [UInt8] = []
        var minV = SIMD3<Float>(0, 0, 0), maxV = SIMD3<Float>(1, 1, 1)
        for raw in text.split(whereSeparator: \.isNewline) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("TITLE") { continue }
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            if line.hasPrefix("LUT_3D_SIZE"), parts.count > 1 { n = Int(parts[1]) ?? 0; continue }
            if line.hasPrefix("DOMAIN_MIN"), parts.count > 3 {
                minV = SIMD3(Float(parts[1]) ?? 0, Float(parts[2]) ?? 0, Float(parts[3]) ?? 0); continue
            }
            if line.hasPrefix("DOMAIN_MAX"), parts.count > 3 {
                maxV = SIMD3(Float(parts[1]) ?? 1, Float(parts[2]) ?? 1, Float(parts[3]) ?? 1); continue
            }
            if line.first.map({ $0.isLetter }) == true { continue }
            guard parts.count >= 3, let r = Float(parts[0]), let g = Float(parts[1]), let b = Float(parts[2]) else { continue }
            let v = (SIMD3(r, g, b) - minV) / simd_max(maxV - minV, SIMD3(repeating: 1e-6))
            vals.append(UInt8(max(0, min(255, v.x * 255 + 0.5))))
            vals.append(UInt8(max(0, min(255, v.y * 255 + 0.5))))
            vals.append(UInt8(max(0, min(255, v.z * 255 + 0.5))))
            vals.append(255)
        }
        guard n >= 2, vals.count == n * n * n * 4 else {
            throw RenderError.missingInput(u.lastPathComponent, effect: "LUT .cube invalido")
        }
        return (n, vals)
    }

    /// PNG em tira: N quadros NxN lado a lado (azul por quadro, vermelho em x, verde em y).
    static func parseStrip(_ u: URL) throws -> (Int, [UInt8]) {
        guard let src = CGImageSourceCreateWithURL(u as CFURL, nil),
              let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw RenderError.missingInput(u.lastPathComponent, effect: "LUT")
        }
        let w = img.width
        let n = Int(Double(w).squareRoot().rounded())
        guard n * n == w, img.height >= n else { throw RenderError.missingInput(u.lastPathComponent, effect: "LUT") }
        var px = [UInt8](repeating: 0, count: w * n * 4)
        guard let ctx = CGContext(data: &px, width: w, height: n, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw RenderError.missingInput(u.lastPathComponent, effect: "LUT")
        }
        // as n primeiras linhas da imagem (topo)
        ctx.draw(img, in: CGRect(x: 0, y: n - img.height, width: w, height: img.height))
        var out = [UInt8](repeating: 255, count: n * n * n * 4)
        for b in 0..<n { for g in 0..<n { for r in 0..<n {
            let si = (g * w + b * n + r) * 4
            let di = ((b * n + g) * n + r) * 4
            out[di] = px[si]; out[di + 1] = px[si + 1]; out[di + 2] = px[si + 2]
        } } }
        return (n, out)
    }
}
