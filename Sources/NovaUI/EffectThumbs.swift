//
//  EffectThumbs.swift
//  NovaUI
//
//  Miniaturas do navegador de efeito. Como no APK (yq2.M), a miniatura e o
//  proprio efeito aplicado numa imagem de amostra: presets/amostra.jpg nos
//  recentes e nas listas, effects/vitrine/personagem.jpg nos Destaques.
//  Uma por vez, em 180 px, guardadas na memoria enquanto o app estiver aberto.
//
//  Tambem guarda os nove ultimos efeitos usados ("Usados recentemente").
//

import SwiftUI
import Metal
import CoreImage
import UIKit

@MainActor
final class EffectThumbs: ObservableObject {
    static let shared = EffectThumbs()

    enum Base: String {
        case amostra = "presets/amostra.jpg"
        case personagem = "effects/vitrine/personagem.jpg"
    }

    @Published private(set) var cache: [String: UIImage] = [:]
    private var pedidos: Set<String> = []
    private var fila: [(String, Base)] = []
    private var rodando = false
    private var renderer: EffectRenderer?
    private var queue: MTLCommandQueue?
    private var bases: [Base: MTLTexture] = [:]
    private let ci = CIContext()
    private let lado = 180

    private static var imagensBase: [Base: UIImage] = [:]

    static func imagemBase(_ b: Base) -> UIImage? {
        if let i = imagensBase[b] { return i }
        guard let u = Bundle.main.resourceURL?.appendingPathComponent(b.rawValue),
              let i = UIImage(contentsOfFile: u.path) else { return nil }
        imagensBase[b] = i
        return i
    }

    private func chave(_ id: String, _ b: Base) -> String { b.rawValue + "|" + id }

    func imagem(_ id: String, base: Base) -> UIImage? { cache[chave(id, base)] }

    /// Pede a miniatura; quando ficar pronta, `cache` muda e a tela redesenha.
    func pedir(_ id: String, base: Base) {
        let k = chave(id, base)
        guard cache[k] == nil, !pedidos.contains(k) else { return }
        pedidos.insert(k)
        fila.append((id, base))
        if !rodando {
            rodando = true
            Task { await processar() }
        }
    }

    private func processar() async {
        while !fila.isEmpty {
            let (id, b) = fila.removeFirst()
            let feita = await renderizar(id, base: b)
            DemoMode.log.info("miniatura \(id, privacy: .public): \(feita == nil ? "amostra" : "renderizada", privacy: .public)")
            let img = feita ?? Self.imagemBase(b)
            if let img { cache[chave(id, b)] = img }
            await Task.yield()
        }
        rodando = false
    }

    private func texturaBase(_ b: Base, _ device: MTLDevice) -> MTLTexture? {
        if let t = bases[b] { return t }
        guard let img = Self.imagemBase(b)?.cgImage else { return nil }
        // reduz para o tamanho da miniatura antes de subir para a GPU
        let w = lado, h = max(1, Int(Double(lado) * Double(img.height) / Double(max(img.width, 1))))
        var px = [UInt8](repeating: 0, count: w * h * 4)
        let ok: Bool = px.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                                        | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            ctx.interpolationQuality = .high
            ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return nil }
        // Como a sonda do CI: float16, leitura, escrita e alvo de desenho (varios
        // efeitos usam a entrada tambem como "comp" e desenham nela).
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: w, height: h,
                                                         mipmapped: false)
        d.usage = [.shaderRead, .shaderWrite, .renderTarget]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else { return nil }
        let meio = px.map { Float16(Float($0) / 255) }
        meio.withUnsafeBytes { buf in
            t.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0,
                      withBytes: buf.baseAddress!, bytesPerRow: w * 8)
        }
        bases[b] = t
        return t
    }

    private func renderizar(_ id: String, base: Base) async -> UIImage? {
        // So o que passou limpo no teste da GPU do CI (os outros ficam na amostra).
        guard EffectVerification.statusById[id] == "ok",
              let m = try? await EffectRegistry.shared.manifest(id: id),
              m.stage == nil || m.stage == "mblooks" else { return nil }
        do {
            if renderer == nil {
                renderer = try EffectRenderer()
                queue = renderer?.device.makeCommandQueue()
            }
            guard let r = renderer, let q = queue, let entrada = texturaBase(base, r.device),
                  let cb = q.makeCommandBuffer() else { return nil }
            let valores = AppliedEffect(effectID: id).values(at: 0.5, manifest: m)
            let saida: MTLTexture
            if m.stage == "mblooks", let t = LooksFerramentas.porManifesto[id] {
                saida = try r.renderLooks(entrada: entrada,
                                          passos: [LooksPasso(codigo: t.codigo,
                                                              valores: LooksFerramentas.valores(t.params, de: valores),
                                                              lut: nil)],
                                          forca: 1, mediaRoot: nil, cb: cb)
            } else {
                saida = try r.render(m, input: .init(content: entrada, comp: entrada,
                                                     time: 0.5, frameDuration: 1.0 / 30),
                                     values: valores, into: cb)
            }
            // O aviso de "terminou" tem que ser pedido ANTES do commit: depois
            // dele o Metal lanca excecao e o app fecha.
            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                cb.addCompletedHandler { _ in c.resume() }
                cb.commit()
            }
            if cb.error != nil { return nil }
            defer { if saida !== entrada { r.release(saida) } }
            // A linha 0 da textura e o topo da imagem; o CIImage le de baixo para cima.
            guard let ciImg = CIImage(mtlTexture: saida, options: [.colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!])?
                    .oriented(.downMirrored),
                  let cg = ci.createCGImage(ciImg, from: ciImg.extent) else { return nil }
            return UIImage(cgImage: cg)
        } catch {
            return nil
        }
    }

    // MARK: recentes

    private static let chaveRecentes = "nova.efeitos.recentes"

    static var recentes: [String] {
        UserDefaults.standard.stringArray(forKey: chaveRecentes) ?? []
    }

    /// O APK lembra os nove ultimos efeitos usados, entre uma sessao e outra.
    static func usar(_ id: String) {
        var r = recentes.filter { $0 != id }
        r.insert(id, at: 0)
        UserDefaults.standard.set(Array(r.prefix(9)), forKey: chaveRecentes)
    }
}

/// Miniatura do efeito: mostra a amostra enquanto o efeito renderiza.
struct MiniaturaEfeito: View {
    let id: String
    var base: EffectThumbs.Base = .amostra
    /// Metade esquerda original, metade direita com o efeito (os recentes do APK).
    var dividida = false
    @ObservedObject private var thumbs = EffectThumbs.shared

    var body: some View {
        GeometryReader { g in
            let orig = EffectThumbs.imagemBase(base)
            let fx = thumbs.imagem(id, base: base)
            ZStack {
                Color(red: 0.08, green: 0.09, blue: 0.13)
                if let img = fx ?? orig {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: g.size.width, height: g.size.height)
                }
                if dividida, let orig {
                    Image(uiImage: orig).resizable().scaledToFill()
                        .frame(width: g.size.width, height: g.size.height)
                        .mask(alignment: .leading) {
                            Rectangle().frame(width: g.size.width / 2)
                        }
                    Rectangle().fill(Color.white.opacity(0.9))
                        .frame(width: 1.5, height: g.size.height)
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
        }
        .onAppear { thumbs.pedir(id, base: base) }
    }
}
