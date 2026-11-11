//
//  AEImport.swift
//  NovaUI
//
//  Importa projetos (.aep) e presets de efeito (.ffx) do After Effects direto
//  no iPhone, sem servidor. No Android o NovaEditor manda o arquivo para o
//  conversor da Nova (que exige o Play Integrity do Google e nao atende o iOS);
//  aqui o arquivo e lido localmente.
//
//  Formato (RIFX, big-endian), lido nos arquivos de exemplo:
//    "RIFX" tam "Egg!" (.aep) / "FaFX" (.ffx); blocos [4cc][u32 tam][dados] com
//    preenchimento par; "LIST" [tam][tipo 4cc][filhos].
//    Item (LIST Item): idta u16 tipo (1 pasta, 4 comp, 7 footage) e u32 id @16;
//      nome em Utf8. Comp: cdta, largura/altura u16 @140/@142, duracao u32 @44
//      dividida pela base de tempo u32 @8, fps 16.16 @156.
//    Camada (LIST Layr): ldta, id u32 @0, inicio s32 @12 / base u32 @16,
//      entrada s32 @20 / u32 @24 e saida s32 @28 / u32 @32 relativas ao
//      inicio, id da fonte u32 @40, pai u32 @132; nome em Utf8.
//      Propriedades: LIST tdgp com pares tdmn (nome interno, 40 bytes) +
//      LIST tdbs (valor) ou LIST tdgp (grupo). tdbs: tdsn (nome visivel),
//      cdat (doubles estaticos) e LIST list (lhd3: quantidade @8, espacial @12,
//      tamanho do item @16; ldat: tempo s32 @0, valores em double @8 — ou @56
//      nas propriedades espaciais). So o que difere do padrao fica gravado.
//    Efeito (LIST sspc): fnam (nome), LIST parT (tdmn "<match>-0001"…), LIST
//      tdgp com os valores. Footage (LIST Pin): sspc com tipo 4cc @22 e
//      largura/altura u32 @30/@34; opti "Soli" com cor ARGB float @10 e nome
//      @26; Alas/alas com o JSON {"fullpath": …}.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Leitor RIFX

struct AEChunk {
    let id: String
    let listType: String?
    let range: Range<Int>
    var kids: [AEChunk] = []
}

struct AEArquivo {
    let bytes: [UInt8]
    let forma: String
    let raiz: [AEChunk]

    init(_ data: Data) throws {
        bytes = [UInt8](data)
        guard bytes.count >= 12, String(bytes: bytes[0..<4], encoding: .ascii) == "RIFX" else {
            throw AEErro.formato
        }
        forma = String(bytes: bytes[8..<12], encoding: .ascii) ?? ""
        var r: [AEChunk] = []
        AEArquivo.ler(bytes, 12, bytes.count, &r, 0)
        raiz = r
    }

    private static func ler(_ b: [UInt8], _ inicio: Int, _ fim: Int, _ out: inout [AEChunk], _ prof: Int) {
        var o = inicio
        while o + 8 <= fim {
            let id = String(bytes: b[o..<o + 4], encoding: .isoLatin1) ?? "????"
            let tam = Int(u32(b, o + 4))
            let dados = o + 8
            guard tam >= 0, dados + tam <= b.count else { break }
            if id == "LIST", tam >= 4 {
                let tipo = String(bytes: b[dados..<dados + 4], encoding: .isoLatin1) ?? ""
                var c = AEChunk(id: id, listType: tipo, range: (dados + 4)..<(dados + tam))
                if tipo != "btdk" && prof < 64 { ler(b, dados + 4, dados + tam, &c.kids, prof + 1) }
                out.append(c)
            } else {
                out.append(AEChunk(id: id, listType: nil, range: dados..<(dados + tam)))
            }
            o = dados + tam + (tam & 1)
        }
    }

    static func u32(_ b: [UInt8], _ o: Int) -> UInt32 {
        guard o + 4 <= b.count else { return 0 }
        return UInt32(b[o]) << 24 | UInt32(b[o + 1]) << 16 | UInt32(b[o + 2]) << 8 | UInt32(b[o + 3])
    }
    func u32(_ c: AEChunk, _ o: Int) -> UInt32 {
        let p = c.range.lowerBound + o
        return p + 4 <= c.range.upperBound ? AEArquivo.u32(bytes, p) : 0
    }
    func s32(_ c: AEChunk, _ o: Int) -> Int32 { Int32(bitPattern: u32(c, o)) }
    func u16(_ c: AEChunk, _ o: Int) -> UInt16 {
        let p = c.range.lowerBound + o
        guard p + 2 <= c.range.upperBound else { return 0 }
        return UInt16(bytes[p]) << 8 | UInt16(bytes[p + 1])
    }
    func f64(_ c: AEChunk, _ o: Int) -> Double {
        let p = c.range.lowerBound + o
        guard p + 8 <= c.range.upperBound else { return 0 }
        var v: UInt64 = 0
        for i in 0..<8 { v = v << 8 | UInt64(bytes[p + i]) }
        return Double(bitPattern: v)
    }
    func f32(_ c: AEChunk, _ o: Int) -> Float {
        Float(bitPattern: u32(c, o))
    }
    /// Texto de um bloco: "Utf8"+tam+texto dentro dele, ou texto com zero no fim.
    func texto(_ c: AEChunk) -> String {
        let r = c.range
        if r.count >= 8, String(bytes: bytes[r.lowerBound..<r.lowerBound + 4], encoding: .ascii) == "Utf8" {
            let n = Int(AEArquivo.u32(bytes, r.lowerBound + 4))
            let a = r.lowerBound + 8, z = min(a + n, r.upperBound)
            return String(decoding: bytes[a..<z], as: UTF8.self)
        }
        let fatia = bytes[r]
        let fim = fatia.firstIndex(of: 0) ?? r.upperBound
        return String(decoding: bytes[r.lowerBound..<fim], as: UTF8.self)
    }
    func textoBruto(_ c: AEChunk, de o: Int, max: Int) -> String {
        let a = c.range.lowerBound + o
        guard a < c.range.upperBound else { return "" }
        let z = min(a + max, c.range.upperBound)
        let fim = bytes[a..<z].firstIndex(of: 0) ?? z
        return String(decoding: bytes[a..<fim], as: UTF8.self)
    }
}

