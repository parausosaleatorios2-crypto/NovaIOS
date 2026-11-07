//
//  EffectRenderer.swift
//  NovaEngine
//
//  Executa um efeito em Metal: monta o buffer de uniforms a partir do manifesto,
//  resolve as texturas, roda os passes na ordem do XML e devolve a textura final.
//
//  Equivale ao motor de efeitos do app Android, que interpretava o mesmo XML e
//  rodava os mesmos shaders em OpenGL ES 3.0.
//

import Metal
import MetalKit
import simd
import os

// MARK: - Erros

public enum RenderError: LocalizedError {
    case noDevice
    case libraryMissing(String)
    case functionMissing(String, effect: String)
    case pipelineFailed(String, underlying: String)
    case textureAllocFailed(width: Int, height: Int)
    case missingInput(String, effect: String)
    case encoderFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noDevice:
            return "Este aparelho nao tem Metal"
        case .libraryMissing(let n):
            return "Biblioteca de shaders nao encontrada: \(n)"
        case .functionMissing(let f, let e):
            return "Shader \(f) do efeito \(e) nao esta na biblioteca. Rode Tools/gerar-shaders.sh."
        case .pipelineFailed(let f, let u):
            return "Nao consegui compilar o pipeline de \(f): \(u)"
        case .textureAllocFailed(let w, let h):
            return "Sem memoria para uma textura \(w)x\(h)"
        case .missingInput(let t, let e):
            return "Falta a textura '\(t)' para o efeito \(e)"
        case .encoderFailed(let m):
            return "Falha no encoder: \(m)"
        }
    }
}

// MARK: - Valores de parametro

/// Valor concreto de um parametro num instante. O avaliador de keyframes
/// (ver Animated.swift) produz estes valores.
public enum EffectValue: Sendable, Equatable {
    case float(Float)
    case int(Int32)
    case vec2(SIMD2<Float>)
    case vec3(SIMD3<Float>)
    case vec4(SIMD4<Float>)

    var floats: [Float] {
        switch self {
        case .float(let v): return [v]
        case .int(let v):   return [Float(bitPattern: UInt32(bitPattern: v))]
        case .vec2(let v):  return [v.x, v.y]
        case .vec3(let v):  return [v.x, v.y, v.z]
        case .vec4(let v):  return [v.x, v.y, v.z, v.w]
        }
    }
}

// MARK: - Pool de texturas

/// Reaproveita texturas intermediarias. Sem isto, um efeito multipass em 4K
/// aloca e descarta dezenas de megabytes por quadro.
public final class TexturePool {
    private let device: MTLDevice
    private var free: [String: [MTLTexture]] = [:]
    private let lock = NSLock()
    public private(set) var allocated = 0

    public init(device: MTLDevice) { self.device = device }

    private func key(_ w: Int, _ h: Int, _ f: MTLPixelFormat) -> String { "\(w)x\(h)x\(f.rawValue)" }

    public func obtain(width: Int, height: Int,
                       format: MTLPixelFormat = .rgba16Float) throws -> MTLTexture {
        let w = max(1, width), h = max(1, height)
        lock.lock()
        if var list = free[key(w, h, format)], let t = list.popLast() {
            free[key(w, h, format)] = list
            lock.unlock()
            return t
        }
        lock.unlock()
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: w,
                                                         height: h, mipmapped: false)
        d.usage = [.shaderRead, .shaderWrite, .renderTarget]
        d.storageMode = .private
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: w, height: h)
        }
        allocated += 1
        return t
    }

    public func recycle(_ t: MTLTexture) {
        lock.lock(); defer { lock.unlock() }
        free[key(t.width, t.height, t.pixelFormat), default: []].append(t)
    }

    public func drain() {
        lock.lock(); free.removeAll(); lock.unlock()
    }
}

// MARK: - Renderer

public final class EffectRenderer {

    public let device: MTLDevice
    private let queue: MTLCommandQueue
    private let library: MTLLibrary
    private let pool: TexturePool
    private let sampler: MTLSamplerState
    private let log = Logger(subsystem: "com.novavision.editor", category: "EffectRenderer")

    private var pipelines: [String: MTLRenderPipelineState] = [:]
    private let pipelineLock = NSLock()

    /// Formato de trabalho. rgba16Float preserva faixa alta — os efeitos do AE
    /// trabalham em float e estourar em 8 bits muda o resultado.
    public var workingFormat: MTLPixelFormat = .rgba16Float

