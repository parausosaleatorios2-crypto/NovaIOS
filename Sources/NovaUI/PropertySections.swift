//
//  PropertySections.swift
//  NovaUI
//
//  Secoes do painel de propriedades: mascaras, forma, texto, midia e pai.
//  Modelos conferidos no APK com o REA (LayerMask, LayerContent.Shape,
//  LayerContent.Media).
//

import SwiftUI
import UIKit
import simd

// MARK: - Slider animavel reutilizavel

struct AnimSlider: View {
    let title: String
    let value: Float
    let range: ClosedRange<Float>
    var unit: String = ""
    var format: String = "%.1f"
    let animated: Bool
    let hasKey: Bool
    let onKey: (() -> Void)?
    let onChange: (Float, Bool) -> Void   // (valor, gravar)
    var onEasing: ((Easing) -> Void)? = nil
    var easing: Easing? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 8) {
                if let onKey {
                    Button(action: onKey) {
                        Image(systemName: !animated ? "stopwatch" : (hasKey ? "diamond.fill" : "diamond"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(animated ? NovaTheme.accent : NovaTheme.dim)
                            .frame(width: 38, height: 38)
                            .background(RoundedRectangle(cornerRadius: 9)
                                .fill(animated ? NovaTheme.accent.opacity(0.12) : NovaTheme.button))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
                Text(title.loc).font(.system(size: 11.5))
                if hasKey, let onEasing { EasingMenu(current: easing, onPick: onEasing) }
                Spacer()
                Text(String(format: format, value) + unit)
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(NovaTheme.dim)
            }
            Slider(value: Binding(get: { min(max(value, range.lowerBound), range.upperBound) },
                                  set: { onChange($0, false) }),
                   in: range, onEditingChanged: { ed in if !ed { onChange(value, true) } })
        }
    }
}

/// Liga/cria/apaga chave, como o losango do AE.
func toggleKeyframe<T: Interpolatable>(_ a: inout Animated<T>, at t: Float) {
    LayerPropertiesSheet.toggleKey(&a, at: t)
}

// MARK: - Mascaras

struct MaskSection: View {
    let layer: Layer
    let comp: Composition
    let time: Float
    let edit: LayerEdit

    var body: some View {
        let size = layer.size ?? comp.size
        Section("Máscaras".loc) {
            ForEach(Array(layer.maskList.enumerated()), id: \.element.id) { i, m in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Toggle(isOn: bind(i, \.enabled)) {
                            Text(m.name).font(.system(size: 12.5, weight: .semibold))
                        }
                        Button(role: .destructive) {
                            edit(layer.id, true) { l in l.maskList.removeAll { $0.id == m.id } }
                        } label: { Image(systemName: "trash").font(.system(size: 12)) }
                            .buttonStyle(.plain).foregroundStyle(NovaTheme.warning)
                    }
                    Picker("Formato".loc, selection: bind(i, \.shape)) {
                        ForEach(MaskShape.allCases, id: \.self) { Text($0.label.loc).tag($0) }
                    }.font(.system(size: 11.5))
                    Picker("Modo".loc, selection: bind(i, \.mode)) {
                        ForEach(MaskMode.allCases, id: \.self) { Text($0.label.loc).tag($0) }
                    }.font(.system(size: 11.5))
                    Toggle("Inverter".loc, isOn: bind(i, \.inverted)).font(.system(size: 11.5))
                    vec(i, "Posição", \.position, range: -size.max()...size.max() * 2)
                    vec(i, "Tamanho", \.size, range: 1...size.max() * 2)
                    flt(i, "Rotação", \.rotation, -360...360, "°")
                    flt(i, "Suavizar borda", \.feather, 0...300, "px")
                    flt(i, "Expandir", \.expand, -300...300, "px")
                    flt(i, "Opacidade", \.opacity, 0...100, "%")
                    if m.shape == .rectangle { flt(i, "Arredondar cantos", \.cornerRadius, 0...500, "px") }
                    if m.shape == .polygon || m.shape == .star { flt(i, "Lados", \.sides, 3...20, "") }
                    if m.shape == .star { flt(i, "Raio interno", \.innerRatio, 0.05...1, "") }
                }
            }
            Menu {
                ForEach(MaskShape.allCases, id: \.self) { s in
                    Button(s.label.loc) {
                        edit(layer.id, true) { l in
                            var m = LayerMask(shape: s, center: size / 2, size: size * 0.6)
                            m.name = "\(s.label.loc) \(l.maskList.count + 1)"
                            l.maskList.append(m)
                        }
                    }
                }
            } label: {
                Label("Adicionar máscara".loc, systemImage: "plus.square.dashed").font(.system(size: 12.5))
            }
        }
    }

    private func bind<V>(_ i: Int, _ kp: WritableKeyPath<LayerMask, V>) -> Binding<V> {
        Binding(get: { layer.maskList[i][keyPath: kp] },
                set: { v in edit(layer.id, true) { $0.maskList[i][keyPath: kp] = v } })
    }

    private func flt(_ i: Int, _ title: String, _ kp: WritableKeyPath<LayerMask, Animated<Float>>,
                     _ range: ClosedRange<Float>, _ unit: String) -> some View {
        let a = layer.maskList[i][keyPath: kp]
        return AnimSlider(title: title, value: a.value(at: time), range: range, unit: unit,
                          animated: !a.keyframes.isEmpty, hasKey: a.hasKeyframe(at: time),
                          onKey: { edit(layer.id, true) { toggleKeyframe(&$0.maskList[i][keyPath: kp], at: time) } },
                          onChange: { v, save in edit(layer.id, save) { $0.maskList[i][keyPath: kp].set(v, at: time) } },
                          onEasing: { e in edit(layer.id, true) { $0.maskList[i][keyPath: kp].setEasing(at: time, e) } },
                          easing: a.easing(at: time))
    }

    private func vec(_ i: Int, _ title: String, _ kp: WritableKeyPath<LayerMask, Animated<SIMD2<Float>>>,
                     range: ClosedRange<Float>) -> some View {
        let a = layer.maskList[i][keyPath: kp]
        let v = a.value(at: time)
        return VStack(spacing: 0) {
            AnimSlider(title: title + " X", value: v.x, range: range, format: "%.0f",
                       animated: !a.keyframes.isEmpty, hasKey: a.hasKeyframe(at: time),
                       onKey: { edit(layer.id, true) { toggleKeyframe(&$0.maskList[i][keyPath: kp], at: time) } },
                       onChange: { x, save in edit(layer.id, save) { $0.maskList[i][keyPath: kp].set(SIMD2(x, v.y), at: time) } })
            AnimSlider(title: title + " Y", value: v.y, range: range, format: "%.0f",
                       animated: !a.keyframes.isEmpty, hasKey: a.hasKeyframe(at: time), onKey: nil,
                       onChange: { y, save in edit(layer.id, save) { $0.maskList[i][keyPath: kp].set(SIMD2(v.x, y), at: time) } })
        }
    }
}

