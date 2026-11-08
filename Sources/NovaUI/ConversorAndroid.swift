//
//  ConversorAndroid.swift
//  NovaUI
//
//  Converte o formato de projeto do app Android para o modelo iOS. Serve aos
//  templates (.novatemplate, que vem no app) e a importacao de .nova feito no
//  Android.
//
//  Esquema tirado do APK com o REA (serializers kotlinx de com.novaeditor.persistence):
//    ProjectDto{version,id,name,width,height,fpsNumerator,fpsDenominator,durationUs,
//               background,layers,...}
//    LayerDto{id,name,content,transform,blendMode,effects,startUs,endUs,visible,
//             locked,solo,parentId,...}
//    TransformDto{position,scale,rotation,anchor,opacity,skew,positionZ,rotationX,rotationY}
//    AnimatedDto{kind,staticValue,keys}  KeyframeDto{timeUs,value,easing,id}
//    EasingDto{kind,x1,y1,x2,y2,label}   EffectDto{id,manifestId,enabled,values}
//    ContentDto{kind,color,text,fontSize,fontFamily,uri,mediaKind,sourceInPointUs,
//               sourceDurationUs,muted,speed,larguraDoSolido,alturaDoSolido,...}
//    Pacote .nova: manifesto.json (ManifestoDoPacote{midias:[{caminho,uriOriginal}]}),
//    projeto.json, midia/, capa.png.
//
//  Convencoes do Android (vistas nos templates): posicao relativa ao CENTRO da
//  composicao, ancora relativa ao centro da camada, escala e opacidade como
//  fator (1 = 100%), tempos em microssegundos.
//

import Foundation
import CoreText
import AVFoundation
import UniformTypeIdentifiers
import os

enum ConversorAndroid {

    private static let log = Logger(subsystem: "com.novavision.editor", category: "ConversorAndroid")

    struct Resultado {
        var composicao: Composition
        var avisos: [String] = []
    }

    // MARK: projeto

    /// `projeto` e o ProjectDto (ou um template, que tem `camadas`).
    /// `midias` mapeia a uri gravada na camada para o caminho dentro de media/.
    static func converter(projeto p: [String: Any], nome: String? = nil,
                          midias: [String: String] = [:]) async -> Resultado {
        let w = int(p["width"] ?? p["largura"]) ?? 1920
        let h = int(p["height"] ?? p["altura"]) ?? 1080
        let fpsN = dbl(p["fpsNumerator"]) ?? 30, fpsD = dbl(p["fpsDenominator"]) ?? 1
        let durUs = dbl(p["durationUs"] ?? p["duracaoUs"]) ?? 10_000_000
        var comp = Composition(name: nome ?? (p["name"] as? String) ?? (p["nome"] as? String) ?? "Projeto",
                               width: w, height: h,
                               frameRate: Float(fpsN / max(fpsD, 1)),
                               duration: Float(durUs / 1_000_000))
        comp.backgroundColor = cor(p["background"]) ?? SIMD4(0, 0, 0, 1)

        var avisos: [String] = []
        let camadas = (p["layers"] ?? p["camadas"]) as? [[String: Any]] ?? []
        var ids: [String: UUID] = [:]
        var layers: [Layer] = []
        for c in camadas {
            if let l = await camada(c, comp: comp, midias: midias, avisos: &avisos) {
                if let id = c["id"] as? String { ids[id] = l.id }
                layers.append(l)
            }
        }
        // Pais depois que todos tem id novo.
        for (i, c) in camadas.enumerated() where i < layers.count {
            if let pid = c["parentId"] as? String, let novo = ids[pid] { layers[i].parentID = novo }
        }
        // Android guarda de baixo para cima; a timeline iOS guarda de cima para baixo.
        comp.layers = layers.reversed()
        return Resultado(composicao: comp, avisos: avisos)
    }

    // MARK: camada

