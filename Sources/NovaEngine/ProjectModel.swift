//
//  ProjectModel.swift
//  NovaEngine
//
//  Composicao, camadas e transformacao. Porte do modelo de com.novaeditor.model.
//  Os nomes das propriedades seguem o app Android e o After Effects.
//

import Foundation
import simd

// MARK: - Modos de mesclagem

public enum BlendMode: String, Codable, Sendable, CaseIterable {
    case normal, dissolve, darken, multiply, colorBurn, linearBurn, darkerColor
    case add, lighten, screen, colorDodge, linearDodge, lighterColor
    case overlay, softLight, hardLight, vividLight, linearLight, pinLight, hardMix
    case difference, exclusion, subtract, divide
    case hue, saturation, color, luminosity
    case alphaAdd = "alpha_add", luminescentPremul = "luminescent_premul"

    public var label: String {
        switch self {
        case .normal: return "Normal";          case .dissolve: return "Dissolver"
        case .darken: return "Escurecer";       case .multiply: return "Multiplicar"
        case .colorBurn: return "Superexpor";   case .linearBurn: return "Subexposição linear"
        case .darkerColor: return "Cor mais escura"
        case .add: return "Adicionar";          case .lighten: return "Clarear"
        case .screen: return "Tela";            case .colorDodge: return "Subexpor"
        case .linearDodge: return "Superexposição linear"
        case .lighterColor: return "Cor mais clara"
        case .overlay: return "Sobrepor";       case .softLight: return "Luz suave"
        case .hardLight: return "Luz direta";   case .vividLight: return "Luz brilhante"
        case .linearLight: return "Luz linear"; case .pinLight: return "Luz do pino"
        case .hardMix: return "Mistura direta"
        case .difference: return "Diferença";   case .exclusion: return "Exclusão"
        case .subtract: return "Subtrair";      case .divide: return "Dividir"
        case .hue: return "Matiz";              case .saturation: return "Saturação"
        case .color: return "Cor";              case .luminosity: return "Luminosidade"
        case .alphaAdd: return "Adicionar alfa"
        case .luminescentPremul: return "Pré-multiplicação luminescente"
        }
    }
}

// MARK: - Transformacao

public struct Transform: Codable, Sendable, Equatable {
    public var anchorPoint = Animated<SIMD2<Float>>(.zero)
    public var position    = Animated<SIMD2<Float>>(.zero)
    public var positionZ   = Animated<Float>(0)
    public var scale       = Animated<SIMD2<Float>>(SIMD2(100, 100))   // percentual, como no AE
    public var rotationX   = Animated<Float>(0)
    public var rotationY   = Animated<Float>(0)
    public var rotationZ   = Animated<Float>(0)
    public var opacity     = Animated<Float>(100)                      // percentual
    /// Inclinacao em graus (x, y). Opcional para abrir projetos antigos.
    public var skew: Animated<SIMD2<Float>>?

    public init() {}

    /// Matriz 4x4 da camada no instante dado, igual a
    /// com.novaeditor.model.Transform.buildMatrix do APK (conferido com o REA):
    ///   M = T(posicao, z) * Rz * Ry * Rx * Skew * S(escala) * T(-ancora)
    /// Aplicada a um ponto da camada: tira a ancora, escala, inclina, gira, posiciona.
    public func matrix(at t: Float) -> simd_float4x4 {
        let a = anchorPoint.value(at: t)
        let p = position.value(at: t)
        let z = positionZ.value(at: t)
        let s = scale.value(at: t) / 100
        let rx = rotationX.value(at: t) * .pi / 180
        let ry = rotationY.value(at: t) * .pi / 180
        let rz = rotationZ.value(at: t) * .pi / 180
        let k = skew?.value(at: t) ?? .zero

        var m = Self.translation(p.x, p.y, z)
        if rz != 0 { m = m * Self.rotationZ(rz) }
        if ry != 0 { m = m * Self.rotationY(ry) }
        if rx != 0 { m = m * Self.rotationX(rx) }
        if k.x != 0 || k.y != 0 {
            var sk = matrix_identity_float4x4
            sk.columns.1.x = tan(k.x * .pi / 180)
            sk.columns.0.y = tan(k.y * .pi / 180)
            m = m * sk
        }
        m = m * Self.scaling(s.x, s.y, 1)
        m = m * Self.translation(-a.x, -a.y, 0)
        return m
    }

