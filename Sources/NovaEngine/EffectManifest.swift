//
//  EffectManifest.swift
//  NovaEngine
//
//  Le os XMLs de efeito do NovaEditor (os mesmos 1.490 arquivos do app Android,
//  sem alteracao) e devolve a descricao do efeito: parametros, passes e texturas.
//
//  O corpo GLSL do <shader> NAO e lido aqui — ele ja foi traduzido para MSL em
//  tempo de build por Tools/glsl2msl.py e vive em Shaders/fx_<slug>.metal.
//  Este parser so precisa da parte declarativa.
//

import Foundation

// MARK: - Tipos de parametro

public enum EffectParamKind: String, Codable, Sendable {
    case slider, spinner, float, hueDisc = "hue-disc"
    case switchParam = "switch", checkbox
    case selector, cycle
    case color, point, xyz, orient
    case curve, flare, gradacao, lut, malha
    case nodeGrading = "node-grading"

    /// Quantos floats este parametro ocupa no buffer de uniforms.
    public var floatCount: Int {
        switch self {
        case .slider, .spinner, .float, .hueDisc: return 1
        case .switchParam, .checkbox, .selector, .cycle: return 1   // int, mesmo tamanho
        case .point: return 2
        case .xyz: return 3
        case .color, .orient, .curve, .flare, .gradacao, .lut, .malha, .nodeGrading: return 4
        }
    }

    public var isInteger: Bool {
        switch self {
        case .switchParam, .checkbox, .selector, .cycle: return true
        default: return false
        }
    }
}

// MARK: - Parametro

public struct EffectParam: Codable, Sendable, Identifiable {
    public let id: String
    public let kind: EffectParamKind
    public let label: String?
    public let labelEn: String?
    public let defaultValue: [Float]
    public let minValue: Float?
    public let maxValue: Float?
    public let step: Float?
    public let options: [String]

    public init(id: String, kind: EffectParamKind, label: String? = nil, labelEn: String? = nil,
                defaultValue: [Float] = [], minValue: Float? = nil, maxValue: Float? = nil,
                step: Float? = nil, options: [String] = []) {
        self.id = id; self.kind = kind; self.label = label; self.labelEn = labelEn
        self.defaultValue = defaultValue; self.minValue = minValue; self.maxValue = maxValue
        self.step = step; self.options = options
    }
}

// MARK: - Textura

public struct EffectTexture: Codable, Sendable, Identifiable {
    /// `content` = o conteudo da camada; `buffer` = alvo intermediario de um pass;
    /// `comp` = a composicao montada atras; qualquer outro valor e um arquivo em Resources.
    public enum Source: String, Codable, Sendable {
        case content, buffer, comp, scene, file
    }
    public let id: String
    public let source: Source
    public let path: String?
    public init(id: String, source: Source, path: String? = nil) {
        self.id = id; self.source = source; self.path = path
    }
}

// MARK: - Pass

public struct EffectPass: Codable, Sendable {
    /// Para qual textura-buffer este pass escreve. `nil` = escreve na saida final.
    public let target: String?
    public let blend: String?
    public init(target: String?, blend: String? = nil) { self.target = target; self.blend = blend }
}

// MARK: - Efeito

public struct EffectManifest: Codable, Sendable, Identifiable {
    public let id: String
    public let slug: String
    public let fileName: String
    public let name: String
    public let nameEn: String?
    public let desc: String?
    public let category: String?
    public let tags: [String]
    public let thumb: String?
    public let params: [EffectParam]
    public let textures: [EffectTexture]
    public let passes: [EffectPass]
    /// Nome do parametro que controla quantas vezes os passes repetem (65 efeitos usam).
    public let iterationsParam: String?
    /// Nome da funcao fragment no .metal gerado.
    public var functionName: String { "fx_\(slug)" }

    public var hasShader: Bool { !passes.isEmpty }

    public func param(_ id: String) -> EffectParam? { params.first { $0.id == id } }
}

// MARK: - Erros

public enum EffectParseError: LocalizedError {
    case unreadable(String)
    case malformed(String, underlying: String)
    case missingRoot(String)

    public var errorDescription: String? {
        switch self {
        case .unreadable(let p):            return "Nao consegui ler o efeito em \(p)"
        case .malformed(let p, let u):      return "XML invalido em \(p): \(u)"
        case .missingRoot(let p):           return "Faltou o elemento <effect> em \(p)"
        }
    }
}

// MARK: - Parser

/// Le um XML de efeito. Usa XMLParser (SAX) para nao carregar arvore inteira:
/// alguns efeitos passam de 30 KB e sao 1.490 deles.
public final class EffectManifestParser: NSObject, XMLParserDelegate {

    private var effectAttrs: [String: String] = [:]
    private var params: [EffectParam] = []
    private var textures: [EffectTexture] = []
    private var passes: [EffectPass] = []
    private var iterationsParam: String?
    private var seenIDs: Set<String> = []
    private var insideParams = false
    private var insidePasses = false
    private var currentSelectorID: String?
    private var currentOptions: [String] = []
    private var parseError: Error?

    public static func parse(contentsOf url: URL) throws -> EffectManifest {
        guard let data = try? Data(contentsOf: url) else {
            throw EffectParseError.unreadable(url.lastPathComponent)
        }
        return try parse(data: data, fileName: url.lastPathComponent)
    }

    public static func parse(data: Data, fileName: String) throws -> EffectManifest {
        let p = EffectManifestParser()
        let xml = XMLParser(data: data)
        xml.delegate = p
        xml.shouldProcessNamespaces = false
        guard xml.parse() else {
            let msg = p.parseError?.localizedDescription
                ?? xml.parserError?.localizedDescription
                ?? "erro desconhecido na linha \(xml.lineNumber)"
            throw EffectParseError.malformed(fileName, underlying: msg)
        }
        guard !p.effectAttrs.isEmpty else { throw EffectParseError.missingRoot(fileName) }
        return p.build(fileName: fileName)
    }