extension AEChunk {
    func filho(_ id: String, _ tipo: String? = nil) -> AEChunk? {
        kids.first { $0.id == id && (tipo == nil || $0.listType == tipo) }
    }
    func filhos(_ id: String, _ tipo: String? = nil) -> [AEChunk] {
        kids.filter { $0.id == id && (tipo == nil || $0.listType == tipo) }
    }
}

enum AEErro: LocalizedError {
    case formato, semComp, semEfeito
    var errorDescription: String? {
        switch self {
        case .formato: return "Esse arquivo não é um projeto (.aep) nem um preset (.ffx) do After Effects.".loc
        case .semComp: return "Não achei nenhuma composição no projeto do After Effects.".loc
        case .semEfeito: return "Não achei efeitos nesse preset (.ffx).".loc
        }
    }
}

// MARK: - Modelo lido

struct AEPropriedade {
    var match: String
    var nome: String
    var estatico: [Double]
    var chaves: [(t: Double, v: [Double])]
}

struct AEEfeito {
    var match: String
    var nome: String
    var props: [AEPropriedade]
    /// Magic Bullet Looks: as ferramentas do Look (codigo de 4 letras + valores), lidas
    /// do bloco "MBL2" que o plugin guarda no parametro de dados (LIST aRbs / aRbp).
    var look: [(codigo: String, valores: [Double])] = []
    var lookIgnoradas: [String] = []
    /// Optical Flares: o flare do Lens Editor (bloco "OFP" do parametro de dados).
    var flareOfp: Data? = nil
}

struct AEGrupo {
    var props: [String: AEPropriedade] = [:]
    var efeitos: [AEEfeito] = []
    var temTexto = false
    var temForma = false
    var temCamera = false
}

extension AEArquivo {
    /// Le um tdgp: propriedades (pelo nome interno), efeitos e marcas do tipo de camada.
    /// `base` converte as chaves para segundos.
    func grupo(_ g: AEChunk, base: Double) -> AEGrupo {
        var out = AEGrupo()
        var atual: String?
        for k in g.kids {
            if k.id == "tdmn" { atual = texto(k); continue }
            guard k.id == "LIST", let nome = atual else {
                if k.id == "LIST", k.listType == "sspc", let e = efeito(k, base: base) { out.efeitos.append(e) }
                continue
            }
            switch k.listType {
            case "tdbs":
                out.props[nome] = propriedade(k, match: nome, base: base)
            case "tdgp":
                if nome == "ADBE Text Properties" { out.temTexto = true }
                if nome == "ADBE Root Vectors Group" { out.temForma = true }
                if nome == "ADBE Camera Options Group" { out.temCamera = true }
                let sub = grupo(k, base: base)
                out.efeitos += sub.efeitos
                if nome == "ADBE Transform Group" || nome == "ADBE Effect Parade" {
                    for (a, b) in sub.props where out.props[a] == nil { out.props[a] = b }
                }
                out.temTexto = out.temTexto || sub.temTexto
            case "sspc":
                if let e = efeito(k, base: base) { out.efeitos.append(e) }
            default: break
            }
            atual = nil
        }
        return out
    }

    func propriedade(_ tdbs: AEChunk, match: String, base: Double) -> AEPropriedade {
        let nome = tdbs.filho("tdsn").map(texto) ?? ""
        var est: [Double] = []
        if let cd = tdbs.filho("cdat") {
            let n = min(cd.range.count / 8, 4)
            est = (0..<n).map { f64(cd, $0 * 8) }
        }
        var chaves: [(Double, [Double])] = []
        if let l = tdbs.filho("LIST", "list"), let h = l.filho("lhd3"), let d = l.filho("ldat") {
            let qtd = Int(u32(h, 8)), tam = Int(u32(h, 16))
            let espacial = u32(h, 12) == 2
            if tam > 8, qtd > 0, qtd < 100_000, qtd * tam <= d.range.count {
                let ini = espacial ? 56 : 8
                let dims = max(1, min(3, (tam - ini) / 8))
                for i in 0..<qtd {
                    let o = i * tam
                    let t = Double(s32(d, o)) / base
                    chaves.append((t, (0..<dims).map { f64(d, o + ini + $0 * 8) }))
                }
            }
        }
        return AEPropriedade(match: match, nome: nome == "-_0_/-" ? "" : nome, estatico: est,
                             chaves: chaves.map { (t: $0.0, v: $0.1) })
    }

    func efeito(_ sspc: AEChunk, base: Double) -> AEEfeito? {
        let nome = sspc.filho("fnam").map(texto) ?? ""
        var match = ""
        var nomes: [String: String] = [:]
        if let pt = sspc.filho("LIST", "parT") {
            var ultimo: String?
            for k in pt.kids {
                if k.id == "tdmn" {
                    let m = texto(k)
                    if match.isEmpty, let r = m.range(of: "-", options: .backwards) { match = String(m[..<r.lowerBound]) }
                    ultimo = m
                } else if k.id == "pard", let u = ultimo {
                    nomes[u] = textoBruto(k, de: 16, max: 32)
                }
            }
        }
        guard let g = sspc.filho("LIST", "tdgp") else { return nil }
        var props: [AEPropriedade] = []
        var atual: String?
        for k in g.kids {
            if k.id == "tdmn" { atual = texto(k); continue }
            if k.id == "LIST", k.listType == "tdbs", let m = atual {
                var p = propriedade(k, match: m, base: base)
                if p.nome.isEmpty { p.nome = nomes[m] ?? "" }
                props.append(p)
            }
            atual = nil
        }
        if nome.isEmpty && match.isEmpty { return nil }
        var fx = AEEfeito(match: match, nome: nome.isEmpty ? match : nome, props: props)
        if match == "VIDEOCOPILOT OpticalFlares" || nome == "Optical Flares" {
            for rb in g.filhos("LIST", "aRbs") {
                if let d = rb.filho("aRbp"), d.range.count > 4,
                   bytes[d.range.lowerBound] == 0x4F, bytes[d.range.lowerBound + 1] == 0x46,
                   bytes[d.range.lowerBound + 2] == 0x50 {
                    fx.flareOfp = Data(bytes[d.range])
                }
            }
        }
        if match == "MB LookSuite3" || nome == "Magic Bullet Looks" || nome == "Looks" {
            for rb in g.filhos("LIST", "aRbs") {
                if let d = rb.filho("aRbp") { lerLook(d, &fx) }
            }
        }
        return fx
    }

