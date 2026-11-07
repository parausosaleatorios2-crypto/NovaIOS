//
//  NovaProjectIO.swift
//  NovaEngine
//
//  Leitura e escrita do formato .nova.
//
//  No app Android o .nova e um ZIP com o projeto em JSON mais as midias.
//  O manifesto declara: MIME application/x-nova, e tambem application/zip e
//  application/octet-stream nos intent-filters — o que confirma o container ZIP.
//
//  ATENCAO: o layout interno exato do ZIP do app Android nao foi decodificado
//  (a serializacao esta no bytecode). O que esta aqui e o formato do app iOS,
//  compativel na ESTRUTURA (ZIP + JSON + pasta de midia). Para abrir arquivos
//  .nova feitos no Android e preciso confirmar o nome e o esquema do JSON
//  interno — veja Docs/PENDENCIAS.md.
//

import Foundation

public enum NovaIOError: LocalizedError {
    case notAZip(URL)
    case missingManifest(String)
    case unsupportedVersion(Int)
    case writeFailed(String)
    case readFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notAZip(let u):          return "\(u.lastPathComponent) nao e um pacote .nova valido"
        case .missingManifest(let n):  return "Faltou \(n) dentro do pacote"
        case .unsupportedVersion(let v): return "Formato de projeto versao \(v), mais novo que este app"
        case .writeFailed(let m):      return "Nao consegui gravar o projeto: \(m)"
        case .readFailed(let m):       return "Nao consegui ler o projeto: \(m)"
        }
    }
}

/// Um projeto aberto: o modelo mais a pasta onde as midias foram extraidas.
public struct OpenedProject {
    public let project: NovaProject
    /// Pasta de trabalho. As `mediaPath` das camadas sao relativas a ela.
    public let mediaRoot: URL
    public func mediaURL(_ relative: String) -> URL {
        mediaRoot.appendingPathComponent(relative)
    }
}

public enum NovaProjectIO {

    public static let manifestName = "project.json"
    public static let mediaFolder  = "media"
    public static let currentVersion = 1

