//
//  LayerContent.swift
//  NovaEngine
//
//  Provedor de conteudo das camadas (Docs/PENDENCIAS.md 4.1): entrega ao
//  Compositor a textura de cada camada num instante.
//
//  Do APK (com.novaeditor.model.LayerContent): os tipos de conteudo sao Media
//  (IMAGE ou VIDEO, com uri, ponto de entrada e duracao da fonte em us,
//  velocidade, mudo, ganho, invertido e em laco), Text, Solid, Shape, Audio,
//  Camera, Luz, Nulo, Group, Model3D, Midi, Osso e Adjustment.
//  «Arquivo que falta, ou que o aparelho nao abre, entra como barras coloridas.»
//

import Foundation
import Metal
import MetalKit
import AVFoundation
import CoreText
import ImageIO
#if canImport(UIKit)
import UIKit
#endif
import os

public final class MediaContentProvider: LayerContentProvider {

    /// Pasta media/ do projeto: as `mediaPath` das camadas sao relativas a ela.
    public let mediaRoot: URL
    private let device: MTLDevice
    private let log = Logger(subsystem: "com.novavision.editor", category: "LayerContent")

    private var images: [String: MTLTexture] = [:]
    private var decoders: [String: VideoDecoder] = [:]
    private var lastVideoFrame: [String: (time: Double, tex: MTLTexture)] = [:]
    private var texts: [String: MTLTexture] = [:]
    private var solids: [String: MTLTexture] = [:]
    private var shapes: [String: MTLTexture] = [:]
    private var maskCache: [String: MTLTexture] = [:]
    private var animatedText: (key: String, tex: MTLTexture)?
    private var colorBars: MTLTexture?
    private let lock = NSLock()

    public init(mediaRoot: URL, device: MTLDevice) {
        self.mediaRoot = mediaRoot
        self.device = device
    }

    public func url(for layer: Layer) -> URL? {
        guard let p = layer.mediaPath, !p.isEmpty else { return nil }
        return mediaRoot.appendingPathComponent(p)
    }

    /// Esquece o que estiver em cache (trocou o projeto ou apagou midia).
    public func purge() {
        lock.lock(); defer { lock.unlock() }
        images.removeAll(); decoders.removeAll(); lastVideoFrame.removeAll()
        texts.removeAll(); solids.removeAll(); shapes.removeAll(); maskCache.removeAll()
    }

    public func texture(for layer: Layer, at mediaTime: Float,
                        device: MTLDevice) async throws -> MTLTexture? {
        switch layer.kind {
        case .image:
            return try imageTexture(layer)
        case .video:
            return try await videoTexture(layer, at: mediaTime)
        case .text:
            return try textTexture(layer, at: mediaTime)
        case .shape:
            if layer.shapeStyle != nil { return try shapeTexture(layer, at: mediaTime) }
            return try solidTexture(layer)
        case .solid:
            return try solidTexture(layer)
        default:
            return nil
        }
    }

    // MARK: imagem

    private func imageTexture(_ layer: Layer) throws -> MTLTexture {
        guard let url = url(for: layer), FileManager.default.fileExists(atPath: url.path) else {
            return try bars()
        }
        let key = url.path
        lock.lock(); let cached = images[key]; lock.unlock()
        if let cached { return cached }
        guard let cg = Self.loadOrientedImage(url, maxPixel: 4096) else { return try bars() }
        let tex = try VideoDecoder.makeTexture(from: cg, device: device)
        lock.lock(); images[key] = tex; lock.unlock()
        return tex
    }