    /// "MBL2" [4cc][u32 tam][dados]...; cada "tool" traz [codigo][0] [u32 n] e n doubles.
    func lerLook(_ c: AEChunk, _ fx: inout AEEfeito) {
        let a = c.range.lowerBound, z = c.range.upperBound
        guard z - a > 16, String(bytes: bytes[a..<a + 4], encoding: .ascii) == "MBL2" else { return }
        func tag(_ o: Int) -> String { String(bytes: bytes[o..<o + 4], encoding: .isoLatin1) ?? "" }
        func dbl(_ o: Int) -> Double {
            var v: UInt64 = 0
            for i in 0..<8 { v = v << 8 | UInt64(bytes[o + i]) }
            return Double(bitPattern: v)
        }
        var o = a + 8
        while o + 8 <= z {
            let t = tag(o), n = Int(AEArquivo.u32(bytes, o + 4))
            let dados = o + 8
            guard n >= 0, dados + n <= z else { break }
            if t == "tool", n >= 12 {
                let cod = tag(dados)
                let q = Int(AEArquivo.u32(bytes, dados + 8))
                if q >= 0, dados + 12 + q * 8 <= dados + n {
                    fx.look.append((cod, (0..<q).map { dbl(dados + 12 + $0 * 8) }))
                }
            } else if t == "lutr" {
                fx.lookIgnoradas.append("LUT")
            } else if t == "cust" {
                fx.lookIgnoradas.append(textoBruto(AEChunk(id: t, listType: nil, range: dados..<(dados + n)), de: 0, max: 64))
            }
            o = dados + n
        }
    }
}

// MARK: - Para o modelo da Nova

enum AEImportador {

    static let tipos: [UTType] = [
        UTType(filenameExtension: "aep") ?? .data,
        UTType(filenameExtension: "ffx") ?? .data,
        .data,
    ]

    /// Nomes do AE (match name) -> nome do efeito no catalogo da Nova.
    static let porMatch: [String: String] = [
        "ADBE Gaussian Blur 2": "Gaussian Blur", "ADBE Gaussian Blur": "Gaussian Blur",
        "ADBE Glo2": "Glow", "ADBE Glow": "Glow", "PEDG": "Deep Glow",
        "ADBE CurvesCustom": "Curves", "ADBE HUE SATURATION": "Hue/Saturation",
        "ADBE Easy Levels2": "Levels", "ADBE Pro Levels2": "Levels",
        "ADBE Turbulent Displace": "Turbulent Displace", "ADBE Tile": "Motion Tile",
        "ADBE Geometry2": "Transform", "ADBE Optics Compensation": "Optics Compensation",
        "ADBE Motion Blur": "Directional Blur", "ADBE Radial Blur": "Radial Blur",
        "ADBE Brightness & Contrast 2": "Brightness & Contrast", "ADBE Exposure2": "Exposure",
        "ADBE Box Blur2": "Fast Box Blur", "ADBE Camera Lens Blur": "Camera Lens Blur",
        "ADBE Sharpen": "Sharpen", "ADBE Unsharp Mask2": "Unsharp Mask",
        "ADBE Fractal Noise": "Fractal Noise", "ADBE Displacement Map": "Displacement Map",
        "ADBE Wave Warp": "Wave Warp", "ADBE Twirl": "Twirl", "ADBE Lumetri": "Lumetri Color",
        "ADBE Tint": "Tint", "ADBE Fill": "Fill", "ADBE Invert": "Invert",
        "ADBE Drop Shadow": "Drop Shadow", "ADBE Linear Color Key2": "Linear Color Key",
        "ADBE Venetian Blinds": "Venetian Blinds", "ADBE Vibrance": "Vibrance",
        "ADBE Color Balance (HLS)": "Color Balance (HLS)", "ADBE Tritone": "Tritone",
        "ADBE Threshold2": "Threshold", "ADBE Minimax": "Minimax", "ADBE Bevel Alpha": "Bevel Alpha",
        "ADBE Linear Wipe": "Linear Wipe", "ADBE Slider Control": "Slider Control",
        "ADBE Point Control": "Point Control", "ADBE Angle Control": "Angle Control",
        "ADBE Checkbox Control": "Checkbox Control", "ADBE Color Control": "Color Control",
        "VIDEOCOPILOT OpticalFlares": "Optical Flares", "ADBE Apply Color LUT2": "Apply Color LUT",
        "ADBE Noise2": "Noise", "ADBE Posterize": "Posterize", "ADBE Mosaic": "Mosaic",
        "ADBE Ripple": "Ripple", "ADBE Spherize": "Spherize", "ADBE Bulge": "Bulge",
        "ADBE Echo": "Echo", "ADBE Posterize Time": "Posterize Time", "ADBE Black&White": "Black & White",
        "ADBE Change To Color": "Change to Color", "ADBE Channel Mixer": "Channel Mixer",
        "ADBE Gradient Ramp": "Gradient Ramp", "ADBE Ramp": "Gradient Ramp", "ADBE Stroke": "Stroke",
        "ADBE Glo": "Glow", "S_Shake": "S_Shake", "S_Glow": "S_Glow", "S_Sharpen": "S_Sharpen",
        "MB LookSuite3": "Magic Bullet Looks", "Looks": "Magic Bullet Looks",
        "CSpice Glitchify": "Glitchify", "ADBE 4ColorGradient": "4-Color Gradient",
    ]

    enum TipoAE { case num, bool, menu([Int]), ponto, inteiro, direcao }

