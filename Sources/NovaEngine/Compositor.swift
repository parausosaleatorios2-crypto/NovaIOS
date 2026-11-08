//
//  Compositor.swift
//  NovaEngine
//
//  Monta um quadro da composicao: desenha cada camada visivel na ordem,
//  aplica a cadeia de efeitos de cada uma e mescla no buffer da composicao.
//

import Metal
import MetalKit
import simd
import os

public protocol LayerContentProvider: AnyObject {
    /// Devolve a textura do conteudo de uma camada num instante.
    /// Video vem do decodificador; imagem e texto vem de cache.
    func texture(for layer: Layer, at mediaTime: Float,
                 device: MTLDevice) async throws -> MTLTexture?
}

public final class Compositor {

    private let renderer: EffectRenderer
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pool: TexturePool
    private let log = Logger(subsystem: "com.novavision.editor", category: "Compositor")

    private var blendPipelines: [BlendMode: MTLRenderPipelineState] = [:]
    private let library: MTLLibrary

    public weak var contentProvider: LayerContentProvider?

    /// Erros de camadas individuais num quadro. O quadro sai mesmo assim —
    /// uma camada quebrada nao pode derrubar o preview inteiro.
    public private(set) var lastFrameWarnings: [String] = []

    public init(renderer: EffectRenderer) throws {
        self.renderer = renderer
        self.device = renderer.device
        guard let q = device.makeCommandQueue() else { throw RenderError.noDevice }
        self.queue = q
        self.pool = TexturePool(device: device)
        guard let l = (try? device.makeDefaultLibrary(bundle: .main)) ?? device.makeDefaultLibrary()
        else { throw RenderError.libraryMissing("default.metallib") }
        self.library = l
    }

    // MARK: pipeline de mescla

    private func blendPipeline(_ mode: BlendMode) throws -> MTLRenderPipelineState {
        if let p = blendPipelines[mode] { return p }
        guard let vert = library.makeFunction(name: "nova_fullscreen_vertex"),
              let frag = library.makeFunction(name: "nova_blend_fragment") else {
            throw RenderError.functionMissing("nova_blend_fragment", effect: "compositor")
        }
        let d = MTLRenderPipelineDescriptor()
        d.label = "blend.\(mode.rawValue)"
        d.vertexFunction = vert
        d.fragmentFunction = frag
        d.colorAttachments[0].pixelFormat = renderer.workingFormat
        // A mescla inteira acontece no shader, que le o fundo (copia da
        // composicao) — os modos do AE precisam dele. Sem mescla fixa.
        do {
            let p = try device.makeRenderPipelineState(descriptor: d)
            blendPipelines[mode] = p
            return p
        } catch {
            throw RenderError.pipelineFailed("blend", underlying: error.localizedDescription)
        }
    }

    // MARK: quadro

    public struct BlendUniforms {
        var mode: Int32 = 0
        var opacity: Float = 1
        var layerToScreen = matrix_identity_float4x4
        var layerSize = SIMD2<Float>(1, 1)
        var screenSize = SIMD2<Float>(1, 1)
    }

    /// Desenha um quadro da composicao. A textura devolvida sai do pool interno.
    public func renderFrame(_ comp: Composition, at time: Float,
                            registry: EffectRegistry? = nil,
                            manifests: [String: EffectManifest] = [:]) async throws -> MTLTexture {
        lastFrameWarnings = []
        let w = comp.width, h = comp.height
        let output = try pool.obtain(width: w, height: h, format: renderer.workingFormat)

        guard let cb = queue.makeCommandBuffer() else {
            throw RenderError.encoderFailed("command buffer do quadro")
        }
        cb.label = "frame @\(time)s"

        // Limpa com a cor de fundo da composicao.
        let clear = MTLRenderPassDescriptor()
        clear.colorAttachments[0].texture = output
        clear.colorAttachments[0].loadAction = .clear
        let bg = comp.backgroundColor
        clear.colorAttachments[0].clearColor =
            MTLClearColor(red: Double(bg.x), green: Double(bg.y),
                          blue: Double(bg.z), alpha: Double(bg.w))
        clear.colorAttachments[0].storeAction = .store
        cb.makeRenderCommandEncoder(descriptor: clear)?.endEncoding()

        // Copia do fundo que cada camada le para se mesclar.
        let backdrop = try pool.obtain(width: w, height: h, format: renderer.workingFormat)
        defer { pool.recycle(backdrop) }

        for layer in comp.visibleLayers(at: time) {
            do {
                try await drawLayer(layer, comp: comp, time: time,
                                    into: output, backdrop: backdrop,
                                    cb: cb, manifests: manifests)
            } catch {
                let msg = "\(layer.name): \(error.localizedDescription)"
                lastFrameWarnings.append(msg)
                log.error("camada falhou — \(msg, privacy: .public)")
            }
        }

        cb.commit()
        cb.waitUntilCompleted()
        if let e = cb.error {
            pool.recycle(output)
            throw RenderError.encoderFailed(e.localizedDescription)
        }
        return output
    }