    public func alpha(at t: Float) -> Float { min(max(opacity.value(at: t) / 100, 0), 1) }

    public var isAnimated: Bool {
        anchorPoint.isAnimated || position.isAnimated || positionZ.isAnimated ||
        scale.isAnimated || rotationX.isAnimated || rotationY.isAnimated ||
        rotationZ.isAnimated || opacity.isAnimated || (skew?.isAnimated ?? false)
    }

    // helpers de matriz
    static func translation(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        var m = matrix_identity_float4x4; m.columns.3 = SIMD4(x, y, z, 1); return m
    }
    static func scaling(_ x: Float, _ y: Float, _ z: Float) -> simd_float4x4 {
        simd_float4x4(diagonal: SIMD4(x, y, z, 1))
    }
    static func rotationZ(_ r: Float) -> simd_float4x4 {
        let c = cos(r), s = sin(r)
        return simd_float4x4(SIMD4(c, s, 0, 0), SIMD4(-s, c, 0, 0),
                             SIMD4(0, 0, 1, 0), SIMD4(0, 0, 0, 1))
    }
    static func rotationY(_ r: Float) -> simd_float4x4 {
        let c = cos(r), s = sin(r)
        return simd_float4x4(SIMD4(c, 0, -s, 0), SIMD4(0, 1, 0, 0),
                             SIMD4(s, 0, c, 0), SIMD4(0, 0, 0, 1))
    }
    static func rotationX(_ r: Float) -> simd_float4x4 {
        let c = cos(r), s = sin(r)
        return simd_float4x4(SIMD4(1, 0, 0, 0), SIMD4(0, c, s, 0),
                             SIMD4(0, -s, c, 0), SIMD4(0, 0, 0, 1))
    }
}

// MARK: - Efeito aplicado

public struct AppliedEffect: Codable, Sendable, Identifiable, Equatable {
    public var id = UUID()
    /// id do EffectManifest, ex. "nova.effect.blurrr.box"
    public var effectID: String
    public var enabled = true
    /// Valores animados por parametro. A chave e o id do parametro no XML.
    public var floats:  [String: Animated<Float>] = [:]
    public var points:  [String: Animated<SIMD2<Float>>] = [:]
    public var vec3s:   [String: Animated<SIMD3<Float>>] = [:]
    public var colors:  [String: Animated<SIMD4<Float>>] = [:]
    public var ints:    [String: Int32] = [:]
    /// Parametros-textura: curvas e LUTs (veja EffectParamTextures).
    public var curves: [String: CurveSet]?
    public var luts: [String: String]?

    public init(effectID: String) { self.effectID = effectID }

    /// Resolve todos os parametros no instante dado, prontos para o renderer.
    public func values(at t: Float, manifest: EffectManifest) -> [String: EffectValue] {
        var out: [String: EffectValue] = [:]
        for p in manifest.params {
            switch p.kind.floatCount {
            case 1 where p.kind.isInteger:
                out[p.id] = .int(ints[p.id] ?? Int32(p.defaultValue.first ?? 0))
            case 1:
                out[p.id] = .float(floats[p.id]?.value(at: t) ?? (p.defaultValue.first ?? 0))
            case 2:
                out[p.id] = .vec2(points[p.id]?.value(at: t)
                                  ?? SIMD2(p.defaultValue.first ?? 0,
                                           p.defaultValue.count > 1 ? p.defaultValue[1] : 0))
            case 3:
                let d = p.defaultValue
                out[p.id] = .vec3(vec3s[p.id]?.value(at: t)
                                  ?? SIMD3(d.count > 0 ? d[0] : 0, d.count > 1 ? d[1] : 0,
                                           d.count > 2 ? d[2] : 0))
            default:
                let d = p.defaultValue
                out[p.id] = .vec4(colors[p.id]?.value(at: t)
                                  ?? SIMD4(d.count > 0 ? d[0] : 0, d.count > 1 ? d[1] : 0,
                                           d.count > 2 ? d[2] : 0, d.count > 3 ? d[3] : 1))
            }
        }
        return out
    }
}

// MARK: - Camada

public enum LayerKind: String, Codable, Sendable, CaseIterable {
    case video, image, text, shape, solid, null, adjustment, counter
    case camera, light, audio, group, precomp, model3d

