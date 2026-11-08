//
//  TransformEditing.swift
//  NovaUI
//
//  Mover, girar e escalar camadas na previa, e o painel de propriedades.
//
//  Do APK (com.novaeditor.model.Transform, conferido com o REA): ancora,
//  posicao (+Z), escala, rotacao (Z, X, Y), opacidade e inclinacao (skew),
//  todas animaveis. A matriz e a de Transform.buildMatrix.
//

import SwiftUI
import UIKit
import simd

/// Muda uma camada. `save` false durante o gesto (grava so no fim).
typealias LayerEdit = (_ id: UUID, _ save: Bool, _ change: (inout Layer) -> Void) -> Void

// MARK: - Gizmo na previa

struct TransformGizmo: View {
    let comp: Composition
    let time: Float
    @Binding var selected: UUID?
    let edit: LayerEdit

    @State private var dragStart: SIMD2<Float>?
    @State private var scaleStart: SIMD2<Float>?
    @State private var rotStart: Float?

    private var layer: Layer? { selected.flatMap { comp.layer(id: $0) } }

    var body: some View {
        GeometryReader { g in
            let k = Float(comp.width) / Float(max(g.size.width, 1))
            ZStack {
                Color.clear.contentShape(Rectangle())
                if let l = layer, l.kind.rendersPixels, l.isVisible(at: time) {
                    let c = corners(l, k: k)
                    Path { p in p.addLines(c); p.closeSubpath() }
                        .stroke(NovaTheme.accent, lineWidth: 1.5)
                    ForEach(0..<4, id: \.self) { i in
                        Circle().fill(Color.white).frame(width: 7, height: 7)
                            .overlay(Circle().stroke(NovaTheme.accent, lineWidth: 1))
                            .position(c[i])
                    }
                    let a = anchorPoint(l, k: k)
                    Image(systemName: "plus.circle").font(.system(size: 12))
                        .foregroundStyle(NovaTheme.accent).position(a)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { v in
                        guard let l = layer else { return }
                        let start = dragStart ?? l.transform.position.value(at: time)
                        if dragStart == nil { dragStart = start }
                        let d = SIMD2(Float(v.translation.width), Float(v.translation.height)) * k
                        edit(l.id, false) { $0.transform.position.set(start + d, at: time) }
                    }
                    .onEnded { _ in
                        if let id = selected { edit(id, true) { _ in } }
                        dragStart = nil
                    }
                    .simultaneously(with: MagnificationGesture()
                        .onChanged { m in
                            guard let l = layer else { return }
                            let start = scaleStart ?? l.transform.scale.value(at: time)
                            if scaleStart == nil { scaleStart = start }
                            edit(l.id, false) { $0.transform.scale.set(start * Float(m), at: time) }
                        }
                        .onEnded { _ in
                            if let id = selected { edit(id, true) { _ in } }
                            scaleStart = nil
                        })
                    .simultaneously(with: RotationGesture()
                        .onChanged { r in
                            guard let l = layer else { return }
                            let start = rotStart ?? l.transform.rotationZ.value(at: time)
                            if rotStart == nil { rotStart = start }
                            edit(l.id, false) { $0.transform.rotationZ.set(start + Float(r.degrees), at: time) }
                        }
                        .onEnded { _ in
                            if let id = selected { edit(id, true) { _ in } }
                            rotStart = nil
                        })
            )
            .onTapGesture { p in
                let pt = SIMD2(Float(p.x), Float(p.y)) * k
                selected = hit(pt)
            }
        }
    }

    private func size(_ l: Layer) -> SIMD2<Float> { l.size ?? comp.size }

    private func project(_ m: simd_float4x4, _ x: Float, _ y: Float, k: Float) -> CGPoint {
        let v = m * SIMD4(x, y, 0, 1)
        return CGPoint(x: CGFloat(v.x / k), y: CGFloat(v.y / k))
    }

    private func corners(_ l: Layer, k: Float) -> [CGPoint] {
        let m = comp.worldMatrix(of: l, at: time)
        let s = size(l)
        return [project(m, 0, 0, k: k), project(m, s.x, 0, k: k),
                project(m, s.x, s.y, k: k), project(m, 0, s.y, k: k)]
    }

    private func anchorPoint(_ l: Layer, k: Float) -> CGPoint {
        let a = l.transform.anchorPoint.value(at: time)
        return project(comp.worldMatrix(of: l, at: time), a.x, a.y, k: k)
    }

    /// Camada mais de cima que contem o ponto (em px da composicao).
    private func hit(_ p: SIMD2<Float>) -> UUID? {
        for l in comp.layers where l.isVisible(at: time) && l.kind.rendersPixels && !l.locked
            && l.kind != .adjustment {
            let inv = comp.worldMatrix(of: l, at: time).inverse
            let q = inv * SIMD4(p.x, p.y, 0, 1)
            let s = size(l)
            if q.x >= 0, q.y >= 0, q.x <= s.x, q.y <= s.y { return l.id }
        }
        return nil
    }
}

// MARK: - Painel de propriedades

struct LayerPropertiesSheet: View {
    let comp: Composition
    let layerID: UUID
    let time: Float
    let manifests: [String: EffectManifest]
    let edit: LayerEdit
    var mediaRoot: URL? = nil
    @Environment(\.dismiss) private var dismiss