    // MARK: delegate

    public func parser(_ parser: XMLParser, didStartElement name: String,
                       namespaceURI: String?, qualifiedName qn: String?,
                       attributes a: [String: String]) {
        switch name {
        case "effect":
            effectAttrs = a
        case "params":
            insideParams = true
        case "passes":
            insidePasses = true
        case "iterations":
            iterationsParam = a["param"]
        case "pass" where insidePasses:
            passes.append(EffectPass(target: a["target"], blend: a["blend"]))
        case "choice", "option":
            if currentSelectorID != nil, let t = a["text"] ?? a["label"] ?? a["name"] {
                currentOptions.append(t)
            }
        case "texture" where insideParams:
            guard let id = a["id"], !seenIDs.contains(id) else { break }
            seenIDs.insert(id)
            let srcRaw = a["src"] ?? "content"
            let src = EffectTexture.Source(rawValue: srcRaw) ?? .file
            textures.append(EffectTexture(id: id, source: src,
                                          path: src == .file ? srcRaw : a["path"]))
        default:
            guard insideParams, let kind = EffectParamKind(rawValue: name),
                  let id = a["id"], !seenIDs.contains(id) else { break }
            seenIDs.insert(id)
            flushSelector()
            if kind == .selector || kind == .cycle {
                currentSelectorID = id
                currentOptions = []
            }
            params.append(EffectParam(
                id: id, kind: kind,
                label: a["label"], labelEn: a["label-en"],
                defaultValue: Self.floats(a["default"] ?? Self.defaultXYZ(a), count: kind.floatCount),
                minValue: a["min"].flatMap(Float.init),
                maxValue: a["max"].flatMap(Float.init),
                step: (a["passo"] ?? a["step"]).flatMap(Float.init)))
        }
    }

    public func parser(_ parser: XMLParser, didEndElement name: String,
                       namespaceURI: String?, qualifiedName qn: String?) {
        switch name {
        case "params":   insideParams = false; flushSelector()
        case "passes":   insidePasses = false
        case "selector", "cycle": flushSelector()
        default: break
        }
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred e: Error) {
        parseError = e
    }

    // MARK: helpers

    private func flushSelector() {
        guard let sid = currentSelectorID, !currentOptions.isEmpty,
              let idx = params.firstIndex(where: { $0.id == sid }) else {
            currentSelectorID = nil; currentOptions = []; return
        }
        let old = params[idx]
        params[idx] = EffectParam(id: old.id, kind: old.kind, label: old.label,
                                  labelEn: old.labelEn, defaultValue: old.defaultValue,
                                  minValue: old.minValue, maxValue: old.maxValue,
                                  step: old.step, options: currentOptions)
        currentSelectorID = nil; currentOptions = []
    }

    /// Le "1.0", "0.5, 0.5" ou "#ff8800" conforme o numero de componentes esperado.
    /// Pontos e vetores do XML trazem o padrao em defaultX/defaultY/defaultZ.
    static func defaultXYZ(_ a: [String: String]) -> String? {
        guard let x = a["defaultX"] else { return nil }
        return [x, a["defaultY"], a["defaultZ"]].compactMap { $0 }.joined(separator: ",")
    }

    static func floats(_ raw: String?, count: Int) -> [Float] {
        guard let raw = raw?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return Array(repeating: 0, count: count)
        }
        if raw.hasPrefix("#") { return colorFloats(raw, count: count) }
        // chaves: default="true"/"false"
        switch raw.lowercased() {
        case "true", "on", "yes": return Array(repeating: 1, count: max(count, 1))
        case "false", "off", "no": return Array(repeating: 0, count: max(count, 1))
        default: break
        }
        var out = raw.split(whereSeparator: { $0 == "," || $0 == " " })
                     .compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
        if out.isEmpty { out = [0] }
        while out.count < count { out.append(out.count == 3 ? 1 : out[0]) }
        return Array(out.prefix(count))
    }

    static func colorFloats(_ hex: String, count: Int) -> [Float] {
        var h = hex.dropFirst()
        if h.count == 3 { h = Substring(h.map { "\($0)\($0)" }.joined()) }
        if h.count == 6 { h = h + "ff" }
        guard h.count == 8, let v = UInt32(h, radix: 16) else {
            return Array(repeating: 0, count: count)
        }
        let c: [Float] = [Float((v >> 24) & 0xff) / 255, Float((v >> 16) & 0xff) / 255,
                          Float((v >>  8) & 0xff) / 255, Float( v        & 0xff) / 255]
        return Array(c.prefix(max(count, 1)))
    }

    private func build(fileName: String) -> EffectManifest {
        let base = (fileName as NSString).deletingPathExtension
        let slug = base.map { $0.isLetter || $0.isNumber ? String($0) : "_" }.joined()
        // Efeito sem <passes> mas com shader roda num pass unico na saida.
        let effective = passes.isEmpty ? [EffectPass(target: nil)] : passes
        return EffectManifest(
            id: effectAttrs["id"] ?? "nova.effect.\(slug)",
            slug: slug,
            fileName: fileName,
            name: effectAttrs["name"] ?? base,
            nameEn: effectAttrs["name-en"],
            desc: effectAttrs["desc"],
            category: effectAttrs["category"],
            tags: (effectAttrs["tags"] ?? "").split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty },
            thumb: effectAttrs["thumb"],
            params: params,
            textures: textures,
            passes: effective,
            iterationsParam: iterationsParam)
    }
}
