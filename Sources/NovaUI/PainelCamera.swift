//
//  PainelCamera.swift
//  NovaUI
//
//  O painel da Camera 3D, no jeito do Blurrr: em vez de digitar Posicao Z e Rotacao, a
//  camera se mexe arrastando o dedo numa area grande — Orbitar (gira em volta do que ela
//  esta olhando), Mover (desliza de lado/cima), Aproximar (anda para frente/tras), Lente
//  (zoom optico) e Girar (inclina o horizonte). A pinca aproxima em qualquer modo e dois
//  toques voltam a camera para o comeco. O diamante grava um keyframe da camera inteira.
//
//  Por baixo continua a camera do AE (Transform: posicao, Z, rotacoes e zoom), entao tudo
//  anima, exporta e importa como antes.
//

import SwiftUI
import simd

struct PainelCamera: View {
    let layer: Layer
    let comp: Composition
    let time: Float
    let edit: LayerEdit
    let onVoltar: () -> Void

    @State private var modo = 0
    /// Transform no comeco do gesto (os gestos usam o deslocamento total, sem acumular erro).
    @State private var inicio: Transform?
    @State private var pinca: Transform?

    private static let modos: [(String, String)] = [
        ("rotate.3d", "Orbitar"), ("hand.draw", "Mover"), ("arrow.up.and.down", "Aproximar"),
        ("camera.aperture", "Lente"), ("arrow.clockwise", "Girar"),
    ]

