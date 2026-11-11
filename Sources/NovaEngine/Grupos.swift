//
//  Grupos.swift
//  NovaEngine
//
//  Grupos (como os do Blurrr: um clipe so na timeline, que se abre para editar o que tem
//  dentro, e que pode ser pre-renderizado num video), e o vinculo a um pai (nulo) que
//  mantem a camada onde ela esta, como o pick whip do After Effects.
//

import Foundation
import simd

/// O grupo pre-renderizado: o video (relativo a pasta de midia do projeto) e a assinatura do
/// conteudo quando ele foi feito. Mudou o conteudo, a assinatura nao bate e o grupo volta a
/// ser montado ao vivo ate o proximo pre-render.
public struct PreRenderDoGrupo: Codable, Sendable, Equatable {
    public var arquivo: String
    public var assinatura: String
    public init(arquivo: String, assinatura: String) { self.arquivo = arquivo; self.assinatura = assinatura }
}

extension Composition {

    /// Tudo o que esta dentro do grupo, em qualquer nivel (de cima para baixo).
    public func descendentes(de grupo: UUID) -> [Layer] {
        var ids: Set<UUID> = [grupo]
        var mudou = true
        while mudou {
            mudou = false
            for l in layers where l.groupID.map(ids.contains) == true && !ids.contains(l.id) {
                ids.insert(l.id); mudou = true
            }
        }
        return layers.filter { $0.id != grupo && ids.contains($0.id) }
    }

    /// Anda com o grupo no tempo levando o conteudo junto (comeco e chaves).
    public mutating func deslocarConteudo(doGrupo grupo: UUID, por dt: Float) {
        guard dt != 0 else { return }
        let ids = Set(descendentes(de: grupo).map(\.id))
        for i in layers.indices where ids.contains(layers[i].id) {
            layers[i].startTime += dt
            Self.deslocarChaves(&layers[i].transform, dt)
        }
    }

    static func deslocarChaves(_ tr: inout Transform, _ d: Float) {
        guard d != 0 else { return }
        func mover<T: Interpolatable>(_ a: inout Animated<T>) {
            let ks = a.keyframes
            for k in (d > 0 ? Array(ks.reversed()) : ks) { a.moveKeyframe(id: k.id, to: k.time + d) }
        }
        mover(&tr.anchorPoint); mover(&tr.position); mover(&tr.positionZ); mover(&tr.scale)
        mover(&tr.rotationX); mover(&tr.rotationY); mover(&tr.rotationZ); mover(&tr.opacity)
        if var s = tr.skew { mover(&s); tr.skew = s }
    }

    /// A composicao so com o conteudo do grupo, no tempo do grupo (0 = comeco do grupo):
    /// e o que o pre-render grava e o que a assinatura mede.
    public func composicaoDoGrupo(_ grupo: UUID) -> Composition? {
        guard let g = layer(id: grupo), g.kind == .group else { return nil }
        var c = Composition(name: g.name, width: width, height: height, frameRate: frameRate,
                            duration: max(g.duration, 1 / max(frameRate, 1)),
                            backgroundColor: SIMD4(0, 0, 0, 0))
        c.id = grupo
        var dentro = descendentes(de: grupo)
        for i in dentro.indices {
            if dentro[i].groupID == grupo { dentro[i].groupID = nil }
            dentro[i].startTime -= g.startTime
            Self.deslocarChaves(&dentro[i].transform, -g.startTime)
            dentro[i].prerender = nil
        }
        c.layers = dentro
        return c
    }

