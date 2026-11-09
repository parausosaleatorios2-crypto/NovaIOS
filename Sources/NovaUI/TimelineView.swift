//
//  TimelineView.swift
//  NovaUI
//
//  Timeline do editor, no jeito da do APK (v78 / yw8 no Compose descompilado):
//  - arrastar para os lados rola a timeline; pincar muda o zoom;
//  - tocar ou arrastar na regua move o cursor;
//  - tocar no clipe seleciona; com ele selecionado, arrastar o meio move o clipe
//    (as chaves vao junto) e as alcas das pontas aparam a entrada e a saida;
//  - encaixe magnetico no cursor, no inicio e nas pontas dos outros clipes;
//  - acoes do clipe do APK: Dividir, Cortar antes / depois do cursor (com e sem
//    puxar o resto), Comecar / Terminar no cursor, Duplicar e Excluir.
//

import SwiftUI

public struct TimelineView: View {
    let composition: Composition
    @Binding var time: Float
    @Binding var selected: UUID?
    /// (id, gravar, mudanca) — como editLayer do editor. nil = so leitura.
    let editLayer: ((UUID, Bool, (inout Layer) -> Void) -> Void)?
    /// Mudanca na composicao inteira (dividir, duplicar, excluir). Grava.
    let editComp: (((inout Composition) -> Void) -> Void)?

    @State private var pixelsPerSecond: CGFloat = 60
    @State private var zoomBase: CGFloat = 60
    @State private var scrollX: CGFloat = 0
    @State private var scrollBase: CGFloat?
    @State private var largura: CGFloat = 300
    /// Gesto em andamento num clipe: (id, tipo, estado do clipe no comeco).
    @State private var gesto: (UUID, Alca, Layer)?
    @State private var guia: Float?
    @State private var aviso: String?

    private enum Alca { case corpo, entrada, saida }

    private let nameColumn: CGFloat = 112
    private let alcaLargura: CGFloat = 14
    private let encaixePx: CGFloat = 9

    public init(composition: Composition, time: Binding<Float>, selected: Binding<UUID?>,
                editLayer: ((UUID, Bool, (inout Layer) -> Void) -> Void)? = nil,
                editComp: (((inout Composition) -> Void) -> Void)? = nil) {
        self.composition = composition
        _time = time
        _selected = selected
        self.editLayer = editLayer
        self.editComp = editComp
    }

    private func el(_ id: UUID, _ save: Bool, _ f: (inout Layer) -> Void) { editLayer?(id, save, f) }
    private func ec(_ f: (inout Composition) -> Void) { editComp?(f) }

    private var selecionada: Layer? { selected.flatMap { id in composition.layers.first { $0.id == id } } }

    public var body: some View {
        VStack(spacing: 0) {
            if selecionada != nil && editComp != nil { acoes }
            ruler
            ScrollView([.vertical], showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(composition.layers) { layer in
                        row(layer)
                    }
                    if composition.layers.isEmpty {
                        Text("Nenhuma camada. Toque em + para adicionar.".loc)
                            .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
                            .padding(.vertical, 18).frame(maxWidth: .infinity)
                    }
                }.padding(.vertical, 5)
            }
            .simultaneousGesture(rolagem)
        }
        .background(NovaTheme.surface)
        .overlay(alignment: .topLeading) { cursor }
        .overlay(alignment: .bottom) {
            if let aviso {
                Text(aviso).font(.system(size: 10.5)).foregroundStyle(NovaTheme.text)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(NovaTheme.button))
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .background(GeometryReader { g in
            Color.clear.onAppear { largura = g.size.width }
                .onChange(of: g.size.width) { _, w in largura = w }
        })
        .simultaneousGesture(MagnificationGesture()
            .onChanged { v in pixelsPerSecond = min(600, max(6, zoomBase * v)); limitarRolagem() }
            .onEnded { _ in zoomBase = pixelsPerSecond })
        .onChange(of: time) { _, t in seguirCursor(t) }
    }

    // MARK: rolagem

    private var pista: CGFloat { max(40, largura - nameColumn) }

    private var maxScroll: CGFloat {
        let fim = CGFloat(max(composition.duration, composition.layers.map(\.endTime).max() ?? 0)) * pixelsPerSecond
        return max(0, fim + 60 - pista)
    }

    private func limitarRolagem() { scrollX = min(max(0, scrollX), maxScroll) }

