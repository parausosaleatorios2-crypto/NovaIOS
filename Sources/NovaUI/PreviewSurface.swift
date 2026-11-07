//
//  PreviewSurface.swift
//  NovaUI
//
//  A superficie Metal onde a composicao e desenhada. Usa MTKView por UIViewRepresentable:
//  SwiftUI sozinho nao da acesso ao drawable.
//

import SwiftUI
import MetalKit
import os

public struct PreviewSurface: UIViewRepresentable {
    let composition: Composition
    let time: Float

    public init(composition: Composition, time: Float) {
        self.composition = composition
        self.time = time
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public func makeUIView(context: Context) -> MTKView {
        let v = MTKView()
        v.device = MTLCreateSystemDefaultDevice()
        v.colorPixelFormat = .bgra8Unorm
        v.framebufferOnly = false
        v.isOpaque = false
        v.backgroundColor = .clear
        v.enableSetNeedsDisplay = true
        v.isPaused = true
        v.delegate = context.coordinator
        context.coordinator.attach(view: v)
        return v
    }

    public func updateUIView(_ v: MTKView, context: Context) {
        context.coordinator.composition = composition
        context.coordinator.time = time
        v.setNeedsDisplay()
    }

    public final class Coordinator: NSObject, MTKViewDelegate {
        var composition: Composition?
        var time: Float = 0
        private var queue: MTLCommandQueue?
        private let log = Logger(subsystem: "com.novavision.editor", category: "Preview")

        func attach(view: MTKView) { queue = view.device?.makeCommandQueue() }

        public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        public func draw(in view: MTKView) {
            guard let d = view.currentDrawable,
                  let rp = view.currentRenderPassDescriptor,
                  let cb = queue?.makeCommandBuffer() else { return }
            // Por enquanto so limpa com a cor de fundo da composicao.
            // O Compositor entra aqui quando o provedor de conteudo das camadas
            // estiver escrito — veja Docs/PENDENCIAS.md.
            let bg = composition?.backgroundColor ?? SIMD4<Float>(0, 0, 0, 1)
            rp.colorAttachments[0].loadAction = .clear
            rp.colorAttachments[0].clearColor = MTLClearColor(
                red: Double(bg.x), green: Double(bg.y), blue: Double(bg.z), alpha: Double(bg.w))
            cb.makeRenderCommandEncoder(descriptor: rp)?.endEncoding()
            cb.present(d)
            cb.commit()
        }
    }
}
