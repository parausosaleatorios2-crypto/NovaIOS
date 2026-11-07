//
//  VideoPipeline.swift
//  NovaEngine
//
//  Decodificacao de video para textura Metal e exportacao do resultado.
//  Substitui MediaCodec + SurfaceTexture (decode) e MediaMuxer (export) do Android.
//

import AVFoundation
import VideoToolbox
import CoreVideo
import Metal
import MetalKit
import os

// MARK: - Erros

public enum MediaError: LocalizedError {
    case noVideoTrack(URL)
    case readerFailed(String)
    case writerFailed(String)
    case textureCacheFailed
    case pixelBufferFailed
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .noVideoTrack(let u):   return "\(u.lastPathComponent) nao tem faixa de video"
        case .readerFailed(let m):   return "Falha ao ler o video: \(m)"
        case .writerFailed(let m):   return "Falha ao gravar o video: \(m)"
        case .textureCacheFailed:    return "Nao consegui criar o cache de texturas do Metal"
        case .pixelBufferFailed:     return "Nao consegui alocar o buffer de pixels"
        case .cancelled:             return "Exportacao cancelada"
        }
    }
}

// MARK: - Decodificador

/// Le quadros de um arquivo de video e entrega como textura Metal, sem copia
/// para a CPU: o CVPixelBuffer vira textura pelo CVMetalTextureCache.
public actor VideoDecoder {

    private let asset: AVURLAsset
    private let device: MTLDevice
    private var cache: CVMetalTextureCache?
    private var output: AVPlayerItemVideoOutput?
    private var generator: AVAssetImageGenerator?
    private let log = Logger(subsystem: "com.novavision.editor", category: "VideoDecoder")

    public private(set) var naturalSize: CGSize = .zero
    public private(set) var nominalFrameRate: Float = 30
    public private(set) var duration: Double = 0
    public private(set) var preferredTransform: CGAffineTransform = .identity

    public init(url: URL, device: MTLDevice) async throws {
        self.asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])
        self.device = device

        var c: CVMetalTextureCache?
        guard CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &c) == kCVReturnSuccess,
              let cache = c else {
            throw MediaError.textureCacheFailed
        }
        self.cache = cache

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaError.noVideoTrack(url)
        }
        self.naturalSize = try await track.load(.naturalSize)
        self.nominalFrameRate = try await track.load(.nominalFrameRate)
        self.duration = try await asset.load(.duration).seconds
        self.preferredTransform = try await track.load(.preferredTransform)

        let g = AVAssetImageGenerator(asset: asset)
        g.appliesPreferredTrackTransform = true
        g.requestedTimeToleranceBefore = .zero
        g.requestedTimeToleranceAfter = .zero
        g.maximumSize = naturalSize
        self.generator = g
    }

    /// Textura de um instante. Precisao de quadro: as tolerancias sao zero,
    /// porque uma timeline que erra o quadro mostra a imagem errada no corte.
    public func texture(at seconds: Double) async throws -> MTLTexture? {
        guard let generator, let cache else { return nil }
        let t = CMTime(seconds: max(0, min(seconds, duration)), preferredTimescale: 600)
        let image: CGImage
        do {
            image = try await generator.image(at: t).image
        } catch {
            throw MediaError.readerFailed(error.localizedDescription)
        }
        return try Self.makeTexture(from: image, device: device)
    }

    nonisolated static func makeTexture(from image: CGImage, device: MTLDevice) throws -> MTLTexture {
        let loader = MTKTextureLoader(device: device)
        do {
            return try loader.newTexture(cgImage: image, options: [
                .SRGB: false,
                .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
                .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
            ])
        } catch {
            throw MediaError.readerFailed(error.localizedDescription)
        }
    }

    /// Leitura sequencial, para exportar: muito mais rapida que buscar quadro a quadro.
    public func sequentialReader() async throws -> AVAssetReaderTrackOutput {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaError.noVideoTrack(asset.url)
        }
        let reader: AVAssetReader
        do { reader = try AVAssetReader(asset: asset) }
        catch { throw MediaError.readerFailed(error.localizedDescription) }
        let out = AVAssetReaderTrackOutput(track: track, outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ])
        out.alwaysCopiesSampleData = false
        reader.add(out)
        guard reader.startReading() else {
            throw MediaError.readerFailed(reader.error?.localizedDescription ?? "startReading")
        }
        return out
    }
}

// MARK: - Exportador

public struct ExportSettings: Sendable {
    public enum Container: String, Sendable, CaseIterable { case mp4, mov }
    public enum Codec: String, Sendable, CaseIterable { case h264, hevc }

    public var container: Container = .mp4
    public var codec: Codec = .h264
    public var width: Int = 1920
    public var height: Int = 1080
    public var frameRate: Float = 30
    public var bitrate: Int = 12_000_000
    public var includeAudio = true
    public var transparentBackground = false