    /// Le a imagem ja na orientacao certa (EXIF), limitada a `maxPixel`.
    public static func loadOrientedImage(_ url: URL, maxPixel: Int) -> CGImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ]
        return CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary)
    }

    // MARK: video

    private func videoTexture(_ layer: Layer, at mediaTime: Float) async throws -> MTLTexture {
        guard let url = url(for: layer), FileManager.default.fileExists(atPath: url.path) else {
            return try bars()
        }
        let key = url.path
        lock.lock(); var dec = decoders[key]; lock.unlock()
        if dec == nil {
            do {
                let d = try await VideoDecoder(url: url, device: device)
                lock.lock(); decoders[key] = d; lock.unlock()
                dec = d
            } catch {
                log.error("video ilegivel \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return try bars()
            }
        }
        guard let dec else { return try bars() }
        let t = Double(max(0, mediaTime))
        // Mesmo instante de antes (previa parada): reaproveita o quadro.
        lock.lock(); let last = lastVideoFrame[key]; lock.unlock()
        if let last, abs(last.time - t) < 0.0005 { return last.tex }
        guard let tex = try await dec.texture(at: t) else { return try bars() }
        lock.lock(); lastVideoFrame[key] = (t, tex); lock.unlock()
        return tex
    }

    // MARK: texto

    private func textTexture(_ layer: Layer, at mediaTime: Float) throws -> MTLTexture? {
        let text = (layer.text ?? "").isEmpty ? " " : (layer.text ?? " ")
        let size = CGFloat(layer.fontSize ?? 96)
        let color = layer.textColor ?? SIMD4(1, 1, 1, 1)
        let style = layer.textStyle ?? TextStyle()
        // Animacao de entrada: progresso pelo tempo desde o inicio da camada.
        if style.animation != .none {
            let elapsed = (mediaTime - layer.mediaOffset) / max(layer.speed, 0.01)
            let prog = min(1, max(0, elapsed / max(style.animationDuration, 0.05)))
            if prog < 1 {
                let q = (prog * 120).rounded() / 120
                let key = "\(text)|\(size)|\(color)|\(layer.fontName ?? "")|\(style)|\(q)"
                lock.lock(); let cached = animatedText; lock.unlock()
                if let cached, cached.key == key { return cached.tex }
                guard let cg = Self.renderText(text, fontName: layer.fontName, size: size, color: color,
                                               style: style, progress: q) else { return nil }
                let tex = try VideoDecoder.makeTexture(from: cg, device: device)
                lock.lock(); animatedText = (key, tex); lock.unlock()
                return tex
            }
        }
        let key = "\(text)|\(size)|\(color)|\(layer.fontName ?? "")|\(style)"
        lock.lock(); let cached = texts[key]; lock.unlock()
        if let cached { return cached }
        guard let cg = Self.renderText(text, fontName: layer.fontName, size: size, color: color,
                                       style: style, progress: 1) else {
            return nil
        }
        let tex = try VideoDecoder.makeTexture(from: cg, device: device)
        lock.lock(); texts[key] = tex; lock.unlock()
        return tex
    }

    // MARK: forma vetorial

    private func shapeTexture(_ layer: Layer, at mediaTime: Float) throws -> MTLTexture? {
        guard let st = layer.shapeStyle else { return nil }
        let size = layer.size ?? SIMD2(400, 400)
        // Keyframes vivem no tempo da composicao.
        let t = layer.startTime + (mediaTime - layer.mediaOffset) / max(layer.speed, 0.01)
        var parts: [String] = ["\(layer.id)", "\(size)", "\(st.shape)", "\(st.fillMode)", "\(st.shadowOn)"]
        parts.append("\(st.fill.value(at: t))")
        parts.append("\(st.gradientColor2.value(at: t))")
        parts.append("\(st.gradientAngle.value(at: t))")
        parts.append("\(st.strokeColor.value(at: t))")
        parts.append("\(st.strokeWidth.value(at: t))")
        parts.append("\(st.cornerRadius.value(at: t))")
        parts.append("\(st.sides.value(at: t))")
        parts.append("\(st.innerRatio.value(at: t))")
        parts.append("\(st.shadowColor.value(at: t))")
        parts.append("\(st.shadowAngle.value(at: t))")
        parts.append("\(st.shadowDistance.value(at: t))")
        parts.append("\(st.shadowSoftness.value(at: t))")
        let key = parts.joined(separator: "|")
        lock.lock(); let cached = shapes[key]; lock.unlock()
        if let cached { return cached }
        guard let cg = VectorDraw.shapeImage(st, size: size, at: t) else { return nil }
        let tex = try VideoDecoder.makeTexture(from: cg, device: device)
        lock.lock()
        if shapes.count > 64 { shapes.removeAll() }
        shapes[key] = tex
        lock.unlock()
        return tex
    }

    // MARK: mascaras

    public func maskTexture(for layer: Layer, at time: Float, device: MTLDevice) throws -> MTLTexture? {
        let masks = layer.maskList.filter(\.enabled)
        guard !masks.isEmpty else { return nil }
        let size = layer.size ?? SIMD2(1920, 1080)
        var key = "\(layer.id)|\(size)"
        for m in masks {
            key += "|\(m.shape)\(m.mode)\(m.inverted)\(m.position.value(at: time))\(m.size.value(at: time))"
            key += "\(m.rotation.value(at: time))\(m.feather.value(at: time))\(m.expand.value(at: time))"
            key += "\(m.opacity.value(at: time))\(m.cornerRadius.value(at: time))\(m.sides.value(at: time))"
            key += "\(m.innerRatio.value(at: time))"
        }
        lock.lock(); let cached = maskCache[key]; lock.unlock()
        if let cached { return cached }
        guard let cg = VectorDraw.maskImage(masks, layerSize: size, at: time) else { return nil }
        let tex = try VideoDecoder.makeTexture(from: cg, device: self.device)
        lock.lock()
        if maskCache.count > 64 { maskCache.removeAll() }
        maskCache[key] = tex
        lock.unlock()
        return tex
    }

#if canImport(UIKit)
    /// Mede o texto como a camada vai ocupar (para posicionar ao criar).
    public static func measureText(_ text: String, fontName: String?, size: CGFloat,
                                   style: TextStyle = TextStyle()) -> CGSize {
        let attr = attributed(text.isEmpty ? " " : text, fontName: fontName, size: size,
                              color: SIMD4(1, 1, 1, 1), style: style)
        let r = attr.boundingRect(with: CGSize(width: 8192, height: 8192),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let pad = CGFloat(8 + style.strokeWidth * 2)
            + (style.shadowOn ? CGFloat(max(abs(style.shadowOffset.x), abs(style.shadowOffset.y)) + style.shadowBlur) * 2 : 0)
        return CGSize(width: ceil(r.width) + pad, height: ceil(r.height) + pad)
    }

    static func font(_ name: String?, _ size: CGFloat) -> UIFont {
        name.flatMap { UIFont(name: $0, size: size) } ?? UIFont.systemFont(ofSize: size, weight: .bold)
    }

    static func uiColor(_ c: SIMD4<Float>) -> UIColor {
        UIColor(red: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: CGFloat(c.w))
    }

    static func attributed(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>, style: TextStyle = TextStyle()) -> NSAttributedString {
        let para = NSMutableParagraphStyle()
        switch style.align {
        case .left: para.alignment = .left
        case .center: para.alignment = .center
        case .right: para.alignment = .right
        }
        para.lineSpacing = CGFloat(style.lineSpacing)
        var a: [NSAttributedString.Key: Any] = [
            .font: font(fontName, size), .foregroundColor: uiColor(color), .paragraphStyle: para,
            .kern: CGFloat(style.letterSpacing)
        ]
        if style.strokeWidth > 0 {
            // negativo = preenche e contorna; o valor e % do tamanho da fonte
            a[.strokeWidth] = -CGFloat(style.strokeWidth) / size * 100
            a[.strokeColor] = uiColor(style.strokeColor)
        }
        if style.shadowOn {
            let sh = NSShadow()
            sh.shadowColor = uiColor(style.shadowColor)
            sh.shadowOffset = CGSize(width: CGFloat(style.shadowOffset.x), height: CGFloat(style.shadowOffset.y))
            sh.shadowBlurRadius = CGFloat(style.shadowBlur)
            a[.shadow] = sh
        }
        return NSAttributedString(string: text, attributes: a)
    }

    static func renderText(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>, style: TextStyle = TextStyle(),
                           progress: Float = 1) -> CGImage? {
        let attr = attributed(text, fontName: fontName, size: size, color: color, style: style)
        let box = measureText(text, fontName: fontName, size: size, style: style)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        fmt.opaque = false
        let pad = (box.width - attr.boundingRect(with: CGSize(width: 8192, height: 8192),
                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                context: nil).width) / 2
        let rect = CGRect(x: pad, y: pad, width: box.width - pad * 2, height: box.height - pad * 2)
        let img = UIGraphicsImageRenderer(size: box, format: fmt).image { rc in
            if style.animation == .none || progress >= 1 {
                attr.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            } else {
                drawAnimated(attr, in: rect, box: box, ctx: rc.cgContext, style: style, progress: progress)
            }
        }
        return img.cgImage
    }

    /// Desenha letra a letra (ou palavra a palavra) com a animacao de entrada.
    /// Cada unidade entra numa janela que se sobrepoe as vizinhas.
    static func drawAnimated(_ attr: NSAttributedString, in rect: CGRect, box: CGSize,
                             ctx: CGContext, style: TextStyle, progress: Float) {
        let ns = attr.string as NSString
        // indice de palavra de cada caractere (UTF-16)
        var wordOf = [Int](repeating: 0, count: ns.length + 1)
        var w = 0, inWord = false
        for i in 0..<ns.length {
            let c = ns.character(at: i)
            let space = c == 32 || c == 10 || c == 9
            if !space && !inWord { w += 1 }
            inWord = !space
            wordOf[i] = max(0, w - 1)
        }
        let byWord = style.animation == .fadeWords || style.animation == .riseWords
        let units = max(1, byWord ? w : ns.length)
        let overlap: Float = style.animation == .typewriter ? 0.001 : 3
        func local(_ idx: Int) -> Float {
            let span = Float(units) + overlap
            return min(1, max(0, (progress * span - Float(idx)) / max(overlap, 0.001)))
        }

        // CoreText trabalha com origem embaixo: vira o contexto.
        ctx.saveGState()
        ctx.translateBy(x: 0, y: box.height)
        ctx.scaleBy(x: 1, y: -1)
        let ctRect = CGRect(x: rect.minX, y: box.height - rect.maxY, width: rect.width, height: rect.height)
        let fs = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        let frame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0), CGPath(rect: ctRect, transform: nil), nil)
        guard let lines = CTFrameGetLines(frame) as? [CTLine] else { ctx.restoreGState(); return }
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)

        for (li, line) in lines.enumerated() {
            guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { continue }
            for run in runs {
                let n = CTRunGetGlyphCount(run)
                guard n > 0 else { continue }
                var glyphs = [CGGlyph](repeating: 0, count: n)
                var pos = [CGPoint](repeating: .zero, count: n)
                var idx = [CFIndex](repeating: 0, count: n)
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                CTRunGetPositions(run, CFRange(location: 0, length: 0), &pos)
                CTRunGetStringIndices(run, CFRange(location: 0, length: 0), &idx)
                let attrs = CTRunGetAttributes(run) as NSDictionary
                guard let fontRef = attrs[kCTFontAttributeName as String] else { continue }
                let ctFont = fontRef as! CTFont
                let fill = (attrs[NSAttributedString.Key.foregroundColor.rawValue] as? UIColor)?.cgColor
                    ?? CGColor(gray: 1, alpha: 1)
                for g in 0..<n {
                    let ci = Int(idx[g])
                    let u = byWord ? wordOf[min(ci, wordOf.count - 1)] : ci
                    let p = local(u)
                    if p <= 0 { continue }
                    var alpha: CGFloat = 1, dy: CGFloat = 0, sc: CGFloat = 1
                    let e = CGFloat(1 - pow(1 - p, 3))   // saida suave
                    switch style.animation {
                    case .typewriter: alpha = p > 0 ? 1 : 0
                    case .fadeLetters, .fadeWords: alpha = e
                    case .riseLetters, .riseWords: alpha = e; dy = (1 - e) * CTFontGetSize(ctFont) * 0.6
                    case .scaleLetters: alpha = e; sc = max(0.01, e)
                    case .none: break
                    }
                    ctx.saveGState()
                    ctx.setAlpha(alpha)
                    let o = CGPoint(x: origins[li].x + ctRect.minX + pos[g].x,
                                    y: origins[li].y + ctRect.minY + pos[g].y - dy)
                    ctx.translateBy(x: o.x, y: o.y)
                    if sc != 1 {
                        let adv = CTFontGetSize(ctFont) * 0.3
                        ctx.translateBy(x: adv, y: adv); ctx.scaleBy(x: sc, y: sc); ctx.translateBy(x: -adv, y: -adv)
                    }
                    if style.strokeWidth > 0 {
                        ctx.setTextDrawingMode(.fillStroke)
                        ctx.setStrokeColor(uiColor(style.strokeColor).cgColor)
                        ctx.setLineWidth(CGFloat(style.strokeWidth))
                    }
                    if style.shadowOn {
                        ctx.setShadow(offset: CGSize(width: CGFloat(style.shadowOffset.x), height: -CGFloat(style.shadowOffset.y)),
                                      blur: CGFloat(style.shadowBlur), color: uiColor(style.shadowColor).cgColor)
                    }
                    ctx.setFillColor(fill)
                    var gl = glyphs[g]
                    var zero = CGPoint.zero
                    CTFontDrawGlyphs(ctFont, &gl, &zero, 1, ctx)
                    ctx.restoreGState()
                }
            }
        }
        ctx.restoreGState()
    }

