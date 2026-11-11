//
//  PreviewSurface.swift
//  NovaUI
//
//  A superficie Metal onde a composicao e desenhada. Usa MTKView por UIViewRepresentable:
//  SwiftUI sozinho nao da acesso ao drawable.
//
//  Cada mudanca de tempo ou de composicao pede um quadro ao Compositor; se um
//  quadro ainda esta sendo montado, guarda so o pedido mais recente (a previa
//  pula quadros em vez de acumular atraso).
//

import SwiftUI
import MetalKit
import os

public struct PreviewSurface: UIViewRepresentable {
    let composition: Composition
    let time: Float
    let mediaRoot: URL
    let manifests: [String: EffectManifest]
    /// Cache de quadros (RAM Preview); nil = monta sempre.
    let cache: CacheDeQuadros?

    public init(composition: Composition, time: Float, mediaRoot: URL,
                manifests: [String: EffectManifest] = [:], cache: CacheDeQuadros? = nil) {
        self.composition = composition
        self.time = time
        self.mediaRoot = mediaRoot
        self.manifests = manifests
        self.cache = cache
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public func makeUIView(context: Context) -> MTKView {
        let v = MTKView()
        v.device = MTLCreateSystemDefaultDevice()
        v.colorPixelFormat = .bgra8Unorm
        v.framebufferOnly = true
        v.isOpaque = false
        v.backgroundColor = .clear
        v.enableSetNeedsDisplay = true
        v.isPaused = true
        v.delegate = context.coordinator
        context.coordinator.attach(view: v)
        return v
    }

    public func updateUIView(_ v: MTKView, context: Context) {
        context.coordinator.cache = cache
        context.coordinator.request(composition, time: time,
                                    mediaRoot: mediaRoot, manifests: manifests)
    }

    public final class Coordinator: NSObject, MTKViewDelegate {
        private weak var view: MTKView?
        private var device: MTLDevice?
        private var compositor: Compositor?
        private var provider: MediaContentProvider?
        private var frame: MTLTexture?
        /// Quadro do cache na tela (nao e do pool do Compositor: nao se devolve).
        private var doCache: MTLTexture?
        var cache: CacheDeQuadros?
        /// Ultimo quadro pedido pela tela: um quadro montado depois que a tela ja foi para
        /// outro (do cache) entra no cache mas nao volta para a tela.
        private var alvo: Int?
        private var rendering = false
        private var pending: (Composition, Float)?
        private var manifests: [String: EffectManifest] = [:]
        private let log = Logger(subsystem: "com.novavision.editor", category: "Preview")

        /// Ultimo aviso do Compositor (camada que falhou), para a tela mostrar.
        public private(set) var lastWarning: String?

        func attach(view: MTKView) {
            self.view = view
            self.device = view.device
        }

        @MainActor
        func request(_ comp: Composition, time: Float, mediaRoot: URL,
                     manifests: [String: EffectManifest]) {
            guard let device else { return }
            self.manifests = manifests
            if provider?.mediaRoot != mediaRoot {
                provider = MediaContentProvider(mediaRoot: mediaRoot, device: device)
                compositor?.contentProvider = provider
            }
            if let cache {
                cache.validar(comp, efeitos: manifests.keys.sorted())
                let q = CacheDeQuadros.quadro(time, fps: comp.frameRate)
                alvo = q
                if let t = cache.textura(q) {
                    // Quadro pronto: sai na hora, sem montar.
                    doCache = t
                    pending = nil
                    view?.setNeedsDisplay()
                    cache.mostrou(q)
                    return
                }
            }
            if rendering { pending = (comp, time); return }
            rendering = true
            Task { @MainActor in
                await self.render(comp, time: time)
            }
        }

        @MainActor
        private func render(_ comp: Composition, time: Float) async {
            do {
                if compositor == nil, let device {
                    let r = try EffectRenderer(device: device)
                    let c = try Compositor(renderer: r)
                    c.contentProvider = provider
                    compositor = c
                }
                if let compositor {
                    // Com cache, monta o quadro exato (como o AE) e guarda uma copia do tamanho da tela.
                    let q = CacheDeQuadros.quadro(time, fps: comp.frameRate)
                    let tq = cache != nil ? Float(q) / max(comp.frameRate, 1) : time
                    let tex = try await compositor.renderFrame(comp, at: tq, manifests: manifests)
                    let completo = compositor.lastFrameWarnings.isEmpty
                    lastWarning = compositor.lastFrameWarnings.first
                    if cache == nil || alvo == nil || alvo == q {
                        if let old = frame { compositor.release(old) }
                        frame = tex
                        doCache = nil
                        view?.setNeedsDisplay()
                    }
                    if let cache {
                        cache.validar(comp, efeitos: manifests.keys.sorted())
                        // Quadro com aviso (efeito ainda carregando, camada que falhou) nao fica no cache.
                        if completo, let c = copiaParaCache(tex, compositor, comp: comp) { cache.guardar(q, c, perto: alvo ?? q) }
                        else { cache.mostrou(q) }
                    }
                    if frame !== tex { compositor.release(tex) }
                }
            } catch {
                lastWarning = error.localizedDescription
                log.error("quadro da previa falhou: \(error.localizedDescription, privacy: .public)")
            }
            rendering = false
            if let p = pending {
                pending = nil
                rendering = true
                await render(p.0, time: p.1)
            }
        }

        /// Copia o quadro para uma textura bgra8 do tamanho da tela (no maximo o da composicao).
        @MainActor
        private func copiaParaCache(_ tex: MTLTexture, _ c: Compositor, comp: Composition) -> MTLTexture? {
            guard let device, let view, let cache else { return nil }
            let ds = view.drawableSize
            var k = min(1, min(Double(max(ds.width, 1)) / Double(tex.width), Double(max(ds.height, 1)) / Double(tex.height)))
            // Como a resolucao da previa do AE: tamanho em que a composicao INTEIRA cabe no cache
            // (senao o comeco sai do cache enquanto o fim entra e o play nunca fica em tempo real).
            let quadros = max(1, Double(comp.duration) * Double(max(comp.frameRate, 1)))
            let porQuadro = Double(cache.orcamento) / quadros / 4
            let kCabe = (porQuadro / Double(tex.width * tex.height)).squareRoot()
            let kMin = 360.0 / Double(max(tex.width, tex.height))
            k = min(k, max(kCabe, kMin))
            let w = max(2, Int(Double(tex.width) * k)), h = max(2, Int(Double(tex.height) * k))
            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: w, height: h, mipmapped: false)
            d.usage = [.renderTarget, .shaderRead]
            d.storageMode = .private
            guard let t = device.makeTexture(descriptor: d), let cb = c.makeCommandBuffer() else { return nil }
            do { try c.encodeCopy(tex, to: t, in: cb) } catch { return nil }
            cb.commit()
            return t
        }

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.setNeedsDisplay()
        }

        public func draw(in view: MTKView) {
            guard let d = view.currentDrawable, let compositor,
                  let cb = compositor.makeCommandBuffer() else { return }
            if let fonte = doCache ?? frame {
                do { try compositor.encodeCopy(fonte, to: d.texture, in: cb) }
                catch { log.error("copia para a tela falhou: \(error.localizedDescription, privacy: .public)") }
            }
            cb.present(d)
            cb.commit()
        }
    }
}
