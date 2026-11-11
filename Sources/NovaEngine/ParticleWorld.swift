//
//  ParticleWorld.swift
//  NovaEngine
//
//  CC Particle World na CPU, sem estado entre quadros (como o plugin): cada quadro refaz as
//  particulas vivas pelo instante de nascimento, entao tocar de qualquer ponto da o mesmo
//  resultado. Unidades do plugin: posicoes, raios e tamanhos em larguras da camada, origem no
//  centro, y para baixo. A camada (o solido) vira so as particulas; os tipos texturizados
//  amostram a propria camada.
//

import Foundation
import Metal
import simd

public enum ParticleWorld {

    public struct Controles {
        var birthRate: Float = 2, longevity: Float = 1
        var pos = SIMD3<Float>(0, 0, 0), rad = SIMD3<Float>(0.025, 0.025, 0.025)
        var animation = 0, velocity: Float = 1, inherit: Float = 0, gravity: Float = 0.5
        var resistance: Float = 0, extra: Float = 0.5, extraAngle: Float = 360
        var floorPos: Float = 0.2, visibility = 0, renderAnim = 0, floorAction = 0
        var bounce: Float = 65, randBounce: Float = 25, bounceSpread: Float = 10
        var axis = SIMD3<Float>(0, -1, 0), gvec = SIMD3<Float>(0, 1, 0)
        var tipo = 0, rotSpeed: Float = 180, rotInit: Float = 360, rotAxis = 3
        var birthSize: Float = 0.25, deathSize: Float = 0.25, sizeVar: Float = 50, maxOp: Float = 75
        var colorMap = 1
        var birthColor = SIMD3<Float>(1, 1, 0.31), deathColor = SIMD3<Float>(0.78, 0.16, 0.16)
        var custom: [SIMD3<Float>] = [SIMD3(1, 1, 1), SIMD3(1, 1, 0.31), SIMD3(1, 0.63, 0.16), SIMD3(0.75, 0.36, 0.08), SIMD3(0.5, 0, 0)]
        var volumeShade: Float = 0, transfer = 0
        var camDist: Float = 1, camRot = SIMD3<Float>(0, 0, 0), fov: Float = 45
        var depthCue = 0, depthDist: Float = 2, fog = SIMD3<Float>(0.5, 0.5, 0.5)
        var light = SIMD3<Float>(-0.577, 0.577, 0.577)
        var fps: Float = 30
        /// Matriz da camera da comp (opcional), em pixels da camada.
        var camComp: simd_float4x4?

        public init(valores v: [String: EffectValue], fps: Float) {
            self.fps = max(fps, 1)
            func f(_ k: String, _ p: inout Float) {
                switch v[k] { case .float(let x)?: p = x; case .int(let i)?: p = Float(i); default: break }
            }
            func i(_ k: String, _ p: inout Int) { var x = Float(p); f(k, &x); p = Int(x.rounded()) }
            func c(_ k: String, _ p: inout SIMD3<Float>) {
                switch v[k] { case .vec4(let x)?: p = SIMD3(x.x, x.y, x.z); case .vec3(let x)?: p = x; default: break }
            }
            f("birthRate", &birthRate); f("longevity", &longevity)
            f("posX", &pos.x); f("posY", &pos.y); f("posZ", &pos.z)
            f("radX", &rad.x); f("radY", &rad.y); f("radZ", &rad.z)
            i("animation", &animation); f("velocity", &velocity); f("inheritVelocity", &inherit)
            f("gravity", &gravity); f("resistance", &resistance); f("extra", &extra); f("extraAngle", &extraAngle)
            f("floorPosition", &floorPos); i("particleVisibility", &visibility); i("renderAnimation", &renderAnim)
            i("floorAction", &floorAction); f("bounciness", &bounce); f("randomBounciness", &randBounce)
            f("bounceSpread", &bounceSpread)
            f("axisX", &axis.x); f("axisY", &axis.y); f("axisZ", &axis.z)
            f("gravityX", &gvec.x); f("gravityY", &gvec.y); f("gravityZ", &gvec.z)
            i("particleType", &tipo); f("rotationSpeed", &rotSpeed); f("initialRotation", &rotInit)
            i("rotationAxis", &rotAxis)
            f("birthSize", &birthSize); f("deathSize", &deathSize); f("sizeVariation", &sizeVar); f("maxOpacity", &maxOp)
            i("colorMap", &colorMap); c("birthColor", &birthColor); c("deathColor", &deathColor)
            c("colorAtBirth", &custom[0]); c("colorAt25", &custom[1]); c("colorAt50", &custom[2])
            c("colorAt75", &custom[3]); c("colorAtDeath", &custom[4])
            f("volumeShade", &volumeShade); i("transferMode", &transfer)
            f("camDistance", &camDist); f("camRotX", &camRot.x); f("camRotY", &camRot.y); f("camRotZ", &camRot.z)
            f("fov", &fov); i("depthCueType", &depthCue); f("depthCueDistance", &depthDist); c("fogColor", &fog)
            f("lightX", &light.x); f("lightY", &light.y); f("lightZ", &light.z)
        }
    }