    private static func camada(_ c: [String: Any], comp: Composition, midias: [String: String],
                               avisos: inout [String]) async -> Layer? {
        let content = c["content"] as? [String: Any] ?? [:]
        let kindRaw = (content["kind"] as? String ?? "null").lowercased()
        let nome = (c["name"] as? String) ?? kindRaw
        var l: Layer

        switch kindRaw {
        case "text":
            l = Layer(name: nome, kind: .text)
            l.text = content["text"] as? String ?? nome
            l.fontSize = Float(valor(content["fontSize"])?.first ?? 96)
            l.fontName = Fontes.nomePostScript(content["fontFamily"] as? String)
            l.textColor = cor(content["color"]) ?? SIMD4(1, 1, 1, 1)
            let m = MediaContentProvider.measureText(l.text ?? " ", fontName: l.fontName,
                                                     size: CGFloat(l.fontSize ?? 96))
            l.size = SIMD2(Float(m.width), Float(m.height))
        case "solid":
            l = Layer(name: nome, kind: .solid)
            l.solidColor = cor(content["color"]) ?? SIMD4(1, 1, 1, 1)
            l.size = SIMD2(Float(dbl(content["larguraDoSolido"]) ?? Double(comp.width)),
                           Float(dbl(content["alturaDoSolido"]) ?? Double(comp.height)))
        case "adjustment":
            // Camada de ajuste: os efeitos dela valem para o que esta embaixo.
            // O motor iOS ainda desenha o conteudo dela como solido; transparente
            // ate o Compositor tratar ajuste (Docs/PENDENCIAS.md).
            l = Layer(name: nome, kind: .adjustment)
            l.solidColor = SIMD4(0, 0, 0, 0)
            l.size = comp.size
            avisos.append("\(nome): camada de ajuste ainda nao aplica efeitos no iOS")
        case "media", "image", "video":
            let k = ((content["mediaKind"] as? String) ?? kindRaw).uppercased()
            l = Layer(name: (content["displayName"] as? String) ?? nome, kind: k == "VIDEO" ? .video : .image)
            let uri = content["uri"] as? String ?? ""
            l.mediaPath = midias[uri] ?? midias[(uri as NSString).lastPathComponent]
            if l.mediaPath == nil { avisos.append("\(nome): midia nao veio no pacote") }
            l.mediaOffset = Float((dbl(content["sourceInPointUs"]) ?? 0) / 1_000_000)
            if let s = dbl(content["sourceDurationUs"]) { l.sourceDuration = Float(s / 1_000_000) }
            l.speed = Float(valor(content["speed"])?.first ?? 1)
            l.muted = content["muted"] as? Bool
        case "shape":
            l = Layer(name: nome, kind: .shape)
            l.solidColor = cor(content["fill"] ?? content["color"]) ?? SIMD4(1, 1, 1, 1)
            l.size = SIMD2(200, 200)
            avisos.append("\(nome): forma vetorial entra como retangulo")
        case "nulo", "null":
            l = Layer(name: nome, kind: .null)
        case "audio":
            l = Layer(name: nome, kind: .audio)
            l.mediaPath = midias[content["uri"] as? String ?? ""]
        default:
            avisos.append("\(nome): tipo \(kindRaw) ainda nao existe no iOS")
            return nil
        }

        let start = Float((dbl(c["startUs"]) ?? 0) / 1_000_000)
        let end = Float((dbl(c["endUs"]) ?? Double(comp.duration) * 1_000_000) / 1_000_000)
        l.startTime = start
        l.duration = max(0.04, end - start)
        l.enabled = (c["visible"] as? Bool) ?? true
        l.locked = (c["locked"] as? Bool) ?? false
        l.solo = (c["solo"] as? Bool) ?? false
        if let b = int(c["blendMode"]), BlendMode.allCases.indices.contains(b) {
            l.blendMode = BlendMode.allCases[b]
        }

        // Midia sem tamanho ainda: mede o arquivo depois (ver medirMidias).
        let tamanho = l.size ?? comp.size
        transformar(&l, c["transform"] as? [String: Any] ?? [:], comp: comp, tamanho: tamanho)
        l.effects = await efeitos(c["effects"] as? [[String: Any]] ?? [], avisos: &avisos)
        return l
    }

    private static func transformar(_ l: inout Layer, _ t: [String: Any], comp: Composition,
                                     tamanho: SIMD2<Float>) {
        let centro = comp.size / 2, meio = tamanho / 2
        if let a = animado2(t["position"], { $0 + centro }) { l.transform.position = a }
        else { l.transform.position = Animated(centro) }
        if let a = animado2(t["anchor"], { $0 + meio }) { l.transform.anchorPoint = a }
        else { l.transform.anchorPoint = Animated(meio) }
        if let a = animado2(t["scale"], { $0 * 100 }) { l.transform.scale = a }
        if let a = animado1(t["opacity"], { $0 * 100 }) { l.transform.opacity = a }
        if let a = animado1(t["rotation"], { $0 }) { l.transform.rotationZ = a }
        if let a = animado1(t["rotationX"], { $0 }) { l.transform.rotationX = a }
        if let a = animado1(t["rotationY"], { $0 }) { l.transform.rotationY = a }
        if let a = animado1(t["positionZ"], { $0 }) { l.transform.positionZ = a }
        if let a = animado2(t["skew"], { $0 }), a.isAnimated || a.value(at: 0) != .zero {
            l.transform.skew = a
        }
    }

