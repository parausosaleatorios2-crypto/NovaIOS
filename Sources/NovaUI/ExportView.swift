//
//  ExportView.swift
//  NovaUI
//
//  Exportar video neste aparelho.
//
//  Do APK: o servico com.novaeditor.export.ServicoDeExportacao segura o export
//  em primeiro plano (acoes CANCELAR e TERMINAR); a tela tem «Exportar com fundo
//  transparente», «Exportar o audio» («Desligado, o video sai mudo»),
//  «Exportacao pronta» e «Como no Alight Motion: o que voce exporta aparece numa
//  tela para ver e compartilhar».
//
//  Aqui: o Compositor monta cada quadro, o VideoExporter grava (H.264/HEVC, ou
//  HEVC com alfa em .mov), o AudioMux junta o som dos videos, e o resultado abre
//  numa tela com Salvar na galeria e Compartilhar.
//

import SwiftUI
import AVKit
import UIKit
import Metal
import Photos
import ImageIO
import UniformTypeIdentifiers
import os

public struct ExportSheet: View {
    let composition: Composition
    let mediaRoot: URL
    let manifests: [String: EffectManifest]
    let time: Float

    /// «Exportar vídeo», «Exportando GIF», «Exportar PNGs» (strings do APK).
    enum Formato: String, CaseIterable { case video, gif, png }
    @State private var formato: Formato = .video
    @State private var settings: ExportSettings
    @State private var phase: Phase = .options
    @State private var progress: Double = 0
    @State private var exporter: VideoExporter?
    @State private var savedToPhotos: String?
    @Environment(\.dismiss) private var dismiss

    enum Phase: Equatable {
        case options, running, done(URL), failed(String)
    }