    /// Assinatura estavel do conteudo do grupo (FNV-1a do JSON ordenado).
    public func assinaturaDoGrupo(_ grupo: UUID) -> String? {
        guard let c = composicaoDoGrupo(grupo) else { return nil }
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        guard let d = try? enc.encode(c) else { return nil }
        var h: UInt64 = 0xcbf29ce484222325
        for b in d { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return String(h, radix: 16)
    }

    /// O pre-render do grupo ainda vale para o conteudo de agora.
    public func preRenderValido(_ g: Layer) -> PreRenderDoGrupo? {
        guard g.kind == .group, let p = g.prerender, assinaturaDoGrupo(g.id) == p.assinatura else { return nil }
        return p
    }

    /// Duplica a camada; num grupo, duplica tudo o que tem dentro (com ids novos, os vinculos
    /// de pai e de grupo remapeados). A copia entra logo acima da original.
    @discardableResult
    public mutating func duplicar(_ id: UUID, sufixo: String) -> UUID? {
        guard let i = layers.firstIndex(where: { $0.id == id }) else { return nil }
        let original = layers[i]
        var mapa: [UUID: UUID] = [original.id: UUID()]
        let dentro = original.kind == .group ? descendentes(de: id) : []
        for d in dentro { mapa[d.id] = UUID() }
        func copia(_ l: Layer) -> Layer {
            var c = l
            c.id = mapa[l.id]!
            if let g = l.groupID, let n = mapa[g] { c.groupID = n }
            if let p = l.parentID, let n = mapa[p] { c.parentID = n }
            return c
        }
        var topo = copia(original)
        topo.name = original.name + " " + sufixo
        var novas = [topo]
        novas += dentro.map(copia)
        layers.insert(contentsOf: novas, at: i)
        return topo.id
    }

    /// Divide um grupo em `t`: a metade de cima e uma copia do grupo com todo o conteudo,
    /// e cada metade mostra so o seu trecho (antes a segunda metade saia vazia).
    @discardableResult
    public mutating func dividirGrupo(_ id: UUID, em t: Float) -> UUID? {
        guard let g = layer(id: id), g.kind == .group, t > g.startTime, t < g.endTime,
              let nova = duplicar(id, sufixo: "") else { return nil }
        if let i = layers.firstIndex(where: { $0.id == nova }) {
            layers[i].name = g.name
            layers[i].startTime = t
            layers[i].duration = g.endTime - t
            layers[i].prerender = nil
        }
        if let i = layers.firstIndex(where: { $0.id == id }) {
            layers[i].duration = t - g.startTime
            layers[i].prerender = nil
        }
        return nova
    }

    /// Camada nova: com um grupo aberto na timeline, entra dentro dele (no topo do grupo).
    public mutating func add(_ l: Layer, em grupo: UUID?) {
        guard let grupo, let i = layers.firstIndex(where: { $0.id == grupo }) else { add(l); return }
        var n = l
        n.groupID = grupo
        layers.insert(n, at: i + 1)
    }

    public enum OrdemNaPilha { case subir, descer, frente, tras }

    /// Muda a camada de lugar na pilha (frente = desenhada por cima), entre as do mesmo nivel
    /// (o topo da composicao ou o mesmo grupo). Devolve false quando ja esta na ponta.
    @discardableResult
    public mutating func mover(_ id: UUID, _ o: OrdemNaPilha) -> Bool {
        guard let l = layer(id: id) else { return false }
        let irmas = layers.indices.filter { layers[$0].groupID == l.groupID }
        guard let k = irmas.firstIndex(where: { layers[$0].id == id }) else { return false }
        let alvoK: Int
        switch o {
        case .subir: alvoK = k - 1
        case .descer: alvoK = k + 1
        case .frente: alvoK = 0
        case .tras: alvoK = irmas.count - 1
        }
        guard alvoK != k, irmas.indices.contains(alvoK) else { return false }
        let referencia = layers[irmas[alvoK]].id
        let camada = layers.remove(at: irmas[k])
        guard let r = layers.firstIndex(where: { $0.id == referencia }) else { layers.insert(camada, at: irmas[k]); return false }
        // subir/frente: entra logo acima da referencia; descer/tras: logo abaixo (depois dela e
        // do conteudo dela, se for um grupo)
        if alvoK < k {
            layers.insert(camada, at: r)
        } else {
            var fim = r
            let dentro = Set(descendentes(de: referencia).map(\.id))
            while fim + 1 < layers.count, dentro.contains(layers[fim + 1].id) { fim += 1 }
            layers.insert(camada, at: fim + 1)
        }
        return true
    }

    // MARK: 3D

    /// Zoom da camera padrao do AE (lente de 50 mm): 1,389 x a largura da comp.
    public var zoomPadrao: Float { Float(width) * 1.3888889 }

    /// A camera ativa em `t`: a camada Camera de cima que esta visivel (como no AE).
    public func cameraAtiva(em t: Float) -> Layer? {
        layers.first { $0.kind == .camera && $0.enabled && t >= $0.startTime && t < $0.endTime }
    }

    /// Projecao da camera: leva um ponto da comp (x, y, z) para (x*w, y*w, w) na tela.
    /// Sem camera, a padrao do AE: no centro, a `zoom` px na frente do plano z = 0.
    public func projecao(em t: Float) -> simd_float4x4 {
        let c = SIMD2<Float>(Float(width), Float(height)) / 2
        var zoom = zoomPadrao
        var vista = matrix_identity_float4x4
        if let cam = cameraAtiva(em: t) {
            zoom = max(1, cam.transform.zoom?.value(at: t) ?? zoomPadrao)
            vista = worldMatrix(of: cam, at: t).inverse
        } else {
            vista = Transform.translation(-c.x, -c.y, zoom)
        }
        // K: (xc, yc, zc) -> (cx*zc + zoom*xc, cy*zc + zoom*yc, zc)
        var k = matrix_identity_float4x4
        k.columns.0 = SIMD4(zoom, 0, 0, 0)
        k.columns.1 = SIMD4(0, zoom, 0, 0)
        k.columns.2 = SIMD4(c.x, c.y, 0, 1)
        k.columns.3 = SIMD4(0, 0, 0, 0)
        return k * vista
    }

    /// Para uma camada 3D: a matriz que o shader usa para levar o pixel da tela ao pixel da
    /// camada (homografia invertida, com w); nil se a camada esta atras da camera.
    public func telaParaCamada3D(_ mundo: simd_float4x4, em t: Float) -> simd_float4x4? {
        let m = projecao(em: t) * mundo
        // (u, v, 0, 1) -> colunas 0, 1 e 3; linhas x, y e w (a 4a linha de K e w)
        let h = simd_float3x3(SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.w),
                              SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.w),
                              SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.w))
        guard abs(h.determinant) > 1e-9 else { return nil }
        let i = h.inverse
        var r = simd_float4x4(0)
        r.columns.0 = SIMD4(i.columns.0.x, i.columns.0.y, 0, i.columns.0.z)
        r.columns.1 = SIMD4(i.columns.1.x, i.columns.1.y, 0, i.columns.1.z)
        r.columns.3 = SIMD4(i.columns.2.x, i.columns.2.y, 0, i.columns.2.z)
        return r
    }

    /// Camadas que podem ser pai de `filho` sem criar ciclo (mesmo nivel de grupo).
    public func paisPossiveis(para filho: UUID) -> [Layer] {
        guard let f = layer(id: filho) else { return [] }
        return layers.filter { c in
            guard c.id != filho, c.groupID == f.groupID, c.kind != .audio else { return false }
            var pid: UUID? = c.parentID, n = 0
            while let p = pid, n < 32 {
                if p == filho { return false }
                pid = layer(id: p)?.parentID; n += 1
            }
            return true
        }
    }

    /// Vincula `filho` a `pai` (nil = solta) sem a camada sair do lugar no instante `t`,
    /// como o pick whip do AE: posicao, rotacao e escala passam a ser relativas ao pai.
    public mutating func vincular(_ filho: UUID, a pai: UUID?, em t: Float) {
        guard let i = layers.firstIndex(where: { $0.id == filho }) else { return }
        if let pai, !paisPossiveis(para: filho).contains(where: { $0.id == pai }) { return }
        let antes = mundoDoPai(layers[i].parentID, t)
        let depois = mundoDoPai(pai, t)
        var l = layers[i]
        let p = l.transform.position.value(at: t)
        let mundo = antes * SIMD4(p.x, p.y, l.transform.positionZ.value(at: t), 1)
        let local = depois.inverse * mundo
        let dp = SIMD2(local.x, local.y) - p
        let rot = Self.rotacao(antes) - Self.rotacao(depois)
        let esc = Self.escala(antes) / max(Self.escala(depois), 1e-6)
        func somar(_ a: inout Animated<SIMD2<Float>>, _ d: SIMD2<Float>) {
            if a.keyframes.isEmpty { a = Animated(a.value(at: t) + d) }
            else { for k in a.keyframes { _ = a.setKeyframe(time: k.time, value: k.value + d) } }
        }
        func somarF(_ a: inout Animated<Float>, _ d: Float) {
            if a.keyframes.isEmpty { a = Animated(a.value(at: t) + d) }
            else { for k in a.keyframes { _ = a.setKeyframe(time: k.time, value: k.value + d) } }
        }
        func vezes(_ a: inout Animated<SIMD2<Float>>, _ k: Float) {
            if a.keyframes.isEmpty { a = Animated(a.value(at: t) * k) }
            else { for c in a.keyframes { _ = a.setKeyframe(time: c.time, value: c.value * k) } }
        }
        somar(&l.transform.position, dp)
        if abs(rot) > 1e-4 { somarF(&l.transform.rotationZ, rot) }
        if abs(esc - 1) > 1e-5 { vezes(&l.transform.scale, esc) }
        l.parentID = pai
        layers[i] = l
    }

    private func mundoDoPai(_ pai: UUID?, _ t: Float) -> simd_float4x4 {
        guard let pai, let p = layer(id: pai) else { return matrix_identity_float4x4 }
        return worldMatrix(of: p, at: t)
    }

    private static func rotacao(_ m: simd_float4x4) -> Float {
        atan2(m.columns.0.y, m.columns.0.x) * 180 / .pi
    }

    private static func escala(_ m: simd_float4x4) -> Float {
        simd_length(SIMD2(m.columns.0.x, m.columns.0.y))
    }
}