    // MARK: efeitos

    private static func efeitos(_ lista: [[String: Any]], avisos: inout [String]) async -> [AppliedEffect] {
        var out: [AppliedEffect] = []
        for e in lista {
            guard let mid = e["manifestId"] as? String else { continue }
            var fx = AppliedEffect(effectID: mid)
            fx.enabled = (e["enabled"] as? Bool) ?? true
            let manifesto = try? await EffectRegistry.shared.manifest(id: mid)
            if manifesto == nil { avisos.append("efeito \(mid) nao existe no catalogo iOS") }
            for (pid, v) in (e["values"] as? [String: Any]) ?? [:] {
                guard let d = v as? [String: Any] else { continue }
                let kind = (d["kind"] as? String ?? "FLOAT").uppercased()
                let param = manifesto?.param(pid)
                if let param, param.kind.isInteger {
                    fx.ints[pid] = Int32((valor(d)?.first ?? 0).rounded())
                    continue
                }
                switch kind {
                case "VEC2": if let a = animado2(d, { $0 }) { fx.points[pid] = a }
                case "VEC3": if let a = animado3(d) { fx.vec3s[pid] = a }
                case "COLOR", "VEC4": if let a = animado4(d) { fx.colors[pid] = a }
                default: if let a = animado1(d, { $0 }) { fx.floats[pid] = a }
                }
            }
            out.append(fx)
        }
        return out
    }

    // MARK: Animated

    private static func chaves(_ d: [String: Any]) -> [(Float, [Double], Easing)] {
        ((d["keys"] as? [[String: Any]]) ?? []).compactMap { k in
            guard let t = dbl(k["timeUs"]), let v = numeros(k["value"]) else { return nil }
            return (Float(t / 1_000_000), v, easing(k["easing"]))
        }
    }

    static func animado1(_ any: Any?, _ f: (Float) -> Float) -> Animated<Float>? {
        guard let d = any as? [String: Any], let s = valor(d) else { return nil }
        var a = Animated(f(Float(s.first ?? 0)))
        for (t, v, e) in chaves(d) { a.setKeyframe(time: t, value: f(Float(v.first ?? 0)), easing: e) }
        return a
    }

    static func animado2(_ any: Any?, _ f: (SIMD2<Float>) -> SIMD2<Float>) -> Animated<SIMD2<Float>>? {
        guard let d = any as? [String: Any], let s = valor(d) else { return nil }
        func v2(_ x: [Double]) -> SIMD2<Float> {
            SIMD2(Float(x.first ?? 0), Float(x.count > 1 ? x[1] : (x.first ?? 0)))
        }
        var a = Animated(f(v2(s)))
        for (t, v, e) in chaves(d) { a.setKeyframe(time: t, value: f(v2(v)), easing: e) }
        return a
    }

    static func animado3(_ d: [String: Any]) -> Animated<SIMD3<Float>>? {
        guard let s = valor(d) else { return nil }
        func v3(_ x: [Double]) -> SIMD3<Float> {
            SIMD3((0..<3).map { Float(x.count > $0 ? x[$0] : 0) })
        }
        var a = Animated(v3(s))
        for (t, v, e) in chaves(d) { a.setKeyframe(time: t, value: v3(v), easing: e) }
        return a
    }

    static func animado4(_ d: [String: Any]) -> Animated<SIMD4<Float>>? {
        guard let s = valor(d) else { return nil }
        func v4(_ x: [Double]) -> SIMD4<Float> {
            SIMD4((0..<4).map { Float(x.count > $0 ? x[$0] : ($0 == 3 ? 1 : 0)) })
        }
        var a = Animated(v4(s))
        for (t, v, e) in chaves(d) { a.setKeyframe(time: t, value: v4(v), easing: e) }
        return a
    }

    static func easing(_ any: Any?) -> Easing {
        guard let d = any as? [String: Any] else { return .linear }
        switch (d["kind"] as? String ?? "linear").lowercased() {
        case "linear": return .linear
        case "hold", "constante": return .hold
        case "bezier", "cubic":
            return .bezier(SIMD2(Float(dbl(d["x1"]) ?? 0), Float(dbl(d["y1"]) ?? 0)),
                           SIMD2(Float(dbl(d["x2"]) ?? 1), Float(dbl(d["y2"]) ?? 1)))
        case let outro: return .named(outro)
        }
    }