    // MARK: aleatorio por particula (deterministico)

    @inline(__always) static func hash(_ a: UInt32, _ b: UInt32) -> Float {
        var h = a &* 0x9E3779B1 ^ (b &+ 0x7F4A7C15) &* 0x85EBCA6B
        h ^= h >> 15; h = h &* 0x2C1B3C6D; h ^= h >> 12; h = h &* 0x297A2D39; h ^= h >> 15
        return Float(h & 0xFFFFFF) / Float(0x1000000)
    }
    @inline(__always) static func sn(_ k: UInt32, _ s: UInt32) -> Float { hash(k, s) * 2 - 1 }
    static func esfera(_ k: UInt32, _ s: UInt32) -> SIMD3<Float> {
        let z = sn(k, s), a = hash(k, s + 1) * 2 * .pi
        let r = (1 - z * z).squareRoot()
        return SIMD3(r * cos(a), r * sin(a), z)
    }
    static func ruido(_ p: SIMD3<Float>) -> SIMD3<Float> {
        SIMD3(sin(p.y * 3.1 + p.z * 1.7) + sin(p.x * 5.3 + 1.3) * 0.5,
              sin(p.z * 2.9 + p.x * 2.3) + sin(p.y * 4.7 + 2.1) * 0.5,
              sin(p.x * 3.7 + p.y * 1.9) + sin(p.z * 5.1 + 0.7) * 0.5)
    }

    struct Part { var p: SIMD3<Float>; var vel: SIMD3<Float>; var vida: Float; var k: UInt32; var z: Float = 0 }

    // MARK: fisica

    /// Posicao e velocidade com a idade `a` (resistencia exponencial, gravidade constante).
    static func balistica(_ p0: SIMD3<Float>, _ v0: SIMD3<Float>, _ g: SIMD3<Float>, _ r: Float, _ a: Float)
        -> (SIMD3<Float>, SIMD3<Float>) {
        if r < 1e-4 { return (p0 + v0 * a + 0.5 * g * a * a, v0 + g * a) }
        let e = exp(-r * a)
        let p = p0 + v0 * (1 - e) / r + g * (a / r - (1 - e) / (r * r))
        let v = v0 * e + g * (1 - e) / r
        return (p, v)
    }