    public init(device: MTLDevice? = nil, library: MTLLibrary? = nil) throws {
        guard let dev = device ?? MTLCreateSystemDefaultDevice() else { throw RenderError.noDevice }
        self.device = dev
        guard let q = dev.makeCommandQueue() else { throw RenderError.noDevice }
        self.queue = q
        if let library {
            self.library = library
        } else if let l = try? dev.makeDefaultLibrary(bundle: .main) {
            self.library = l
        } else if let l = dev.makeDefaultLibrary() {
            self.library = l
        } else {
            throw RenderError.libraryMissing("default.metallib")
        }
        self.pool = TexturePool(device: dev)

        let sd = MTLSamplerDescriptor()
        sd.minFilter = .linear; sd.magFilter = .linear; sd.mipFilter = .notMipmapped
        // CLAMP_TO_EDGE: e o que o motor Android usava, e varios shaders contam com isso.
        sd.sAddressMode = .clampToEdge; sd.tAddressMode = .clampToEdge
        guard let s = dev.makeSamplerState(descriptor: sd) else { throw RenderError.noDevice }
        self.sampler = s
    }

    // MARK: pipeline

    private func pipeline(for m: EffectManifest) throws -> MTLRenderPipelineState {
        pipelineLock.lock(); defer { pipelineLock.unlock() }
        if let p = pipelines[m.id] { return p }
        guard let frag = library.makeFunction(name: m.functionName) else {
            throw RenderError.functionMissing(m.functionName, effect: m.name)
        }
        guard let vert = library.makeFunction(name: "nova_fullscreen_vertex") else {
            throw RenderError.functionMissing("nova_fullscreen_vertex", effect: m.name)
        }
        let d = MTLRenderPipelineDescriptor()
        d.label = m.functionName
        d.vertexFunction = vert
        d.fragmentFunction = frag
        d.colorAttachments[0].pixelFormat = workingFormat
        do {
            let p = try device.makeRenderPipelineState(descriptor: d)
            pipelines[m.id] = p
            return p
        } catch {
            throw RenderError.pipelineFailed(m.functionName, underlying: error.localizedDescription)
        }
    }

