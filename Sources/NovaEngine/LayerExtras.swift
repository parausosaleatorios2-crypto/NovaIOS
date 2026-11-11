//
//  LayerExtras.swift
//  NovaEngine
//
//  Mascaras, formas vetoriais e texto animado — porte do modelo do APK
//  (conferido com o REA/JADX):
//    com.novaeditor.model.LayerMask: shape (RECTANGLE, ELLIPSE, POLYGON, STAR),
//      position, size, rotation, feather, expand, opacity, inverted,
//      cornerRadius, sides, innerRatio, mode, enabled, name
//    com.novaeditor.model.LayerContent.Shape: fill, strokeColor, strokeWidth,
//      gradiente (tipo, cor1, cor2, angulo, escala), sombra (ligada, cor,
//      angulo, distancia, suavidade)
//
//  Tudo desenhado com CoreGraphics/CoreText e entregue ao Compositor como
//  textura (conteudo da forma/texto) ou como alfa da mascara.
//

import Foundation
import CoreGraphics
import CoreText
import CoreImage
import ImageIO
import simd
import UIKit

// MARK: - Mascara

public enum MaskShape: String, Codable, Sendable, CaseIterable {
    case rectangle, ellipse, polygon, star
    public var label: String {
        switch self {
        case .rectangle: return "Retângulo"; case .ellipse: return "Elipse"
        case .polygon: return "Polígono";    case .star: return "Estrela"
        }
    }
}

public enum MaskMode: String, Codable, Sendable, CaseIterable {
    case add, subtract, intersect, difference
    public var label: String {
        switch self {
        case .add: return "Adicionar"; case .subtract: return "Subtrair"
        case .intersect: return "Interseção"; case .difference: return "Diferença"
        }
    }
}

public struct LayerMask: Codable, Sendable, Identifiable, Equatable {
    public var id = UUID()
    public var name = "Máscara"
    public var enabled = true
    public var shape: MaskShape = .rectangle
    public var mode: MaskMode = .add
    public var inverted = false
    /// Centro e tamanho em px da camada.
    public var position = Animated<SIMD2<Float>>(.zero)
    public var size = Animated<SIMD2<Float>>(SIMD2(200, 200))
    public var rotation = Animated<Float>(0)
    public var feather = Animated<Float>(0)
    public var expand = Animated<Float>(0)
    public var opacity = Animated<Float>(100)
    public var cornerRadius = Animated<Float>(0)
    public var sides = Animated<Float>(5)
    public var innerRatio = Animated<Float>(0.5)

    public init(shape: MaskShape = .rectangle, center: SIMD2<Float>, size: SIMD2<Float>) {
        self.shape = shape
        self.position = Animated(center)
        self.size = Animated(size)
    }
}

// MARK: - Forma

public enum FillMode: String, Codable, Sendable, CaseIterable {
    case solid, linear, radial, none
    public var label: String {
        switch self {
        case .solid: return "Cor"; case .linear: return "Degradê linear"
        case .radial: return "Degradê radial"; case .none: return "Sem preenchimento"
        }
    }
}

public struct ShapeStyle: Codable, Sendable, Equatable {
    public var shape: MaskShape = .rectangle
    public var fillMode: FillMode = .solid
    public var fill = Animated<SIMD4<Float>>(SIMD4(0.39, 0.33, 0.95, 1))
    public var gradientColor2 = Animated<SIMD4<Float>>(SIMD4(0.95, 0.3, 0.6, 1))
    public var gradientAngle = Animated<Float>(0)
    public var strokeColor = Animated<SIMD4<Float>>(SIMD4(1, 1, 1, 1))
    public var strokeWidth = Animated<Float>(0)
    public var cornerRadius = Animated<Float>(0)
    public var sides = Animated<Float>(5)
    public var innerRatio = Animated<Float>(0.5)
    public var shadowOn = false
    public var shadowColor = Animated<SIMD4<Float>>(SIMD4(0, 0, 0, 0.6))
    public var shadowAngle = Animated<Float>(135)
    public var shadowDistance = Animated<Float>(12)
    public var shadowSoftness = Animated<Float>(12)

    public init(shape: MaskShape = .rectangle) { self.shape = shape }
}

// MARK: - Texto