    static func particula(_ k: UInt32, nasc tb: Float, agora t: Float, _ c: Controles) -> Part? {
        let a = t - tb
        let vida = a / max(c.longevity, 1e-4)
        guard a >= 0, vida < 1 else { return nil }
        var p0 = c.pos + c.rad * SIMD3(sn(k, 1), sn(k, 2), sn(k, 3))
        let dirA = esfera(k, 10)
        let eixo = simd_length(c.axis) > 1e-5 ? simd_normalize(c.axis) : SIMD3<Float>(0, -1, 0)
        // espalhamento do Extra Angle em volta do eixo
        let ang = min(abs(c.extraAngle), 360) / 360
        var v = SIMD3<Float>(0, 0, 0)
        var r = c.resistance
        switch c.animation {
        case 1: v = eixo * c.velocity                                   // Direction Axis
        case 2:                                                         // Cone Axis
            let cone = simd_normalize(eixo + dirA * 0.35)
            v = cone * c.velocity
        case 3: v = dirA * c.velocity; r = max(r, 3)                    // Viscouse
        case 7: v = SIMD3(0, -abs(c.velocity) * 0.6, 0) + dirA * c.velocity * 0.15   // Fire
        case 8: v = SIMD3(c.velocity * (hash(k, 11) < 0.5 ? -1 : 1), 0, 0) + dirA * c.velocity * 0.1  // Jet Sideways
        default: v = dirA * c.velocity                                  // Explosive, Twirl, Vortex, Fractal
        }
        // Extra: variacao aleatoria da velocidade dentro do angulo
        let ex = esfera(k, 20) * ang + eixo * (1 - ang)
        v += ex * c.extra * hash(k, 21)
        let g = (simd_length(c.gvec) > 1e-5 ? simd_normalize(c.gvec) : SIMD3(0, 1, 0)) * c.gravity
        var (p, vel) = balistica(p0, v, g, r, a)
        // giros e campos
        switch c.animation {
        case 4, 5, 6:                                                   // Twirl, Twirly, Vortex
            let rel = p - c.pos
            let w: Float = c.animation == 6 ? 4 / max(0.05, simd_length(SIMD2(rel.x, rel.z))) * 0.2 : (c.animation == 5 ? 3 : 1.6)
            let th = w * a * (c.velocity >= 0 ? 1 : -1)
            let cs = cos(th), sn_ = sin(th)
            p = c.pos + SIMD3(rel.x * cs - rel.z * sn_, rel.y, rel.x * sn_ + rel.z * cs)
        case 7:                                                         // Fire: sobe tremendo
            p += ruido(p * 6 + SIMD3(0, -t, 0)) * 0.03 * a
        case 9, 10:                                                     // Fractal Omni / Uni
            let n = ruido(p0 * 4 + SIMD3(0, 0, a * 0.7))
            p += (c.animation == 10 ? SIMD3(n.x, -abs(n.y), n.z) : n) * c.velocity * 0.25 * a
        default: break
        }
        // chao
        let fy = c.floorPos
        if c.floorAction != 0, p.y > fy {
            switch c.floorAction {
            case 1: p.y = fy; vel.y = 0                                 // Ice: escorrega
            case 2: // Glue: para onde tocou (acha o instante do toque por bissecao)
                var lo: Float = 0, hi = a
                for _ in 0..<14 { let m = (lo + hi) / 2; if balistica(p0, v, g, r, m).0.y > fy { hi = m } else { lo = m } }
                p = balistica(p0, v, g, r, lo).0; p.y = fy; vel = .zero
            default: // Bounce
                var lo: Float = 0, hi = a
                for _ in 0..<14 { let m = (lo + hi) / 2; if balistica(p0, v, g, r, m).0.y > fy { hi = m } else { lo = m } }
                let (ph, vh) = balistica(p0, v, g, r, lo)
                let b = max(0, c.bounce + c.randBounce * sn(k, 30)) / 100
                let sp = c.bounceSpread / 100
                var v2 = SIMD3(vh.x + sp * sn(k, 31) * abs(vh.y), -abs(vh.y) * b, vh.z + sp * sn(k, 32) * abs(vh.y))
                var p2 = SIMD3(ph.x, fy, ph.z)
                var resto = a - lo
                // quiques seguintes
                for _ in 0..<6 {
                    let (pp, vv) = balistica(p2, v2, g, r, resto)
                    if pp.y <= fy { p = pp; vel = vv; resto = 0; break }
                    var l2: Float = 0, h2 = resto
                    for _ in 0..<12 { let m = (l2 + h2) / 2; if balistica(p2, v2, g, r, m).0.y > fy { h2 = m } else { l2 = m } }
                    let (q, qv) = balistica(p2, v2, g, r, l2)
                    p2 = SIMD3(q.x, fy, q.z); v2 = SIMD3(qv.x, -abs(qv.y) * b, qv.z); resto -= l2
                    p = p2; vel = .zero
                }
            }
        }
        switch c.visibility {
        case 1 where p.y > fy: return nil                               // Above Floor
        case 2 where c.floorAction == 0 ? p.y < fy : (p.y < fy - 1e-4): return nil   // After Floor
        default: break
        }
        if c.renderAnim == 2 { p.y = fy }                               // Projected on Floor
        if c.renderAnim == 1, p.y > fy { p.y = 2 * fy - p.y }           // Reflected on Floor
        _ = p0; p0 = .zero
        return Part(p: p, vel: vel, vida: vida, k: k)
    }

    // MARK: cor e opacidade