    // MARK: valores crus

    static func valor(_ any: Any?) -> [Double]? {
        if let d = any as? [String: Any] { return numeros(d["staticValue"]) }
        return numeros(any)
    }

    static func numeros(_ any: Any?) -> [Double]? {
        if let a = any as? [Any] { return a.compactMap(dbl) }
        if let n = dbl(any) { return [n] }
        return nil
    }

    static func dbl(_ any: Any?) -> Double? {
        switch any {
        case let n as NSNumber: return n.doubleValue
        case let s as String: return Double(s)
        default: return nil
        }
    }

    static func int(_ any: Any?) -> Int? { dbl(any).map { Int($0) } }

    /// Cor: AnimatedDto COLOR (0..1), array, inteiro ARGB ou "#AARRGGBB"/"#RRGGBB".
    static func cor(_ any: Any?) -> SIMD4<Float>? {
        if let d = any as? [String: Any], let v = valor(d), v.count >= 3 {
            return SIMD4(Float(v[0]), Float(v[1]), Float(v[2]), Float(v.count > 3 ? v[3] : 1))
        }
        if let v = any as? [Any] {
            let n = v.compactMap(dbl)
            if n.count >= 3 { return SIMD4(Float(n[0]), Float(n[1]), Float(n[2]), Float(n.count > 3 ? n[3] : 1)) }
        }
        if let s = any as? String { return hex(s) }
        if let n = any as? NSNumber {
            let u = UInt32(truncatingIfNeeded: n.int64Value)
            return SIMD4(Float((u >> 16) & 0xff) / 255, Float((u >> 8) & 0xff) / 255,
                         Float(u & 0xff) / 255, Float((u >> 24) & 0xff) / 255)
        }
        return nil
    }

    static func hex(_ s: String) -> SIMD4<Float>? {
        var h = s.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        guard let u = UInt64(h, radix: 16) else { return nil }
        if h.count == 6 {
            return SIMD4(Float((u >> 16) & 0xff) / 255, Float((u >> 8) & 0xff) / 255, Float(u & 0xff) / 255, 1)
        }
        guard h.count == 8 else { return nil }
        return SIMD4(Float((u >> 16) & 0xff) / 255, Float((u >> 8) & 0xff) / 255,
                     Float(u & 0xff) / 255, Float((u >> 24) & 0xff) / 255)
    }
}

// MARK: - Fontes do app (Resources/fonts/galeria)

enum Fontes {
    private static var registradas: [String: String] = [:]   // arquivo -> PostScript
    private static let lock = NSLock()

    /// Registra as fontes da galeria do app (uma vez) e devolve o nome PostScript
    /// de "galeria:Montserrat-Bold.ttf". nil = fonte do sistema.
    static func nomePostScript(_ familia: String?) -> String? {
        guard var f = familia, !f.isEmpty else { return nil }
        if let i = f.firstIndex(of: ":") { f = String(f[f.index(after: i)...]) }
        lock.lock(); defer { lock.unlock() }
        if let n = registradas[f] { return n }
        guard let url = Bundle.main.url(forResource: (f as NSString).deletingPathExtension,
                                        withExtension: (f as NSString).pathExtension,
                                        subdirectory: "fonts/galeria") else { return nil }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let d = descs.first,
              let nome = CTFontDescriptorCopyAttribute(d, kCTFontNameAttribute) as? String else { return nil }
        registradas[f] = nome
        return nome
    }
}

// MARK: - Templates (Resources/templates/*.novatemplate)

struct TemplateDoApp: Identifiable, Hashable {
    struct Campo: Hashable {
        let id: String, tipo: String, rotulo: String, padrao: String
        let min: Double?, max: Double?
        let alvos: [[String: String]]
    }
    let id: String
    let nome: String
    let descricao: String
    let categoria: String
    let largura: Int, altura: Int
    let duracao: Double
    let campos: [Campo]
    let url: URL