    /// Arrastar para os lados (fora de um gesto de clipe) rola a timeline.
    private var rolagem: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { g in
                guard gesto == nil else { return }
                if scrollBase == nil {
                    guard abs(g.translation.width) > abs(g.translation.height) else { return }
                    scrollBase = scrollX
                }
                if let b = scrollBase { scrollX = min(max(0, b - g.translation.width), maxScroll) }
            }
            .onEnded { _ in scrollBase = nil }
    }

    /// Durante a reproducao o cursor nao sai da tela (como no APK).
    private func seguirCursor(_ t: Float) {
        guard gesto == nil, scrollBase == nil else { return }
        let x = CGFloat(t) * pixelsPerSecond - scrollX
        if x > pista - 24 { scrollX = min(maxScroll, CGFloat(t) * pixelsPerSecond - pista * 0.25) }
        else if x < 0 { scrollX = max(0, CGFloat(t) * pixelsPerSecond - pista * 0.25) }
    }

    private func x(_ t: Float) -> CGFloat { CGFloat(t) * pixelsPerSecond - scrollX }
    private func t(_ x: CGFloat) -> Float { Float((x + scrollX) / pixelsPerSecond) }

    // MARK: regua

    private var ruler: some View {
        Canvas { ctx, size in
            let step = tickStep()
            var tt: Float = Float(Int(Float(scrollX / pixelsPerSecond) / step)) * step
            let fim = Float((scrollX + size.width) / pixelsPerSecond)
            while tt <= min(fim, max(composition.duration, 0) + step) {
                let px = nameColumn + x(tt)
                if px >= nameColumn - 1 && px <= size.width {
                    ctx.stroke(Path { p in
                        p.move(to: CGPoint(x: px, y: size.height - 6))
                        p.addLine(to: CGPoint(x: px, y: size.height))
                    }, with: .color(NovaTheme.dim2), lineWidth: 1)
                    ctx.draw(Text(label(tt)).font(.system(size: 8)).foregroundColor(NovaTheme.dim2),
                             at: CGPoint(x: px + 13, y: size.height / 2))
                }
                tt += step
            }
            // fim da composicao
            let fx = nameColumn + x(composition.duration)
            if fx >= nameColumn && fx <= size.width {
                ctx.fill(Path(CGRect(x: fx, y: 0, width: 1, height: size.height)),
                         with: .color(NovaTheme.danger.opacity(0.7)))
            }
            for m in composition.markers ?? [] {
                let mx = nameColumn + x(m)
                guard mx >= nameColumn && mx <= size.width else { continue }
                ctx.fill(Path { p in
                    p.move(to: CGPoint(x: mx - 4, y: 0))
                    p.addLine(to: CGPoint(x: mx + 4, y: 0))
                    p.addLine(to: CGPoint(x: mx, y: 7))
                    p.closeSubpath()
                }, with: .color(NovaTheme.warning))
            }
        }
        .frame(height: NovaTheme.Metrics.rulerHeight)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { g in
            guard g.location.x > nameColumn else { return }
            time = min(max(0, t(g.location.x - nameColumn)), composition.duration)
        })
        .background(NovaTheme.surface2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .bottom)
    }

    private func tickStep() -> Float {
        let candidates: [Float] = [1.0 / 30, 0.1, 0.25, 0.5, 1, 2, 5, 10, 15, 30, 60]
        for c in candidates where CGFloat(c) * pixelsPerSecond >= 56 { return c }
        return 120
    }

    private func label(_ t: Float) -> String {
        if t < 1 && tickStep() < 0.5 { return String(format: "%.2fs", t) }
        return t < 60 ? String(format: tickStep() < 1 ? "%.1fs" : "%.0fs", t)
                      : String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: linha de camada

    private func row(_ layer: Layer) -> some View {
        let sel = selected == layer.id
        return HStack(spacing: 0) {
            HStack(spacing: 5) {
                Button {
                    el(layer.id, true) { $0.enabled.toggle() }
                } label: {
                    Image(systemName: layer.enabled ? "eye" : "eye.slash")
                        .font(.system(size: 9))
                        .foregroundStyle(layer.enabled ? NovaTheme.dim : NovaTheme.dim2)
                }.buttonStyle(.plain)
                Text(layer.name).font(.system(size: 10)).lineLimit(1)
                    .foregroundStyle(sel ? NovaTheme.text : NovaTheme.dim)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(width: nameColumn, height: NovaTheme.Metrics.timelineRowHeight)
            .background(sel ? NovaTheme.selectedFill : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { selected = sel ? nil : layer.id }

            ZStack(alignment: .topLeading) {
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { selected = nil }
                clipe(layer, sel)
            }
            .frame(height: NovaTheme.Metrics.timelineRowHeight)
            .frame(maxWidth: .infinity)
            .clipped()
        }
    }

    private func clipe(_ layer: Layer, _ sel: Bool) -> some View {
        let w = max(6, CGFloat(layer.duration) * pixelsPerSecond)
        let h = NovaTheme.Metrics.timelineRowHeight - 5
        return RoundedRectangle(cornerRadius: 5)
            .fill(NovaTheme.trackColor(layer.kind.rawValue).opacity(layer.enabled ? 1 : 0.45))
            .frame(width: w, height: h)
            .overlay(alignment: .leading) {
                Text(layer.name).font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.leading, sel ? alcaLargura + 3 : 6).lineLimit(1)
            }
            .overlay(RoundedRectangle(cornerRadius: 5)
                .strokeBorder(sel ? NovaTheme.accent : Color.white.opacity(0.1), lineWidth: sel ? 1.6 : 1))
            .overlay(alignment: .leading) { if sel { alca(layer, .entrada) } }
            .overlay(alignment: .trailing) { if sel { alca(layer, .saida) } }
            .contentShape(Rectangle())
            .onTapGesture { selected = layer.id }
            .highPriorityGesture(arrastar(layer, .corpo),
                                 including: sel && editLayer != nil && !layer.locked ? .all : .subviews)
            .offset(x: x(layer.startTime), y: 2.5)
    }

    /// Alca de aparar (o "[" e o "]" do clipe selecionado no APK).
    private func alca(_ layer: Layer, _ tipo: Alca) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: tipo == .entrada ? 5 : 0,
                               bottomLeadingRadius: tipo == .entrada ? 5 : 0,
                               bottomTrailingRadius: tipo == .saida ? 5 : 0,
                               topTrailingRadius: tipo == .saida ? 5 : 0)
            .fill(NovaTheme.accent)
            .frame(width: alcaLargura)
            .overlay(Image(systemName: tipo == .entrada ? "chevron.compact.left" : "chevron.compact.right")
                .font(.system(size: 10, weight: .heavy)).foregroundStyle(Color.black))
            .contentShape(Rectangle().inset(by: -6))
            .highPriorityGesture(arrastar(layer, tipo), including: editLayer != nil && !layer.locked ? .all : .none)
    }

    // MARK: mover e aparar

    /// Pontos de encaixe: cursor, 0, fim da comp e as pontas dos outros clipes.
    private func encaixes(sem id: UUID) -> [Float] {
        var p: [Float] = [time, 0, composition.duration]
        for l in composition.layers where l.id != id { p.append(l.startTime); p.append(l.endTime) }
        p.append(contentsOf: composition.markers ?? [])
        return p
    }

    private func encaixar(_ v: Float, _ pontos: [Float]) -> (Float, Float?) {
        let lim = Float(encaixePx / pixelsPerSecond)
        var melhor: Float?
        for p in pontos where abs(p - v) <= lim {
            if melhor == nil || abs(p - v) < abs(melhor! - v) { melhor = p }
        }
        return (melhor ?? v, melhor)
    }

    private func arrastar(_ layer: Layer, _ tipo: Alca) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { g in
                if gesto == nil || gesto!.0 != layer.id { gesto = (layer.id, tipo, layer) }
                guard let gs = gesto else { return }
                let id = gs.0, tp = gs.1, orig = gs.2
                let dt = Float(g.translation.width / pixelsPerSecond)
                let pontos = encaixes(sem: id)
                let minDur: Float = max(1.0 / max(composition.frameRate, 1), 0.04)
                switch tp {
                case .corpo:
                    var ini = max(0, orig.startTime + dt)
                    let (a, ga) = encaixar(ini, pontos)
                    let (b, gb) = encaixar(ini + orig.duration, pontos)
                    if ga != nil { ini = a } else if gb != nil { ini = b - orig.duration }
                    guia = ga ?? gb
                    let desloc = ini - orig.startTime
                    el(id, false) { l in
                        l.startTime = ini
                        l.transform = orig.transform
                        Self.deslocarChaves(&l.transform, desloc)
                    }
                case .entrada:
                    let fim = orig.endTime
                    // nao passa do comeco da midia (mediaOffset >= 0), a nao ser em laco
                    let livre = (orig.loop ?? false) || orig.mediaPath == nil
                    let minIni = livre ? 0 : max(0, orig.startTime - orig.mediaOffset / max(orig.speed, 0.01))
                    var ini = min(max(minIni, orig.startTime + dt), fim - minDur)
                    let (a, ga) = encaixar(ini, pontos); if ga != nil { ini = min(max(minIni, a), fim - minDur) }
                    guia = ga
                    el(id, false) { l in
                        l.startTime = ini
                        l.duration = fim - ini
                        if l.mediaPath != nil {
                            l.mediaOffset = max(0, orig.mediaOffset + (ini - orig.startTime) * orig.speed)
                        }
                    }
                case .saida:
                    var maxFim: Float = .greatestFiniteMagnitude
                    if let src = orig.sourceDuration, src > 0, !(orig.loop ?? false) {
                        maxFim = orig.startTime + (src - orig.mediaOffset) / max(orig.speed, 0.01)
                    }
                    var fim = min(max(orig.startTime + minDur, orig.endTime + dt), maxFim)
                    let (b, gb) = encaixar(fim, pontos); if gb != nil { fim = min(max(orig.startTime + minDur, b), maxFim) }
                    guia = gb
                    el(id, false) { l in l.duration = fim - l.startTime }
                }
            }
            .onEnded { _ in
                if let gs = gesto { el(gs.0, true) { _ in } }
                gesto = nil
                guia = nil
            }
    }

    /// Leva as chaves junto quando o clipe inteiro anda no tempo.
    static func deslocarChaves(_ tr: inout Transform, _ d: Float) {
        guard d != 0 else { return }
        func mover<T: Interpolatable>(_ a: inout Animated<T>) {
            let ks = a.keyframes
            let ordem = d > 0 ? Array(ks.reversed()) : ks
            for k in ordem { a.moveKeyframe(id: k.id, to: k.time + d) }
        }
        mover(&tr.anchorPoint); mover(&tr.position); mover(&tr.positionZ); mover(&tr.scale)
        mover(&tr.rotationX); mover(&tr.rotationY); mover(&tr.rotationZ); mover(&tr.opacity)
        if var s = tr.skew { mover(&s); tr.skew = s }
    }

    // MARK: acoes do clipe (as do APK)

    private var acoes: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                acao("Dividir", "scissors") { dividir() }
                acao("Cortar antes", "arrow.left.to.line") { cortar(antes: true, puxar: false) }
                acao("Cortar depois", "arrow.right.to.line") { cortar(antes: false, puxar: false) }
                acao("Cortar antes e puxar", "arrow.left.to.line.compact") { cortar(antes: true, puxar: true) }
                acao("Cortar depois e puxar", "arrow.right.to.line.compact") { cortar(antes: false, puxar: true) }
                acao("Começar no cursor", "increase.indent") { comecarNoCursor() }
                acao("Terminar no cursor", "decrease.indent") { terminarNoCursor() }
                acao("Duplicar", "plus.square.on.square") { duplicar() }
                acao("Excluir", "trash", perigo: true) { excluir(puxar: false) }
                acao("Excluir e puxar", "trash.slash", perigo: true) { excluir(puxar: true) }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 32)
        .background(NovaTheme.surface)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .bottom)
    }

    private func acao(_ titulo: String, _ icone: String, perigo: Bool = false, _ f: @escaping () -> Void) -> some View {
        Button(action: f) {
            HStack(spacing: 4) {
                Image(systemName: icone).font(.system(size: 10, weight: .semibold))
                Text(titulo.loc).font(.system(size: 10.5, weight: .medium))
            }
            .padding(.horizontal, 9).frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 8).fill(NovaTheme.chip))
            .foregroundStyle(perigo ? NovaTheme.danger : NovaTheme.text)
        }.buttonStyle(.plain)
    }

    private func avisar(_ s: String) {
        withAnimation { aviso = s.loc }
        let atual = aviso
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            if aviso == atual { withAnimation { aviso = nil } }
        }
    }

    private func dentro(_ l: Layer) -> Bool { time > l.startTime + 0.001 && time < l.endTime - 0.001 }

    /// Dividir no cursor: a parte de depois vira uma camada nova logo acima.
    private func dividir() {
        guard let l = selecionada else { return }
        guard dentro(l) else { avisar("Ponha o cursor dentro do clipe para dividir"); return }
        let t = time
        var nova = l
        nova.id = UUID()
        nova.startTime = t
        nova.duration = l.endTime - t
        if l.mediaPath != nil { nova.mediaOffset = l.mediaOffset + (t - l.startTime) * l.speed }
        ec { c in
            guard let i = c.layers.firstIndex(where: { $0.id == l.id }) else { return }
            c.layers[i].duration = t - l.startTime
            c.layers.insert(nova, at: i)
        }
        selected = nova.id
    }

    /// Cortar o que esta antes/depois do cursor; "puxar" fecha o buraco (ripple).
    private func cortar(antes: Bool, puxar: Bool) {
        guard let l = selecionada else { return }
        guard dentro(l) else { avisar("Ponha o cursor dentro do clipe"); return }
        let t = time
        ec { c in
            guard let i = c.layers.firstIndex(where: { $0.id == l.id }) else { return }
            if antes {
                let corte = t - l.startTime
                c.layers[i].startTime = t
                c.layers[i].duration = l.endTime - t
                if l.mediaPath != nil { c.layers[i].mediaOffset = l.mediaOffset + corte * l.speed }
                if puxar {
                    // o clipe volta para onde comecava e o resto anda junto
                    for j in c.layers.indices where c.layers[j].startTime >= t - 0.0001 {
                        c.layers[j].startTime -= corte
                        Self.deslocarChaves(&c.layers[j].transform, -corte)
                    }
                }
            } else {
                let corte = l.endTime - t
                c.layers[i].duration = t - l.startTime
                if puxar {
                    for j in c.layers.indices where j != i && c.layers[j].startTime >= l.endTime - 0.0001 {
                        c.layers[j].startTime -= corte
                        Self.deslocarChaves(&c.layers[j].transform, -corte)
                    }
                }
            }
        }
    }

    private func comecarNoCursor() {
        guard let l = selecionada else { return }
        let d = time - l.startTime
        el(l.id, true) { x in
            x.startTime = time
            Self.deslocarChaves(&x.transform, d)
        }
    }

    private func terminarNoCursor() {
        guard let l = selecionada else { return }
        let d = time - l.endTime
        el(l.id, true) { x in
            x.startTime = max(0, l.startTime + d)
            Self.deslocarChaves(&x.transform, x.startTime - l.startTime)
        }
    }

    private func duplicar() {
        guard let l = selecionada else { return }
        var c2 = l
        c2.id = UUID()
        ec { c in
            if let i = c.layers.firstIndex(where: { $0.id == l.id }) { c.layers.insert(c2, at: i) }
        }
        selected = c2.id
    }

    private func excluir(puxar: Bool) {
        guard let l = selecionada else { return }
        ec { c in
            c.layers.removeAll { $0.id == l.id }
            if puxar {
                for j in c.layers.indices where c.layers[j].startTime >= l.endTime - 0.0001 {
                    c.layers[j].startTime -= l.duration
                    Self.deslocarChaves(&c.layers[j].transform, -l.duration)
                }
            }
        }
        selected = nil
    }

    // MARK: cursor

    private var cursor: some View {
        GeometryReader { geo in
            let topo: CGFloat = (selecionada != nil && editComp != nil) ? 32 : 0
            ZStack(alignment: .topLeading) {
                if let g = guia {
                    let gx = nameColumn + x(g)
                    if gx >= nameColumn && gx <= geo.size.width {
                        Rectangle().fill(NovaTheme.warning).frame(width: 1)
                            .offset(x: gx - 0.5, y: topo)
                    }
                }
                let px = nameColumn + x(time)
                if px >= nameColumn && px <= geo.size.width {
                    ZStack(alignment: .top) {
                        Rectangle().fill(NovaTheme.accent).frame(width: 1.4)
                        Rectangle().fill(NovaTheme.accent).frame(width: 9, height: 7)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .offset(x: px - 0.7, y: topo)
                }
            }
            .allowsHitTesting(false)
        }
    }
}