    /// Parametros pelo nome interno do AE (sufixo de "<match>-0001"), como a tabela do
    /// conversor do APK: os nomes visiveis do Glitchify se repetem entre os grupos.
    static let porParametro: [String: [String: (String, TipoAE)]] = [
        "CSpice Glitchify": [
            "0001": ("amount", .num), "0002": ("speed", .num), "0003": ("seed", .inteiro),
            "0005": ("completion", .num), "0006": ("softness", .num),
            "0007": ("transitionChannel", .menu(Glitchify.menuTransicao)),
            "0010": ("transformSpeed", .num), "0011": ("position", .ponto), "0012": ("positionWiggle", .num),
            "0013": ("scale", .num), "0014": ("scaleWiggle", .num), "0015": ("cropTopLeft", .ponto),
            "0016": ("cropBottomRight", .ponto), "0017": ("cropWiggle", .num), "0018": ("opacity", .num),
            "0019": ("transferMode", .menu(Glitchify.menuModos)), "0020": ("compositeOver", .bool),
            "0023": ("channelEnable", .bool), "0025": ("splitChannel", .menu(Glitchify.menuSplit)),
            "0026": ("splitH", .num), "0027": ("splitV", .num), "0028": ("splitSpeed", .num),
            "0031": ("scaleAmount", .num), "0032": ("scaleChannel", .menu(Glitchify.menuScale)),
            "0033": ("scaleVertical", .bool), "0034": ("scaleOffset", .num), "0035": ("scaleSpeed", .num),
            "0037": ("channelMode", .menu(Glitchify.menuModos)), "0040": ("colorEnable", .bool),
            "0041": ("colorOffset", .num), "0042": ("colorAmount", .num), "0043": ("colorOpacity", .num),
            "0044": ("colorMode", .menu(Glitchify.menuModos)), "0047": ("imageEnable", .bool),
            "0048": ("streak", .num), "0049": ("verticalSort", .bool), "0051": ("sliceAmount", .num),
            "0057": ("blockAmount", .num), "0058": ("blockSpeed", .num), "0059": ("blockWidth", .num),
            "0060": ("blockHeight", .num), "0061": ("blockDirection", .direcao),
            "0063": ("blockMode", .menu(Glitchify.menuModos)), "0066": ("compressionEnable", .bool),
            "0067": ("compressionMultiplier", .num), "0068": ("ditherAmount", .num), "0069": ("jpegAmount", .num),
            "0073": ("showNoise", .bool), "0074": ("gain", .num), "0075": ("lacunarity", .num),
            "0076": ("octaves", .inteiro), "0079": ("repeatEdge", .bool), "0082": ("sigmoid", .bool),
            "0083": ("quantization", .num), "0084": ("fillGaps", .bool), "0087": ("useNoise", .bool),
            "0088": ("noiseCutoff", .inteiro), "0096": ("grouping", .num), "0099": ("wiggleSteps", .num),
        ],
    ]