    /// Compila os pipelines em segundo plano. Chamar quando o usuario abre o
    /// painel de efeitos, para o primeiro toque nao engasgar.
    public func warmUp(_ manifests: [EffectManifest]) {
        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            for m in manifests {
                _ = try? self.pipeline(for: m)
            }
        }
    }

    // MARK: uniforms

    /// Empacota os parametros na ordem do manifesto, respeitando o alinhamento do MSL.
    /// Esta ordem tem de bater com o struct <slug>Params gerado por glsl2msl.py,
    /// que emite os campos na mesma ordem em que aparecem no XML.
    func packParams(_ m: EffectManifest, values: [String: EffectValue]) -> [UInt8] {
        var bytes: [UInt8] = []

        func align(_ n: Int) {
            let r = bytes.count % n
            if r != 0 { bytes.append(contentsOf: Array(repeating: 0, count: n - r)) }
        }
        func push(_ f: Float) { withUnsafeBytes(of: f) { bytes.append(contentsOf: $0) } }
        func push(_ i: Int32) { withUnsafeBytes(of: i) { bytes.append(contentsOf: $0) } }

        for p in m.params {
            let v = values[p.id]
            switch p.kind.floatCount {
            case 1:
                align(4)
                if p.kind.isInteger {
                    if case .int(let i) = v { push(i) }
                    else if case .float(let f) = v { push(Int32(f)) }
                    else { push(Int32(p.defaultValue.first ?? 0)) }
                } else {
                    if case .float(let f) = v { push(f) }
                    else if case .int(let i) = v { push(Float(i)) }
                    else { push(p.defaultValue.first ?? 0) }
                }
            case 2:
                align(8)
                if case .vec2(let s) = v { push(s.x); push(s.y) }
                else { push(p.defaultValue.first ?? 0); push(p.defaultValue.count > 1 ? p.defaultValue[1] : 0) }
            case 3:
                align(16)
                if case .vec3(let s) = v { push(s.x); push(s.y); push(s.z) }
                else { for i in 0..<3 { push(p.defaultValue.count > i ? p.defaultValue[i] : 0) } }
                push(Float(0))   // float3 ocupa 16 bytes no MSL
            default:
                align(16)
                if case .vec4(let s) = v { push(s.x); push(s.y); push(s.z); push(s.w) }
                else { for i in 0..<4 { push(p.defaultValue.count > i ? p.defaultValue[i] : 0) } }
            }
        }
        align(16)
        if bytes.isEmpty { bytes = Array(repeating: 0, count: 16) }  // struct vazio
        return bytes
    }

    // MARK: render

    public struct Input {
        public var content: MTLTexture
        public var comp: MTLTexture?
        public var files: [String: MTLTexture]
        public var layerSize: SIMD2<Float>
        public var layerCenter: SIMD2<Float>
        public var pixelScale: Float
        public var time: Float
        public var frameDuration: Float

        public init(content: MTLTexture, comp: MTLTexture? = nil,
                    files: [String: MTLTexture] = [:],
                    layerSize: SIMD2<Float>? = nil,
                    layerCenter: SIMD2<Float>? = nil,
                    pixelScale: Float = 1,
                    time: Float = 0, frameDuration: Float = 1.0/30.0) {
            self.content = content
            self.comp = comp
            self.files = files
            let w = Float(content.width), h = Float(content.height)
            self.layerSize = layerSize ?? SIMD2(w, h)
            self.layerCenter = layerCenter ?? SIMD2(w/2, h/2)
            self.pixelScale = pixelScale
            self.time = time
            self.frameDuration = frameDuration
        }
    }

    /// Roda o efeito e devolve a textura resultante.
    /// A textura devolvida sai do pool — devolva com `release(_:)` quando terminar.
    @discardableResult
    public func render(_ m: EffectManifest,
                       input: Input,
                       values: [String: EffectValue],
                       into commandBuffer: MTLCommandBuffer? = nil) throws -> MTLTexture {

        let w = input.content.width, h = input.content.height
        let cb = commandBuffer ?? queue.makeCommandBuffer()
        guard let cb else { throw RenderError.encoderFailed("sem command buffer") }

        let state = try pipeline(for: m)

        // Texturas-buffer declaradas no XML (alvos dos passes intermediarios).
        var buffers: [String: MTLTexture] = [:]
        for t in m.textures where t.source == .buffer {
            buffers[t.id] = try pool.obtain(width: w, height: h, format: workingFormat)
        }

        // Quantas vezes os passes repetem.
        var iterations = 1
        if let ip = m.iterationsParam {
            if case .int(let i)? = values[ip] { iterations = max(1, min(Int(i), 64)) }
            else if case .float(let f)? = values[ip] { iterations = max(1, min(Int(f), 64)) }
            else if let p = m.param(ip) { iterations = max(1, Int(p.defaultValue.first ?? 1)) }
        }

        var uni = EngineUniforms()
        uni.sync(screenSize: SIMD2(Float(w), Float(h)),
                 layerSize: input.layerSize,
                 layerCenter: input.layerCenter,
                 pixelScale: input.pixelScale,
                 time: input.time,
                 frameDuration: input.frameDuration)
        uni.acIterationCount = Int32(iterations)

        let paramBytes = packParams(m, values: values)

        var current = input.content
        var scratch: MTLTexture? = nil
        var passIndex: Int32 = 0

        for iter in 0..<iterations {
            uni.acIteration = Int32(iter)
            for pass in m.passes {
                let target: MTLTexture
                if let name = pass.target, let b = buffers[name] {
                    target = b
                } else {
                    let t = try pool.obtain(width: w, height: h, format: workingFormat)
                    if let old = scratch, old !== input.content { pool.recycle(old) }
                    scratch = t
                    target = t
                }

                let rp = MTLRenderPassDescriptor()
                rp.colorAttachments[0].texture = target
                rp.colorAttachments[0].loadAction = .clear
                rp.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
                rp.colorAttachments[0].storeAction = .store

                guard let enc = cb.makeRenderCommandEncoder(descriptor: rp) else {
                    throw RenderError.encoderFailed("render encoder do pass \(passIndex)")
                }
                enc.label = "\(m.functionName) pass \(passIndex)"
                enc.setRenderPipelineState(state)

                uni.acPass = passIndex
                withUnsafeBytes(of: uni) { enc.setFragmentBytes($0.baseAddress!, length: $0.count, index: 0) }
                paramBytes.withUnsafeBytes { enc.setFragmentBytes($0.baseAddress!, length: $0.count, index: 1) }
                enc.setFragmentSamplerState(sampler, index: 0)

                // Resolve cada textura declarada no XML.
                var infoIndex = 2
                for (slot, t) in m.textures.enumerated() {
                    let tex: MTLTexture?
                    switch t.source {
                    case .content:        tex = current
                    case .buffer:         tex = buffers[t.id]
                    case .comp, .scene:   tex = input.comp ?? current
                    case .file:           tex = input.files[t.id]
                    }
                    guard let tex else {
                        enc.endEncoding()
                        throw RenderError.missingInput(t.id, effect: m.name)
                    }
                    enc.setFragmentTexture(tex, index: slot)
                    var info = NovaTexInfo(size: SIMD2(Float(tex.width), Float(tex.height)))
                    withUnsafeBytes(of: &info) {
                        enc.setFragmentBytes($0.baseAddress!, length: $0.count, index: infoIndex)
                    }
                    infoIndex += 1
                }

                enc.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                enc.endEncoding()

                if pass.target == nil { current = target }
                passIndex += 1
            }
        }

        for (_, b) in buffers where b !== current { pool.recycle(b) }

        if commandBuffer == nil { cb.commit() }
        return current
    }

    public func release(_ t: MTLTexture) { pool.recycle(t) }
    public func drainPool() { pool.drain() }
}