public enum TextAlign: String, Codable, Sendable, CaseIterable {
    case left, center, right
}

/// Animacoes de texto por letra/palavra, como os presets de entrada do APK
/// (AnimadorDeTexto / SeletorDeFaixa). `progress` vai de 0 a 1 ao longo de `duration`.
public enum TextAnimationPreset: String, Codable, Sendable, CaseIterable {
    case none, typewriter, fadeLetters, riseLetters, scaleLetters, fadeWords, riseWords
    // Animacoes no estilo do Animation Composer (por letra, palavra ou linha)
    case dropLetters, slideLeft, slideRight, popBounce, elastic, spinLetters, flipLetters
    case zoomOut, trackingIn, randomFade, centerOut, swingLetters, shakeIn, riseLines, typewriterCursor
    public var label: String {
        switch self {
        case .none: return "Nenhuma"
        case .typewriter: return "Máquina de escrever"
        case .fadeLetters: return "Aparecer por letra"
        case .riseLetters: return "Subir por letra"
        case .scaleLetters: return "Crescer por letra"
        case .fadeWords: return "Aparecer por palavra"
        case .riseWords: return "Subir por palavra"
        case .dropLetters: return "Cair por letra"
        case .slideLeft: return "Deslizar da direita"
        case .slideRight: return "Deslizar da esquerda"
        case .popBounce: return "Pop com quique"
        case .elastic: return "Elástico"
        case .spinLetters: return "Girar por letra"
        case .flipLetters: return "Virar por letra"
        case .zoomOut: return "Zoom (de grande)"
        case .trackingIn: return "Espaçamento fechando"
        case .randomFade: return "Aparecer embaralhado"
        case .centerOut: return "Do centro para fora"
        case .swingLetters: return "Balançar por letra"
        case .shakeIn: return "Tremer e parar"
        case .riseLines: return "Subir por linha"
        case .typewriterCursor: return "Digitando com cursor"
        }
    }
}

/// Animacoes em laco do texto (rodam o tempo todo, depois da entrada).
public enum TextLoopPreset: String, Codable, Sendable, CaseIterable {
    case none, wave, jitter, float, flicker, pulse, rainbowWave
    public var label: String {
        switch self {
        case .none: return "Nenhum"
        case .wave: return "Onda"
        case .jitter: return "Tremer"
        case .float: return "Flutuar"
        case .flicker: return "Piscar"
        case .pulse: return "Pulsar"
        case .rainbowWave: return "Onda de escala"
        }
    }
}

public struct TextStyle: Codable, Sendable, Equatable {
    public var align: TextAlign = .center
    public var strokeColor: SIMD4<Float> = SIMD4(0, 0, 0, 1)
    public var strokeWidth: Float = 0
    public var letterSpacing: Float = 0
    public var lineSpacing: Float = 0
    public var shadowOn = false
    public var shadowColor: SIMD4<Float> = SIMD4(0, 0, 0, 0.7)
    public var shadowOffset: SIMD2<Float> = SIMD2(4, 6)
    public var shadowBlur: Float = 8
    public var animation: TextAnimationPreset = .none
    /// Duracao da animacao de entrada, em segundos a partir do inicio da camada.
    public var animationDuration: Float = 1.2
    /// Saida (a entrada tocada ao contrario no fim da camada), laco e velocidade do laco.
    public var animationOut: TextAnimationPreset?
    public var animationOutDuration: Float?
    public var loop: TextLoopPreset?
    public var loopSpeed: Float?
    /// Eixos da fonte variavel (id do eixo em texto -> valor), ex. "2003265652" (wght) -> 700.
    public var variation: [String: Float]?
    public init() {}
}

// MARK: - Campos novos da camada (opcionais: projetos antigos abrem)

public extension Layer {
    var maskList: [LayerMask] {
        get { masks ?? [] }
        set { masks = newValue.isEmpty ? nil : newValue }
    }
}

// MARK: - Fontes

public enum FontCatalog {
    /// Nomes PostScript das fontes do pacote (Resources/fonts), ja registradas.
    nonisolated(unsafe) public private(set) static var bundled: [String] = []