// MARK: - Forma

struct ShapeSection: View {
    let layer: Layer
    let time: Float
    let edit: LayerEdit

    var body: some View {
        let st = layer.shapeStyle ?? ShapeStyle()
        Section("Forma".loc) {
            Picker("Formato".loc, selection: bind(\.shape)) {
                ForEach(MaskShape.allCases, id: \.self) { Text($0.label.loc).tag($0) }
            }
            Picker("Preenchimento".loc, selection: bind(\.fillMode)) {
                ForEach(FillMode.allCases, id: \.self) { Text($0.label.loc).tag($0) }
            }
            if st.fillMode != .none { color("Cor".loc, \.fill, st) }
            if st.fillMode == .linear || st.fillMode == .radial {
                color("Cor 2".loc, \.gradientColor2, st)
                if st.fillMode == .linear { flt("Ângulo do degradê", \.gradientAngle, st, -180...180, "°") }
            }
            color("Contorno".loc, \.strokeColor, st)
            flt("Espessura do contorno", \.strokeWidth, st, 0...80, "px")
            if st.shape == .rectangle { flt("Arredondar cantos", \.cornerRadius, st, 0...500, "px") }
            if st.shape == .polygon || st.shape == .star { flt("Lados", \.sides, st, 3...20, "") }
            if st.shape == .star { flt("Raio interno", \.innerRatio, st, 0.05...1, "") }
            Toggle("Sombra".loc, isOn: bind(\.shadowOn))
            if st.shadowOn {
                color("Cor da sombra".loc, \.shadowColor, st)
                flt("Ângulo da sombra", \.shadowAngle, st, 0...360, "°")
                flt("Distância", \.shadowDistance, st, 0...200, "px")
                flt("Suavidade", \.shadowSoftness, st, 0...100, "px")
            }
        }.font(.system(size: 12))
    }