    private var layer: Layer? { comp.layer(id: layerID) }

    // Abas da camada, como as ferramentas de camada do APK (enum s22):
    // Camada, Opacidade, Transformar, Preencher, Borda e sombra, Editar forma,
    // Animar, Efeitos, Mascara, Velocidade, Som.
    @State private var aba: String?

    private func abasDe(_ l: Layer) -> [(String, String, String)] {
        var a: [(String, String, String)] = [("camada", "Camada", "square.3.layers.3d")]
        if l.kind.rendersPixels {
            a.append(("opacidade", "Opacidade", "circle.lefthalf.filled"))
            a.append(("transformar", "Transformar", "arrow.up.left.and.arrow.down.right"))
        }
        if l.kind == .shape || l.kind == .text || l.kind == .solid {
            a.append(("preencher", "Preencher", "paintbrush.fill"))
        }
        if l.kind == .shape || l.kind == .text { a.append(("borda", "Borda e sombra", "square.dashed")) }
        if l.kind == .shape { a.append(("forma", "Editar forma", "pencil.and.outline")) }
        if l.kind.rendersPixels { a.append(("animar", "Animar", "diamond")) }
        a.append(("efeitos", "Efeitos", "wand.and.stars"))
        if l.kind.rendersPixels && l.kind != .adjustment { a.append(("mascara", "Máscara", "circle.circle")) }
        if l.kind == .video || l.kind == .audio {
            a.append(("velocidade", "Velocidade", "speedometer"))
            a.append(("som", "Som", "speaker.wave.2"))
        }
        return a
    }

    private func abaAtual(_ l: Layer) -> String {
        let ids = abasDe(l).map(\.0)
        if let aba, ids.contains(aba) { return aba }
        return l.kind.rendersPixels ? "transformar" : "camada"
    }