    var body: some View {
        let tr = layer.transform
        PainelComTrilho(onVoltar: onVoltar,
                        onChave: { alternarChave() },
                        temChave: tr.position.hasKeyframe(at: time) || tr.rotationY.hasKeyframe(at: time),
                        easing: tr.position.easing(at: time) ?? tr.rotationY.easing(at: time),
                        onEasing: temTrecho ? { e in mudarCurva(e) } : nil,
                        rolar: false, mais: {
            Button { resetar() } label: { Label("Voltar a câmera para o começo".loc, systemImage: "arrow.counterclockwise") }
            Button { ligar3DEmTudo() } label: { Label("Ligar o 3D em todas as camadas".loc, systemImage: "cube") }
        }, conteudo: {
            HStack(spacing: 0) {
                VStack(spacing: 8) {
                    leituras.padding(.top, 12)
                    almofada
                        .padding(.horizontal, 12).padding(.bottom, 10)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                trilhoDosModos
            }
        })
    }

    // MARK: leituras

    private var leituras: some View {
        let t = layer.transform
        let p = t.position.value(at: time), z = t.positionZ.value(at: time)
        return HStack(spacing: 6) {
            leitura("X", p.x); leitura("Y", p.y); leitura("Z", z)
            leitura("↻", t.rotationY.value(at: time), "°")
            leitura("⤒", t.rotationX.value(at: time), "°")
            leitura("mm", milimetros(t.zoomValue.value(at: time)))
        }
        .padding(.horizontal, 10)
        .lineLimit(1).minimumScaleFactor(0.6)
    }

    private func leitura(_ r: String, _ v: Float, _ u: String = "") -> some View {
        VStack(spacing: 1) {
            Text(String(format: abs(v) >= 100 ? "%.0f%@" : "%.1f%@", v, u))
                .font(.system(size: 11.5, weight: .medium, design: .rounded)).foregroundStyle(NovaTheme.accent)
            Text(r).font(.system(size: 8.5)).foregroundStyle(NovaTheme.dim2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(CoresPainel.pilula.opacity(0.7)))
    }

    /// Zoom em px para a lente equivalente em mm (filme de 36 mm, como o AE mostra).
    private func milimetros(_ zoom: Float) -> Float { zoom * 36 / max(Float(comp.width), 1) }

    // MARK: a area de arrastar

    private var almofada: some View {
        GeometryReader { g in
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.25))
                GradePerspectiva(transform: layer.transform, time: time)
                    .stroke(NovaTheme.accent.opacity(0.28), lineWidth: 1)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(spacing: 6) {
                    Image(systemName: Self.modos[modo].0).font(.system(size: 26, weight: .medium))
                        .foregroundStyle(NovaTheme.accent)
                    Text(dica).font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                        .multilineTextAlignment(.center).padding(.horizontal, 16)
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if inicio == nil { inicio = layer.transform }
                        guard let a = inicio else { return }
                        let k = Float(max(comp.size.x, comp.size.y)) / Float(max(g.size.width, 1))
                        aplicar(arrasto(a, dx: Float(v.translation.width), dy: Float(v.translation.height), k: k), salvar: false)
                    }
                    .onEnded { _ in inicio = nil; edit(layer.id, true) { _ in } }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { s in
                        if pinca == nil { pinca = layer.transform }
                        guard let a = pinca else { return }
                        aplicar(aproximarPinca(a, escala: Float(s)), salvar: false)
                    }
                    .onEnded { _ in pinca = nil; edit(layer.id, true) { _ in } }
            )
            .onTapGesture(count: 2) { resetar() }
        }
    }

    private var dica: String {
        switch modo {
        case 0: return "Arraste para girar a câmera em volta da cena".loc
        case 1: return "Arraste para deslizar a câmera".loc
        case 2: return "Arraste para cima para chegar perto, para baixo para afastar".loc
        case 3: return "Arraste para cima para fechar a lente (zoom), para baixo para abrir".loc
        default: return "Arraste para os lados para inclinar o horizonte".loc
        }
    }

    private var trilhoDosModos: some View {
        VStack(spacing: 8) {
            ForEach(Self.modos.indices, id: \.self) { i in
                Button { modo = i } label: {
                    VStack(spacing: 3) {
                        Image(systemName: Self.modos[i].0).font(.system(size: 19, weight: .medium))
                        Text(Self.modos[i].1.loc).font(.system(size: 9.5, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(modo == i ? NovaTheme.accent : NovaTheme.text)
                    .frame(width: 62, height: 46)
                    .background(RoundedRectangle(cornerRadius: 10).fill(modo == i ? CoresPainel.pilula : Color.clear))
                }.buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .frame(width: 70)
        .background(CoresPainel.trilho)
    }

    // MARK: a conta da camera

    /// So a rotacao da camera (eixos dela no mundo).
    private static func base(_ t: Transform, _ time: Float) -> simd_float4x4 {
        var r = Transform()
        r.rotationX = Animated(t.rotationX.value(at: time))
        r.rotationY = Animated(t.rotationY.value(at: time))
        r.rotationZ = Animated(t.rotationZ.value(at: time))
        r.anchorPoint = Animated(.zero)
        r.position = Animated(.zero)
        r.positionZ = Animated(0)
        r.scale = Animated(SIMD2(100, 100))
        return r.matrix(at: time)
    }
    private static func eixo(_ m: simd_float4x4, _ v: SIMD3<Float>) -> SIMD3<Float> {
        let r = m * SIMD4(v.x, v.y, v.z, 0)
        return simd_normalize(SIMD3(r.x, r.y, r.z))
    }

    /// O que a camera muda num gesto: so as propriedades do modo (as outras nao ganham chave).
    private struct Mudanca {
        var posicao: SIMD3<Float>?
        var rotX: Float?, rotY: Float?, rotZ: Float?
        var zoom: Float?
    }

    private func olho(_ a: Transform) -> SIMD3<Float> {
        let p = a.position.value(at: time)
        return SIMD3(p.x, p.y, a.positionZ.value(at: time))
    }

    /// Distancia ate o que a camera olha: o plano z = 0 (onde ficam as camadas), ou o zoom.
    private func alvo(_ a: Transform) -> Float {
        let f = Self.eixo(Self.base(a, time), SIMD3(0, 0, 1))
        let p = olho(a)
        if f.z > 0.08 { return min(max(-p.z / f.z, 50), 60000) }
        return max(a.zoomValue.value(at: time), 50)
    }

    private func arrasto(_ a: Transform, dx: Float, dy: Float, k: Float) -> Mudanca {
        var m = Mudanca()
        let p0 = olho(a)
        let b = Self.base(a, time)
        switch modo {
        case 0:   // Orbitar em volta do ponto que a camera olha
            let d = alvo(a)
            let f0 = Self.eixo(b, SIMD3(0, 0, 1))
            let centro = p0 + f0 * d
            let ry = a.rotationY.value(at: time) - dx * 0.3
            let rx = min(max(a.rotationX.value(at: time) + dy * 0.3, -89), 89)
            var n = a
            n.rotationY = Animated(ry); n.rotationX = Animated(rx)
            let f1 = Self.eixo(Self.base(n, time), SIMD3(0, 0, 1))
            m.posicao = centro - f1 * d
            m.rotX = rx; m.rotY = ry
        case 1:   // Mover: desliza no plano da camera, na velocidade do que ela olha
            let d = alvo(a)
            let zoom = max(a.zoomValue.value(at: time), 1)
            let r = Self.eixo(b, SIMD3(1, 0, 0)), u = Self.eixo(b, SIMD3(0, 1, 0))
            let s = k * d / zoom
            m.posicao = p0 - (r * dx + u * dy) * s
        case 2:   // Aproximar: anda na direcao em que olha
            let f = Self.eixo(b, SIMD3(0, 0, 1))
            let d = alvo(a)
            m.posicao = p0 + f * (-dy * k * max(d, 200) / 300)
        case 3:   // Lente
            let z0 = a.zoomValue.value(at: time)
            m.zoom = min(max(z0 * exp(-dy * 0.006), 40), 30000)
        default:  // Girar o horizonte
            m.rotZ = a.rotationZ.value(at: time) + dx * 0.35
        }
        return m
    }

    private func aproximarPinca(_ a: Transform, escala: Float) -> Mudanca {
        var m = Mudanca()
        let f = Self.eixo(Self.base(a, time), SIMD3(0, 0, 1))
        let d = alvo(a)
        // abrir os dedos chega perto: a distancia vira d / escala
        let nova = min(max(d / max(escala, 0.05), 20), 60000)
        m.posicao = olho(a) + f * (d - nova)
        return m
    }

    private func aplicar(_ m: Mudanca, salvar: Bool) {
        let t = time
        edit(layer.id, salvar) { l in
            if let p = m.posicao {
                l.transform.position.set(SIMD2(p.x, p.y), at: t)
                l.transform.positionZ.set(p.z, at: t)
            }
            if let v = m.rotX { l.transform.rotationX.set(v, at: t) }
            if let v = m.rotY { l.transform.rotationY.set(v, at: t) }
            if let v = m.rotZ { l.transform.rotationZ.set(v, at: t) }
            if let v = m.zoom { var z = l.transform.zoomValue; z.set(v, at: t); l.transform.zoom = z }
        }
    }

    // MARK: chave, curva, reset

    private var temTrecho: Bool {
        let t = layer.transform
        return t.position.easing(at: time) != nil || t.rotationY.easing(at: time) != nil
    }

    /// Um keyframe da camera inteira (posicao, Z, rotacoes e lente) no cursor; de novo apaga.
    private func alternarChave() {
        let t = time
        let tem = layer.transform.position.hasKeyframe(at: t) || layer.transform.rotationY.hasKeyframe(at: t)
        edit(layer.id, true) { l in
            func f(_ a: inout Animated<Float>) {
                if tem { a.removeKeyframe(at: t, tolerance: 1e-3) } else { a.setKeyframe(time: t, value: a.value(at: t)) }
            }
            if tem { l.transform.position.removeKeyframe(at: t, tolerance: 1e-3) }
            else { l.transform.position.setKeyframe(time: t, value: l.transform.position.value(at: t)) }
            f(&l.transform.positionZ); f(&l.transform.rotationX); f(&l.transform.rotationY); f(&l.transform.rotationZ)
            var z = l.transform.zoomValue; f(&z); l.transform.zoom = z
        }
    }

    private func mudarCurva(_ e: Easing) {
        let t = time
        edit(layer.id, true) { l in
            l.transform.position.setEasing(at: t, e)
            l.transform.positionZ.setEasing(at: t, e)
            l.transform.rotationX.setEasing(at: t, e)
            l.transform.rotationY.setEasing(at: t, e)
            l.transform.rotationZ.setEasing(at: t, e)
            var z = l.transform.zoomValue; z.setEasing(at: t, e); l.transform.zoom = z
        }
    }

    private func resetar() {
        let t = time
        let c = comp.size / 2, zp = comp.zoomPadrao
        edit(layer.id, true) { l in
            l.transform.position.set(c, at: t)
            l.transform.positionZ.set(-zp, at: t)
            l.transform.rotationX.set(0, at: t)
            l.transform.rotationY.set(0, at: t)
            l.transform.rotationZ.set(0, at: t)
            var z = l.transform.zoomValue; z.set(zp, at: t); l.transform.zoom = z
        }
    }

    private func ligar3DEmTudo() {
        for l in comp.layers where l.kind.canBe3D && l.kind != .adjustment && !l.is3D {
            edit(l.id, false) { $0.is3D = true }
        }
        edit(layer.id, true) { _ in }
    }
}

/// Um chao quadriculado visto pela camera: mostra para onde ela esta virada.
private struct GradePerspectiva: Shape {
    let transform: Transform
    let time: Float

    func path(in r: CGRect) -> Path {
        var p = Path()
        let ry = Double(transform.rotationY.value(at: time)) * .pi / 180
        let rx = Double(transform.rotationX.value(at: time)) * .pi / 180
        let rz = Double(transform.rotationZ.value(at: time)) * .pi / 180
        let horizonte = r.midY + CGFloat(sin(rx)) * r.height * 0.6 - r.height * 0.05
        let desl = CGFloat(ry.truncatingRemainder(dividingBy: .pi / 6) / (.pi / 6)) * r.width / 6
        func gira(_ q: CGPoint) -> CGPoint {
            let c = CGPoint(x: r.midX, y: r.midY)
            let dx = q.x - c.x, dy = q.y - c.y
            return CGPoint(x: c.x + dx * CGFloat(cos(rz)) - dy * CGFloat(sin(rz)),
                           y: c.y + dx * CGFloat(sin(rz)) + dy * CGFloat(cos(rz)))
        }
        // linhas que fogem para o horizonte
        let fuga = CGPoint(x: r.midX - desl, y: horizonte)
        for i in -8...8 {
            let x = r.midX + CGFloat(i) * r.width / 5 - desl * 3
            p.move(to: gira(CGPoint(x: x, y: r.maxY + r.height)))
            p.addLine(to: gira(fuga))
        }
        // linhas paralelas ao horizonte, cada vez mais juntas
        for i in 1...9 {
            let y = horizonte + CGFloat(i * i) * (r.maxY - horizonte + r.height * 0.3) / 81
            p.move(to: gira(CGPoint(x: r.minX - r.width, y: y)))
            p.addLine(to: gira(CGPoint(x: r.maxX + r.width, y: y)))
        }
        p.move(to: gira(CGPoint(x: r.minX - r.width, y: horizonte)))
        p.addLine(to: gira(CGPoint(x: r.maxX + r.width, y: horizonte)))
        return p
    }
}
