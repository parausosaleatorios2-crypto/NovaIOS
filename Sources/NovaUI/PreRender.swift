//
//  PreRender.swift
//  NovaUI
//
//  "Pre-renderizar" o grupo, como no Blurrr: o conteudo do grupo vira um video (HEVC com
//  transparencia) na pasta de midia do projeto, e a previa passa a tocar esse video no lugar
//  de montar as camadas de dentro. Editou algo dentro do grupo, a assinatura muda e o grupo
//  volta a ser montado ao vivo (o botao mostra "Pre-render desatualizado").
//

import Foundation
import Metal

enum PreRender {

    /// Grava o conteudo do grupo e devolve o pre-render para por na camada.
    static func gerar(grupo: UUID, comp: Composition, mediaRoot: URL, manifests: [String: EffectManifest],
                      progresso: @escaping @Sendable (Double) -> Void) async throws -> PreRenderDoGrupo {
        guard let c = comp.composicaoDoGrupo(grupo), let assinatura = comp.assinaturaDoGrupo(grupo) else {
            throw MediaError.writerFailed("grupo")
        }
        guard let device = MTLCreateSystemDefaultDevice() else { throw RenderError.noDevice }
        let compositor = try Compositor(renderer: try EffectRenderer(device: device))
        let provider = MediaContentProvider(mediaRoot: mediaRoot, device: device)
        compositor.contentProvider = provider

        var s = ExportSettings()
        s.width = c.width & ~1; s.height = c.height & ~1
        s.frameRate = c.frameRate
        s.transparentBackground = true
        s.container = .mov; s.codec = .hevc
        s.includeAudio = false
        s.bitrate = Int(max(4_000_000, Double(s.width * s.height) * Double(s.frameRate) * 0.15))

        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: s.width, height: s.height,
                                                         mipmapped: false)
        d.usage = [.renderTarget, .shaderRead]
        d.storageMode = .shared
        guard let alvo = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: s.width, height: s.height)
        }
        let pasta = mediaRoot.appendingPathComponent("prerender", isDirectory: true)
        try FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        let nome = "prerender/\(grupo.uuidString)-\(assinatura).mov"
        let url = mediaRoot.appendingPathComponent(nome)
        try? FileManager.default.removeItem(at: url)
        // os pre-renders antigos deste grupo saem
        if let velhos = try? FileManager.default.contentsOfDirectory(atPath: pasta.path) {
            for v in velhos where v.hasPrefix(grupo.uuidString) { try? FileManager.default.removeItem(at: pasta.appendingPathComponent(v)) }
        }
        let ex = VideoExporter(device: device)
        let transparente = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        _ = try await ex.export(composition: c, to: url, settings: s, renderFrame: { _, t in
            let frame = try await compositor.renderFrame(c, at: t, manifests: manifests)
            defer { compositor.release(frame) }
            guard let cb = compositor.makeCommandBuffer() else { throw RenderError.encoderFailed("pre-render") }
            try compositor.encodeCopy(frame, to: alvo, background: transparente, in: cb)
            cb.commit()
            cb.waitUntilCompleted()
            return alvo
        }, onProgress: { p in
            if case .frame(let i, let total) = p { progresso(Double(i + 1) / Double(max(total, 1))) }
        })
        _ = provider
        return PreRenderDoGrupo(arquivo: nome, assinatura: assinatura)
    }
}