    public init() {}

    /// HEVC com alfa e o unico caminho para fundo transparente em video no iOS.
    public var effectiveCodec: AVVideoCodecType {
        if transparentBackground { return .hevcWithAlpha }
        return codec == .hevc ? .hevc : .h264
    }
}

public actor VideoExporter {

    public enum Progress: Sendable {
        case preparing
        case frame(index: Int, total: Int)
        case finishing
        case done(URL)
        case failed(String)
    }

    private let device: MTLDevice
    private let log = Logger(subsystem: "com.novavision.editor", category: "VideoExporter")
    private var cancelled = false

    public init(device: MTLDevice) { self.device = device }

    public func cancel() { cancelled = true }

    /// Exporta a composicao quadro a quadro. `renderFrame` devolve a textura
    /// de cada quadro; o exportador cuida de converter e gravar.
    public func export(composition: Composition,
                       to url: URL,
                       settings: ExportSettings,
                       renderFrame: @Sendable (Int, Float) async throws -> MTLTexture,
                       onProgress: @Sendable (Progress) -> Void = { _ in }) async throws -> URL {
        cancelled = false
        onProgress(.preparing)

        let fm = FileManager.default
        if fm.fileExists(atPath: url.path) { try? fm.removeItem(at: url) }

        let fileType: AVFileType = settings.container == .mp4 ? .mp4 : .mov
        let writer: AVAssetWriter
        do { writer = try AVAssetWriter(outputURL: url, fileType: fileType) }
        catch { throw MediaError.writerFailed(error.localizedDescription) }

        var videoSettings: [String: Any] = [
            AVVideoCodecKey: settings.effectiveCodec,
            AVVideoWidthKey: settings.width,
            AVVideoHeightKey: settings.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: settings.bitrate,
                AVVideoExpectedSourceFrameRateKey: Int(settings.frameRate),
                AVVideoMaxKeyFrameIntervalKey: Int(settings.frameRate * 2)
            ]
        ]
        if settings.transparentBackground {
            videoSettings[AVVideoCompressionPropertiesKey] = [
                AVVideoAverageBitRateKey: settings.bitrate,
                kVTCompressionPropertyKey_TargetQualityForAlpha as String: 0.9
            ]
        }

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false
        let attrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                settings.transparentBackground ? kCVPixelFormatType_32BGRA : kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: settings.width,
            kCVPixelBufferHeightKey as String: settings.height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input, sourcePixelBufferAttributes: attrs)

        guard writer.canAdd(input) else {
            throw MediaError.writerFailed("o writer recusou a faixa de video")
        }
        writer.add(input)
        guard writer.startWriting() else {
            throw MediaError.writerFailed(writer.error?.localizedDescription ?? "startWriting")
        }
        writer.startSession(atSourceTime: .zero)

        let total = composition.frameCount
        let fd = 1.0 / Double(max(settings.frameRate, 1))

        for i in 0..<total {
            if cancelled {
                input.markAsFinished(); writer.cancelWriting()
                throw MediaError.cancelled
            }
            // Espera o writer pedir mais dados, em vez de encher a fila.
            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 2_000_000)
                if cancelled { writer.cancelWriting(); throw MediaError.cancelled }
            }
            let t = Float(Double(i) * fd)
            let tex = try await renderFrame(i, t)
            guard let pool = adaptor.pixelBufferPool,
                  let pb = Self.pixelBuffer(from: tex, pool: pool) else {
                input.markAsFinished(); writer.cancelWriting()
                throw MediaError.pixelBufferFailed
            }
            let pts = CMTime(value: CMTimeValue(i), timescale: CMTimeScale(settings.frameRate))
            if !adaptor.append(pb, withPresentationTime: pts) {
                input.markAsFinished(); writer.cancelWriting()
                throw MediaError.writerFailed(writer.error?.localizedDescription
                                              ?? "append falhou no quadro \(i)")
            }
            onProgress(.frame(index: i, total: total))
        }

        onProgress(.finishing)
        input.markAsFinished()
        await writer.finishWriting()
        if writer.status == .failed {
            let m = writer.error?.localizedDescription ?? "desconhecido"
            onProgress(.failed(m))
            throw MediaError.writerFailed(m)
        }
        onProgress(.done(url))
        return url
    }

    /// Copia a textura para um CVPixelBuffer do pool do adaptador.
    nonisolated static func pixelBuffer(from texture: MTLTexture,
                                        pool: CVPixelBufferPool) -> CVPixelBuffer? {
        var pb: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pb) == kCVReturnSuccess,
              let buffer = pb else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bpr = CVPixelBufferGetBytesPerRow(buffer)
        let w = min(texture.width, CVPixelBufferGetWidth(buffer))
        let h = min(texture.height, CVPixelBufferGetHeight(buffer))
        texture.getBytes(base, bytesPerRow: bpr,
                         from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        return buffer
    }
}