    private func bind<V>(_ kp: WritableKeyPath<ShapeStyle, V>) -> Binding<V> {
        Binding(get: { (layer.shapeStyle ?? ShapeStyle())[keyPath: kp] },
                set: { v in edit(layer.id, true) { l in
                    var st = l.shapeStyle ?? ShapeStyle(); st[keyPath: kp] = v; l.shapeStyle = st } })
    }

    private func flt(_ title: String, _ kp: WritableKeyPath<ShapeStyle, Animated<Float>>, _ st: ShapeStyle,
                     _ range: ClosedRange<Float>, _ unit: String) -> some View {
        let a = st[keyPath: kp]
        return AnimSlider(title: title, value: a.value(at: time), range: range, unit: unit,
                          animated: !a.keyframes.isEmpty, hasKey: a.hasKeyframe(at: time),
                          onKey: { edit(layer.id, true) { l in
                              var s = l.shapeStyle ?? ShapeStyle(); toggleKeyframe(&s[keyPath: kp], at: time); l.shapeStyle = s } },
                          onChange: { v, save in edit(layer.id, save) { l in
                              var s = l.shapeStyle ?? ShapeStyle(); s[keyPath: kp].set(v, at: time); l.shapeStyle = s } })
    }

    private func color(_ title: String, _ kp: WritableKeyPath<ShapeStyle, Animated<SIMD4<Float>>>,
                       _ st: ShapeStyle) -> some View {
        ColorPicker(title, selection: Binding(get: { Color(rgba: st[keyPath: kp].value(at: time)) },
                                              set: { c in edit(layer.id, true) { l in
                                                  var s = l.shapeStyle ?? ShapeStyle()
                                                  s[keyPath: kp].set(c.rgba, at: time); l.shapeStyle = s } }))
    }
}

// MARK: - Texto

struct TextSection: View {
    let layer: Layer
    let time: Float
    let edit: LayerEdit

    private static let systemFonts = ["Helvetica-Bold", "AvenirNext-Heavy", "Futura-Bold",
                                      "Georgia-Bold", "Menlo-Bold", "Chalkduster", "Didot-Bold",
                                      "MarkerFelt-Wide", "Noteworthy-Bold", "Zapfino"]

    var body: some View {
        let st = layer.textStyle ?? TextStyle()
        Section("Estilo do texto".loc) {
            Picker("Fonte".loc, selection: Binding(get: { layer.fontName ?? "" }, set: { f in
                edit(layer.id, true) { l in l.fontName = f.isEmpty ? nil : f; Self.remeasure(&l, time) }
            })) {
                Text("Sistema (negrito)".loc).tag("")
                ForEach(FontCatalog.bundled, id: \.self) { n in Text(n).font(.custom(n, size: 14)).tag(n) }
                ForEach(Self.systemFonts, id: \.self) { n in Text(n).font(.custom(n, size: 14)).tag(n) }
            }.pickerStyle(.navigationLink)
            Picker("Alinhamento".loc, selection: bind(\.align)) {
                Image(systemName: "text.alignleft").tag(TextAlign.left)
                Image(systemName: "text.aligncenter").tag(TextAlign.center)
                Image(systemName: "text.alignright").tag(TextAlign.right)
            }.pickerStyle(.segmented)
            num("Espaço entre letras", \.letterSpacing, st, -20...80)
            num("Espaço entre linhas", \.lineSpacing, st, -40...200)
            ColorPicker("Cor do contorno".loc, selection: Binding(get: { Color(rgba: st.strokeColor) },
                                                                  set: { c in set(\.strokeColor, c.rgba) }))
            num("Contorno", \.strokeWidth, st, 0...30)
            Toggle("Sombra".loc, isOn: bind(\.shadowOn))
            if st.shadowOn {
                ColorPicker("Cor da sombra".loc, selection: Binding(get: { Color(rgba: st.shadowColor) },
                                                                    set: { c in set(\.shadowColor, c.rgba) }))
                num("Desfoque da sombra", \.shadowBlur, st, 0...60)
            }
            Picker("Animação de entrada".loc, selection: bind(\.animation)) {
                ForEach(TextAnimationPreset.allCases, id: \.self) { Text($0.label.loc).tag($0) }
            }
            if st.animation != .none { num("Duração da animação", \.animationDuration, st, 0.1...10) }
        }.font(.system(size: 12))
    }

