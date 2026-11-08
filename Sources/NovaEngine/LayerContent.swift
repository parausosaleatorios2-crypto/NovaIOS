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
        texts.removeAll(); solids.removeAll()
    }

    public func texture(for layer: Layer, at mediaTime: Float,
                        device: MTLDevice) async throws -> MTLTexture? {
        switch layer.kind {
        case .image:
            return try imageTexture(layer)
        case .video:
            return try await videoTexture(layer, at: mediaTime)
        case .text:
            return try textTexture(layer)
        case .solid, .shape, .adjustment:
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

    private func textTexture(_ layer: Layer) throws -> MTLTexture? {
        let text = (layer.text ?? "").isEmpty ? " " : (layer.text ?? " ")
        let size = CGFloat(layer.fontSize ?? 96)
        let color = layer.textColor ?? SIMD4(1, 1, 1, 1)
        let key = "\(text)|\(size)|\(color)|\(layer.fontName ?? "")"
        lock.lock(); let cached = texts[key]; lock.unlock()
        if let cached { return cached }
        guard let cg = Self.renderText(text, fontName: layer.fontName, size: size, color: color) else {
            return nil
        }
        let tex = try VideoDecoder.makeTexture(from: cg, device: device)
        lock.lock(); texts[key] = tex; lock.unlock()
        return tex
    }

#if canImport(UIKit)
    /// Mede o texto como a camada vai ocupar (para posicionar ao criar).
    public static func measureText(_ text: String, fontName: String?, size: CGFloat) -> CGSize {
        let attr = attributed(text.isEmpty ? " " : text, fontName: fontName, size: size,
                              color: SIMD4(1, 1, 1, 1))
        let r = attr.boundingRect(with: CGSize(width: 8192, height: 8192),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return CGSize(width: ceil(r.width) + 8, height: ceil(r.height) + 8)
    }

    static func attributed(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>) -> NSAttributedString {
        let font = fontName.flatMap { UIFont(name: $0, size: size) }
            ?? UIFont.systemFont(ofSize: size, weight: .bold)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let ui = UIColor(red: CGFloat(color.x), green: CGFloat(color.y),
                         blue: CGFloat(color.z), alpha: CGFloat(color.w))
        return NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: ui, .paragraphStyle: para
        ])
    }

    static func renderText(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>) -> CGImage? {
        let attr = attributed(text, fontName: fontName, size: size, color: color)
        let box = measureText(text, fontName: fontName, size: size)
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        fmt.opaque = false
        let img = UIGraphicsImageRenderer(size: box, format: fmt).image { _ in
            attr.draw(with: CGRect(origin: CGPoint(x: 4, y: 4),
                                   size: CGSize(width: box.width - 8, height: box.height - 8)),
                      options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
        return img.cgImage
    }

#else
    /// Sem UIKit (ferramentas de linha de comando no macOS): texto nao e desenhado.
    public static func measureText(_ text: String, fontName: String?, size: CGFloat) -> CGSize {
        CGSize(width: 8, height: 8)
    }
    static func renderText(_ text: String, fontName: String?, size: CGFloat,
                           color: SIMD4<Float>) -> CGImage? { nil }
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