    static func cor(_ vida: Float, _ k: UInt32, _ c: Controles) -> SIMD3<Float> {
        switch c.colorMap {
        case 0:
            let x = vida * 4, i = min(3, Int(x)), f = x - Float(i)
            return simd_mix(c.custom[i], c.custom[i + 1], SIMD3(repeating: f))
        case 2: return simd_mix(SIMD3(1, 1, 1), c.deathColor, SIMD3(repeating: vida))
        case 3: return simd_mix(c.birthColor, SIMD3(1, 1, 1), SIMD3(repeating: vida))
        case 4: return SIMD3(1, 1, 1)
        default: return simd_mix(c.birthColor, c.deathColor, SIMD3(repeating: vida))
        }
    }

    /// A curva de opacidade padrao do PW: entra rapido e some no fim da vida.
    static func opacidade(_ vida: Float) -> Float {
        let entra = min(1, vida / 0.05)
        let sai = vida > 0.6 ? max(0, 1 - (vida - 0.6) / 0.4) : 1
        return entra * sai
    }

    // MARK: render

    static func rot(_ r: SIMD3<Float>) -> simd_float3x3 {
        let x = r.x * .pi / 180, y = r.y * .pi / 180, z = r.z * .pi / 180
        let rx = simd_float3x3(rows: [SIMD3(1, 0, 0), SIMD3(0, cos(x), -sin(x)), SIMD3(0, sin(x), cos(x))])
        let ry = simd_float3x3(rows: [SIMD3(cos(y), 0, sin(y)), SIMD3(0, 1, 0), SIMD3(-sin(y), 0, cos(y))])
        let rz = simd_float3x3(rows: [SIMD3(cos(z), -sin(z), 0), SIMD3(sin(z), cos(z), 0), SIMD3(0, 0, 1)])
        return rz * ry * rx
    }