    private func drawLayer(_ layer: Layer, comp: Composition, time: Float,
                           into output: MTLTexture, backdrop: MTLTexture,
                           cb: MTLCommandBuffer,
                           manifests: [String: EffectManifest]) async throws {
        guard let provider = contentProvider else { return }
        let mt = layer.mediaTime(at: time)
        guard var tex = try await provider.texture(for: layer, at: mt, device: device) else { return }
        // Tamanho da camada em px da composicao. Solido e forma usam uma textura
        // pequena esticada para esse tamanho.
        let layerSize = layer.size ?? SIMD2(Float(tex.width), Float(tex.height))

        // Cadeia de efeitos da camada.
        let worldMatrix = comp.worldMatrix(of: layer, at: time)
        var owned: MTLTexture? = nil
        for fx in layer.effects where fx.enabled {
            guard let m = manifests[fx.effectID] else {
                lastFrameWarnings.append("efeito \(fx.effectID) nao carregado")
                continue
            }
            let input = EffectRenderer.Input(
                content: tex,
                comp: output,
                layerSize: layerSize,
                layerCenter: SIMD2(Float(tex.width)/2, Float(tex.height)/2),
                pixelScale: 1,
                time: time,
                frameDuration: comp.frameDuration)
            // Efeito que falha fica de fora; a camada continua aparecendo.
            let result: MTLTexture
            do {
                result = try renderer.render(m, input: input,
                                             values: fx.values(at: time, manifest: m),
                                             into: cb)
            } catch {
                lastFrameWarnings.append("\(m.name): \(error.localizedDescription)")
                continue
            }
            if let o = owned { renderer.release(o) }
            owned = result
            tex = result
        }
        defer { if let o = owned { renderer.release(o) } }

        // Fundo atual -> copia que o shader le.
        guard let blit = cb.makeBlitCommandEncoder() else {
            throw RenderError.encoderFailed("blit do fundo")
        }
        blit.copy(from: output, to: backdrop)
        blit.endEncoding()

        // Mescla no buffer da composicao.
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = output
        rp.colorAttachments[0].loadAction = .load
        rp.colorAttachments[0].storeAction = .store
        guard let enc = cb.makeRenderCommandEncoder(descriptor: rp) else {
            throw RenderError.encoderFailed("encoder de mescla")
        }
        enc.label = "blend \(layer.name)"
        enc.setRenderPipelineState(try blendPipeline(layer.blendMode))

        var u = BlendUniforms()
        u.mode = Int32(BlendMode.allCases.firstIndex(of: layer.blendMode) ?? 0)
        u.opacity = layer.transform.alpha(at: time)
        // O shader leva o pixel da TELA para a camada: precisa da inversa.
        u.layerToScreen = worldMatrix.inverse
        u.layerSize = layerSize
        u.screenSize = comp.size
        withUnsafeBytes(of: u) { enc.setFragmentBytes($0.baseAddress!, length: MemoryLayout<BlendUniforms>.stride, index: 0) }
        enc.setFragmentTexture(tex, index: 0)
        enc.setFragmentTexture(backdrop, index: 1)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    public func release(_ t: MTLTexture) { pool.recycle(t) }

    // MARK: copia para a tela / para o exportador

    private var copyPipelines: [MTLPixelFormat: MTLRenderPipelineState] = [:]

    private func copyPipeline(_ format: MTLPixelFormat) throws -> MTLRenderPipelineState {
        if let p = copyPipelines[format] { return p }
        guard let vert = library.makeFunction(name: "nova_fullscreen_vertex"),
              let frag = library.makeFunction(name: "nova_blend_fragment") else {
            throw RenderError.functionMissing("nova_blend_fragment", effect: "copia")
        }
        let d = MTLRenderPipelineDescriptor()
        d.label = "copy.\(format.rawValue)"
        d.vertexFunction = vert
        d.fragmentFunction = frag
        d.colorAttachments[0].pixelFormat = format
        do {
            let p = try device.makeRenderPipelineState(descriptor: d)
            copyPipelines[format] = p
            return p
        } catch {
            throw RenderError.pipelineFailed("copia", underlying: error.localizedDescription)
        }
    }

    /// Desenha `source` (um quadro da composicao) esticado em `target`, sobre
    /// `background`. Serve a previa (drawable BGRA) e o exportador.
    public func encodeCopy(_ source: MTLTexture, to target: MTLTexture,
                           background: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0),
                           in cb: MTLCommandBuffer) throws {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = target
        rp.colorAttachments[0].loadAction = .clear
        rp.colorAttachments[0].clearColor = background
        rp.colorAttachments[0].storeAction = .store
        guard let enc = cb.makeRenderCommandEncoder(descriptor: rp) else {
            throw RenderError.encoderFailed("encoder de copia")
        }
        enc.setRenderPipelineState(try copyPipeline(target.pixelFormat))
        var u = BlendUniforms()
        u.mode = 0
        u.opacity = 1
        let sx = Float(source.width) / Float(max(1, target.width))
        let sy = Float(source.height) / Float(max(1, target.height))
        u.layerToScreen = simd_float4x4(diagonal: SIMD4(sx, sy, 1, 1))
        u.layerSize = SIMD2(Float(source.width), Float(source.height))
        u.screenSize = SIMD2(Float(target.width), Float(target.height))
        withUnsafeBytes(of: u) { enc.setFragmentBytes($0.baseAddress!, length: MemoryLayout<BlendUniforms>.stride, index: 0) }
        enc.setFragmentTexture(source, index: 0)
        enc.setFragmentTexture(try clearTexture(), index: 1)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    public func makeCommandBuffer() -> MTLCommandBuffer? { queue.makeCommandBuffer() }

    private var clear1x1: MTLTexture?
    /// Fundo transparente para a copia (previa/exportacao).
    private func clearTexture() throws -> MTLTexture {
        if let clear1x1 { return clear1x1 }
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                         width: 1, height: 1, mipmapped: false)
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: 1, height: 1)
        }
        let z: [UInt8] = [0, 0, 0, 0]
        t.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: z, bytesPerRow: 4)
        clear1x1 = t
        return t
    }
}
