//
//  MediaImport.swift
//  NovaUI
//
//  Trazer fotos e videos da galeria para o projeto.
//
//  Do APK: «Escolha as fotos e os videos pela galeria — da para marcar varias de
//  uma vez», «Adicionar {0} midias», «Abrindo o projeto e copiando a midia».
//  A midia e COPIADA para a pasta media/ do projeto, como no Android, para o
//  projeto nao depender da galeria depois.
//
//  O seletor do sistema (PhotosPicker) nao pede permissao de acesso a galeria:
//  o app so recebe o que a pessoa escolheu.
//

import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers
import ImageIO

/// Video vindo do seletor: o sistema entrega um arquivo temporario que some
/// quando o callback termina, entao ele e copiado na hora.
struct PickedMovie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { m in
            SentTransferredFile(m.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let dst = FileManager.default.temporaryDirectory
                .appendingPathComponent("import-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: dst)
            return PickedMovie(url: dst)
        }
    }
}

enum MediaImportError: LocalizedError {
    case unreadable(String)
    var errorDescription: String? {
        switch self { case .unreadable(let m): return m }
    }
}

enum MediaImporter {

    /// Importa os itens escolhidos e devolve as camadas, ja posicionadas em
    /// sequencia a partir de `start`. Itens que falham entram em `failures`.
    static func importItems(_ items: [PhotosPickerItem], into mediaRoot: URL,
                            composition: Composition,
                            start: Float) async -> (layers: [Layer], failures: [String]) {
        try? FileManager.default.createDirectory(at: mediaRoot, withIntermediateDirectories: true)
        var layers: [Layer] = []
        var failures: [String] = []
        var cursor = start
        for (i, item) in items.enumerated() {
            do {
                var l: Layer
                if item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
                    l = try await importVideo(item, mediaRoot: mediaRoot, index: i)
                } else {
                    l = try await importImage(item, mediaRoot: mediaRoot, index: i)
                }
                fit(&l, in: composition)
                l.startTime = cursor
                cursor += l.duration
                layers.append(l)
            } catch {
                failures.append(error.localizedDescription)
            }
        }
        return (layers, failures)
    }

    private static func uniqueName(_ base: String, ext: String, in dir: URL) -> String {
        let clean = base.replacingOccurrences(of: "/", with: "-")
        var name = "\(clean).\(ext)"
        var n = 2
        while FileManager.default.fileExists(atPath: dir.appendingPathComponent(name).path) {
            name = "\(clean)-\(n).\(ext)"; n += 1
        }
        return name
    }

    private static func importVideo(_ item: PhotosPickerItem, mediaRoot: URL,
                                    index: Int) async throws -> Layer {
        guard let movie = try await item.loadTransferable(type: PickedMovie.self) else {
            throw MediaImportError.unreadable("Não consegui ler o vídeo \(index + 1)".loc)
        }
        let ext = movie.url.pathExtension.lowercased().isEmpty ? "mov" : movie.url.pathExtension.lowercased()
        let name = uniqueName("video-\(Self.stamp())", ext: ext, in: mediaRoot)
        let dst = mediaRoot.appendingPathComponent(name)
        try FileManager.default.moveItem(at: movie.url, to: dst)

        let asset = AVURLAsset(url: dst)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaImportError.unreadable("O arquivo \(index + 1) não tem vídeo".loc)
        }
        let natural = try await track.load(.naturalSize)
        let tf = try await track.load(.preferredTransform)
        let shown = natural.applying(tf)
        let seconds = Float(try await asset.load(.duration).seconds)

        var l = Layer(name: "Vídeo \(index + 1)".loc, kind: .video)
        l.mediaPath = name
        l.size = SIMD2(Float(abs(shown.width)), Float(abs(shown.height)))
        l.duration = max(0.1, seconds)
        l.sourceDuration = seconds
        return l
    }

    private static func importImage(_ item: PhotosPickerItem, mediaRoot: URL,
                                    index: Int) async throws -> Layer {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw MediaImportError.unreadable("Não consegui ler a imagem \(index + 1)".loc)
        }
        let type = item.supportedContentTypes.first { $0.conforms(to: .image) }
        let ext = type?.preferredFilenameExtension ?? "jpg"
        let name = uniqueName("foto-\(Self.stamp())", ext: ext, in: mediaRoot)
        let dst = mediaRoot.appendingPathComponent(name)
        try data.write(to: dst, options: .atomic)

        guard let cg = MediaContentProvider.loadOrientedImage(dst, maxPixel: 4096) else {
            try? FileManager.default.removeItem(at: dst)
            throw MediaImportError.unreadable("Este formato de imagem não abre no aparelho".loc)
        }
        var l = Layer(name: "Foto \(index + 1)".loc, kind: .image)
        l.mediaPath = name
        l.size = SIMD2(Float(cg.width), Float(cg.height))
        l.duration = 5
        return l
    }

    /// Centraliza e cabe inteira na composicao, mantendo a proporcao.
    static func fit(_ l: inout Layer, in comp: Composition) {
        let size = l.size ?? comp.size
        let s = min(comp.size.x / max(size.x, 1), comp.size.y / max(size.y, 1)) * 100
        l.transform.anchorPoint = Animated(size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.transform.scale = Animated(SIMD2(s, s))
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return f.string(from: Date())
    }
}