    public var label: String {
        switch self {
        case .video: return "Vídeo";        case .image: return "Imagem"
        case .text: return "Texto";         case .shape: return "Forma"
        case .solid: return "Sólido";       case .null: return "Nulo"
        case .adjustment: return "Ajuste";  case .counter: return "Contador"
        case .camera: return "Câmera";      case .light: return "Luz"
        case .audio: return "Áudio";        case .group: return "Grupo"
        case .precomp: return "Pré-composição"; case .model3d: return "Modelo 3D"
        }
    }

    /// Camera, luz e audio nao tem chave 3D — igual ao app Android.
    public var canBe3D: Bool {
        switch self { case .camera, .light, .audio: return false; default: return true }
    }
    public var rendersPixels: Bool {
        switch self { case .camera, .light, .audio, .null: return false; default: return true }
    }
}

public struct Layer: Codable, Sendable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var kind: LayerKind
    public var enabled = true
    public var locked = false
    public var solo = false
    public var is3D = false
    public var shy = false

    /// Intervalo na timeline da composicao, em segundos.
    public var startTime: Float = 0
    public var duration: Float = 5
    /// Deslocamento dentro da midia (trim de entrada).
    public var mediaOffset: Float = 0
    public var speed: Float = 1

    public var transform = Transform()
    public var blendMode: BlendMode = .normal
    public var effects: [AppliedEffect] = []
    public var parentID: UUID?

    /// Caminho relativo da midia dentro da pasta do projeto.
    public var mediaPath: String?
    public var text: String?
    public var solidColor: SIMD4<Float>?
    public var size: SIMD2<Float>?
    /// Texto: tamanho em pt da composicao, fonte (nil = do sistema) e cor.
    public var fontSize: Float?
    public var fontName: String?
    public var textColor: SIMD4<Float>?
    /// Midia: som desligado (como `muted` no LayerContent.Media do Android).
    public var muted: Bool?
    /// Duracao da fonte em segundos (video), para limitar o trim.
    public var sourceDuration: Float?
    /// Midia em laco / invertida (emLaco, reversed no APK).
    public var loop: Bool?
    public var reversed: Bool?
    /// Mascaras da camada (LayerMask no APK).
    public var masks: [LayerMask]?
    /// Forma vetorial (LayerContent.Shape no APK).
    public var shapeStyle: ShapeStyle?
    /// Estilo e animacao do texto.
    public var textStyle: TextStyle?
    /// Grupo (pre-comp) a que a camada pertence: o `groupId` do APK. A camada
    /// some da lista de cima e e desenhada dentro do grupo.
    public var groupID: UUID?

    public var endTime: Float { startTime + duration }

    public init(name: String, kind: LayerKind) {
        self.name = name; self.kind = kind
    }

    public func isVisible(at t: Float) -> Bool {
        enabled && t >= startTime && t < endTime
    }

    /// Tempo dentro da midia para um tempo da composicao.
    public func mediaTime(at t: Float) -> Float {
        mediaOffset + (t - startTime) * speed
    }
}

// MARK: - Composicao

