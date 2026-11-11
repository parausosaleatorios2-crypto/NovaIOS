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
    /// Quadros no cache da previa: a faixa verde em cima da regua (como no AE).
    let emCache: Set<Int>
    /// Grupo aberto (como no Blurrr): a timeline mostra o que tem dentro dele. nil = o topo.
    @Binding var grupoAberto: UUID?

    @State private var pixelsPerSecond: CGFloat = 60
    @State private var zoomBase: CGFloat = 60
    @State private var scrollX: CGFloat = 0
    @State private var scrollBase: CGFloat?
    @State private var largura: CGFloat = 300
    /// Gesto em andamento num clipe: (id, tipo, estado do clipe no comeco).
    @State private var gesto: (UUID, Alca, Layer)?
    @State private var guia: Float?
    @State private var aviso: String?
    @State private var recolhida = false
    @State private var expandidas: Set<UUID> = []

    private enum Alca { case corpo, entrada, saida }

    /// Coluna da esquerda do APK (~78 dp): chevron, olho, solo e o icone do tipo.
    private var nameColumn: CGFloat { recolhida ? 0 : 80 }
    /// Folga antes do tempo 0, como no APK (o primeiro clipe nao cola na coluna).
    private let inicioPista: CGFloat = 16
    private let alturaLinha: CGFloat = 32
    private let alturaCabecalho: CGFloat = 30
    /// Vermelho/rosa do cursor do APK.
    static let corCursor = Color(red: 0xf0/255, green: 0x56/255, blue: 0x6e/255)
    private let alcaLargura: CGFloat = 14
    private let encaixePx: CGFloat = 9

    public init(composition: Composition, time: Binding<Float>, selected: Binding<UUID?>,
                editLayer: ((UUID, Bool, (inout Layer) -> Void) -> Void)? = nil,
                editComp: (((inout Composition) -> Void) -> Void)? = nil,
                emCache: Set<Int> = [], grupoAberto: Binding<UUID?> = .constant(nil)) {
        self.emCache = emCache
        _grupoAberto = grupoAberto
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
            if let g = grupoAberto.flatMap({ composition.layer(id: $0) }) { barraDoGrupo(g) }
            ruler
            ScrollView([.vertical], showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(composition.layers.filter { $0.groupID == nivel }) { layer in
                        row(layer)
                    }
                    if composition.layers.isEmpty {
                        Text("Nenhuma camada. Toque em + para adicionar.".loc)
                            .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
                            .padding(.vertical, 18).frame(maxWidth: .infinity)
                    }
                }.padding(.vertical, 4)
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

    // MARK: grupo aberto

    /// O grupo aberto, se ele ainda existe (apagado ou desagrupado, volta ao topo).
    private var nivel: UUID? { grupoAberto.flatMap { composition.layer(id: $0)?.id } }

    /// "‹ Grupo X": dentro de um grupo, como no Blurrr; tocar volta um nivel.
    private func barraDoGrupo(_ g: Layer) -> some View {
        HStack(spacing: 8) {
            Button {
                selected = g.id
                grupoAberto = g.groupID
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .bold))
                    Text("Sair do grupo".loc).font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(NovaTheme.accent))
            }.buttonStyle(.plain)
            Image(systemName: "folder.fill").font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
            Text(g.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(NovaTheme.text).lineLimit(1)
            Text(String(format: "%d camadas".loc, composition.children(of: g.id).count))
                .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(NovaTheme.background)
    }

    // MARK: rolagem

    private var pista: CGFloat { max(40, largura - nameColumn) }

    private var maxScroll: CGFloat {
        let fim = CGFloat(max(composition.duration, composition.layers.map(\.endTime).max() ?? 0)) * pixelsPerSecond
        return max(0, fim + 60 + inicioPista - pista)
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
        let x = CGFloat(t) * pixelsPerSecond - scrollX + inicioPista
        if x > pista - 24 { scrollX = min(maxScroll, CGFloat(t) * pixelsPerSecond - pista * 0.25) }
        else if x < 0 { scrollX = max(0, CGFloat(t) * pixelsPerSecond - pista * 0.25) }
    }

    private func x(_ t: Float) -> CGFloat { CGFloat(t) * pixelsPerSecond - scrollX + inicioPista }
    private func t(_ x: CGFloat) -> Float { Float((x + scrollX - inicioPista) / pixelsPerSecond) }

    // MARK: regua

    /// Cabecalho do APK: "<" que recolhe a coluna da esquerda e a regua com
    /// tracinhos finos (o chip do tempo fica no cursor).
    private var ruler: some View {
        ZStack(alignment: .leading) {
            Canvas { ctx, size in
                let step = tickStep()
                let sub = step / 5
                var tt: Float = max(0, Float(Int(t(0) / sub)) * sub)
                let fim = t(size.width - nameColumn)
                var n = Int((tt / sub).rounded())
                while tt <= min(fim, composition.duration + step) {
                    let px = nameColumn + x(tt)
                    if px >= nameColumn - 1 && px <= size.width {
                        let grande = n % 5 == 0
                        ctx.stroke(Path { p in
                            p.move(to: CGPoint(x: px, y: size.height - (grande ? 9 : 5)))
                            p.addLine(to: CGPoint(x: px, y: size.height))
                        }, with: .color(NovaTheme.dim2.opacity(grande ? 0.9 : 0.5)), lineWidth: 0.8)
                    }
                    n += 1
                    tt = Float(n) * sub
                }
                // Faixa verde: os quadros que a previa ja tem prontos.
                let fps = CGFloat(max(composition.frameRate, 1))
                for f in CacheDeQuadros.faixas(emCache) {
                    let a = max(nameColumn, nameColumn + x(Float(CGFloat(f.lowerBound) / fps)))
                    let b = min(size.width, nameColumn + x(Float(CGFloat(f.upperBound + 1) / fps)))
                    guard b > a else { continue }
                    ctx.fill(Path(CGRect(x: a, y: 0, width: b - a, height: 3)),
                             with: .color(Color(red: 0.25, green: 0.85, blue: 0.35)))
                }
                let fx = nameColumn + x(composition.duration)
                if fx >= nameColumn && fx <= size.width {
                    ctx.fill(Path(CGRect(x: fx, y: size.height - 12, width: 1, height: 12)),
                             with: .color(NovaTheme.dim))
                }
                for m in composition.markers ?? [] {
                    let mx = nameColumn + x(m)
                    guard mx >= nameColumn && mx <= size.width else { continue }
                    ctx.fill(Path { p in
                        p.move(to: CGPoint(x: mx - 4, y: size.height - 10))
                        p.addLine(to: CGPoint(x: mx + 4, y: size.height - 10))
                        p.addLine(to: CGPoint(x: mx, y: size.height - 3))
                        p.closeSubpath()
                    }, with: .color(NovaTheme.warning))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                guard g.location.x > nameColumn else { return }
                time = min(max(0, t(g.location.x - nameColumn)), composition.duration)
            })
            Button { withAnimation(.easeInOut(duration: 0.2)) { recolhida.toggle(); limitarRolagem() } } label: {
                Image(systemName: recolhida ? "chevron.right" : "chevron.left")
                    .font(.system(size: 13, weight: .semibold)).foregroundStyle(NovaTheme.dim)
                    .frame(width: 34, height: alturaCabecalho)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain)
        }
        .frame(height: alturaCabecalho)
        .background(NovaTheme.surface)
    }

    /// Tempo no formato do chip do APK: minutos:segundos:quadros.
    private func tempoQuadros(_ t: Float) -> String {
        let fps = max(Int(composition.frameRate.rounded()), 1)
        let q = Int((t * Float(fps)).rounded())
        return String(format: "%02d:%02d:%02d", q / (fps * 60), (q / fps) % 60, q % fps)
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

    // Cores e icones por tipo, como no print do APK.
    static func corDoTipo(_ k: LayerKind) -> Color {
        func c(_ h: Int) -> Color {
            Color(red: Double((h >> 16) & 255) / 255, green: Double((h >> 8) & 255) / 255, blue: Double(h & 255) / 255)
        }
        switch k {
        case .null: return c(0x474b63)
        case .camera: return c(0x5a3f86)
        case .video: return c(0x1f5e4b)
        case .image: return c(0x2b4f73)
        case .text: return c(0x6a3d74)
        case .shape: return c(0x7a5426)
        case .solid: return c(0x7a2f3e)
        case .adjustment: return c(0x3a4f86)
        case .audio: return c(0x245f6e)
        case .light: return c(0x7a6a26)
        case .group, .precomp: return c(0x3f4a5e)
        case .model3d: return c(0x45507a)
        case .counter: return c(0x5e4a2a)
        }
    }

    static func iconeDoTipo(_ k: LayerKind) -> String {
        switch k {
        case .null: return "arrow.up.and.down.and.arrow.left.and.right"
        case .camera: return "video.fill"
        case .video: return "film"
        case .image: return "photo"
        case .text: return "textformat"
        case .shape: return "star.fill"
        case .solid: return "square.fill"
        case .adjustment: return "slider.horizontal.3"
        case .audio: return "waveform"
        case .light: return "lightbulb.fill"
        case .group: return "folder.fill"
        case .precomp: return "square.stack.3d.up.fill"
        case .model3d: return "cube.fill"
        case .counter: return "number"
        }
    }

    /// Propriedades animadas da camada (nome, tempos das chaves), na ordem do APK.
    private func animadas(_ l: Layer) -> [(String, [Float])] {
        let tr = l.transform
        var a: [(String, [Float])] = []
        func add<T: Interpolatable>(_ n: String, _ v: Animated<T>) {
            if !v.keyframes.isEmpty { a.append((n, v.keyframes.map { $0.time })) }
        }
        add("Posição", tr.position); add("Escala", tr.scale); add("Rotação", tr.rotationZ)
        add("Opacidade", tr.opacity); add("Âncora", tr.anchorPoint); add("Profundidade (Z)", tr.positionZ)
        add("Rotação X", tr.rotationX); add("Rotação Y", tr.rotationY)
        if let sk = tr.skew { add("Inclinação", sk) }
        return a
    }

    @ViewBuilder
    private func row(_ layer: Layer) -> some View {
        let sel = selected == layer.id
        let props = animadas(layer)
        let aberta = expandidas.contains(layer.id)
        HStack(spacing: 0) {
            if !recolhida { colunaEsquerda(layer, sel, temProps: !props.isEmpty, aberta: aberta) }
            ZStack(alignment: .topLeading) {
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { selected = nil }
                clipe(layer, sel, chaves: props.flatMap { $0.1 })
            }
            .frame(height: alturaLinha)
            .frame(maxWidth: .infinity)
            .clipped()
        }
        if aberta {
            ForEach(Array(props.enumerated()), id: \.offset) { _, p in
                HStack(spacing: 0) {
                    if !recolhida {
                        Text(p.0.loc).font(.system(size: 10)).foregroundStyle(NovaTheme.dim)
                            .lineLimit(1).minimumScaleFactor(0.8)
                            .padding(.leading, 22)
                            .frame(width: nameColumn, height: 22, alignment: .leading)
                    }
                    ZStack(alignment: .topLeading) {
                        Rectangle().fill(Color.white.opacity(0.04)).frame(height: 1).offset(y: 11)
                        ForEach(Array(p.1.enumerated()), id: \.offset) { _, k in
                            losango(9).offset(x: x(k) - 4.5, y: 6.5)
                        }
                    }
                    .frame(height: 22).frame(maxWidth: .infinity, alignment: .leading)
                    .clipped()
                }
            }
        }
    }

    /// Chevron (propriedades), olho verde, circulo do solo e o icone do tipo.
    private func colunaEsquerda(_ layer: Layer, _ sel: Bool, temProps: Bool, aberta: Bool) -> some View {
        HStack(spacing: 0) {
            Button {
                if aberta { expandidas.remove(layer.id) } else { expandidas.insert(layer.id) }
            } label: {
                Image(systemName: aberta ? "chevron.down" : "chevron.right")
                    .font(.system(size: 8, weight: .bold)).foregroundStyle(NovaTheme.dim)
                    .frame(width: 14, height: alturaLinha).contentShape(Rectangle())
            }
            .buttonStyle(.plain).opacity(temProps ? 1 : 0).disabled(!temProps)
            Button { el(layer.id, true) { $0.enabled.toggle() } } label: {
                Image(systemName: layer.enabled ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(layer.enabled ? NovaTheme.accent : NovaTheme.dim2)
                    .frame(width: 24, height: alturaLinha).contentShape(Rectangle())
            }.buttonStyle(.plain)
            Button { el(layer.id, true) { $0.solo.toggle() } } label: {
                Circle()
                    .strokeBorder(layer.solo ? NovaTheme.accent : NovaTheme.dim2, lineWidth: 1.2)
                    .background(Circle().fill(layer.solo ? NovaTheme.accent.opacity(0.35) : Color.clear))
                    .frame(width: 11, height: 11)
                    .frame(width: 18, height: alturaLinha).contentShape(Rectangle())
            }.buttonStyle(.plain)
            RoundedRectangle(cornerRadius: 6)
                .fill(Self.corDoTipo(layer.kind).opacity(0.45))
                .frame(width: 22, height: 22)
                .overlay(Image(systemName: Self.iconeDoTipo(layer.kind))
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.white.opacity(0.85)))
                .padding(.leading, 1)
            Spacer(minLength: 0)
        }
        .frame(width: nameColumn, height: alturaLinha)
        .background(sel ? NovaTheme.selectedFill.opacity(0.6) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { selected = sel ? nil : layer.id }
    }

    /// Losango branco de quadro-chave.
    private func losango(_ lado: CGFloat) -> some View {
        Rectangle().fill(Color.white)
            .overlay(Rectangle().stroke(Color.black.opacity(0.45), lineWidth: 0.8))
            .frame(width: lado / 1.414, height: lado / 1.414)
            .rotationEffect(.degrees(45))
            .frame(width: lado, height: lado)
    }

    private func clipe(_ layer: Layer, _ sel: Bool, chaves: [Float]) -> some View {
        let w = max(6, CGFloat(layer.duration) * pixelsPerSecond)
        let h = alturaLinha - 4
        let cor = Self.corDoTipo(layer.kind)
        let faixa = layer.kind == .video || layer.kind == .audio
        return RoundedRectangle(cornerRadius: 6)
            .fill(cor.opacity(layer.enabled ? 1 : 0.45))
            .frame(width: w, height: h)
            .overlay(alignment: .bottom) {
                // video: a faixa mais clara de baixo, como no APK
                Rectangle().fill(Color.white.opacity(faixa ? 0.14 : 0)).frame(height: 4)
            }
            .overlay(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.35)).frame(width: 2.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .leading) {
                Text(layer.name).font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95)).lineLimit(1)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.38)))
                    .padding(.leading, sel ? alcaLargura + 3 : 6)
                    .frame(maxWidth: max(0, w - 8), alignment: .leading)
            }
            .overlay(alignment: .topLeading) {
                ZStack(alignment: .topLeading) {
                    ForEach(Array(chaves.enumerated()), id: \.offset) { _, k in
                        losango(10).offset(x: CGFloat(k - layer.startTime) * pixelsPerSecond - 5, y: h / 2 - 5)
                    }
                }
                .allowsHitTesting(false)
            }
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(sel ? NovaTheme.accent : Color.white.opacity(0.06), lineWidth: sel ? 1.6 : 1))
            .overlay(alignment: .leading) { if sel { alca(layer, .entrada) } }
            .overlay(alignment: .trailing) { if sel { alca(layer, .saida) } }
            .overlay(alignment: .trailing) {
                if layer.kind == .group {
                    // grupo: quantas camadas tem e o botao de abrir (ou dois toques no clipe)
                    Button { selected = nil; grupoAberto = layer.id } label: {
                        HStack(spacing: 3) {
                            Text("\(composition.children(of: layer.id).count)").font(.system(size: 9, weight: .bold))
                            Image(systemName: "arrow.down.right.square.fill").font(.system(size: 12))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 5).frame(height: h)
                        .background(Color.black.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, sel ? alcaLargura : 0)
                    .opacity(w > 50 ? 1 : 0)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { selected = layer.id }
            .highPriorityGesture(arrastar(layer, .corpo),
                                 including: sel && editLayer != nil && !layer.locked ? .all : .subviews)
            .offset(x: x(layer.startTime), y: 2)
    }

    /// Alca de aparar (o "[" e o "]" do clipe selecionado no APK).
    private func alca(_ layer: Layer, _ tipo: Alca) -> some View {
        UnevenRoundedRectangle(topLeadingRadius: tipo == .entrada ? 6 : 0,
                               bottomLeadingRadius: tipo == .entrada ? 6 : 0,
                               bottomTrailingRadius: tipo == .saida ? 6 : 0,
                               topTrailingRadius: tipo == .saida ? 6 : 0)
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
                if let gs = gesto {
                    // grupo andando no tempo leva o conteudo junto
                    if gs.1 == .corpo, gs.2.kind == .group, let agora = composition.layer(id: gs.0),
                       agora.startTime != gs.2.startTime {
                        let dt = agora.startTime - gs.2.startTime
                        ec { $0.deslocarConteudo(doGrupo: gs.0, por: dt) }
                    } else {
                        el(gs.0, true) { _ in }
                    }
                }
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
        if l.kind == .group {
            var n: UUID?
            ec { c in n = c.dividirGrupo(l.id, em: t) }
            selected = n ?? l.id
            return
        }
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
        var nova: UUID?
        ec { c in nova = c.duplicar(l.id, sufixo: "cópia".loc) }
        selected = nova ?? l.id
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
                        Rectangle().fill(NovaTheme.warning).frame(width: 1, height: max(0, geo.size.height - topo))
                            .offset(x: gx - 0.5, y: topo)
                    }
                }
                let px = nameColumn + x(time)
                if px >= nameColumn && px <= geo.size.width {
                    Rectangle().fill(Self.corCursor)
                        .frame(width: 1.2, height: max(0, geo.size.height - topo - 8))
                        .offset(x: px - 0.6, y: topo + 8)
                    HStack(spacing: 4) {
                        Image(systemName: "flag.fill").font(.system(size: 8))
                        Text(tempoQuadros(time)).font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(Color.black.opacity(0.85))
                    .padding(.horizontal, 8).frame(height: 20)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Self.corCursor))
                    .fixedSize()
                    .position(x: min(max(px, nameColumn + 48), geo.size.width - 48), y: topo + 15)
                }
            }
            .allowsHitTesting(false)
        }
    }
}