    private static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }
    private static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Pasta de trabalho (projeto aberto, nao empacotado)

    /// Grava o projeto como pasta: project.json + media/.
    /// E o formato usado enquanto o projeto esta aberto — gravar um ZIP a cada
    /// alteracao seria caro num projeto com video.
    public static func saveFolder(_ project: NovaProject, to dir: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        try fm.createDirectory(at: dir.appendingPathComponent(mediaFolder),
                               withIntermediateDirectories: true)
        var p = project
        p.modifiedAt = Date()
        p.formatVersion = currentVersion
        do {
            let data = try encoder.encode(p)
            // Grava em arquivo temporario e troca: se o app morrer no meio,
            // o projeto anterior continua intacto.
            let tmp = dir.appendingPathComponent(manifestName + ".tmp")
            try data.write(to: tmp, options: .atomic)
            let final = dir.appendingPathComponent(manifestName)
            if fm.fileExists(atPath: final.path) { try fm.removeItem(at: final) }
            try fm.moveItem(at: tmp, to: final)
        } catch {
            throw NovaIOError.writeFailed(error.localizedDescription)
        }
    }

    public static func loadFolder(from dir: URL) throws -> OpenedProject {
        let manifest = dir.appendingPathComponent(manifestName)
        guard FileManager.default.fileExists(atPath: manifest.path) else {
            throw NovaIOError.missingManifest(manifestName)
        }
        do {
            let data = try Data(contentsOf: manifest)
            let p = try decoder.decode(NovaProject.self, from: data)
            guard p.formatVersion <= currentVersion else {
                throw NovaIOError.unsupportedVersion(p.formatVersion)
            }
            return OpenedProject(project: p,
                                 mediaRoot: dir.appendingPathComponent(mediaFolder))
        } catch let e as NovaIOError {
            throw e
        } catch {
            throw NovaIOError.readFailed(error.localizedDescription)
        }
    }

    // MARK: - Pacote .nova (ZIP, para exportar e compartilhar)

    /// Empacota a pasta do projeto num unico arquivo .nova.
    /// Usa a coordenacao de arquivo do sistema, que produz um ZIP — e como o
    /// iOS compacta pastas sem biblioteca de terceiros.
    public static func pack(folder: URL, to destination: URL) throws {
        let coordinator = NSFileCoordinator()
        var coordError: NSError?
        var thrown: Error?
        coordinator.coordinate(readingItemAt: folder,
                               options: [.forUploading],
                               error: &coordError) { zipURL in
            do {
                let fm = FileManager.default
                if fm.fileExists(atPath: destination.path) {
                    try fm.removeItem(at: destination)
                }
                try fm.copyItem(at: zipURL, to: destination)
            } catch {
                thrown = error
            }
        }
        if let e = coordError { throw NovaIOError.writeFailed(e.localizedDescription) }
        if let e = thrown     { throw NovaIOError.writeFailed(e.localizedDescription) }
    }

    /// Abre um .nova extraindo para uma pasta de trabalho.
    /// - Note: usa `unzipItem` do sistema quando disponivel (iOS 16+ via
    ///   `FileManager`), caso contrario exige a dependencia declarada no README.
    public static func unpack(_ file: URL, into workDir: URL) throws -> OpenedProject {
        let fm = FileManager.default
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)
        guard isZip(file) else { throw NovaIOError.notAZip(file) }
        try ZipReader.extract(file, to: workDir)
        // O ZIP pode ter uma pasta-raiz unica (como o NSFileCoordinator gera).
        let dir = try resolveRoot(workDir)
        return try loadFolder(from: dir)
    }

    static func isZip(_ url: URL) -> Bool {
        guard let h = FileHandle(forReadingAtPath: url.path) else { return false }
        defer { try? h.close() }
        let magic = h.readData(ofLength: 4)
        return magic == Data([0x50, 0x4B, 0x03, 0x04])    // "PK\003\004"
            || magic == Data([0x50, 0x4B, 0x05, 0x06])    // ZIP vazio
    }

    static func resolveRoot(_ dir: URL) throws -> URL {
        let fm = FileManager.default
        if fm.fileExists(atPath: dir.appendingPathComponent(manifestName).path) { return dir }
        let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        for i in items {
            if fm.fileExists(atPath: i.appendingPathComponent(manifestName).path) { return i }
        }
        throw NovaIOError.missingManifest(manifestName)
    }
}

// MARK: - Leitor de ZIP

/// Extracao de ZIP sem dependencia externa, pelo Archive do sistema quando ha,
/// e por leitura direta do formato quando nao ha.
enum ZipReader {
    static func extract(_ zip: URL, to dir: URL) throws {
        // iOS/macOS nao expoem unzip publico; lemos o central directory na mao.
        // Suporta armazenamento (metodo 0) e deflate (metodo 8), que e o que o
        // NSFileCoordinator e o Android produzem.
        let data = try Data(contentsOf: zip)
        let entries = try centralDirectory(data)
        let fm = FileManager.default
        for e in entries {
            let out = dir.appendingPathComponent(e.name)
            // Protecao contra zip-slip: nada pode escapar da pasta de destino.
            guard out.standardizedFileURL.path.hasPrefix(dir.standardizedFileURL.path) else {
                throw NovaIOError.readFailed("caminho suspeito no pacote: \(e.name)")
            }
            if e.name.hasSuffix("/") {
                try fm.createDirectory(at: out, withIntermediateDirectories: true)
                continue
            }
            try fm.createDirectory(at: out.deletingLastPathComponent(),
                                   withIntermediateDirectories: true)
            let bytes = try payload(data, entry: e)
            try bytes.write(to: out, options: .atomic)
        }
    }

    struct Entry { let name: String; let method: UInt16
                   let compressed: Int; let uncompressed: Int; let localHeader: Int }