    /// Registra as fontes do pacote no processo. Chamar uma vez no arranque.
    public static func registerBundled(root: URL? = nil) {
        guard bundled.isEmpty else { return }
        let base = root ?? Bundle.main.resourceURL?.appendingPathComponent("fonts")
        guard let base, let en = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil)
        else { return }
        var names: [String] = []
        for case let url as URL in en where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            if let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] {
                for d in descs {
                    if let n = CTFontDescriptorCopyAttribute(d, kCTFontNameAttribute) as? String { names.append(n) }
                }
            }
        }
        bundled = Array(Set(names)).sorted()
        registerInstalled()
    }

    /// Fontes que o usuario instalou (Documents/Fonts).
    nonisolated(unsafe) public private(set) static var installed: [String] = []

    public static var pastaInstaladas: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Fonts")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    private static func nomes(_ url: URL) -> [String] {
        guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else { return [] }
        return descs.compactMap { CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String }
    }

    public static func registerInstalled() {
        guard let fs = try? FileManager.default.contentsOfDirectory(at: pastaInstaladas, includingPropertiesForKeys: nil) else { return }
        var n: [String] = []
        for u in fs where ["ttf", "otf", "ttc"].contains(u.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(u as CFURL, .process, nil)
            n += nomes(u)
        }
        installed = Array(Set(n)).sorted()
    }

    /// Copia o arquivo para Documents/Fonts, registra e devolve os nomes novos.
    @discardableResult
    public static func install(_ url: URL) -> [String] {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        let dest = pastaInstaladas.appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return [] }
        CTFontManagerRegisterFontsForURL(dest as CFURL, .process, nil)
        let n = nomes(dest)
        installed = Array(Set(installed + n)).sorted()
        return n
    }

    public struct Eixo: Hashable, Sendable {
        public let id: String, nome: String
        public let minimo: Float, maximo: Float, padrao: Float
    }

    /// Eixos de variacao da fonte (vazio se nao for variavel).
    public static func eixos(_ name: String?) -> [Eixo] {
        guard let name else { return [] }
        let f = CTFontCreateWithName(name as CFString, 24, nil)
        guard let arr = CTFontCopyVariationAxes(f) as? [[CFString: Any]] else { return [] }
        return arr.compactMap { d in
            guard let id = d[kCTFontVariationAxisIdentifierKey] as? NSNumber,
                  let mn = d[kCTFontVariationAxisMinimumValueKey] as? NSNumber,
                  let mx = d[kCTFontVariationAxisMaximumValueKey] as? NSNumber else { return nil }
            let df = (d[kCTFontVariationAxisDefaultValueKey] as? NSNumber)?.floatValue ?? mn.floatValue
            var nome = d[kCTFontVariationAxisNameKey] as? String ?? ""
            if nome.isEmpty {
                let v = id.uint32Value
                nome = String(bytes: [24, 16, 8, 0].map { UInt8((v >> $0) & 0xFF) }, encoding: .ascii) ?? "\(v)"
            }
            return Eixo(id: id.stringValue, nome: nome, minimo: mn.floatValue, maximo: mx.floatValue, padrao: df)
        }
    }

    /// A fonte com os eixos aplicados.
    public static func aplicar(_ font: UIFont, _ v: [String: Float]?) -> UIFont {
        guard let v, !v.isEmpty else { return font }
        var m: [NSNumber: NSNumber] = [:]
        for (k, x) in v { if let i = UInt32(k) { m[NSNumber(value: i)] = NSNumber(value: x) } }
        let d = CTFontDescriptorCreateCopyWithAttributes(font.fontDescriptor as CTFontDescriptor,
                                                          [kCTFontVariationAttribute: m] as CFDictionary)
        return CTFontCreateWithFontDescriptor(d, font.pointSize, nil) as UIFont
    }
}

// MARK: - Desenho (CoreGraphics)

public enum VectorDraw {

    static func cg(_ c: SIMD4<Float>) -> CGColor {
        CGColor(srgbRed: CGFloat(c.x), green: CGFloat(c.y), blue: CGFloat(c.z), alpha: CGFloat(c.w))
    }