    public init(composition: Composition, mediaRoot: URL, manifests: [String: EffectManifest],
                time: Float = 0) {
        self.composition = composition
        self.mediaRoot = mediaRoot
        self.manifests = manifests
        self.time = time
        var s = ExportSettings()
        s.width = composition.width; s.height = composition.height
        s.frameRate = composition.frameRate
        s.transparentBackground = composition.backgroundColor.w < 1
        if s.transparentBackground { s.container = .mov; s.codec = .hevc }
        _settings = State(initialValue: s)
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .options: options
                case .running: running
                case .done(let url): done(url)
                case .failed(let m): failed(m)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NovaTheme.background)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase == .running {
                        Button("Cancelar export".loc) { Task { await exporter?.cancel() } }
                    } else {
                        Button("Fechar".loc) { dismiss() }
                    }
                }
            }
        }
        .interactiveDismissDisabled(phase == .running)
        .preferredColorScheme(.dark)
    }

    private var title: String {
        switch phase {
        case .done: return "Exportação pronta".loc
        case .running: return "Exportando vídeo".loc
        default: return "Exportar vídeo".loc
        }
    }

    // MARK: opcoes

    private static let resolutions: [(String, Int)] = [("Original", 0), ("2160p", 2160),
                                                       ("1440p", 1440), ("1080p", 1080),
                                                       ("720p", 720), ("480p", 480)]

    @State private var resolution = 0
    @State private var quality = 1

    private var options: some View {
        Form {
            Picker("", selection: $formato) {
                Text("Vídeo".loc).tag(Formato.video)
                Text("GIF").tag(Formato.gif)
                Text("Imagem PNG".loc).tag(Formato.png)
            }.pickerStyle(.segmented).listRowBackground(Color.clear)
            if formato == .gif {
                Section {
                    Text("GIF em laço, 15 quadros por segundo, até 480 px.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                    exportButton
                }
            } else if formato == .png {
                Section {
                    Text(String(format: "Quadro em %.2fs, no tamanho da composição, com transparência.".loc, time))
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                    exportButton
                }
            } else {
                videoOptions
            }
        }
    }

    private var exportButton: some View {
        Button {
            Task {
                switch formato {
                case .video: await run()
                case .gif: await runGIF()
                case .png: await runPNG()
                }
            }
        } label: {
            Text("Exportar".loc).frame(maxWidth: .infinity).font(.system(size: 15, weight: .semibold))
        }.disabled(composition.layers.isEmpty)
    }

    @ViewBuilder private var videoOptions: some View {
            Section("Qualidade do vídeo".loc) {
                Picker("Resolução".loc, selection: $resolution) {
                    ForEach(Self.resolutions, id: \.1) { r in Text(r.0.loc).tag(r.1) }
                }
                LabeledContent("Tamanho".loc, value: "\(outSize.0)×\(outSize.1)")
                Picker("Quadros por segundo".loc, selection: $settings.frameRate) {
                    ForEach(Array(Set([24, 25, 30, 50, 60, Int(composition.frameRate)])).sorted(), id: \.self) {
                        Text("\($0)").tag(Float($0))
                    }
                }
                Picker("Qualidade".loc, selection: $quality) {
                    Text("Baixa".loc).tag(0); Text("Média".loc).tag(1); Text("Alta".loc).tag(2)
                }
                Picker("Formato".loc, selection: $settings.codec) {
                    Text("H.264").tag(ExportSettings.Codec.h264)
                    Text("HEVC").tag(ExportSettings.Codec.hevc)
                }.disabled(settings.transparentBackground)
                Picker("Contêiner".loc, selection: $settings.container) {
                    Text("MP4").tag(ExportSettings.Container.mp4)
                    Text("MOV").tag(ExportSettings.Container.mov)
                }.disabled(settings.transparentBackground)
            }
            Section {
                Toggle("Exportar o áudio".loc, isOn: $settings.includeAudio)
                if !settings.includeAudio {
                    Text("Desligado, o vídeo sai mudo.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                }
                Toggle("Exportar com fundo transparente".loc, isOn: $settings.transparentBackground)
                    .onChange(of: settings.transparentBackground) { _, on in
                        if on { settings.container = .mov; settings.codec = .hevc }
                    }
                if settings.transparentBackground {
                    Text("Fundo transparente exige HEVC com alfa, em .mov. O MP4 não guarda alfa.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                }
            }
            Section {
                Button {
                    Task { await run() }
                } label: {
                    Text("Exportar".loc).frame(maxWidth: .infinity)
                        .font(.system(size: 15, weight: .semibold))
                }
                .disabled(composition.layers.isEmpty)
                if composition.layers.isEmpty {
                    Text("Comece por uma mídia, um texto ou um som.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                }
            }
    }

    // MARK: GIF e PNG

    /// Monta o compositor e uma textura BGRA compartilhada do tamanho pedido.
    private func pipeline(width: Int, height: Int) throws -> (Compositor, MTLTexture) {
        guard let device = MTLCreateSystemDefaultDevice() else { throw RenderError.noDevice }
        let compositor = try Compositor(renderer: try EffectRenderer(device: device))
        let provider = MediaContentProvider(mediaRoot: mediaRoot, device: device)
        keepAlive = provider
        compositor.contentProvider = provider
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width,
                                                         height: height, mipmapped: false)
        d.usage = [.renderTarget, .shaderRead]
        d.storageMode = .shared
        guard let t = device.makeTexture(descriptor: d) else {
            throw RenderError.textureAllocFailed(width: width, height: height)
        }
        return (compositor, t)
    }

    @State private var keepAlive: MediaContentProvider?

    private func image(_ c: Compositor, _ target: MTLTexture, at t: Float) async throws -> CGImage {
        let frame = try await c.renderFrame(composition, at: t, manifests: manifests)
        defer { c.release(frame) }
        guard let cb = c.makeCommandBuffer() else { throw RenderError.encoderFailed("command buffer") }
        try c.encodeCopy(frame, to: target, in: cb)
        cb.commit(); cb.waitUntilCompleted()
        let w = target.width, h = target.height
        var bytes = [UInt8](repeating: 0, count: w * h * 4)
        target.getBytes(&bytes, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        let info = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let ctx = CGContext(data: &bytes, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info),
              let img = ctx.makeImage() else { throw RenderError.encoderFailed("imagem do quadro") }
        return img
    }

    @MainActor
    private func runGIF() async {
        phase = .running; progress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = false }
        do {
            let k = min(1, 480 / Double(max(composition.width, composition.height)))
            let w = max(2, Int(Double(composition.width) * k)), h = max(2, Int(Double(composition.height) * k))
            let (c, target) = try pipeline(width: w, height: h)
            let fps: Float = 15
            let n = max(1, Int(composition.duration * fps))
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(composition.name).gif")
            try? FileManager.default.removeItem(at: url)
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.gif.identifier as CFString, n, nil) else {
                throw MediaError.writerFailed("GIF")
            }
            CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary as String:
                                                    [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
            let frameProps = [kCGImagePropertyGIFDictionary as String:
                                [kCGImagePropertyGIFDelayTime as String: 1.0 / Double(fps)]] as CFDictionary
            for i in 0..<n {
                let img = try await image(c, target, at: Float(i) / fps)
                CGImageDestinationAddImage(dest, img, frameProps)
                progress = Double(i + 1) / Double(n)
            }
            guard CGImageDestinationFinalize(dest) else { throw MediaError.writerFailed("GIF") }
            phase = .done(url)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    @MainActor
    private func runPNG() async {
        phase = .running; progress = 0
        do {
            let (c, target) = try pipeline(width: composition.width, height: composition.height)
            let img = try await image(c, target, at: time)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(composition.name).png")
            try? FileManager.default.removeItem(at: url)
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
            else { throw MediaError.writerFailed("PNG") }
            CGImageDestinationAddImage(dest, img, nil)
            guard CGImageDestinationFinalize(dest) else { throw MediaError.writerFailed("PNG") }
            progress = 1
            phase = .done(url)
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    /// Tamanho de saida: mesma proporcao da composicao, lado menor = resolucao
    /// escolhida, sempre par (H.264/HEVC exigem).
    private var outSize: (Int, Int) {
        var w = Double(composition.width), h = Double(composition.height)
        if resolution > 0 {
            let k = Double(resolution) / min(w, h)
            if k < 1 { w *= k; h *= k }
        }
        return (max(2, Int(w.rounded()) & ~1), max(2, Int(h.rounded()) & ~1))
    }

    // MARK: export

    @MainActor
    private func run() async {
        phase = .running
        progress = 0
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = false }

        var s = settings
        (s.width, s.height) = outSize
        let px = Double(s.width * s.height)
        let perPixel: [Double] = [0.06, 0.12, 0.2]
        s.bitrate = Int(max(1_500_000, px * Double(s.frameRate) * perPixel[quality]))
        let transparent = s.transparentBackground

        do {
            guard let device = MTLCreateSystemDefaultDevice() else { throw RenderError.noDevice }
            let renderer = try EffectRenderer(device: device)
            let compositor = try Compositor(renderer: renderer)
            let provider = MediaContentProvider(mediaRoot: mediaRoot, device: device)
            compositor.contentProvider = provider

            let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                             width: s.width, height: s.height,
                                                             mipmapped: false)
            d.usage = [.renderTarget, .shaderRead]
            d.storageMode = .shared
            guard let target = device.makeTexture(descriptor: d) else {
                throw RenderError.textureAllocFailed(width: s.width, height: s.height)
            }

            let ext = s.container == .mp4 ? "mp4" : "mov"
            let base = FileManager.default.temporaryDirectory
            let safe = composition.name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
            let videoOnly = base.appendingPathComponent("nova-video-\(UUID().uuidString).\(ext)")
            let final = base.appendingPathComponent("\(safe.isEmpty ? "NovaEditor" : safe).\(ext)")

            let ex = VideoExporter(device: device)
            exporter = ex
            let comp = composition
            let manifests = self.manifests
            let bg = transparent ? MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
                                 : MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
            var outComp = comp
            outComp.frameRate = s.frameRate

            let video = try await ex.export(composition: outComp, to: videoOnly, settings: s,
                renderFrame: { _, t in
                    let frame = try await compositor.renderFrame(comp, at: t, manifests: manifests)
                    defer { compositor.release(frame) }
                    guard let cb = compositor.makeCommandBuffer() else {
                        throw RenderError.encoderFailed("command buffer do export")
                    }
                    try compositor.encodeCopy(frame, to: target, background: bg, in: cb)
                    cb.commit()
                    cb.waitUntilCompleted()
                    return target
                },
                onProgress: { p in
                    if case .frame(let i, let total) = p {
                        Task { @MainActor in progress = Double(i + 1) / Double(max(total, 1)) }
                    }
                })

            var result = video
            if s.includeAudio {
                result = try await AudioMux.addAudio(video: video, composition: comp,
                                                     mediaRoot: mediaRoot, out: final,
                                                     fileType: s.container == .mp4 ? .mp4 : .mov,
                                                     keepAlpha: transparent)
            }
            if result != final {
                if FileManager.default.fileExists(atPath: final.path) { try? FileManager.default.removeItem(at: final) }
                try FileManager.default.moveItem(at: result, to: final)
            }
            phase = .done(final)
        } catch MediaError.cancelled {
            phase = .options
        } catch {
            phase = .failed(error.localizedDescription)
        }
        exporter = nil
    }

    private var running: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView(value: progress)
                .tint(NovaTheme.accent)
                .padding(.horizontal, 40)
            Text("\(Int(progress * 100))%").font(.system(size: 13, design: .monospaced))
                .foregroundStyle(NovaTheme.dim)
            Text("Mantenha o app aberto enquanto exporta.".loc)
                .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: resultado

    private func done(_ url: URL) -> some View {
        VStack(spacing: 14) {
            Group {
                if url.pathExtension == "gif" || url.pathExtension == "png",
                   let img = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    VideoPlayer(player: AVPlayer(url: url))
                }
            }
                .aspectRatio(CGFloat(composition.width) / CGFloat(max(composition.height, 1)),
                             contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
            HStack(spacing: 12) {
                Button {
                    Task { await saveToPhotos(url) }
                } label: {
                    Label("Salvar na galeria".loc, systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.accent.opacity(0.18)))
                }
                ShareLink(item: url) {
                    Label("Compartilhar".loc, systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface))
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(NovaTheme.text)
            .padding(.horizontal, 16)
            if let savedToPhotos {
                Text(savedToPhotos).font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
            }
            Button("Exportar de novo".loc) { phase = .options; savedToPhotos = nil }
                .font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
            Spacer()
        }
        .padding(.top, 14)
    }

    @MainActor
    private func saveToPhotos(_ url: URL) async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            savedToPhotos = "Sem permissão para salvar na galeria. Libere em Ajustes › Nova Editor › Fotos.".loc
            return
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let tipo: PHAssetResourceType = url.pathExtension == "mp4" || url.pathExtension == "mov" ? .video : .photo
                PHAssetCreationRequest.forAsset().addResource(with: tipo, fileURL: url, options: nil)
            }
            savedToPhotos = "Salvo na galeria.".loc
        } catch {
            savedToPhotos = error.localizedDescription
        }
    }

    private func failed(_ m: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.system(size: 28))
                .foregroundStyle(NovaTheme.warning)
            Text(m).font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button("Tentar de novo".loc) { phase = .options }
                .foregroundStyle(NovaTheme.accent)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
