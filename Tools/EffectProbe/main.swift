//
//  EffectProbe — sonda de efeitos do CI.
//
//  Aplica cada efeito, com os valores padrao do XML, numa imagem de teste e
//  mede o que sai da GPU. Roda no Mac do GitHub Actions, com os shaders
//  compilados para macOS e o MESMO EffectRenderer do app.
//
//  Classes:
//    ok           mudou a imagem e o resultado e visivel
//    sem_mudanca  saiu igual a entrada (efeito neutro no padrao — nao e defeito)
//    preto        tudo preto e opaco
//    transparente alfa ~0 com entrada opaca
//    nan          NaN/inf no resultado
//    erro         o renderer lancou erro (pipeline, textura...)
//
//  Uso: nova-effect-probe <probe.metallib> <Resources/effects> <Resources> <saida.json>
//

import Foundation
import Metal
import NovaEngine

let args = CommandLine.arguments
guard args.count >= 5 else {
    print("uso: nova-effect-probe <metallib> <effects> <resources> <saida.json>")
    exit(2)
}
let libURL = URL(fileURLWithPath: args[1])
let effectsURL = URL(fileURLWithPath: args[2])
let resourcesURL = URL(fileURLWithPath: args[3])
let outURL = URL(fileURLWithPath: args[4])

guard let device = MTLCreateSystemDefaultDevice() else {
    print("sem GPU Metal neste Mac"); exit(3)
}
print("GPU: \(device.name)")
let library = try device.makeLibrary(URL: libURL)
let functions = Set(library.functionNames)
EffectRenderer.resourceRoot = resourcesURL
let renderer = try EffectRenderer(device: device, library: library)
guard let queue = device.makeCommandQueue() else { exit(3) }

// Imagem de teste: gradiente colorido com um circulo claro, opaca.
let W = 192, H = 108
func makeInput() -> MTLTexture {
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: W, height: H,
                                                     mipmapped: false)
    d.usage = [.shaderRead, .shaderWrite, .renderTarget]
    d.storageMode = .shared
    let t = device.makeTexture(descriptor: d)!
    var px = [Float16](repeating: 0, count: W * H * 4)
    for y in 0..<H {
        for x in 0..<W {
            let u = Float(x) / Float(W - 1), v = Float(y) / Float(H - 1)
            let dx = u - 0.5, dy = (v - 0.5) * Float(H) / Float(W)
            let inCircle = dx * dx + dy * dy < 0.04
            let i = (y * W + x) * 4
            px[i]     = Float16(inCircle ? 0.95 : u)
            px[i + 1] = Float16(inCircle ? 0.9 : v)
            px[i + 2] = Float16(inCircle ? 0.8 : 1 - u)
            px[i + 3] = 1
        }
    }
    t.replace(region: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0, withBytes: px,
              bytesPerRow: W * 8)
    return t
}
let input = makeInput()

func readBack(_ tex: MTLTexture) -> [Float]? {
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: tex.pixelFormat,
                                                     width: tex.width, height: tex.height,
                                                     mipmapped: false)
    d.storageMode = .shared
    d.usage = [.shaderRead]
    guard let shared = device.makeTexture(descriptor: d),
          let cb = queue.makeCommandBuffer(), let blit = cb.makeBlitCommandEncoder() else { return nil }
    blit.copy(from: tex, to: shared)
    blit.endEncoding()
    cb.commit(); cb.waitUntilCompleted()
    let n = tex.width * tex.height * 4
    switch tex.pixelFormat {
    case .rgba16Float:
        var h = [Float16](repeating: 0, count: n)
        shared.getBytes(&h, bytesPerRow: tex.width * 8,
                        from: MTLRegionMake2D(0, 0, tex.width, tex.height), mipmapLevel: 0)
        return h.map { Float($0) }
    case .rgba32Float:
        var f = [Float](repeating: 0, count: n)
        shared.getBytes(&f, bytesPerRow: tex.width * 16,
                        from: MTLRegionMake2D(0, 0, tex.width, tex.height), mipmapLevel: 0)
        return f
    default:
        var b = [UInt8](repeating: 0, count: n)
        shared.getBytes(&b, bytesPerRow: tex.width * 4,
                        from: MTLRegionMake2D(0, 0, tex.width, tex.height), mipmapLevel: 0)
        return b.map { Float($0) / 255 }
    }
}
let inputPixels = readBack(input) ?? []

