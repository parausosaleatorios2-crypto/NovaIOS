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
    /// Alfa das mascaras da camada no instante da composicao (nil = sem mascara).
    func maskTexture(for layer: Layer, at time: Float, device: MTLDevice) throws -> MTLTexture?
}

public extension LayerContentProvider {
    func maskTexture(for layer: Layer, at time: Float, device: MTLDevice) throws -> MTLTexture? { nil }
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
    private lazy var paramTextures = EffectParamTextures(device: device)

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
                           manifests: [String: EffectManifest],
                           profundidade: Int = 0) async throws {
        var guardar: [MTLTexture] = []          // texturas do pool do compositor
        var doRenderer: [MTLTexture] = []       // texturas do pool do EffectRenderer
        defer {
            for t in guardar { pool.recycle(t) }
            for t in doRenderer { renderer.release(t) }
        }
        guard let inicio = try await conteudoBase(layer, comp: comp, time: time, output: output,
                                                  cb: cb, manifests: manifests,
                                                  profundidade: profundidade, guardar: &guardar)
        else { return }
        let (base, layerSize) = inicio
        let mask = try contentProvider?.maskTexture(for: layer, at: time, device: device)
        let worldMatrix = layer.kind == .adjustment ? matrix_identity_float4x4
                                                    : comp.worldMatrix(of: layer, at: time)
        let tex = try await cadeia(layer, comp: comp, time: time, inicial: base, layerSize: layerSize,
                                   limite: layer.effects.count, output: output, cb: cb, manifests: manifests,
                                   profundidade: profundidade, guardar: &guardar, doRenderer: &doRenderer)

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
        enc.setFragmentTexture(try mask ?? whiteTexture(), index: 2)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    /// Conteudo da camada no instante, antes dos efeitos. Camada de ajuste: o que
    /// esta embaixo dela (no instante do quadro, o proprio buffer; noutro instante,
    /// as camadas de baixo desenhadas de novo).
    private func conteudoBase(_ layer: Layer, comp: Composition, time: Float, output: MTLTexture,
                              cb: MTLCommandBuffer, manifests: [String: EffectManifest],
                              profundidade: Int, emOutroTempo: Bool = false,
                              guardar: inout [MTLTexture]) async throws -> (MTLTexture, SIMD2<Float>)? {
        guard let provider = contentProvider else { return nil }
        if layer.kind == .adjustment {
            guard !layer.effects.isEmpty else { return nil }
            let c = try pool.obtain(width: output.width, height: output.height, format: output.pixelFormat)
            guardar.append(c)
            if emOutroTempo {
                try await desenharAbaixo(layer, comp: comp, time: time, into: c, cb: cb,
                                         manifests: manifests, profundidade: profundidade + 1)
            } else {
                guard let blit = cb.makeBlitCommandEncoder() else { throw RenderError.encoderFailed("blit do ajuste") }
                blit.copy(from: output, to: c)
                blit.endEncoding()
            }
            return (c, comp.size)
        }
        guard let t = try await provider.texture(for: layer, at: layer.mediaTimeAdjusted(at: time), device: device)
        else { return nil }
        // Tamanho da camada em px da composicao. Solido e forma usam uma textura
        // pequena esticada para esse tamanho.
        return (t, layer.size ?? SIMD2(Float(t.width), Float(t.height)))
    }

    /// As camadas que estao embaixo de `layer`, no instante `time`, num buffer limpo.
    private func desenharAbaixo(_ layer: Layer, comp: Composition, time: Float, into alvo: MTLTexture,
                                cb: MTLCommandBuffer, manifests: [String: EffectManifest],
                                profundidade: Int) async throws {
        let rp = MTLRenderPassDescriptor()
        rp.colorAttachments[0].texture = alvo
        rp.colorAttachments[0].loadAction = .clear
        let bg = comp.backgroundColor
        rp.colorAttachments[0].clearColor = MTLClearColor(red: Double(bg.x), green: Double(bg.y),
                                                          blue: Double(bg.z), alpha: Double(bg.w))
        rp.colorAttachments[0].storeAction = .store
        cb.makeRenderCommandEncoder(descriptor: rp)?.endEncoding()
        guard let idx = comp.layers.firstIndex(where: { $0.id == layer.id }) else { return }
        let abaixo = Set(comp.layers[(idx + 1)...].map(\.id))
        let fundo = try pool.obtain(width: alvo.width, height: alvo.height, format: alvo.pixelFormat)
        defer { pool.recycle(fundo) }
        for l in comp.visibleLayers(at: time) where abaixo.contains(l.id) {
            try? await drawLayer(l, comp: comp, time: time, into: alvo, backdrop: fundo, cb: cb,
                                 manifests: manifests, profundidade: profundidade)
        }
    }

    // MARK: efeitos de tempo (CC Wide Time, S_TimeSlice)

    private static let estagiosDeTempo: Set<String> = ["widetime", "timeslice"]

    /// Aplica os efeitos [0..<limite] da camada sobre `inicial`.
    private func cadeia(_ layer: Layer, comp: Composition, time: Float, inicial: MTLTexture,
                        layerSize: SIMD2<Float>, limite: Int, output: MTLTexture, cb: MTLCommandBuffer,
                        manifests: [String: EffectManifest], profundidade: Int,
                        guardar: inout [MTLTexture], doRenderer: inout [MTLTexture]) async throws -> MTLTexture {
        var tex = inicial
        var pularLooks = Set<Int>()
        let efeitos = Array(layer.effects.prefix(limite))
        for (i, fx) in efeitos.enumerated() where fx.enabled {
            guard let m = manifests[fx.effectID] else {
                lastFrameWarnings.append("efeito \(fx.effectID) nao carregado")
                continue
            }
            if m.stage == "mblooks" {
                // Magic Bullet Looks: a cabeca e as ferramentas logo depois dela sao UMA
                // passada do motor do Looks (como uma instancia do efeito no AE); uma
                // ferramenta sem cabeca antes roda sozinha, com forca 100.
                if pularLooks.contains(i) { continue }
                func passo(_ e: AppliedEffect, _ me: EffectManifest) -> LooksPasso? {
                    guard let t = LooksFerramentas.porManifesto[e.effectID] else { return nil }
                    let v = e.values(at: time, manifest: me)
                    return LooksPasso(codigo: t.codigo, valores: LooksFerramentas.valores(t.params, de: v),
                                      lut: e.lutPaths["lut"])
                }
                var passos: [LooksPasso] = []
                var forca: Float = 1
                if fx.effectID == LooksFerramentas.cabeca {
                    if case .float(let s)? = fx.values(at: time, manifest: m)["strength"] { forca = s / 100 }
                    var j = i + 1
                    while j < efeitos.count, let m2 = manifests[efeitos[j].effectID], m2.stage == "mblooks",
                          efeitos[j].effectID != LooksFerramentas.cabeca {
                        if efeitos[j].enabled, let p = passo(efeitos[j], m2) { passos.append(p) }
                        pularLooks.insert(j)
                        j += 1
                    }
                } else if let p = passo(fx, m) {
                    passos.append(p)
                }
                guard !passos.isEmpty else { continue }
                do {
                    let r = try renderer.renderLooks(entrada: tex, passos: passos, forca: forca,
                                                     mediaRoot: (contentProvider as? MediaContentProvider)?.mediaRoot,
                                                     cb: cb)
                    doRenderer.append(r)
                    tex = r
                    lastFrameWarnings.append(contentsOf: renderer.looksAvisos)
                } catch {
                    lastFrameWarnings.append("\(m.name): \(error.localizedDescription)")
                }
                continue
            }
            if let st = m.stage, Self.estagiosDeTempo.contains(st) {
                // Dentro de uma amostra de outro instante o efeito de tempo passa direto
                // (como no AE, que nao aninha o Wide Time).
                guard profundidade == 0 else { continue }
                do {
                    let r = try await efeitoDeTempo(st, m, fx, indice: i, layer: layer, comp: comp, time: time,
                                                    atual: tex, output: output, cb: cb, manifests: manifests,
                                                    guardar: &guardar)
                    tex = r
                } catch {
                    lastFrameWarnings.append("\(m.name): \(error.localizedDescription)")
                }
                continue
            }
            paramTextures.mediaRoot = (contentProvider as? MediaContentProvider)?.mediaRoot
            var input = EffectRenderer.Input(
                content: tex,
                comp: output,
                layerSize: layerSize,
                layerCenter: SIMD2(Float(tex.width)/2, Float(tex.height)/2),
                pixelScale: 1,
                time: time,
                frameDuration: comp.frameDuration)
            input.paramTextures = paramTextures.textures(for: fx, manifest: m)
            // Efeito que falha fica de fora; a camada continua aparecendo.
            do {
                let result = try renderer.render(m, input: input, values: fx.values(at: time, manifest: m), into: cb)
                doRenderer.append(result)
                tex = result
            } catch {
                lastFrameWarnings.append("\(m.name): \(error.localizedDescription)")
            }
        }
        return tex
    }

    /// A camada no instante `t`, com os efeitos que vem antes do efeito de tempo.
    private func amostra(_ layer: Layer, comp: Composition, t: Float, indice: Int, output: MTLTexture,
                         cb: MTLCommandBuffer, manifests: [String: EffectManifest],
                         guardar: inout [MTLTexture]) async throws -> MTLTexture? {
        var doRenderer: [MTLTexture] = []
        guard let inicio = try await conteudoBase(layer, comp: comp, time: t, output: output, cb: cb,
                                                  manifests: manifests, profundidade: 1,
                                                  emOutroTempo: true, guardar: &guardar) else { return nil }
        let (base, tam) = inicio
        let r = try await cadeia(layer, comp: comp, time: t, inicial: base, layerSize: tam, limite: indice,
                                 output: output, cb: cb, manifests: manifests, profundidade: 1,
                                 guardar: &guardar, doRenderer: &doRenderer)
        // o resultado passa para o pool do compositor (copia), o resto volta ao renderer
        if doRenderer.isEmpty { return r }
        let c = try pool.obtain(width: r.width, height: r.height, format: renderer.workingFormat)
        guardar.append(c)
        guard let blit = cb.makeBlitCommandEncoder() else { throw RenderError.encoderFailed("blit da amostra") }
        if r.pixelFormat == c.pixelFormat { blit.copy(from: r, to: c) }
        blit.endEncoding()
        for t in doRenderer { renderer.release(t) }
        return c
    }

    private struct TempoUniforms {
        var peso: Float = 1
        var modo: Int32 = 0           // 0 = peso fixo (Wide Time); 1 = fatia (Time Slice)
        var cosseno: Float = 1
        var seno: Float = 0
        var k: Float = 8
        var base: Float = 0
        var inicio: Float = 0
        var passo: Float = 1
        var indice: Float = 0
        var ultimo: Float = 0
        var aspecto: Float = 1
        var interpolar: Int32 = 0
        var opacidade: Int32 = 1
    }

    private var pipelineDeTempo: MTLRenderPipelineState?
    private func tempoPipeline() throws -> MTLRenderPipelineState {
        if let p = pipelineDeTempo { return p }
        guard let vert = library.makeFunction(name: "nova_fullscreen_vertex"),
              let frag = library.makeFunction(name: "nova_tempo_fragment") else {
            throw RenderError.functionMissing("nova_tempo_fragment", effect: "tempo")
        }
        let d = MTLRenderPipelineDescriptor()
        d.label = "tempo"
        d.vertexFunction = vert
        d.fragmentFunction = frag
        let a = d.colorAttachments[0]!
        a.pixelFormat = renderer.workingFormat
        a.isBlendingEnabled = true          // soma: cada amostra entra com o seu peso
        a.rgbBlendOperation = .add; a.alphaBlendOperation = .add
        a.sourceRGBBlendFactor = .one; a.destinationRGBBlendFactor = .one
        a.sourceAlphaBlendFactor = .one; a.destinationAlphaBlendFactor = .one
        let p = try device.makeRenderPipelineState(descriptor: d)
        pipelineDeTempo = p
        return p
    }

    private func numero(_ v: [String: EffectValue], _ id: String, _ m: EffectManifest, _ padrao: Float) -> Float {
        switch v[id] {
        case .float(let f): return f
        case .int(let i): return Float(i)
        default: return m.param(id)?.defaultValue.first ?? padrao
        }
    }

    private func efeitoDeTempo(_ estagio: String, _ m: EffectManifest, _ fx: AppliedEffect, indice: Int,
                               layer: Layer, comp: Composition, time: Float, atual: MTLTexture,
                               output: MTLTexture, cb: MTLCommandBuffer, manifests: [String: EffectManifest],
                               guardar: inout [MTLTexture]) async throws -> MTLTexture {
        let v = fx.values(at: time, manifest: m)
        let fd = comp.frameDuration
        let destino = try pool.obtain(width: atual.width, height: atual.height, format: renderer.workingFormat)
        guardar.append(destino)
        var meus: [MTLTexture] = []          // amostras de outros instantes
        defer { guardar += meus }
        let limpa = MTLRenderPassDescriptor()
        limpa.colorAttachments[0].texture = destino
        limpa.colorAttachments[0].loadAction = .clear
        limpa.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        limpa.colorAttachments[0].storeAction = .store
        cb.makeRenderCommandEncoder(descriptor: limpa)?.endEncoding()

        func somar(_ t: MTLTexture, _ u: TempoUniforms) throws {
            let rp = MTLRenderPassDescriptor()
            rp.colorAttachments[0].texture = destino
            rp.colorAttachments[0].loadAction = .load
            rp.colorAttachments[0].storeAction = .store
            guard let enc = cb.makeRenderCommandEncoder(descriptor: rp) else {
                throw RenderError.encoderFailed("encoder do tempo")
            }
            enc.setRenderPipelineState(try tempoPipeline())
            var uu = u
            withUnsafeBytes(of: &uu) { enc.setFragmentBytes($0.baseAddress!, length: MemoryLayout<TempoUniforms>.stride, index: 0) }
            enc.setFragmentTexture(t, index: 0)
            enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            enc.endEncoding()
        }
        /// Camada no instante (o proprio quadro reaproveita `atual`).
        var cache: [Int: MTLTexture] = [:]
        func quadro(_ q: Int, _ t: Float) async throws -> MTLTexture? {
            if abs(t - time) < fd * 0.25 { return atual }
            if let c = cache[q] { return c }
            let lim = max(0, min(t, comp.duration))
            let r = try await amostra(layer, comp: comp, t: lim, indice: indice, output: output, cb: cb,
                                      manifests: manifests, guardar: &meus)
            if let r { cache[q] = r }
            return r
        }

        if estagio == "widetime" {
            // CC Wide Time: a media dos quadros de -Backward a +Forward. Com Native
            // Motion Blur, sub-quadros entre eles. No maximo 25 imagens por quadro.
            let fwd = max(0, Int(numero(v, "forwardSteps", m, 3).rounded()))
            let back = max(0, Int(numero(v, "backwardSteps", m, 3).rounded()))
            let mb = numero(v, "nativeMotionBlur", m, 0) != 0
            let sub = mb ? 4 : 1
            var desl: [Float] = []
            for passo in (-back * sub)...(fwd * sub) { desl.append(Float(passo) / Float(sub)) }
            if desl.count > 25 {
                let n = desl.count
                desl = (0..<25).map { desl[Int((Float($0) / 24 * Float(n - 1)).rounded())] }
            }
            let peso = 1 / Float(desl.count)
            for (k, d) in desl.enumerated() {
                let t = time + d * fd
                guard let q = try await quadro(k * 1000 + Int((d * 100).rounded()), t) else { continue }
                var u = TempoUniforms(); u.peso = peso; u.modo = 0
                try somar(q, u)
            }
            return destino
        }

        // S_TimeSlice (porte de FatiaDoTempo do APK).
        let angulo = Double(numero(v, "sliceDirection", m, -90)) * .pi / 180
        let fatias = max(Double(numero(v, "sliceNumber", m, 12)), 1)
        let interp = numero(v, "interpFrames", m, 0) != 0
        let opac = Int32(numero(v, "opacity", m, 1))
        let cosA = cos(angulo), senA = sin(angulo)
        let k = fatias / 1.5
        let aspecto = Double(atual.height) / Double(max(atual.width, 1))
        let base = Double(time / fd) + Double(numero(v, "frameOffset", m, 0))
        let alcance = (abs(senA) * aspecto + abs(cosA)) * k
        let lo = Int(floor(base - alcance)), hi = Int(floor(base + alcance))
        let total = hi - lo + 1 + (interp ? 1 : 0)
        let passo = max(1, Int(ceil(Double(total) / 64)))
        let n = (hi - lo) / passo + (interp ? 1 : 0)
        for j in 0...max(n, 0) {
            let f = lo + j * passo
            guard let q = try await quadro(f, Float(f) * fd) else { continue }
            var u = TempoUniforms()
            u.modo = 1; u.cosseno = Float(cosA); u.seno = Float(senA); u.k = Float(k)
            u.base = Float(base); u.inicio = Float(lo); u.passo = Float(passo)
            u.indice = Float(j); u.ultimo = Float(max(n, 0)); u.aspecto = Float(aspecto)
            u.interpolar = interp ? 1 : 0; u.opacidade = opac
            try somar(q, u)
        }
        return destino
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
        enc.setFragmentTexture(try whiteTexture(), index: 2)
        enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        enc.endEncoding()
    }

    public func makeCommandBuffer() -> MTLCommandBuffer? { queue.makeCommandBuffer() }

    private var white1x1: MTLTexture?
    /// Mascara "tudo visivel".
    private func whiteTexture() throws -> MTLTexture {
        if let white1x1 { return white1x1 }
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                         width: 1, height: 1, mipmapped: false)
        d.usage = [.shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: 1, height: 1)
        }
        let one: [UInt8] = [255, 255, 255, 255]
        t.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: one, bytesPerRow: 4)
        white1x1 = t
        return t
    }

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
