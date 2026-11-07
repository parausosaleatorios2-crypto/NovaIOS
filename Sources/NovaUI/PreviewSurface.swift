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

    public init(composition: Composition, time: Float, mediaRoot: URL,
                manifests: [String: EffectManifest] = [:]) {
        self.composition = composition
        self.time = time
        self.mediaRoot = mediaRoot
        self.manifests = manifests
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
        context.coordinator.request(composition, time: time,
                                    mediaRoot: mediaRoot, manifests: manifests)
    }

    public final class Coordinator: NSObject, MTKViewDelegate {
        private weak var view: MTKView?
        private var device: MTLDevice?
        private var compositor: Compositor?
        private var provider: MediaContentProvider?
        private var frame: MTLTexture?
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

        func request(_ comp: Composition, time: Float, mediaRoot: URL,
                     manifests: [String: EffectManifest]) {
            guard let device else { return }
            self.manifests = manifests
            if provider?.mediaRoot != mediaRoot {
                provider = MediaContentProvider(mediaRoot: mediaRoot, device: device)
                compositor?.contentProvider = provider
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
                    let tex = try await compositor.renderFrame(comp, at: time, manifests: manifests)
                    if let old = frame { compositor.release(old) }
                    frame = tex
                    lastWarning = compositor.lastFrameWarnings.first
                    view?.setNeedsDisplay()
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

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.setNeedsDisplay()
        }

        public func draw(in view: MTKView) {
            guard let d = view.currentDrawable, let compositor,
                  let cb = compositor.makeCommandBuffer() else { return }
            if let frame {
                do { try compositor.encodeCopy(frame, to: d.texture, in: cb) }
                catch { log.error("copia para a tela falhou: \(error.localizedDescription, privacy: .public)") }
            }
            cb.present(d)
            cb.commit()
        }
    }
}