public struct Composition: Codable, Sendable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var width: Int
    public var height: Int
    public var frameRate: Float
    public var duration: Float
    public var backgroundColor: SIMD4<Float>
    public var layers: [Layer] = []
    /// Marcadores da composicao, em segundos (Marker/Markers no APK).
    public var markers: [Float]?

    public var size: SIMD2<Float> { SIMD2(Float(width), Float(height)) }
    public var frameCount: Int { max(1, Int((duration * frameRate).rounded())) }
    public var frameDuration: Float { frameRate > 0 ? 1 / frameRate : 1.0/30 }

    public init(name: String = "Composição", width: Int = 1920, height: Int = 1080,
                frameRate: Float = 30, duration: Float = 10,
                backgroundColor: SIMD4<Float> = SIMD4(0, 0, 0, 0)) {
        self.name = name; self.width = width; self.height = height
        self.frameRate = frameRate; self.duration = duration
        self.backgroundColor = backgroundColor
    }

    /// Camadas visiveis num instante, da de baixo para a de cima (ordem de composicao).
    /// `layers` guarda de cima para baixo, como a timeline mostra.
    public func visibleLayers(at t: Float) -> [Layer] {
        let soloed = layers.filter(\.solo)
        let pool = soloed.isEmpty ? layers : soloed
        return pool.filter { $0.groupID == nil && $0.isVisible(at: t) && $0.kind.rendersPixels }.reversed()
    }

    /// As camadas de dentro de um grupo, visiveis em `t`, de baixo para cima.
    public func visibleChildren(of group: UUID, at t: Float) -> [Layer] {
        layers.filter { $0.groupID == group && $0.isVisible(at: t) && $0.kind.rendersPixels }.reversed()
    }

    /// As camadas de dentro de um grupo (de cima para baixo).
    public func children(of group: UUID) -> [Layer] { layers.filter { $0.groupID == group } }

    /// Agrupa as camadas (como a pre-comp do AE): cria a camada Grupo do tamanho
    /// da composicao no lugar da de cima e poe as outras logo abaixo dela.
    @discardableResult
    public mutating func group(_ ids: [UUID], name: String) -> UUID? {
        let alvo = layers.filter { ids.contains($0.id) }
        guard !alvo.isEmpty else { return nil }
        var g = Layer(name: name, kind: .group)
        g.size = size
        g.transform.anchorPoint = Animated(size / 2)
        g.transform.position = Animated(size / 2)
        g.startTime = alvo.map(\.startTime).min() ?? 0
        g.duration = max(0.04, (alvo.map(\.endTime).max() ?? duration) - g.startTime)
        g.groupID = alvo.first?.groupID      // grupo dentro de grupo fica onde estava
        let topo = layers.firstIndex { ids.contains($0.id) } ?? 0
        var filhos: [Layer] = []
        for var l in layers where ids.contains(l.id) {
            l.groupID = g.id
            filhos.append(l)
        }
        layers.removeAll { ids.contains($0.id) }
        let pos = min(topo, layers.count)
        layers.insert(g, at: pos)
        layers.insert(contentsOf: filhos, at: pos + 1)
        return g.id
    }

    /// Desfaz o grupo: as camadas voltam para fora, no lugar dele.
    public mutating func ungroup(_ id: UUID) {
        guard let g = layer(id: id), g.kind == .group else { return }
        for i in layers.indices where layers[i].groupID == id { layers[i].groupID = g.groupID }
        layers.removeAll { $0.id == id }
    }

    public func layer(id: UUID) -> Layer? { layers.first { $0.id == id } }

    public mutating func add(_ l: Layer) { layers.insert(l, at: 0) }

    public mutating func remove(id: UUID) {
        // apagar um grupo apaga o que esta dentro dele
        if layer(id: id)?.kind == .group {
            for f in children(of: id) { remove(id: f.id) }
        }
        layers.removeAll { $0.id == id }
        for i in layers.indices where layers[i].parentID == id { layers[i].parentID = nil }
    }

    public mutating func move(from: Int, to: Int) {
        guard layers.indices.contains(from), to >= 0, to <= layers.count else { return }
        let l = layers.remove(at: from)
        layers.insert(l, at: min(to, layers.count))
    }

    /// Matriz acumulada com a cadeia de pais. Protegida contra ciclo.
    public func worldMatrix(of layer: Layer, at t: Float) -> simd_float4x4 {
        var m = layer.transform.matrix(at: t)
        var guardCount = 0
        var pid = layer.parentID
        while let p = pid, guardCount < 32 {
            guard let parent = self.layer(id: p) else { break }
            m = parent.transform.matrix(at: t) * m
            pid = parent.parentID
            guardCount += 1
        }
        return m
    }
}

// MARK: - Projeto

public struct NovaProject: Codable, Sendable, Identifiable, Equatable {
    public var id = UUID()
    public var name: String
    public var formatVersion = 1
    public var createdAt = Date()
    public var modifiedAt = Date()
    public var compositions: [Composition]
    public var mainCompositionID: UUID?

    public var mainComposition: Composition? {
        if let id = mainCompositionID { return compositions.first { $0.id == id } }
        return compositions.first
    }

    public init(name: String = "Novo projeto",
                composition: Composition = Composition()) {
        self.name = name
        self.compositions = [composition]
        self.mainCompositionID = composition.id
    }
}

// MARK: - Inclinacao sempre presente para a interface

public extension Transform {
    /// `skew` com valor padrao zero, para editar sem tratar o opcional.
    var skewValue: Animated<SIMD2<Float>> {
        get { skew ?? Animated(.zero) }
        set { skew = newValue }
    }
}
