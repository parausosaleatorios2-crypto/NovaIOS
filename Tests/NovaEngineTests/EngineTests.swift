//
//  EngineTests.swift
//  Testes do que da para testar sem GPU: parser de efeito, keyframes, easing,
//  transformacao e o pacote .nova.
//

import XCTest
import simd
@testable import NovaEngine

final class EffectManifestTests: XCTestCase {

    func testLeParametrosEPasses() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <effect id="nova.effect.teste" name="Teste" name-en="Test" category="blur">
          <params>
            <texture id="inputImg" src="content" />
            <texture id="hblur" src="buffer" />
            <slider id="radius" label="Raio" default="8.0" min="0.0" max="40.0" passo="0.5" />
            <slider id="iterations" default="2" min="1" max="4" />
            <color id="tint" default="#ff8800" />
            <point id="centro" default="0.5, 0.5" />
          </params>
          <iterations param="iterations" />
          <passes><pass target="hblur" /><pass /></passes>
          <shader><![CDATA[ void main() { fragColor = vec4(1.0); } ]]></shader>
        </effect>
        """
        let m = try EffectManifestParser.parse(data: Data(xml.utf8), fileName: "nv-teste.xml")
        XCTAssertEqual(m.id, "nova.effect.teste")
        XCTAssertEqual(m.name, "Teste")
        XCTAssertEqual(m.slug, "nv_teste")
        XCTAssertEqual(m.functionName, "fx_nv_teste")
        XCTAssertEqual(m.textures.count, 2)
        XCTAssertEqual(m.textures[0].source, .content)
        XCTAssertEqual(m.textures[1].source, .buffer)
        XCTAssertEqual(m.params.count, 4)
        XCTAssertEqual(m.passes.count, 2)
        XCTAssertEqual(m.passes[0].target, "hblur")
        XCTAssertNil(m.passes[1].target)
        XCTAssertEqual(m.iterationsParam, "iterations")
        XCTAssertEqual(m.param("radius")?.defaultValue, [8.0])
        XCTAssertEqual(m.param("radius")?.maxValue, 40.0)
    }

    func testCorHexadecimal() {
        let c = EffectManifestParser.colorFloats("#ff8800", count: 4)
        XCTAssertEqual(c[0], 1.0, accuracy: 0.01)
        XCTAssertEqual(c[1], 0x88/255.0, accuracy: 0.01)
        XCTAssertEqual(c[2], 0.0, accuracy: 0.01)
        XCTAssertEqual(c[3], 1.0, accuracy: 0.01)
    }

    func testSemPassesViraPassUnico() throws {
        let xml = "<effect id=\"a\" name=\"A\"><params/><shader><![CDATA[void main(){}]]></shader></effect>"
        let m = try EffectManifestParser.parse(data: Data(xml.utf8), fileName: "a.xml")
        XCTAssertEqual(m.passes.count, 1)
        XCTAssertNil(m.passes[0].target)
    }

    func testXmlQuebradoDaErro() {
        let xml = "<effect id=\"a\"><params>"
        XCTAssertThrowsError(try EffectManifestParser.parse(data: Data(xml.utf8), fileName: "a.xml"))
    }
}

final class AnimatedTests: XCTestCase {

    func testValorEstaticoSemChaves() {
        let a = Animated<Float>(42)
        XCTAssertEqual(a.value(at: 0), 42)
        XCTAssertEqual(a.value(at: 99), 42)
        XCTAssertFalse(a.isAnimated)
    }

    func testInterpolacaoLinear() {
        var a = Animated<Float>(0)
        a.setKeyframe(time: 0, value: 0)
        a.setKeyframe(time: 2, value: 10)
        XCTAssertEqual(a.value(at: 0), 0, accuracy: 1e-5)
        XCTAssertEqual(a.value(at: 1), 5, accuracy: 1e-5)
        XCTAssertEqual(a.value(at: 2), 10, accuracy: 1e-5)
        XCTAssertEqual(a.value(at: -1), 0, accuracy: 1e-5)   // antes da primeira
        XCTAssertEqual(a.value(at: 99), 10, accuracy: 1e-5)  // depois da ultima
    }

    func testHoldNaoInterpola() {
        var a = Animated<Float>(0)
        a.setKeyframe(time: 0, value: 0, easing: .hold)
        a.setKeyframe(time: 2, value: 10)
        XCTAssertEqual(a.value(at: 1.9), 0, accuracy: 1e-5)
        XCTAssertEqual(a.value(at: 2), 10, accuracy: 1e-5)
    }

    func testBuscaBinariaComMuitasChaves() {
        var a = Animated<Float>(0)
        for i in 0..<500 { a.setKeyframe(time: Float(i), value: Float(i)) }
        XCTAssertEqual(a.value(at: 250.5), 250.5, accuracy: 1e-3)
        XCTAssertEqual(a.value(at: 499), 499, accuracy: 1e-3)
    }

    func testMoverChaveMantemOrdem() {
        var a = Animated<Float>(0)
        let id = a.setKeyframe(time: 0, value: 0)
        a.setKeyframe(time: 1, value: 1)
        a.setKeyframe(time: 2, value: 2)
        a.moveKeyframe(id: id, to: 1.5)
        XCTAssertEqual(a.keyframes.map(\.time), [1.0, 1.5, 2.0])
    }

    func testInverter() {
        var a = Animated<Float>(0)
        a.setKeyframe(time: 0, value: 0)
        a.setKeyframe(time: 1, value: 1)
        a.setKeyframe(time: 4, value: 4)
        a.reverse()
        XCTAssertEqual(a.keyframes.map(\.time), [0.0, 3.0, 4.0])
    }

    func testBezierNosExtremos() {
        let e = Easing.bezier(SIMD2(0.42, 0), SIMD2(0.58, 1))
        XCTAssertEqual(e.apply(0), 0, accuracy: 1e-4)
        XCTAssertEqual(e.apply(1), 1, accuracy: 1e-4)
        XCTAssertEqual(e.apply(0.5), 0.5, accuracy: 0.02)   // simetrica
    }

    func testBezierMonotona() {
        let e = Easing.bezier(SIMD2(0.25, 0.1), SIMD2(0.25, 1))
        var anterior: Float = -1
        for i in 0...100 {
            let v = e.apply(Float(i) / 100)
            XCTAssertGreaterThanOrEqual(v, anterior - 1e-4, "caiu em t=\(i)")
            anterior = v
        }
    }

    func testPresetsDoFlowFechamNoIntervalo() {
        for n in ["ease","easeIn","easeOut","quadIn","cubicOut","expoOut","bounce","elastic","circIn"] {
            XCTAssertEqual(Easing.named(n).apply(0), 0, accuracy: 1e-3, "\(n) em 0")
            XCTAssertEqual(Easing.named(n).apply(1), 1, accuracy: 1e-3, "\(n) em 1")
        }
    }
}

final class TransformTests: XCTestCase {

    func testIdentidadeComValoresPadrao() {
        let t = Transform()
        let m = t.matrix(at: 0)
        XCTAssertEqual(m.columns.0.x, 1, accuracy: 1e-5)
        XCTAssertEqual(m.columns.1.y, 1, accuracy: 1e-5)
        XCTAssertEqual(m.columns.3.x, 0, accuracy: 1e-5)
    }

    func testPosicaoEEscala() {
        var t = Transform()
        t.position = Animated(SIMD2(100, 50))
        t.scale = Animated(SIMD2(200, 200))
        let m = t.matrix(at: 0)
        let p = m * SIMD4<Float>(1, 0, 0, 1)
        XCTAssertEqual(p.x, 102, accuracy: 1e-4)
        XCTAssertEqual(p.y, 50, accuracy: 1e-4)
    }

    func testOpacidadeEmFracao() {
        var t = Transform()
        t.opacity = Animated(50)
        XCTAssertEqual(t.alpha(at: 0), 0.5, accuracy: 1e-5)
        t.opacity = Animated(150)
        XCTAssertEqual(t.alpha(at: 0), 1.0, accuracy: 1e-5)   // preso em 1
    }
}

final class CompositionTests: XCTestCase {

    func testCamadasVisiveis() {
        var c = Composition(duration: 10)
        var a = Layer(name: "A", kind: .video); a.startTime = 0; a.duration = 5
        var b = Layer(name: "B", kind: .text);  b.startTime = 5; b.duration = 5
        c.add(a); c.add(b)
        XCTAssertEqual(c.visibleLayers(at: 1).map(\.name), ["A"])
        XCTAssertEqual(c.visibleLayers(at: 7).map(\.name), ["B"])
        XCTAssertTrue(c.visibleLayers(at: 11).isEmpty)
    }

    func testSoloIsolaCamada() {
        var c = Composition()
        var a = Layer(name: "A", kind: .video); a.duration = 10
        var b = Layer(name: "B", kind: .video); b.duration = 10; b.solo = true
        c.add(a); c.add(b)
        XCTAssertEqual(c.visibleLayers(at: 1).map(\.name), ["B"])
    }

    func testCadeiaDePaisNaoEntraEmCiclo() {
        var c = Composition()
        var a = Layer(name: "A", kind: .null)
        var b = Layer(name: "B", kind: .null)
        a.parentID = b.id
        b.parentID = a.id          // ciclo de proposito
        c.add(a); c.add(b)
        // Se nao houver protecao, isto trava o teste.
        _ = c.worldMatrix(of: a, at: 0)
    }

    func testContagemDeQuadros() {
        let c = Composition(frameRate: 60, duration: 2.5)
        XCTAssertEqual(c.frameCount, 150)
    }
}

final class ProjectIOTests: XCTestCase {

    func testGravaEleProjeto() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nova-teste-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }

        var comp = Composition(name: "Demo", width: 1080, height: 1920, frameRate: 60)
        var l = Layer(name: "Fundo", kind: .solid)
        l.transform.position.setKeyframe(time: 0, value: SIMD2(0, 0))
        l.transform.position.setKeyframe(time: 1, value: SIMD2(100, 0), easing: .named("ease"))
        comp.add(l)
        let p = NovaProject(name: "Demo", composition: comp)

        try NovaProjectIO.saveFolder(p, to: dir)
        let lido = try NovaProjectIO.loadFolder(from: dir)

        XCTAssertEqual(lido.project.name, "Demo")
        XCTAssertEqual(lido.project.mainComposition?.width, 1080)
        XCTAssertEqual(lido.project.mainComposition?.frameRate, 60)
        let camada = lido.project.mainComposition?.layers.first
        XCTAssertEqual(camada?.name, "Fundo")
        XCTAssertEqual(camada?.transform.position.keyframes.count, 2)
        XCTAssertEqual(camada?.transform.position.value(at: 0.5), SIMD2(50, 0))
    }

    func testProjetoAusenteDaErro() {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nao-existe-\(UUID().uuidString)")
        XCTAssertThrowsError(try NovaProjectIO.loadFolder(from: dir))
    }
}