    /// Caminho do formato num retangulo centrado em (0,0).
    static func path(_ shape: MaskShape, size: CGSize, corner: CGFloat,
                     sides: Int, inner: CGFloat) -> CGPath {
        let r = CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height)
        switch shape {
        case .rectangle:
            let c = min(corner, min(r.width, r.height) / 2)
            return CGPath(roundedRect: r, cornerWidth: max(0, c), cornerHeight: max(0, c), transform: nil)
        case .ellipse:
            return CGPath(ellipseIn: r, transform: nil)
        case .polygon, .star:
            let n = max(3, sides)
            let p = CGMutablePath()
            let pts = shape == .star ? n * 2 : n
            for i in 0..<pts {
                let a = -CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / CGFloat(pts)
                let k: CGFloat = (shape == .star && i % 2 == 1) ? max(0.05, min(1, inner)) : 1
                let pt = CGPoint(x: cos(a) * r.width / 2 * k, y: sin(a) * r.height / 2 * k)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            return p
        }
    }

    static func context(_ w: Int, _ h: Int, gray: Bool = false) -> CGContext? {
        if gray {
            return CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                             space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        }
        return CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!,
                         bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }

    /// Escala para caber em `maxSide` (texturas grandes demais pesam na GPU).
    static func fitScale(_ size: SIMD2<Float>, maxSide: Float = 2048) -> CGFloat {
        CGFloat(min(1, maxSide / max(size.x, size.y, 1)))
    }

    // MARK: forma

    public static func shapeImage(_ s: ShapeStyle, size: SIMD2<Float>, at t: Float) -> CGImage? {
        let k = fitScale(size)
        let w = max(1, Int(CGFloat(size.x) * k)), h = max(1, Int(CGFloat(size.y) * k))
        guard let ctx = context(w, h) else { return nil }
        // Origem no topo-esquerdo, como a textura.
        ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
        ctx.scaleBy(x: k, y: k)

        let stroke = CGFloat(s.strokeWidth.value(at: t))
        let shadowDist = s.shadowOn ? CGFloat(s.shadowDistance.value(at: t)) : 0
        let margin = stroke / 2 + (s.shadowOn ? shadowDist + CGFloat(s.shadowSoftness.value(at: t)) : 0)
        let inner = CGSize(width: max(1, CGFloat(size.x) - margin * 2),
                           height: max(1, CGFloat(size.y) - margin * 2))
        let p = path(s.shape, size: inner, corner: CGFloat(s.cornerRadius.value(at: t)),
                     sides: Int(s.sides.value(at: t).rounded()), inner: CGFloat(s.innerRatio.value(at: t)))
        ctx.translateBy(x: CGFloat(size.x) / 2, y: CGFloat(size.y) / 2)

        if s.shadowOn {
            let a = CGFloat(s.shadowAngle.value(at: t)) * .pi / 180
            ctx.setShadow(offset: CGSize(width: cos(a) * shadowDist, height: sin(a) * shadowDist),
                          blur: CGFloat(s.shadowSoftness.value(at: t)), color: cg(s.shadowColor.value(at: t)))
        }
        if s.fillMode != .none {
            ctx.saveGState()
            ctx.addPath(p)
            switch s.fillMode {
            case .solid, .none:
                ctx.setFillColor(cg(s.fill.value(at: t)))
                ctx.fillPath()
            case .linear, .radial:
                ctx.clip()
                let cs = CGColorSpace(name: CGColorSpace.sRGB)!
                if let g = CGGradient(colorsSpace: cs, colors: [cg(s.fill.value(at: t)),
                                                                 cg(s.gradientColor2.value(at: t))] as CFArray,
                                      locations: [0, 1]) {
                    let half = max(inner.width, inner.height) / 2
                    if s.fillMode == .linear {
                        let a = CGFloat(s.gradientAngle.value(at: t)) * .pi / 180
                        let d = CGPoint(x: cos(a) * half, y: sin(a) * half)
                        ctx.drawLinearGradient(g, start: CGPoint(x: -d.x, y: -d.y), end: d,
                                               options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
                    } else {
                        ctx.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero,
                                               endRadius: half, options: [.drawsAfterEndLocation])
                    }
                }
            }
            ctx.restoreGState()
        }
        if stroke > 0 {
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            ctx.addPath(p)
            ctx.setStrokeColor(cg(s.strokeColor.value(at: t)))
            ctx.setLineWidth(stroke)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        }
        return ctx.makeImage()
    }

    // MARK: mascara

