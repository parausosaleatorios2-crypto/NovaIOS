//
//  EffectRegistry.swift
//  NovaEngine
//
//  Catalogo dos efeitos. Le a pasta Resources/effects e indexa por id, por
//  categoria e por nome, com busca. O carregamento e preguicoso: so o indice
//  entra na memoria no arranque; o manifesto completo so quando o efeito e usado.
//

import Foundation
import os

public struct EffectIndexEntry: Sendable, Identifiable {
    public let id: String
    public let slug: String
    public let fileName: String
    public let name: String
    public let nameEn: String?
    public let category: String?
    public let tags: [String]
    public let thumb: String?
}

public actor EffectRegistry {

    public static let shared = EffectRegistry()

    private let log = Logger(subsystem: "com.novavision.editor", category: "EffectRegistry")
    private var entries: [EffectIndexEntry] = []
    private var byID: [String: EffectIndexEntry] = [:]
    private var cache: [String: EffectManifest] = [:]
    private var rootURL: URL?
    private var loaded = false

    /// Erros encontrados ao indexar, para diagnostico. Nao interrompem o carregamento.
    public private(set) var indexErrors: [String] = []

    public init() {}

    // MARK: carregar

    /// Indexa a pasta de efeitos. Chamar uma vez no arranque.
    /// - Parameter url: pasta com os .xml. Se `nil`, usa Resources/effects do bundle.
    public func load(from url: URL? = nil) throws {
        guard !loaded else { return }
        let dir: URL
        if let url { dir = url }
        else if let b = Bundle.main.url(forResource: "effects", withExtension: nil) { dir = b }
        else { throw EffectParseError.unreadable("Resources/effects nao esta no bundle") }
        rootURL = dir

        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension.lowercased() == "xml" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

        guard !files.isEmpty else {
            throw EffectParseError.unreadable("nenhum .xml em \(dir.path)")
        }

        var out: [EffectIndexEntry] = []
        out.reserveCapacity(files.count)
        for f in files {
            do {
                let m = try EffectManifestParser.parse(contentsOf: f)
                let e = EffectIndexEntry(id: m.id, slug: m.slug, fileName: m.fileName,
                                         name: m.name, nameEn: m.nameEn,
                                         category: m.category, tags: m.tags, thumb: m.thumb)
                out.append(e)
                cache[m.id] = m
            } catch {
                indexErrors.append("\(f.lastPathComponent): \(error.localizedDescription)")
                log.error("efeito ignorado \(f.lastPathComponent, privacy: .public)")
            }
        }
        entries = out
        byID = Dictionary(out.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        loaded = true
        log.info("indexados \(out.count) efeitos, \(self.indexErrors.count) com erro")
    }

    // MARK: consulta

    public var count: Int { entries.count }
    public var all: [EffectIndexEntry] { entries }

    public var categories: [String: Int] {
        Dictionary(grouping: entries, by: { $0.category ?? "sem categoria" })
            .mapValues(\.count)
    }

    public func entry(id: String) -> EffectIndexEntry? { byID[id] }

    public func manifest(id: String) throws -> EffectManifest {
        if let m = cache[id] { return m }
        guard let e = byID[id], let root = rootURL else {
            throw EffectParseError.unreadable("efeito desconhecido: \(id)")
        }
        let m = try EffectManifestParser.parse(contentsOf: root.appendingPathComponent(e.fileName))
        cache[id] = m
        return m
    }

    /// Busca por nome, nome em ingles, tags e categoria. Sem acento e sem caixa.
    public func search(_ query: String, category: String? = nil, limit: Int = 200) -> [EffectIndexEntry] {
        let q = Self.fold(query)
        var out = entries
        if let category { out = out.filter { $0.category == category } }
        guard !q.isEmpty else { return Array(out.prefix(limit)) }
        let scored: [(EffectIndexEntry, Int)] = out.compactMap { e in
            let n = Self.fold(e.name)
            if n == q { return (e, 0) }
            if n.hasPrefix(q) { return (e, 1) }
            if n.contains(q) { return (e, 2) }
            if let en = e.nameEn, Self.fold(en).contains(q) { return (e, 3) }
            if e.tags.contains(where: { Self.fold($0).contains(q) }) { return (e, 4) }
            if let c = e.category, Self.fold(c).contains(q) { return (e, 5) }
            return nil
        }
        return scored.sorted { $0.1 == $1.1 ? $0.0.name < $1.0.name : $0.1 < $1.1 }
                     .prefix(limit).map(\.0)
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
         .trimmingCharacters(in: .whitespaces)
    }
}