    static func todos() -> [TemplateDoApp] {
        guard let dir = Bundle.main.url(forResource: "templates", withExtension: nil),
              let arquivos = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return [] }
        return arquivos.filter { $0.pathExtension == "novatemplate" }.compactMap(ler).sorted { $0.nome < $1.nome }
    }

    static func ler(_ url: URL) -> TemplateDoApp? {
        guard let d = try? Data(contentsOf: url),
              let j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else { return nil }
        let campos = ((j["campos"] as? [[String: Any]]) ?? []).map { c in
            Campo(id: c["id"] as? String ?? "", tipo: c["tipo"] as? String ?? "texto",
                  rotulo: c["rotulo"] as? String ?? "", padrao: c["padrao"] as? String ?? "",
                  min: ConversorAndroid.dbl(c["min"]), max: ConversorAndroid.dbl(c["max"]),
                  alvos: ((c["alvos"] as? [[String: Any]]) ?? []).map { a in
                      a.compactMapValues { $0 as? String }
                  })
        }
        return TemplateDoApp(id: j["id"] as? String ?? url.lastPathComponent,
                             nome: j["nome"] as? String ?? url.lastPathComponent,
                             descricao: j["descricao"] as? String ?? "",
                             categoria: j["categoria"] as? String ?? "",
                             largura: ConversorAndroid.int(j["largura"]) ?? 1080,
                             altura: ConversorAndroid.int(j["altura"]) ?? 1920,
                             duracao: (ConversorAndroid.dbl(j["duracaoUs"]) ?? 3_000_000) / 1_000_000,
                             campos: campos, url: url)
    }

    /// Aplica os valores dos campos (texto, cor, numero) no JSON e converte.
    func composicao(valores: [String: String]) async -> ConversorAndroid.Resultado? {
        guard let d = try? Data(contentsOf: url),
              var j = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any],
              var camadas = j["camadas"] as? [[String: Any]] else { return nil }
        for campo in campos {
            let v = valores[campo.id] ?? campo.padrao
            for alvo in campo.alvos {
                guard let nomeCamada = alvo["camada"], let prop = alvo["propriedade"],
                      let i = camadas.firstIndex(where: { ($0["id"] as? String) == nomeCamada }) else { continue }
                Self.aplicar(&camadas[i], propriedade: prop, valor: v, tipo: campo.tipo,
                             padrao: campo.padrao, modo: alvo["modo"])
            }
        }
        j["camadas"] = camadas
        return await ConversorAndroid.converter(projeto: j, nome: nome)
    }

    private static func aplicar(_ c: inout [String: Any], propriedade: String, valor: String,
                                tipo: String, padrao: String, modo: String?) {
        var content = c["content"] as? [String: Any] ?? [:]
        if propriedade == "texto" {
            content["text"] = valor
            if (c["name"] as? String) != nil { c["name"] = valor }
        } else if propriedade == "cor" {
            if let rgba = ConversorAndroid.hex(valor) {
                content["color"] = ["kind": "COLOR", "staticValue": [rgba.x, rgba.y, rgba.z, rgba.w]]
            }
        } else if propriedade.hasPrefix("efeito:") {
            let partes = propriedade.split(separator: ":").map(String.init)
            guard partes.count == 3, var fxs = c["effects"] as? [[String: Any]],
                  let k = fxs.firstIndex(where: { ($0["id"] as? String) == partes[1] }),
                  var values = fxs[k]["values"] as? [String: Any],
                  var p = values[partes[2]] as? [String: Any] else { return }
            if tipo == "cor", let rgba = ConversorAndroid.hex(valor) {
                p["staticValue"] = [rgba.x, rgba.y, rgba.z, rgba.w]
            } else if let n = Double(valor) {
                if modo == "escala" {
                    // Multiplica o parametro (e as chaves) pela razao valor/padrao.
                    let fator = n / max(Double(padrao) ?? 1, 1e-6)
                    if let s = ConversorAndroid.numeros(p["staticValue"]) { p["staticValue"] = s.map { $0 * fator } }
                    if var keys = p["keys"] as? [[String: Any]] {
                        for i in keys.indices {
                            if let v = ConversorAndroid.numeros(keys[i]["value"]) { keys[i]["value"] = v.map { $0 * fator } }
                        }
                        p["keys"] = keys
                    }
                } else {
                    p["staticValue"] = [n]
                    p.removeValue(forKey: "keys")
                }
            }
            values[partes[2]] = p
            fxs[k]["values"] = values
            c["effects"] = fxs
        }
        c["content"] = content
    }
}

// MARK: - Importar .nova do Android

enum ImportadorNova {

    static let tipos: [UTType] = [UTType(filenameExtension: "nova") ?? .zip, .zip]