    /// Alfa combinado das mascaras da camada (cinza: branco = visivel).
    public static func maskImage(_ masks: [LayerMask], layerSize: SIMD2<Float>, at t: Float) -> CGImage? {
        let active = masks.filter(\.enabled)
        guard !active.isEmpty else { return nil }
        let k = fitScale(layerSize, maxSide: 1024)
        let w = max(1, Int(CGFloat(layerSize.x) * k)), h = max(1, Int(CGFloat(layerSize.y) * k))
        guard let ctx = context(w, h) else { return nil }
        ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
        ctx.scaleBy(x: k, y: k)
        // A primeira mascara em modo "adicionar" parte do vazio; subtrair parte do cheio.
        if active.first?.mode == .subtract || active.first?.mode == .intersect {
            ctx.setFillColor(CGColor(gray: 1, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(layerSize.x), height: CGFloat(layerSize.y)))
        }
        for m in active {
            guard let one = singleMask(m, layerSize: layerSize, at: t, k: k, w: w, h: h) else { continue }
            ctx.saveGState()
            ctx.resetClip()
            // desenha em px da imagem
            ctx.scaleBy(x: 1 / k, y: 1 / k)
            ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
            let r = CGRect(x: 0, y: 0, width: w, height: h)
            switch m.mode {
            case .add: ctx.setBlendMode(.normal)
            case .subtract: ctx.setBlendMode(.destinationOut)
            case .intersect: ctx.setBlendMode(.destinationIn)
            case .difference: ctx.setBlendMode(.xor)
            }
            ctx.draw(one, in: r)
            ctx.restoreGState()
        }
        return ctx.makeImage()
    }

    static func singleMask(_ m: LayerMask, layerSize: SIMD2<Float>, at t: Float,
                           k: CGFloat, w: Int, h: Int) -> CGImage? {
        guard let ctx = context(w, h) else { return nil }
        ctx.translateBy(x: 0, y: CGFloat(h)); ctx.scaleBy(x: 1, y: -1)
        ctx.scaleBy(x: k, y: k)
        let c = m.position.value(at: t), sz = m.size.value(at: t)
        let e = CGFloat(m.expand.value(at: t))
        let p = path(m.shape, size: CGSize(width: max(1, CGFloat(sz.x) + e * 2), height: max(1, CGFloat(sz.y) + e * 2)),
                     corner: CGFloat(m.cornerRadius.value(at: t)),
                     sides: Int(m.sides.value(at: t).rounded()), inner: CGFloat(m.innerRatio.value(at: t)))
        let a = CGFloat(min(max(m.opacity.value(at: t) / 100, 0), 1))
        if m.inverted {
            ctx.setFillColor(CGColor(gray: 1, alpha: a))
            ctx.fill(CGRect(x: 0, y: 0, width: CGFloat(layerSize.x), height: CGFloat(layerSize.y)))
            ctx.setBlendMode(.destinationOut)
            ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        } else {
            ctx.setFillColor(CGColor(gray: 1, alpha: a))
        }
        ctx.translateBy(x: CGFloat(c.x), y: CGFloat(c.y))
        ctx.rotate(by: CGFloat(m.rotation.value(at: t)) * .pi / 180)
        ctx.addPath(p)
        ctx.fillPath()
        guard var img = ctx.makeImage() else { return nil }
        let f = CGFloat(m.feather.value(at: t)) * k
        if f > 0.5 {
            let ci = CIImage(cgImage: img).clampedToExtent()
                .applyingGaussianBlur(sigma: Double(f) / 2)
                .cropped(to: CGRect(x: 0, y: 0, width: w, height: h))
            if let out = CIContext(options: [.useSoftwareRenderer: false]).createCGImage(ci, from: ci.extent) {
                img = out
            }
        }
        return img
    }
}

// MARK: - Midia invertida / em laco

public extension Layer {
    /// Tempo dentro da midia considerando laco e invertido (LayerContent.Media
    /// do APK: emLaco, reversed).
    func mediaTimeAdjusted(at t: Float) -> Float {
        var m = mediaTime(at: t)
        if let src = sourceDuration, src > 0 {
            if loop ?? false { m = m.truncatingRemainder(dividingBy: src); if m < 0 { m += src } }
            if reversed ?? false { m = max(0, src - m - 0.001) }
        }
        return m
    }
}