    private func abas(_ l: Layer) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(abasDe(l), id: \.0) { t in
                    FerramentaBotao(label: t.1.loc, icon: t.2, ativa: abaAtual(l) == t.0, habilitada: true) {
                        aba = t.0
                    }
                }
            }.padding(.horizontal, 6)
        }
        .frame(height: 64)
        .background(NovaTheme.surface)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let l = layer {
                    VStack(spacing: 0) {
                        abas(l)
                        Form {
                            switch abaAtual(l) {
                            case "transformar", "opacidade", "animar":
                                if l.kind == .text && abaAtual(l) == "animar" {
                                    TextSection(layer: l, time: time, edit: edit)
                                }
                                if l.kind.rendersPixels { transformSection(l) }
                            case "preencher", "borda", "forma":
                                if l.kind == .shape { ShapeSection(layer: l, time: time, edit: edit) }
                                if l.kind == .text { TextSection(layer: l, time: time, edit: edit) }
                                if l.kind == .solid { layerSection(l) }
                            case "efeitos":
                                if l.effects.isEmpty {
                                    Text("Nenhum efeito. Toque em Efeitos na barra de baixo para aplicar.".loc)
                                        .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                                } else { effectsSection(l) }
                            case "mascara":
                                MaskSection(layer: l, comp: comp, time: time, edit: edit)
                            case "velocidade", "som":
                                MediaSection(layer: l, edit: edit)
                            default:
                                layerSection(l)
                                ParentSection(layer: l, comp: comp, edit: edit)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    Text("Camada não encontrada".loc).foregroundStyle(NovaTheme.dim)
                }
            }
            .background(NovaTheme.background)
            .navigationTitle(layer?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Fechar".loc) { dismiss() } } }
        }
        .presentationDetents([.fraction(0.45), .large])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.45)))
        .preferredColorScheme(.dark)
    }

    // MARK: transformar

    private func transformSection(_ l: Layer) -> some View {
        let s = l.size ?? comp.size
        let big = max(comp.size.x, comp.size.y) * 2
        return Section("Transformar".loc) {
            vec2Row("Posição", \.position, l, range: -big...big)
            vec2Row("Escala", \.scale, l, range: 0...400, unit: "%", uniform: true)
            floatRow("Rotação", \.rotationZ, l, range: -360...360, unit: "°")
            floatRow("Opacidade", \.opacity, l, range: 0...100, unit: "%")
            vec2Row("Ponto de ancoragem", \.anchorPoint, l,
                    range: -max(s.x, s.y)...max(s.x, s.y) * 2)
            vec2Row("Inclinação", \.skewValue, l, range: -80...80, unit: "°")
            floatRow("Rotação X", \.rotationX, l, range: -180...180, unit: "°")
            floatRow("Rotação Y", \.rotationY, l, range: -180...180, unit: "°")
            Button("Centralizar e caber na tela".loc) {
                edit(l.id, true) { MediaImporter.fit(&$0, in: comp) }
            }.font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
        }
    }

    private func floatRow(_ title: String, _ kp: WritableKeyPath<Transform, Animated<Float>>,
                          _ l: Layer, range: ClosedRange<Float>, unit: String = "") -> some View {
        let a = l.transform[keyPath: kp]
        let v = a.value(at: time)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                keyButton(a.keyframes.isEmpty, a.hasKeyframe(at: time)) {
                    edit(l.id, true) { layer in
                        var p = layer.transform[keyPath: kp]
                        Self.toggleKey(&p, at: time)
                        layer.transform[keyPath: kp] = p
                    }
                }
                Text(title.loc).font(.system(size: 12))
                if a.hasKeyframe(at: time) {
                    EasingMenu(current: a.easing(at: time)) { e in edit(l.id, true) { $0.transform[keyPath: kp].setEasing(at: time, e) } }
                }
                Spacer()
                Text(String(format: "%.1f%@", v, unit)).font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(NovaTheme.dim)
            }
            Slider(value: Binding(get: { min(max(v, range.lowerBound), range.upperBound) },
                                  set: { nv in edit(l.id, false) { $0.transform[keyPath: kp].set(nv, at: time) } }),
                   in: range, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
        }
    }

    private func vec2Row(_ title: String, _ kp: WritableKeyPath<Transform, Animated<SIMD2<Float>>>,
                         _ l: Layer, range: ClosedRange<Float>, unit: String = "",
                         uniform: Bool = false) -> some View {
        let a = l.transform[keyPath: kp]
        let v = a.value(at: time)
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                keyButton(a.keyframes.isEmpty, a.hasKeyframe(at: time)) {
                    edit(l.id, true) { layer in
                        var p = layer.transform[keyPath: kp]
                        Self.toggleKey(&p, at: time)
                        layer.transform[keyPath: kp] = p
                    }
                }
                Text(title.loc).font(.system(size: 12))
                if a.hasKeyframe(at: time) {
                    EasingMenu(current: a.easing(at: time)) { e in edit(l.id, true) { $0.transform[keyPath: kp].setEasing(at: time, e) } }
                }
                Spacer()
                Text(String(format: "%.0f, %.0f%@", v.x, v.y, unit))
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(NovaTheme.dim)
            }
            if uniform {
                Slider(value: Binding(get: { min(max(v.x, range.lowerBound), range.upperBound) },
                                      set: { nv in
                                          let r = v.x != 0 ? v.y / v.x : 1
                                          edit(l.id, false) { $0.transform[keyPath: kp].set(SIMD2(nv, nv * r), at: time) }
                                      }),
                       in: range, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
            } else {
                HStack(spacing: 6) {
                    Text("X").font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
                    Slider(value: Binding(get: { min(max(v.x, range.lowerBound), range.upperBound) },
                                          set: { nv in edit(l.id, false) { $0.transform[keyPath: kp].set(SIMD2(nv, v.y), at: time) } }),
                           in: range, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                }
                HStack(spacing: 6) {
                    Text("Y").font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
                    Slider(value: Binding(get: { min(max(v.y, range.lowerBound), range.upperBound) },
                                          set: { nv in edit(l.id, false) { $0.transform[keyPath: kp].set(SIMD2(v.x, nv), at: time) } }),
                           in: range, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                }
            }
        }
    }

    /// Losango do keyframe: cheio = ha chave neste instante; contorno = animado;
    /// cronometro = sem animacao.
    private func keyButton(_ notAnimated: Bool, _ hasKey: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: notAnimated ? "stopwatch" : (hasKey ? "diamond.fill" : "diamond"))
                .font(.system(size: 11))
                .foregroundStyle(notAnimated ? NovaTheme.dim2 : NovaTheme.accent)
                .frame(width: 22, height: 22)
        }.buttonStyle(.plain)
    }

    static func toggleKey<T: Interpolatable>(_ a: inout Animated<T>, at t: Float) {
        if a.keyframes.isEmpty { a.toggleAnimation(at: t) }
        else if a.hasKeyframe(at: t) {
            a.removeKeyframe(at: t, tolerance: 1e-3)
            if a.keyframes.isEmpty { a.clearKeyframes() }
        } else { a.setKeyframe(time: t, value: a.value(at: t)) }
    }

    // MARK: efeitos

    private func effectsSection(_ l: Layer) -> some View {
        Section("Efeitos".loc) {
            ForEach(Array(l.effects.enumerated()), id: \.element.id) { i, fx in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Toggle(isOn: Binding(get: { fx.enabled },
                                             set: { on in edit(l.id, true) { $0.effects[i].enabled = on } })) {
                            Text(manifests[fx.effectID]?.name ?? fx.effectID)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Button(role: .destructive) {
                            edit(l.id, true) { $0.effects.removeAll { $0.id == fx.id } }
                        } label: { Image(systemName: "trash").font(.system(size: 12)) }
                            .buttonStyle(.plain).foregroundStyle(NovaTheme.warning)
                    }
                    if let m = manifests[fx.effectID] {
                        ForEach(m.params) { p in paramRow(l, i, fx, p) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func paramRow(_ l: Layer, _ i: Int, _ fx: AppliedEffect, _ p: EffectParam) -> some View {
        let title = p.label ?? p.labelEn ?? p.id
        switch p.kind {
        case .slider, .spinner, .float, .hueDisc:
            let def = p.defaultValue.first ?? 0
            let lo = p.minValue ?? min(0, def)
            let hi = max(p.maxValue ?? max(100, def * 2), lo + 0.001)
            let v = fx.floats[p.id]?.value(at: time) ?? def
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(title).font(.system(size: 11))
                    Spacer()
                    Text(String(format: "%.2f", v)).font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(NovaTheme.dim)
                }
                Slider(value: Binding(get: { min(max(v, lo), hi) }, set: { nv in
                    edit(l.id, false) { layer in
                        var a = layer.effects[i].floats[p.id] ?? Animated(def)
                        a.set(nv, at: time)
                        layer.effects[i].floats[p.id] = a
                    }
                }), in: lo...hi, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
            }
        case .switchParam, .checkbox:
            let on = (fx.ints[p.id] ?? Int32(p.defaultValue.first ?? 0)) != 0
            Toggle(title, isOn: Binding(get: { on }, set: { nv in
                edit(l.id, true) { $0.effects[i].ints[p.id] = nv ? 1 : 0 }
            })).font(.system(size: 11))
        case .selector, .cycle:
            let cur = Int(fx.ints[p.id] ?? Int32(p.defaultValue.first ?? 0))
            Picker(title, selection: Binding(get: { cur }, set: { nv in
                edit(l.id, true) { $0.effects[i].ints[p.id] = Int32(nv) }
            })) {
                if p.options.isEmpty {
                    ForEach(0..<max(1, cur + 2), id: \.self) { Text("\($0)").tag($0) }
                } else {
                    ForEach(Array(p.options.enumerated()), id: \.offset) { Text($0.element).tag($0.offset) }
                }
            }.font(.system(size: 11))
        case .color:
            let d = p.defaultValue
            let c = fx.colors[p.id]?.value(at: time)
                ?? SIMD4(d.count > 0 ? d[0] : 1, d.count > 1 ? d[1] : 1, d.count > 2 ? d[2] : 1, d.count > 3 ? d[3] : 1)
            ColorPicker(title, selection: Binding(get: { Color(rgba: c) }, set: { nc in
                edit(l.id, true) { layer in
                    var a = layer.effects[i].colors[p.id] ?? Animated(c)
                    a.set(nc.rgba, at: time)
                    layer.effects[i].colors[p.id] = a
                }
            })).font(.system(size: 11))
        case .point:
            let d = p.defaultValue
            let v = fx.points[p.id]?.value(at: time) ?? SIMD2(d.first ?? 0.5, d.count > 1 ? d[1] : 0.5)
            let hi: Float = max(1, max(abs(v.x), abs(v.y)) * 2, p.maxValue ?? 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 11))
                ForEach(0..<2, id: \.self) { axis in
                    Slider(value: Binding(get: { axis == 0 ? v.x : v.y }, set: { nv in
                        edit(l.id, false) { layer in
                            var a = layer.effects[i].points[p.id] ?? Animated(v)
                            var nvv = a.value(at: time)
                            if axis == 0 { nvv.x = nv } else { nvv.y = nv }
                            a.set(nvv, at: time)
                            layer.effects[i].points[p.id] = a
                        }
                    }), in: (p.minValue ?? -hi)...hi,
                           onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                }
            }
        case .curve:
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 11.5))
                CurvesParamEditor(curves: fx.curveSets[p.id] ?? CurveSet()) { c, save in
                    edit(l.id, save) { $0.effects[i].curveSets[p.id] = c }
                }
            }
        case .lut:
            LutParamEditor(title: title, current: fx.lutPaths[p.id], mediaRoot: mediaRoot) { path in
                edit(l.id, true) { layer in
                    if let path { layer.effects[i].lutPaths[p.id] = path }
                    else { layer.effects[i].lutPaths[p.id] = nil }
                }
            }
        case .nodeGrading, .gradacao:
            Text(String(format: "%@: gradação neutra (editor de rodas de cor ainda não escrito)".loc, title))
                .font(.system(size: 10.5)).foregroundStyle(NovaTheme.dim2)
        default:
            EmptyView()
        }
    }

    // MARK: camada

    private func layerSection(_ l: Layer) -> some View {
        Section("Camada".loc) {
            if l.kind == .text {
                TextField("Texto".loc, text: Binding(get: { l.text ?? "" }, set: { t in
                    edit(l.id, true) { layer in
                        layer.text = t
                        TextSection.remeasure(&layer, time)
                    }
                }))
                HStack {
                    Text("Tamanho".loc).font(.system(size: 12))
                    Slider(value: Binding(get: { l.fontSize ?? 96 }, set: { v in
                        edit(l.id, false) { layer in
                            layer.fontSize = v
                            TextSection.remeasure(&layer, time)
                        }
                    }), in: 8...600, onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                }
                ColorPicker("Cor".loc, selection: Binding(get: { Color(rgba: l.textColor ?? SIMD4(1, 1, 1, 1)) },
                                                          set: { c in edit(l.id, true) { $0.textColor = c.rgba } }))
            }
            if l.kind == .solid || l.kind == .shape {
                ColorPicker("Cor".loc, selection: Binding(get: { Color(rgba: l.solidColor ?? SIMD4(1, 1, 1, 1)) },
                                                          set: { c in edit(l.id, true) { $0.solidColor = c.rgba } }))
            }
            Picker("Mesclagem".loc, selection: Binding(get: { l.blendMode },
                                                       set: { b in edit(l.id, true) { $0.blendMode = b } })) {
                ForEach(BlendMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            HStack {
                Text("Duração".loc).font(.system(size: 12))
                Slider(value: Binding(get: { l.duration }, set: { d in edit(l.id, false) { $0.duration = d } }),
                       in: 0.1...max(comp.duration, l.duration, 1),
                       onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                Text(String(format: "%.1fs", l.duration)).font(.system(size: 10, design: .monospaced))
            }
            HStack {
                Text("Início".loc).font(.system(size: 12))
                Slider(value: Binding(get: { l.startTime }, set: { s in edit(l.id, false) { $0.startTime = s } }),
                       in: 0...max(comp.duration, 0.1),
                       onEditingChanged: { ed in if !ed { edit(l.id, true) { _ in } } })
                Text(String(format: "%.1fs", l.startTime)).font(.system(size: 10, design: .monospaced))
            }
        }
    }
}

// MARK: - Cor <-> SIMD4

extension Color {
    init(rgba c: SIMD4<Float>) {
        self.init(.sRGB, red: Double(c.x), green: Double(c.y), blue: Double(c.z), opacity: Double(c.w))
    }
    var rgba: SIMD4<Float> {
        let u = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        u.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD4(Float(r), Float(g), Float(b), Float(a))
    }
}