    static func norm(_ s: String) -> String {
        s.lowercased().folding(options: .diacriticInsensitive, locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }

    /// Catalogo indexado pelo nome normalizado (nome e nome em ingles).
    static func catalogo() async -> [String: EffectIndexEntry] {
        try? await EffectRegistry.shared.load()
        var m: [String: EffectIndexEntry] = [:]
        for e in await EffectRegistry.shared.all {
            for n in [e.nameEn, e.name].compactMap({ $0 }) {
                let k = norm(n)
                // prefere os efeitos "ae-…" (feitos para bater com o AE)
                if m[k] == nil || e.id.contains(".ae") { m[k] = e }
            }
        }
        return m
    }

    /// Converte um efeito do AE num efeito da Nova (nil quando nao ha equivalente).
    static func converter(_ fx: AEEfeito, catalogo: [String: EffectIndexEntry], tamanho: SIMD2<Float>,
                          inicioDaCamada: Double) async -> AppliedEffect? {
        let candidatos = [porMatch[fx.match], porMatch[fx.nome], fx.nome, fx.match].compactMap { $0 }
        guard let entrada = candidatos.lazy.compactMap({ catalogo[norm($0)] }).first,
              let man = try? await EffectRegistry.shared.manifest(id: entrada.id) else { return nil }
        var ap = AppliedEffect(effectID: entrada.id)
        if let f = fx.flareOfp { ap.luts = ["flare": "ofp64:" + f.base64EncodedString()] }
        if let mapa = porParametro[fx.match] {
            for prop in fx.props {
                guard let r = prop.match.range(of: "-", options: .backwards),
                      let (pid, tipo) = mapa[String(prop.match[r.upperBound...])],
                      let p = man.params.first(where: { $0.id == pid }),
                      let v = prop.estatico.first else { continue }
                switch tipo {
                case .bool: ap.ints[pid] = v != 0 ? 1 : 0
                case .direcao: ap.ints[pid] = Int32(max(0, Int(v.rounded()) - 1))
                case .menu(let m): ap.ints[pid] = Int32(max(0, m.firstIndex(of: Int(v.rounded())) ?? 0))
                case .num, .ponto, .inteiro: aplicar(prop, em: p, &ap, tamanho: tamanho, inicio: inicioDaCamada)
                }
            }
            return ap
        }
        var porNome: [String: EffectParam] = [:]
        for p in man.params {
            for n in [p.labelEn, p.label, p.id].compactMap({ $0 }) where porNome[norm(n)] == nil {
                porNome[norm(n)] = p
            }
        }
        for prop in fx.props where !prop.nome.isEmpty {
            guard let p = porNome[norm(prop.nome)] else { continue }
            aplicar(prop, em: p, &ap, tamanho: tamanho, inicio: inicioDaCamada)
        }
        return ap
    }

    private static func aplicar(_ prop: AEPropriedade, em p: EffectParam, _ ap: inout AppliedEffect,
                                tamanho: SIMD2<Float>, inicio: Double) {
        let v = prop.estatico
        switch p.kind {
        case .slider, .spinner, .float, .hueDisc:
            guard let x = v.first else { return }
            var a = Animated(Float(x))
            for k in prop.chaves { _ = a.setKeyframe(time: Float(inicio + k.t), value: Float(k.v.first ?? x)) }
            ap.floats[p.id] = a
        case .switchParam, .checkbox:
            if let x = v.first { ap.ints[p.id] = x != 0 ? 1 : 0 }
        case .selector, .cycle:
            // os menus do AE comecam em 1
            if let x = v.first { ap.ints[p.id] = Int32(max(0, Int(x.rounded()) - 1)) }
        case .color:
            guard v.count >= 4 else { return }
            let esc: Double = (v.max() ?? 0) > 1.0001 ? 255 : 1
            ap.colors[p.id] = Animated(SIMD4(Float(v[1] / esc), Float(v[2] / esc), Float(v[3] / esc), Float(v[0] / esc)))
        case .point:
            guard v.count >= 2 else { return }
            let normalizado = (p.maxValue ?? 1) <= 1.0001
            func conv(_ q: [Double]) -> SIMD2<Float> {
                let x = Float(q.first ?? 0), y = Float(q.count > 1 ? q[1] : 0)
                return normalizado ? SIMD2(x / max(tamanho.x, 1), y / max(tamanho.y, 1)) : SIMD2(x, y)
            }
            var a = Animated(conv(v))
            for k in prop.chaves where k.v.count >= 2 { _ = a.setKeyframe(time: Float(inicio + k.t), value: conv(k.v)) }
            ap.points[p.id] = a
        default:
            break
        }
    }

    /// As ferramentas de um Magic Bullet Looks lido do AE, na ordem do Look, para
    /// entrarem logo depois da cabeca (como o motor espera).
    static func ferramentasDoLook(_ fx: AEEfeito) async -> (efeitos: [AppliedEffect], avisos: [String]) {
        var porCodigo: [String: (id: String, params: [String])] = [:]
        for (id, t) in LooksFerramentas.porManifesto { porCodigo[t.codigo] = (id, t.params) }
        var out: [AppliedEffect] = [], fora: [String] = fx.lookIgnoradas
        for t in fx.look {
            guard let f = porCodigo[t.codigo], let man = try? await EffectRegistry.shared.manifest(id: f.id) else {
                fora.append(t.codigo); continue
            }
            var ap = AppliedEffect(effectID: f.id)
            for (i, nome) in f.params.enumerated() where i < t.valores.count {
                guard let p = man.params.first(where: { $0.id == nome }) else { continue }
                let v = t.valores[i]
                switch p.kind {
                case .switchParam, .checkbox, .selector, .cycle:
                    ap.ints[p.id] = Int32(max(0, min(1_000_000, Int(v.rounded()))))
                case .slider, .spinner, .float, .hueDisc:
                    ap.floats[p.id] = Animated(Float(v))
                default: break
                }
            }
            out.append(ap)
        }
        var avisos: [String] = []
        if !fora.isEmpty {
            avisos.append(String(format: "Ferramentas do Looks sem equivalente: %@".loc, fora.joined(separator: ", ")))
        }
        return (out, avisos)
    }

    // MARK: .ffx

    /// Efeitos de um preset .ffx, para aplicar numa camada.
    static func efeitosDoPreset(_ url: URL, tamanho: SIMD2<Float>) async throws
        -> (efeitos: [AppliedEffect], animacao: [AEPropriedade], avisos: [String]) {
        let dados = try lerArquivo(url)
        let arq = try AEArquivo(dados)
        guard arq.forma == "FaFX" else { throw AEErro.formato }
        var lidos: [AEEfeito] = []
        func varrer(_ cs: [AEChunk]) {
            for c in cs {
                if c.id == "LIST", c.listType == "sspc" {
                    if let e = arq.efeito(c, base: 30720) { lidos.append(e) }
                } else if !c.kids.isEmpty { varrer(c.kids) }
            }
        }
        varrer(arq.raiz)

        // Preset de animacao: os caminhos (tdsp) e, na mesma ordem, os valores (tdbs).
        var animacao: [AEPropriedade] = []
        if let besc = arq.raiz.first(where: { $0.listType == "besc" }) {
            var base: Double = 30720
            if let beso = besc.filho("beso") {
                let b = Double(arq.u32(beso, 12)); if b > 0 { base = b }
            }
            let caminhos = besc.filhos("LIST", "tdsp").compactMap { sp -> String? in
                sp.filhos("LIST", "tdsi").compactMap { $0.filho("tdmn").map(arq.texto) }.last
            }.filter { $0 != "ADBE End of path sentinel" }
            for (i, tb) in besc.filhos("LIST", "tdbs").enumerated() where i < caminhos.count {
                animacao.append(arq.propriedade(tb, match: caminhos[i], base: base))
            }
        }
        guard !lidos.isEmpty || !animacao.isEmpty else { throw AEErro.semEfeito }
        let cat = await catalogo()
        var out: [AppliedEffect] = [], avisos: [String] = []
        for e in lidos {
            if let ap = await converter(e, catalogo: cat, tamanho: tamanho, inicioDaCamada: 0) {
                out.append(ap)
                if !e.look.isEmpty || !e.lookIgnoradas.isEmpty {
                    let (fs, av) = await ferramentasDoLook(e)
                    out += fs; avisos += av
                }
            }
            else { avisos.append(String(format: "Sem equivalente na Nova: %@".loc, e.nome)) }
        }
        return (out, animacao, avisos)
    }

    /// Aplica um preset de animacao (posicao/rotacao como deslocamento sobre o
    /// valor atual da camada; escala e opacidade como estao), a partir de `t0`.
    static func aplicarAnimacao(_ props: [AEPropriedade], em l: inout Layer, aPartirDe t0: Float) -> Int {
        var n = 0
        let pos0 = l.transform.position.value(at: t0)
        let rot0 = l.transform.rotationZ.value(at: t0)
        let px = props.first { $0.match == "ADBE Position_0" }, py = props.first { $0.match == "ADBE Position_1" }
        if px != nil || py != nil {
            let tempos = Set((px?.chaves.map(\.t) ?? []) + (py?.chaves.map(\.t) ?? [])).sorted()
            for t in tempos {
                let kx = px?.chaves.first(where: { abs($0.t - t) < 1e-6 })
                let ky = py?.chaves.first(where: { abs($0.t - t) < 1e-6 })
                let x: Double = kx?.v.first ?? px?.estatico.first ?? 0
                let y: Double = ky?.v.first ?? py?.estatico.first ?? 0
                _ = l.transform.position.setKeyframe(time: t0 + Float(t), value: pos0 + SIMD2(Float(x), Float(y)))
                n += 1
            }
        }
        for p in props {
            switch p.match {
            case "ADBE Position":
                for k in p.chaves where k.v.count >= 2 {
                    _ = l.transform.position.setKeyframe(time: t0 + Float(k.t), value: pos0 + SIMD2(Float(k.v[0]), Float(k.v[1])))
                    n += 1
                }
            case "ADBE Rotate Z":
                for k in p.chaves {
                    _ = l.transform.rotationZ.setKeyframe(time: t0 + Float(k.t), value: rot0 + Float(k.v.first ?? 0)); n += 1
                }
            case "ADBE Scale":
                for k in p.chaves where k.v.count >= 2 {
                    _ = l.transform.scale.setKeyframe(time: t0 + Float(k.t), value: SIMD2(Float(k.v[0]), Float(k.v[1])) * 100); n += 1
                }
            case "ADBE Opacity":
                let fator: Float = (p.chaves.compactMap { $0.v.first }.map { abs($0) }.max() ?? 0) <= 1.0001 ? 100 : 1
                for k in p.chaves {
                    _ = l.transform.opacity.setKeyframe(time: t0 + Float(k.t), value: Float(k.v.first ?? 1) * fator); n += 1
                }
            default: break
            }
        }
        return n
    }

    // MARK: .aep

    struct Footage { var nome: String; var solido: SIMD4<Float>?; var tamanho: SIMD2<Float>?; var caminho: String?; var ehComp = false }

    /// Projeto do AE -> composicao da Nova (a comp com mais camadas). `midias`
    /// sao arquivos escolhidos junto com o .aep; casam com as fontes pelo nome.
    static func projeto(_ url: URL, midias: [URL], pastaDeMidia: URL) async throws -> (Composition, [String]) {
        let dados = try lerArquivo(url)
        let arq = try AEArquivo(dados)
        guard arq.forma == "Egg!" else { throw AEErro.formato }

        // Itens do projeto (comps e footage), pelo id.
        var comps: [(id: UInt32, item: AEChunk)] = []
        var fontes: [UInt32: Footage] = [:]
        func varrer(_ cs: [AEChunk]) {
            for c in cs where c.id == "LIST" {
                if c.listType == "Item", let idta = c.filho("idta") {
                    let tipo = arq.u16(idta, 0), id = arq.u32(idta, 16)
                    let nome = c.filho("Utf8").map(arq.texto) ?? ""
                    if tipo == 4 { comps.append((id, c)); fontes[id] = Footage(nome: nome, ehComp: true) }
                    if tipo == 7, let pin = c.filho("LIST", "Pin ") {
                        var f = Footage(nome: nome)
                        if let ss = pin.filho("sspc") {
                            let w = arq.u32(ss, 30), h = arq.u32(ss, 34)
                            if w > 0, h > 0, w < 20000, h < 20000 { f.tamanho = SIMD2(Float(w), Float(h)) }
                        }
                        if let op = pin.filho("opti"), arq.textoBruto(op, de: 0, max: 4) == "Soli" {
                            let a = arq.f32(op, 10), r = arq.f32(op, 14), g = arq.f32(op, 18), b = arq.f32(op, 22)
                            f.solido = SIMD4(r, g, b, a > 0 ? a : 1)
                            if f.nome.isEmpty { f.nome = arq.textoBruto(op, de: 26, max: 64) }
                        }
                        if let al = pin.filho("Alas") ?? pin.filho("alas"),
                           let j = try? JSONSerialization.jsonObject(with: Data(arq.bytes[al.range])) as? [String: Any],
                           let fp = j["fullpath"] as? String {
                            f.caminho = fp
                            if f.nome.isEmpty {
                                f.nome = fp.replacingOccurrences(of: "\\", with: "/").components(separatedBy: "/").last ?? fp
                            }
                        }
                        fontes[id] = f
                    }
                    varrer(c.kids)
                } else if c.listType != "Layr" && c.listType != "tdgp" {
                    varrer(c.kids)       // pastas (Fold, Sfdr…) e o resto
                }
            }
        }
        varrer(arq.raiz)
        guard let principal = comps.max(by: { $0.item.filhos("LIST", "Layr").count < $1.item.filhos("LIST", "Layr").count })
        else { throw AEErro.semComp }

        let item = principal.item
        let nomeComp = item.filho("Utf8").map(arq.texto) ?? url.deletingPathExtension().lastPathComponent
        var largura = 1920, altura = 1080
        var fps: Float = 30, duracao: Float = 10
        if let cd = item.filho("cdta") {
            let w = Int(arq.u16(cd, 140)), h = Int(arq.u16(cd, 142))
            if w > 0, h > 0, w < 16384, h < 16384 { largura = w; altura = h }
            let f = Float(arq.u32(cd, 156)) / 65536
            if f >= 1, f <= 240 { fps = f }
            let base = Double(arq.u32(cd, 8)), d = Double(arq.u32(cd, 44))
            if base > 0, d > 0, d / base < 36000 { duracao = Float(d / base) }
        }
        var comp = Composition(name: nomeComp.isEmpty ? "After Effects" : nomeComp,
                               width: largura, height: altura, frameRate: fps, duration: duracao,
                               backgroundColor: SIMD4(0, 0, 0, 1))
        let tamComp = SIMD2<Float>(Float(largura), Float(altura))
        let cat = await catalogo()
        var avisos: [String] = []
        var semEquivalente = Set<String>()
        var porNome: [String: URL] = [:]
        for m in midias { porNome[m.lastPathComponent.lowercased()] = m }

        var compsPorID: [UInt32: AEChunk] = [:]
        for c in comps { compsPorID[c.id] = c.item }
        func tamanhoDaComp(_ c: AEChunk) -> SIMD2<Float> {
            guard let cd = c.filho("cdta") else { return tamComp }
            let w = Float(arq.u16(cd, 140)), h = Float(arq.u16(cd, 142))
            return w > 0 && h > 0 ? SIMD2(w, h) : tamComp
        }
        var importadas = 0

        /// As camadas de uma comp, em ordem; uma pre-comp vira um GRUPO com as camadas dela
        /// dentro (recursivo), no tempo da comp de cima (`deslocamento`).
        func montar(_ item: AEChunk, deslocamento: Double, grupo: UUID?, prof: Int, visitadas: Set<UInt32>) async -> [Layer] {
        var idsAE: [UInt32: UUID] = [:]
        var pais: [(UUID, UInt32)] = []
        var camadas: [Layer] = []
        for (n, ly) in item.filhos("LIST", "Layr").enumerated() {
            guard let ld = ly.filho("ldta") else { continue }
            let base = Double(max(arq.u32(ld, 16), 1))
            let inicio = Double(arq.s32(ld, 12)) / base + deslocamento
            let entrada = Double(arq.s32(ld, 20)) / Double(max(arq.u32(ld, 24), 1))
            let saida = Double(arq.s32(ld, 28)) / Double(max(arq.u32(ld, 32), 1))
            let fonteID = arq.u32(ld, 40), paiID = arq.u32(ld, 132), idAE = arq.u32(ld, 0)
            let fonte = fontes[fonteID]
            var nome = ly.filho("Utf8").map(arq.texto) ?? ""
            if nome.isEmpty { nome = fonte?.nome ?? "" }
            if nome.isEmpty { nome = String(format: "Camada %d".loc, n + 1) }

            let g = ly.filho("LIST", "tdgp").map { arq.grupo($0, base: base) } ?? AEGrupo()
            if g.temCamera { avisos.append(String(format: "Câmera \"%@\" não importada.".loc, nome)); continue }

            var kind: LayerKind = .solid
            var l = Layer(name: nome, kind: .solid)
            let baixo = nome.lowercased()
            if g.temTexto {
                kind = .text; l.text = nome; l.fontSize = 96; l.textColor = SIMD4(1, 1, 1, 1)
                let m = MediaContentProvider.measureText(nome, fontName: nil, size: 96)
                l.size = SIMD2(Float(m.width), Float(m.height))
            } else if g.temForma {
                kind = .shape; l.shapeStyle = ShapeStyle(shape: .rectangle)
                l.size = tamComp / 4
            } else if let f = fonte, f.solido != nil {
                if baixo.contains("adjustment") || baixo.contains("ajuste") || f.nome.lowercased().contains("adjustment") {
                    kind = .adjustment
                } else if baixo.contains("null") || baixo.contains("nulo") || f.nome.lowercased().hasPrefix("null") {
                    kind = .null
                } else {
                    kind = .solid; l.solidColor = f.solido
                }
                l.size = f.tamanho ?? tamComp
            } else if let f = fonte, !f.ehComp {
                let arqNome = (f.caminho ?? f.nome).replacingOccurrences(of: "\\", with: "/")
                    .components(separatedBy: "/").last?.lowercased() ?? ""
                if let m = porNome[arqNome] {
                    let destino = pastaDeMidia.appendingPathComponent(m.lastPathComponent)
                    if !FileManager.default.fileExists(atPath: destino.path) {
                        try? FileManager.default.copyItem(at: m, to: destino)
                    }
                    let ext = m.pathExtension.lowercased()
                    kind = ["mp4", "mov", "m4v"].contains(ext) ? .video : (["mp3", "wav", "m4a", "aac"].contains(ext) ? .audio : .image)
                    l.mediaPath = m.lastPathComponent
                } else {
                    kind = .solid; l.solidColor = SIMD4(0.25, 0.25, 0.3, 1)
                    avisos.append(String(format: "Mídia não encontrada: %@ (escolha o arquivo junto com o .aep)".loc, f.nome))
                }
                l.size = f.tamanho ?? tamComp
            } else if let f = fonte, f.ehComp {
                if let pc = compsPorID[fonteID], prof < 12, !visitadas.contains(fonteID) {
                    kind = .group
                    l.size = tamanhoDaComp(pc)
                } else {
                    kind = .solid; l.solidColor = SIMD4(0.2, 0.2, 0.28, 1); l.size = tamComp
                    avisos.append(String(format: "Pré-composição \"%@\" virou um sólido.".loc, f.nome))
                }
            } else {
                kind = .null; l.size = SIMD2(100, 100)
            }
            l.kind = kind
            if kind == .adjustment || kind == .null { l.size = l.size ?? tamComp }

            // Tempo
            let a = inicio + entrada, b = inicio + saida
            l.startTime = Float(max(0, a))
            l.duration = Float(max(0.04, min(b, Double(duracao)) - max(0, a)))
            if kind == .video { l.mediaOffset = Float(max(0, entrada)) }

            // Transform
            let tam = l.size ?? tamComp
            func vec(_ p: AEPropriedade?, _ padrao: SIMD2<Float>, escala: Float = 1) -> Animated<SIMD2<Float>> {
                guard let p else { return Animated(padrao) }
                func s(_ v: [Double]) -> SIMD2<Float> {
                    SIMD2(Float(v.first ?? Double(padrao.x)) * escala, Float(v.count > 1 ? v[1] : Double(padrao.y)) * escala)
                }
                var an = Animated(p.estatico.isEmpty ? padrao : s(p.estatico))
                for k in p.chaves { _ = an.setKeyframe(time: Float(inicio + k.t), value: s(k.v)) }
                return an
            }
            func esc(_ p: AEPropriedade?, _ padrao: Float, percent: Bool) -> Animated<Float> {
                guard let p else { return Animated(padrao) }
                let todos = p.estatico.prefix(1) + p.chaves.compactMap { $0.v.first }
                let fator: Float = percent && (todos.map { abs($0) }.max() ?? 0) <= 1.0001 ? 100 : 1
                var an = Animated(p.estatico.first.map { Float($0) * fator } ?? padrao)
                for k in p.chaves { _ = an.setKeyframe(time: Float(inicio + k.t), value: Float(k.v.first ?? 0) * fator) }
                return an
            }
            l.transform.anchorPoint = vec(g.props["ADBE Anchor Point"], tam / 2)
            if let pos = g.props["ADBE Position"] {
                l.transform.position = vec(pos, tamComp / 2)
            } else if let px = g.props["ADBE Position_0"], let py = g.props["ADBE Position_1"],
                      !px.chaves.isEmpty || !py.chaves.isEmpty {
                var an = Animated(SIMD2(Float(px.estatico.first ?? Double(tamComp.x / 2)),
                                        Float(py.estatico.first ?? Double(tamComp.y / 2))))
                let tempos = Set(px.chaves.map(\.t) + py.chaves.map(\.t)).sorted()
                for t in tempos {
                    let kx = px.chaves.first(where: { abs($0.t - t) < 1e-6 })
                    let ky = py.chaves.first(where: { abs($0.t - t) < 1e-6 })
                    let x: Double = kx?.v.first ?? px.estatico.first ?? 0
                    let y: Double = ky?.v.first ?? py.estatico.first ?? 0
                    _ = an.setKeyframe(time: Float(inicio + t), value: SIMD2(Float(x), Float(y)))
                }
                l.transform.position = an
            } else {
                l.transform.position = Animated(tamComp / 2)
            }
            if let sc = g.props["ADBE Scale"] {
                // o AE grava a escala como fracao (1 = 100%), estatica e nas chaves
                l.transform.scale = vec(sc, SIMD2(100, 100), escala: 100)
            }
            l.transform.rotationZ = esc(g.props["ADBE Rotate Z"], 0, percent: false)
            l.transform.opacity = esc(g.props["ADBE Opacity"], 100, percent: true)

            // Efeitos
            for fx in g.efeitos {
                if let ap = await converter(fx, catalogo: cat, tamanho: tam, inicioDaCamada: inicio) {
                    l.effects.append(ap)
                    if !fx.look.isEmpty || !fx.lookIgnoradas.isEmpty {
                        let (fs, av) = await ferramentasDoLook(fx)
                        l.effects += fs; avisos += av
                    }
                } else if !semEquivalente.contains(fx.nome) {
                    semEquivalente.insert(fx.nome)
                }
            }
            idsAE[idAE] = l.id
            if paiID != 0 { pais.append((l.id, paiID)) }
            l.groupID = grupo
            camadas.append(l)
            importadas += 1
            // pre-comp: o conteudo dela entra logo abaixo do grupo
            if kind == .group, let pc = compsPorID[fonteID] {
                camadas += await montar(pc, deslocamento: inicio, grupo: l.id, prof: prof + 1,
                                        visitadas: visitadas.union([fonteID]))
            }
        }
        for (filho, pai) in pais {
            if let alvo = idsAE[pai], let i = camadas.firstIndex(where: { $0.id == filho }) { camadas[i].parentID = alvo }
        }
        return camadas
        }

        comp.layers = await montar(item, deslocamento: 0, grupo: nil, prof: 0, visitadas: [principal.id])
        // a ordem do AE: a de cima primeiro, como na Nova
        if !semEquivalente.isEmpty {
            avisos.append(String(format: "Efeitos sem equivalente na Nova: %@".loc, semEquivalente.sorted().joined(separator: ", ")))
        }
        if comps.count > 1 {
            avisos.append(String(format: "O projeto tem %d composições; importei \"%@\".".loc, comps.count, comp.name))
        }
        return (comp, avisos)
    }

    static func lerArquivo(_ url: URL) throws -> Data {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }
}

// MARK: - Botoes

/// "Importar do After Effects": escolha o .aep (e, junto, as midias dele).
struct ImportarAEBotao: View {
    @ObservedObject var store: ProjectStore
    @State private var escolhendo = false
    @State private var trabalhando = false
    @State private var aviso: String?