#else
    /// Sem UIKit (ferramentas de linha de comando no macOS): texto nao e desenhado.
    public static func measureText(_ text: String, fontName: String?, size: CGFloat,
                                   style: TextStyle = TextStyle()) -> CGSize {
        CGSize(width: 8, height: 8)
    }
    static func renderText(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>, style: TextStyle = TextStyle(),
                           progress: Float = 1) -> CGImage? { nil }
#endif

    // MARK: solido

    private func solidTexture(_ layer: Layer) throws -> MTLTexture {
        let c = layer.solidColor ?? SIMD4(1, 1, 1, 1)
        let key = "\(c)"
        lock.lock(); let cached = solids[key]; lock.unlock()
        if let cached { return cached }
        // 4x4 basta: o Compositor estica a textura para `layer.size`.
        let r = UInt8(max(0, min(255, c.x * c.w * 255)))
        let g = UInt8(max(0, min(255, c.y * c.w * 255)))
        let b = UInt8(max(0, min(255, c.z * c.w * 255)))
        let a = UInt8(max(0, min(255, c.w * 255)))
        let tex = try makeRGBA(width: 4, height: 4) { _, _ in (r, g, b, a) }
        lock.lock(); solids[key] = tex; lock.unlock()
        return tex
    }

    // MARK: barras coloridas (midia que falta)

    private func bars() throws -> MTLTexture {
        if let colorBars { return colorBars }
        let cols: [(UInt8, UInt8, UInt8)] = [
            (192, 192, 192), (192, 192, 0), (0, 192, 192), (0, 192, 0),
            (192, 0, 192), (192, 0, 0), (0, 0, 192)
        ]
        let w = 256, h = 144
        let tex = try makeRGBA(width: w, height: h) { x, _ in
            let c = cols[min(cols.count - 1, x * cols.count / w)]
            return (c.0, c.1, c.2, 255)
        }
        colorBars = tex
        return tex
    }

    private func makeRGBA(width w: Int, height h: Int,
                          _ pixel: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)) throws -> MTLTexture {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                         width: w, height: h, mipmapped: false)
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: w, height: h)
        }
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        for y in 0..<h {
            for x in 0..<w {
                let p = pixel(x, y), i = (y * w + x) * 4
                bytes[i] = p.0; bytes[i + 1] = p.1; bytes[i + 2] = p.2; bytes[i + 3] = p.3
            }
        }
        t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0,
                  withBytes: bytes, bytesPerRow: w * 4)
        return t
    }
}