struct Result: Codable {
    var id: String
    var funcao: String
    var status: String
    var rgb: Float
    var alfa: Float
    var diferenca: Float
    var erro: String?
}

let registry = EffectRegistry()
try await registry.load(from: effectsURL)
let entries = await registry.all
var results: [Result] = []
var counts: [String: Int] = [:]

for e in entries {
    let fn = "fx_\(e.slug)"
    guard functions.contains(fn) else { continue }
    var r = Result(id: e.id, funcao: fn, status: "erro", rgb: 0, alfa: 0, diferenca: 0, erro: nil)
    do {
        let m = try await registry.manifest(id: e.id)
        let values = AppliedEffect(effectID: e.id).values(at: 0.5, manifest: m)
        guard let cb = queue.makeCommandBuffer() else { throw RenderError.noDevice }
        let out: MTLTexture
        if m.stage == "mblooks", let t = LooksFerramentas.porManifesto[e.id] {
            // Ferramenta do Magic Bullet Looks: roda pelo motor do Looks, como no editor.
            out = try renderer.renderLooks(entrada: input,
                                           passos: [LooksPasso(codigo: t.codigo,
                                                               valores: LooksFerramentas.valores(t.params, de: values),
                                                               lut: "looks/cinema-teal-orange.png")],
                                           forca: 1, mediaRoot: nil, cb: cb)
        } else {
            out = try renderer.render(m, input: .init(content: input, comp: input,
                                                      time: 0.5, frameDuration: 1.0 / 30),
                                      values: values, into: cb)
        }
        cb.commit(); cb.waitUntilCompleted()
        if let err = cb.error { throw err }
        guard let px = readBack(out) else { throw RenderError.noDevice }
        if out !== input { renderer.release(out) }
        var sumRGB: Float = 0, sumA: Float = 0, diff: Float = 0, bad = 0
        let count = px.count / 4
        for i in 0..<count {
            let rr = px[i*4], gg = px[i*4+1], bb = px[i*4+2], aa = px[i*4+3]
            if !rr.isFinite || !gg.isFinite || !bb.isFinite || !aa.isFinite { bad += 1; continue }
            sumRGB += (rr + gg + bb) / 3
            sumA += aa
            if inputPixels.count == px.count {
                diff += abs(rr - inputPixels[i*4]) + abs(gg - inputPixels[i*4+1])
                    + abs(bb - inputPixels[i*4+2]) + abs(aa - inputPixels[i*4+3])
            }
        }
        r.rgb = sumRGB / Float(count)
        r.alfa = sumA / Float(count)
        r.diferenca = diff / Float(count)
        if bad > count / 100 { r.status = "nan" }
        else if r.alfa < 0.02 { r.status = "transparente" }
        else if r.rgb < 0.01 && r.alfa > 0.9 { r.status = "preto" }
        else if r.diferenca < 0.002 { r.status = "sem_mudanca" }
        else { r.status = "ok" }
    } catch {
        r.erro = error.localizedDescription
    }
    counts[r.status, default: 0] += 1
    results.append(r)
}

let enc = JSONEncoder()
enc.outputFormatting = [.prettyPrinted, .sortedKeys]
try enc.encode(results).write(to: outURL)
print("efeitos testados: \(results.count)")
for (k, v) in counts.sorted(by: { $0.key < $1.key }) { print("  \(k): \(v)") }