    public static func rodar(leitura: MTLTexture, escrita: MTLTexture, controles c: Controles, tempo t: Float) {
        let w = leitura.width, h = leitura.height
        var src = [UInt8](repeating: 0, count: w * h * 4)
        let precisaTextura = [10, 11, 19, 20, 21].contains(c.tipo)
        if precisaTextura {
            src.withUnsafeMutableBytes { b in
                leitura.getBytes(b.baseAddress!, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
            }
        }
        var acc = [Float](repeating: 0, count: w * h * 4)   // premultiplicado, em float
        let W = Float(w)
        let centro = SIMD2<Float>(Float(w) / 2, Float(h) / 2)
        let R = rot(c.camRot)
        let focal = (W / 2) / tan(max(1, min(c.fov, 170)) * .pi / 360)
        let dist = c.camDist * W * (1 / tan(max(1, min(c.fov, 170)) * .pi / 360)) * 0.5
        // particulas vivas
        let rate = max(0, c.birthRate) * 30          // por segundo (~birthRate por quadro a 30 qps... x30)
        var vivas: [Part] = []
        if rate > 0 {
            let primeira = max(0, Int(floor((t - c.longevity) * rate)))
            let ultima = Int(floor(t * rate))
            let maximo = 60000
            let ini = max(primeira, ultima - maximo)
            if ultima >= ini {
                vivas.reserveCapacity(ultima - ini + 1)
                for i in ini...ultima {
                    let tb = Float(i) / rate
                    if let p = particula(UInt32(truncatingIfNeeded: i), nasc: tb, agora: t, c) { vivas.append(p) }
                }
            }
        }
        // projecao
        struct Tela { var x: Float, y: Float, s: Float, z: Float, vx: Float, vy: Float, i: Int }
        var tela: [Tela] = []
        tela.reserveCapacity(vivas.count)
        for (i, p) in vivas.enumerated() {
            var q = R * (p.p * W)
            q.z += dist
            if let m = c.camComp {
                let r = m * SIMD4(p.p.x * W + centro.x, p.p.y * W + centro.y, p.p.z * W, 1)
                guard r.w > 1 else { continue }
                let vq = m * SIMD4((p.p.x + p.vel.x * 0.02) * W + centro.x, (p.p.y + p.vel.y * 0.02) * W + centro.y, (p.p.z + p.vel.z * 0.02) * W, 1)
                let k = focal / max(dist, 1) * (dist / r.w)
                tela.append(Tela(x: r.x / r.w, y: r.y / r.w, s: k, z: r.w,
                                 vx: vq.x / max(vq.w, 1) - r.x / r.w, vy: vq.y / max(vq.w, 1) - r.y / r.w, i: i))
                continue
            }
            guard q.z > W * 0.01 else { continue }
            let k = focal / q.z
            var qv = R * ((p.p + p.vel * 0.02) * W); qv.z += dist
            let vx = qv.z > 1 ? focal * qv.x / qv.z - k * q.x : 0
            let vy = qv.z > 1 ? focal * qv.y / qv.z - k * q.y : 0
            tela.append(Tela(x: centro.x + q.x * k, y: centro.y + q.y * k, s: k, z: q.z, vx: vx, vy: vy, i: i))
        }
        if c.transfer == 0 || c.transfer == 3 { tela.sort { $0.z > $1.z } }   // de longe para perto
        let luz = simd_length(c.light) > 0 ? simd_normalize(c.light) : SIMD3<Float>(0, 0, 1)

        for s in tela {
            let p = vivas[s.i]
            let varT = 1 + c.sizeVar / 100 * sn(p.k, 40)
            let tam = max(0, (c.birthSize + (c.deathSize - c.birthSize) * p.vida) * varT) * W * s.s * 0.5
            guard tam > 0.05 else { continue }
            var rgb = cor(p.vida, p.k, c)
            var a = c.maxOp / 100 * opacidade(p.vida)
            if c.depthCue != 0 {
                let d = max(0, (s.z - dist) / (c.depthDist * W))
                let f = max(0, min(1, 1 - d))
                if c.depthCue == 1 { a *= f } else { rgb = simd_mix(c.fog, rgb, SIMD3(repeating: f)) }
            }
            guard a > 0.002 else { continue }
            let ang = (c.rotInit * sn(p.k, 50) + c.rotSpeed * (p.vida * c.longevity) * (hash(p.k, 51) < 0.5 ? -1 : 1)) * .pi / 180
            let ca = cos(ang), sa = sin(ang)
            // escolhe o desenho
            let raio = tam
            let ext: Float
            switch c.tipo {
            case 0: ext = max(abs(s.vx), abs(s.vy)) * 4 + 2
            case 6, 7: ext = raio * 1.5 + max(abs(s.vx), abs(s.vy))
            default: ext = raio * 1.5
            }
            let x0 = max(0, Int(s.x - ext - 1)), x1 = min(w - 1, Int(s.x + ext + 1))
            let y0 = max(0, Int(s.y - ext - 1)), y1 = min(h - 1, Int(s.y + ext + 1))
            guard x0 <= x1, y0 <= y1 else { continue }
            let len2 = s.vx * s.vx + s.vy * s.vy
            for py in y0...y1 {
                for px in x0...x1 {
                    let dx = Float(px) + 0.5 - s.x, dy = Float(py) + 0.5 - s.y
                    var cov: Float = 0
                    var corPx = rgb
                    switch c.tipo {
                    case 0: // Line: risco na direcao do movimento
                        let lx = s.vx * 4, ly = s.vy * 4, l2 = lx * lx + ly * ly
                        let tt = l2 > 0 ? max(-1, min(0, (dx * lx + dy * ly) / l2)) : 0
                        let ex = dx - lx * tt, ey = dy - ly * tt
                        let d = (ex * ex + ey * ey).squareRoot()
                        let larg = max(0.6, raio * 0.08)
                        cov = max(0, min(1, larg + 0.5 - d))
                    case 1: // Star
                        let rx = dx * ca - dy * sa, ry = dx * sa + dy * ca
                        let d = (rx * rx + ry * ry).squareRoot() / raio
                        let braco = min(abs(rx), abs(ry)) / raio
                        cov = max(0, 1 - d) * max(0, 1 - braco * 8) + max(0, 1 - d * 3) * 0.6
                        cov = min(1, cov)
                    case 2, 14, 15, 16, 17, 18: // Shaded Sphere e lentes (aproximadas)
                        let d2 = (dx * dx + dy * dy) / (raio * raio)
                        if d2 < 1 {
                            let nz = (1 - d2).squareRoot()
                            let n = SIMD3(dx / raio, dy / raio, nz)
                            let l = max(0, simd_dot(n, SIMD3(luz.x, luz.y, luz.z)))
                            corPx = rgb * (0.25 + 0.75 * l)
                            cov = min(1, (1 - d2.squareRoot()) * raio)
                        }
                    case 3, 4: // Faded Sphere / Darken & Faded
                        let d = (dx * dx + dy * dy).squareRoot() / raio
                        if d < 1 { let f = 1 - d; cov = f * f; if c.tipo == 4 { corPx = rgb * f } }
                    case 5: // Bubble
                        let d = (dx * dx + dy * dy).squareRoot() / raio
                        if d < 1 { cov = pow(d, 6) * 0.9 + 0.08 }
                    case 6, 7: // Motion polygon / square: quadrado esticado no movimento
                        let tt = len2 > 0 ? max(0, min(1, (dx * s.vx + dy * s.vy) / len2)) : 0
                        let ex = dx - s.vx * tt, ey = dy - s.vy * tt
                        let rx = ex * ca - ey * sa, ry = ex * sa + ey * ca
                        cov = (abs(rx) < raio * 0.7 && abs(ry) < raio * 0.7) ? 1 : 0
                    case 8, 10, 12: // TriPolygon (gira em 3D: achata num eixo)
                        let sx = max(0.15, abs(cos(ang * 0.7)))
                        let rx = (dx * ca - dy * sa) / sx, ry = dx * sa + dy * ca
                        let y = ry / raio + 0.5
                        cov = (y > -0.5 && y < 1 && abs(rx) / raio < (1 - y) * 0.577 * 1.5) ? 1 : 0
                        corPx = rgb * (0.55 + 0.45 * sx)
                    default: // Quad, Cube, texturizados
                        let sx = max(0.15, abs(cos(ang * 0.7)))
                        let rx = (dx * ca - dy * sa) / sx, ry = dx * sa + dy * ca
                        let disco = c.tipo == 20 || c.tipo == 21
                        let dd = (rx * rx + ry * ry).squareRoot()
                        let dentro = disco ? dd < raio : (abs(rx) < raio * 0.75 && abs(ry) < raio * 0.75)
                        if dentro {
                            cov = c.tipo == 21 ? max(0, 1 - dd / raio) : 1
                            corPx = rgb * (0.55 + 0.45 * sx)
                            if precisaTextura {
                                let u = Int(max(0, min(Float(w - 1), (rx / (raio * 1.5) + 0.5) * Float(w))))
                                let v = Int(max(0, min(Float(h - 1), (ry / (raio * 1.5) + 0.5) * Float(h))))
                                let o = (v * w + u) * 4
                                let ta = Float(src[o + 3]) / 255
                                if ta > 0 {
                                    corPx = SIMD3(Float(src[o]), Float(src[o + 1]), Float(src[o + 2])) / 255 / ta
                                    cov *= ta
                                } else { cov = 0 }
                            }
                        }
                    }
                    if cov <= 0 { continue }
                    let al = min(1, cov * a)
                    let o = (py * w + px) * 4
                    switch c.transfer {
                    case 1: // Screen
                        for ch in 0..<3 { let s0 = acc[o + ch]; acc[o + ch] = s0 + corPx[ch] * al - s0 * corPx[ch] * al }
                        acc[o + 3] = acc[o + 3] + al - acc[o + 3] * al
                    case 2: // Add
                        for ch in 0..<3 { acc[o + ch] += corPx[ch] * al }
                        acc[o + 3] = min(1, acc[o + 3] + al)
                    case 3: // Black Matte: preto por baixo da cor
                        for ch in 0..<3 { acc[o + ch] = corPx[ch] * al + acc[o + ch] * (1 - al) }
                        acc[o + 3] = 1 - (1 - acc[o + 3]) * (1 - al)
                    default: // Composite
                        for ch in 0..<3 { acc[o + ch] = corPx[ch] * al + acc[o + ch] * (1 - al) }
                        acc[o + 3] = al + acc[o + 3] * (1 - al)
                    }
                }
            }
        }
        var out = [UInt8](repeating: 0, count: w * h * 4)
        for i in stride(from: 0, to: w * h * 4, by: 4) {
            let al = min(1, acc[i + 3])
            out[i + 3] = UInt8(al * 255 + 0.5)
            for ch in 0..<3 { out[i + ch] = UInt8(max(0, min(al, acc[i + ch])) * 255 + 0.5) }
        }
        out.withUnsafeBytes { b in
            escrita.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: b.baseAddress!, bytesPerRow: w * 4)
        }
    }
}