    /// Abre o .nova, copia a midia para a pasta do projeto novo e devolve a composicao.
    /// Devolve a composicao, a pasta temporaria com as midias (mover para media/
    /// do projeto criado) e os avisos.
    static func importar(_ arquivo: URL) async throws -> (Composition, URL, [String]) {
        let acesso = arquivo.startAccessingSecurityScopedResource()
        defer { if acesso { arquivo.stopAccessingSecurityScopedResource() } }

        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("nova-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }
        try ZipReader.extract(arquivo, to: tmp)

        // projeto.json pode estar na raiz ou numa subpasta.
        let fm = FileManager.default
        var raiz = tmp
        if !fm.fileExists(atPath: tmp.appendingPathComponent("projeto.json").path),
           let sub = try? fm.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil)
            .first(where: { fm.fileExists(atPath: $0.appendingPathComponent("projeto.json").path) }) {
            raiz = sub
        }
        guard let d = try? Data(contentsOf: raiz.appendingPathComponent("projeto.json")),
              let projeto = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else {
            throw MediaImportError.unreadable("Esse arquivo não parece um projeto .nova do app.".loc)
        }
        let manifesto = (try? Data(contentsOf: raiz.appendingPathComponent("manifesto.json")))
            .flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] } ?? [:]

        let nome = (projeto["name"] as? String) ?? (manifesto["nome"] as? String)
            ?? arquivo.deletingPathExtension().lastPathComponent
        let media = fm.temporaryDirectory.appendingPathComponent("nova-midia-\(UUID().uuidString)",
                                                                 isDirectory: true)
        try fm.createDirectory(at: media, withIntermediateDirectories: true)

        // midia/ do pacote -> media/ do projeto; mapa uri original -> nome do arquivo.
        var mapa: [String: String] = [:]
        for m in (manifesto["midias"] as? [[String: Any]]) ?? [] {
            guard let caminho = m["caminho"] as? String else { continue }
            let origem = raiz.appendingPathComponent(caminho)
            let nomeArq = (caminho as NSString).lastPathComponent
            let alvo = media.appendingPathComponent(nomeArq)
            if fm.fileExists(atPath: origem.path) {
                try? fm.removeItem(at: alvo)
                try? fm.copyItem(at: origem, to: alvo)
                if let uri = m["uriOriginal"] as? String { mapa[uri] = nomeArq }
                mapa[caminho] = nomeArq
                mapa[nomeArq] = nomeArq
            }
        }
        // Pacotes sem manifesto: copia tudo de midia/.
        let pastaMidia = raiz.appendingPathComponent("midia")
        for f in (try? fm.contentsOfDirectory(at: pastaMidia, includingPropertiesForKeys: nil)) ?? []
        where mapa[f.lastPathComponent] == nil {
            let alvo = media.appendingPathComponent(f.lastPathComponent)
            if (try? fm.copyItem(at: f, to: alvo)) != nil { mapa[f.lastPathComponent] = f.lastPathComponent }
        }

        var r = await ConversorAndroid.converter(projeto: projeto, nome: nome, midias: mapa)
        await medirMidias(&r.composicao, media: media)
        return (r.composicao, media, r.avisos)
    }

    /// Mede as midias (o .nova nao guarda o tamanho) e recoloca a ancora no centro.
    static func medirMidias(_ comp: inout Composition, media: URL) async {
        for i in comp.layers.indices {
            guard let p = comp.layers[i].mediaPath, comp.layers[i].size == nil else { continue }
            let url = media.appendingPathComponent(p)
            var tamanho: SIMD2<Float>?
            if comp.layers[i].kind == .image, let cg = MediaContentProvider.loadOrientedImage(url, maxPixel: 4096) {
                tamanho = SIMD2(Float(cg.width), Float(cg.height))
            } else if comp.layers[i].kind == .video {
                let asset = AVURLAsset(url: url)
                if let t = try? await asset.loadTracks(withMediaType: .video).first,
                   let n = try? await t.load(.naturalSize), let tf = try? await t.load(.preferredTransform) {
                    let s = n.applying(tf)
                    tamanho = SIMD2(Float(abs(s.width)), Float(abs(s.height)))
                }
            }
            guard let tamanho else { continue }
            comp.layers[i].size = tamanho
            // A ancora do Android e relativa ao centro: soma o meio do tamanho real.
            let antigo = comp.size / 2   // usado como "meio" na conversao sem tamanho
            var a = comp.layers[i].transform.anchorPoint
            a.staticValue = a.staticValue - antigo + tamanho / 2
            comp.layers[i].transform.anchorPoint = a
        }
    }
}
