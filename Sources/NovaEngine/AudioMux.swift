//
//  AudioMux.swift
//  NovaEngine
//
//  Junta ao video exportado o som das camadas de video que nao estao mudas.
//  O VideoExporter grava so imagem; aqui cada faixa de audio entra no ponto
//  da timeline da sua camada, com o trim (mediaOffset) e a velocidade dela.
//  «Desligado, o video sai mudo.» — chave de audio do export no APK.
//

import AVFoundation

public enum AudioMux {

    /// Camadas cujo som entra no video: video e audio, ligadas, nao mudas.
    /// Invertido fica mudo (o AVFoundation nao toca audio ao contrario).
    static func hasSound(_ l: Layer) -> Bool {
        (l.kind == .video || l.kind == .audio) && l.enabled && !(l.muted ?? false) && !(l.reversed ?? false)
    }

    /// Som da composicao para a previa: um AVPlayerItem so de audio.
    @MainActor
    public static func previewItem(composition: Composition, mediaRoot: URL) async -> AVPlayerItem? {
        let mix = AVMutableComposition()
        var added = 0
        for layer in composition.layers where hasSound(layer) {
            guard let path = layer.mediaPath else { continue }
            let a = AVURLAsset(url: mediaRoot.appendingPathComponent(path))
            guard let aTrack = try? await a.loadTracks(withMediaType: .audio).first,
                  let srcDur = try? await a.load(.duration).seconds else { continue }
            let speed = Double(max(layer.speed, 0.01))
            let offset = Double(max(0, layer.mediaOffset))
            let len = min(Double(layer.duration) * speed, srcDur - offset)
            guard len > 0.02,
                  let ca = mix.addMutableTrack(withMediaType: .audio,
                                               preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            let at = CMTime(seconds: Double(layer.startTime), preferredTimescale: 48000)
            let src = CMTimeRange(start: CMTime(seconds: offset, preferredTimescale: 48000),
                                  duration: CMTime(seconds: len, preferredTimescale: 48000))
            if (try? ca.insertTimeRange(src, of: aTrack, at: at)) != nil {
                if abs(speed - 1) > 0.001 {
                    ca.scaleTimeRange(CMTimeRange(start: at, duration: src.duration),
                                      toDuration: CMTime(seconds: len / speed, preferredTimescale: 48000))
                }
                added += 1
            } else { mix.removeTrack(ca) }
        }
        return added > 0 ? AVPlayerItem(asset: mix) : nil
    }

    /// Devolve `out` com video + audio, ou o proprio `video` se nenhuma camada tem som.
    public static func addAudio(video: URL, composition: Composition, mediaRoot: URL,
                                out: URL, fileType: AVFileType,
                                keepAlpha: Bool = false) async throws -> URL {
        let mix = AVMutableComposition()
        let vAsset = AVURLAsset(url: video)
        guard let vTrack = try await vAsset.loadTracks(withMediaType: .video).first else {
            return video
        }
        let total = try await vAsset.load(.duration)
        guard let cv = mix.addMutableTrack(withMediaType: .video,
                                           preferredTrackID: kCMPersistentTrackID_Invalid) else {
            return video
        }
        try cv.insertTimeRange(CMTimeRange(start: .zero, duration: total), of: vTrack, at: .zero)

        var added = 0
        for layer in composition.layers where Self.hasSound(layer) {
            guard let path = layer.mediaPath else { continue }
            let a = AVURLAsset(url: mediaRoot.appendingPathComponent(path))
            guard let aTrack = try? await a.loadTracks(withMediaType: .audio).first,
                  let srcDur = try? await a.load(.duration).seconds else { continue }
            let speed = Double(max(layer.speed, 0.01))
            let start = Double(layer.startTime)
            let offset = Double(max(0, layer.mediaOffset))
            // Quanto da fonte cabe: duracao da camada, fim da fonte e fim do video.
            let len = min(Double(layer.duration) * speed, srcDur - offset,
                          max(0, total.seconds - start) * speed)
            guard len > 0.02, start >= 0 else { continue }
            guard let ca = mix.addMutableTrack(withMediaType: .audio,
                                               preferredTrackID: kCMPersistentTrackID_Invalid) else { continue }
            let src = CMTimeRange(start: CMTime(seconds: offset, preferredTimescale: 48000),
                                  duration: CMTime(seconds: len, preferredTimescale: 48000))
            let at = CMTime(seconds: start, preferredTimescale: 48000)
            do {
                try ca.insertTimeRange(src, of: aTrack, at: at)
                if abs(speed - 1) > 0.001 {
                    ca.scaleTimeRange(CMTimeRange(start: at, duration: src.duration),
                                      toDuration: CMTime(seconds: len / speed, preferredTimescale: 48000))
                }
                added += 1
            } catch {
                mix.removeTrack(ca)
            }
        }
        guard added > 0 else { return video }

        if FileManager.default.fileExists(atPath: out.path) { try? FileManager.default.removeItem(at: out) }
        // Mais de uma faixa de audio pede reencode do audio; o video vai junto
        // na qualidade mais alta para nao perder nitidez.
        let preset = added == 1 ? AVAssetExportPresetPassthrough
            : (keepAlpha ? AVAssetExportPresetHEVCHighestQualityWithAlpha : AVAssetExportPresetHighestQuality)
        guard let ex = AVAssetExportSession(asset: mix, presetName: preset) else {
            throw MediaError.writerFailed("sessão de áudio indisponível")
        }
        ex.outputURL = out
        ex.outputFileType = fileType
        ex.shouldOptimizeForNetworkUse = true
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            ex.exportAsynchronously { c.resume() }
        }
        if ex.status != .completed {
            throw MediaError.writerFailed(ex.error?.localizedDescription ?? "falha ao juntar o áudio")
        }
        try? FileManager.default.removeItem(at: video)
        return out
    }
}