    static func centralDirectory(_ d: Data) throws -> [Entry] {
        // End of central directory: assinatura PK\005\006 nos ultimos 64 KB.
        let sig: [UInt8] = [0x50, 0x4B, 0x05, 0x06]
        let scanFrom = max(0, d.count - 66_000)
        var eocd = -1
        var i = d.count - 22
        while i >= scanFrom {
            if d[i] == sig[0], d[i+1] == sig[1], d[i+2] == sig[2], d[i+3] == sig[3] {
                eocd = i; break
            }
            i -= 1
        }
        guard eocd >= 0 else { throw NovaIOError.readFailed("central directory nao encontrado") }
        let count   = Int(u16(d, eocd + 10))
        var off     = Int(u32(d, eocd + 16))
        var out: [Entry] = []
        for _ in 0..<count {
            guard off + 46 <= d.count, u32(d, off) == 0x0201_4B50 else { break }
            let method = u16(d, off + 10)
            let csize  = Int(u32(d, off + 20))
            let usize  = Int(u32(d, off + 24))
            let nlen   = Int(u16(d, off + 28))
            let elen   = Int(u16(d, off + 30))
            let clen   = Int(u16(d, off + 32))
            let lho    = Int(u32(d, off + 42))
            let name   = String(data: d.subdata(in: (off+46)..<(off+46+nlen)), encoding: .utf8) ?? ""
            out.append(Entry(name: name, method: method, compressed: csize,
                             uncompressed: usize, localHeader: lho))
            off += 46 + nlen + elen + clen
        }
        return out
    }

    static func payload(_ d: Data, entry e: Entry) throws -> Data {
        let lh = e.localHeader
        guard lh + 30 <= d.count, u32(d, lh) == 0x0403_4B50 else {
            throw NovaIOError.readFailed("cabecalho local invalido em \(e.name)")
        }
        let nlen = Int(u16(d, lh + 26)), elen = Int(u16(d, lh + 28))
        let start = lh + 30 + nlen + elen
        let end = start + e.compressed
        guard end <= d.count else { throw NovaIOError.readFailed("pacote truncado em \(e.name)") }
        let raw = d.subdata(in: start..<end)
        switch e.method {
        case 0:  return raw
        case 8:  return try Inflate.raw(raw, expected: e.uncompressed)
        default: throw NovaIOError.readFailed("compressao \(e.method) nao suportada em \(e.name)")
        }
    }

    static func u16(_ d: Data, _ o: Int) -> UInt16 {
        guard o + 2 <= d.count else { return 0 }
        return UInt16(d[o]) | (UInt16(d[o+1]) << 8)
    }
    static func u32(_ d: Data, _ o: Int) -> UInt32 {
        guard o + 4 <= d.count else { return 0 }
        return UInt32(d[o]) | (UInt32(d[o+1]) << 8) | (UInt32(d[o+2]) << 16) | (UInt32(d[o+3]) << 24)
    }
}

// MARK: - Inflate

import Compression

enum Inflate {
    /// Descompacta um bloco deflate cru (sem cabecalho zlib), que e o que o ZIP guarda.
    static func raw(_ data: Data, expected: Int) throws -> Data {
        guard !data.isEmpty else { return Data() }
        let capacity = max(expected, data.count * 4, 4096)
        var out = Data(count: capacity)
        let written: Int = out.withUnsafeMutableBytes { dst -> Int in
            data.withUnsafeBytes { src -> Int in
                guard let d = dst.bindMemory(to: UInt8.self).baseAddress,
                      let s = src.bindMemory(to: UInt8.self).baseAddress else { return 0 }
                return compression_decode_buffer(d, capacity, s, data.count, nil, COMPRESSION_ZLIB)
            }
        }
        guard written > 0 else {
            throw NovaIOError.readFailed("falha ao descompactar (deflate)")
        }
        return out.prefix(written)
    }
}