    static func remeasure(_ l: inout Layer, _ time: Float) {
        let m = MediaContentProvider.measureText(l.text ?? "", fontName: l.fontName,
                                                 size: CGFloat(l.fontSize ?? 96), style: l.textStyle ?? TextStyle())
        let s = SIMD2(Float(m.width), Float(m.height))
        l.size = s
        l.transform.anchorPoint.set(s / 2, at: time)
    }

    private func set<V>(_ kp: WritableKeyPath<TextStyle, V>, _ v: V) {
        edit(layer.id, true) { l in
            var st = l.textStyle ?? TextStyle(); st[keyPath: kp] = v; l.textStyle = st
            Self.remeasure(&l, time)
        }
    }

    private func bind<V>(_ kp: WritableKeyPath<TextStyle, V>) -> Binding<V> {
        Binding(get: { (layer.textStyle ?? TextStyle())[keyPath: kp] }, set: { set(kp, $0) })
    }

    private func num(_ title: String, _ kp: WritableKeyPath<TextStyle, Float>, _ st: TextStyle,
                     _ range: ClosedRange<Float>) -> some View {
        AnimSlider(title: title, value: st[keyPath: kp], range: range, animated: false, hasKey: false, onKey: nil,
                   onChange: { v, save in edit(layer.id, save) { l in
                       var s = l.textStyle ?? TextStyle(); s[keyPath: kp] = v; l.textStyle = s
                       Self.remeasure(&l, time) } })
    }
}

// MARK: - Midia

struct MediaSection: View {
    let layer: Layer
    let edit: LayerEdit

    var body: some View {
        Section("Mídia".loc) {
            Toggle("Em laço".loc, isOn: Binding(get: { layer.loop ?? false },
                                                set: { v in edit(layer.id, true) { $0.loop = v } }))
            Toggle("Invertido".loc, isOn: Binding(get: { layer.reversed ?? false },
                                                  set: { v in edit(layer.id, true) { $0.reversed = v } }))
            AnimSlider(title: "Velocidade", value: layer.speed, range: 0.1...4, unit: "×", format: "%.2f",
                       animated: false, hasKey: false, onKey: nil,
                       onChange: { v, save in edit(layer.id, save) { l in
                           let fonteUsada = l.duration * l.speed
                           l.speed = v
                           // A camada encolhe/estica junto (o clipe mostra a mesma midia).
                           if !(l.loop ?? false) { l.duration = max(0.1, fonteUsada / v) }
                       } })
            AnimSlider(title: "Cortar início da mídia", value: layer.mediaOffset,
                       range: 0...max(layer.sourceDuration ?? 10, 0.1), unit: "s", format: "%.2f",
                       animated: false, hasKey: false, onKey: nil,
                       onChange: { v, save in edit(layer.id, save) { $0.mediaOffset = v } })
            if layer.kind == .video || layer.kind == .audio {
                Toggle("Sem som".loc, isOn: Binding(get: { layer.muted ?? false },
                                                    set: { m in edit(layer.id, true) { $0.muted = m } }))
            }
        }.font(.system(size: 12))
    }
}

// MARK: - Pai

struct ParentSection: View {
    let layer: Layer
    let comp: Composition
    let edit: LayerEdit

    /// Camadas que podem ser pai sem criar ciclo.
    private var candidates: [Layer] {
        comp.layers.filter { c in
            guard c.id != layer.id else { return false }
            var pid: UUID? = c.parentID, n = 0
            while let p = pid, n < 32 {
                if p == layer.id { return false }
                pid = comp.layer(id: p)?.parentID; n += 1
            }
            return true
        }
    }

    var body: some View {
        Section("Vínculo".loc) {
            Picker("Pai".loc, selection: Binding(get: { layer.parentID }, set: { p in
                edit(layer.id, true) { $0.parentID = p }
            })) {
                Text("Nenhum".loc).tag(UUID?.none)
                ForEach(candidates) { c in Text(c.name).tag(UUID?.some(c.id)) }
            }
        }.font(.system(size: 12))
    }
}