    var body: some View {
        Button { escolhendo = true } label: {
            HStack(spacing: 4) {
                if trabalhando { ProgressView().scaleEffect(0.7) }
                Text("Ae").font(.system(size: 10, weight: .heavy))
                    .foregroundStyle(Color(red: 0.6, green: 0.6, blue: 1))
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.0, green: 0.0, blue: 0.2)))
                Text("Importar .aep".loc)
            }
            .font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.accent)
        }
        .disabled(trabalhando)
        .sheet(isPresented: $escolhendo) {
            SeletorDeArquivos(tipos: AEImportador.tiposDoSeletor, varios: true) { urls in
                escolhendo = false
                guard !urls.isEmpty else { return }
                Task { await importar(urls) }
            }
            .ignoresSafeArea()
        }
        .alert("After Effects", isPresented: Binding(get: { aviso != nil }, set: { if !$0 { aviso = nil } })) {
            Button("OK") { aviso = nil }
        } message: { Text(aviso ?? "") }
    }

    private func importar(_ urls: [URL]) async {
        trabalhando = true; defer { trabalhando = false }
        guard let aep = urls.first(where: { $0.pathExtension.lowercased() == "aep" }) else {
            aviso = "Escolha um arquivo .aep (pode marcar as mídias dele junto).".loc; return
        }
        let midias = urls.filter { $0 != aep }
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent("ae-midias-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        // copia as midias escolhidas (o acesso a elas acaba quando a escolha fecha)
        var locais: [URL] = []
        for m in midias {
            let ok = m.startAccessingSecurityScopedResource()
            let d = temp.appendingPathComponent(m.lastPathComponent)
            if (try? FileManager.default.copyItem(at: m, to: d)) != nil { locais.append(d) }
            if ok { m.stopAccessingSecurityScopedResource() }
        }
        do {
            let saida = temp.appendingPathComponent("saida")
            try? FileManager.default.createDirectory(at: saida, withIntermediateDirectories: true)
            var (comp, avisos) = try await AEImportador.projeto(aep, midias: locais, pastaDeMidia: saida)
            comp.name = store.nomeLivre(comp.name)
            guard let p = store.create(composition: comp) else {
                aviso = store.lastError ?? "Não consegui criar o projeto.".loc; return
            }
            let destino = store.folder(for: p).appendingPathComponent(NovaProjectIO.mediaFolder)
            try? FileManager.default.createDirectory(at: destino, withIntermediateDirectories: true)
            for f in (try? FileManager.default.contentsOfDirectory(at: saida, includingPropertiesForKeys: nil)) ?? [] {
                try? FileManager.default.moveItem(at: f, to: destino.appendingPathComponent(f.lastPathComponent))
            }
            let n = comp.layers.count
            aviso = String(format: "Projeto \"%@\" importado do After Effects: %d camadas.".loc, p.name, n)
                + (avisos.isEmpty ? "" : "\n\n" + avisos.prefix(8).joined(separator: "\n"))
        } catch {
            aviso = error.localizedDescription
        }
    }
}
