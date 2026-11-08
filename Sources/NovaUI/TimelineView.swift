//
//  TimelineView.swift
//  NovaUI
//
//  Timeline: regua, cursor e as barras das camadas. Arrastar move o cursor,
//  pincar muda o zoom. Porte do comportamento visto nas capturas do APK.
//

import SwiftUI

public struct TimelineView: View {
    let composition: Composition
    @Binding var time: Float
    @Binding var selected: UUID?

    @State private var pixelsPerSecond: CGFloat = 60
    @State private var zoomBase: CGFloat = 60
    @State private var scrollX: CGFloat = 0

    private let nameColumn: CGFloat = 124

    public init(composition: Composition, time: Binding<Float>, selected: Binding<UUID?>) {
        self.composition = composition
        _time = time
        _selected = selected
    }

    public var body: some View {
        VStack(spacing: 0) {
            ruler
            ScrollView([.vertical]) {
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
        }
        .background(NovaTheme.surface)
        .overlay(alignment: .topLeading) { playhead }
        .gesture(MagnificationGesture()
            .onChanged { v in pixelsPerSecond = min(400, max(8, zoomBase * v)) }
            .onEnded { _ in zoomBase = pixelsPerSecond })
    }

    // MARK: regua

    private var ruler: some View {
        GeometryReader { geo in
            let w = geo.size.width - nameColumn
            Canvas { ctx, size in
                let step = tickStep()
                var t: Float = 0
                while t <= composition.duration {
                    let x = nameColumn + CGFloat(t) * pixelsPerSecond - scrollX
                    if x >= nameColumn && x <= size.width {
                        ctx.stroke(Path { p in
                            p.move(to: CGPoint(x: x, y: size.height - 6))
                            p.addLine(to: CGPoint(x: x, y: size.height))
                        }, with: .color(NovaTheme.dim2), lineWidth: 1)
                        ctx.draw(Text(label(t)).font(.system(size: 8))
                                    .foregroundColor(NovaTheme.dim2),
                                 at: CGPoint(x: x + 13, y: size.height / 2))
                    }
                    t += step
                }
                // Marcadores da composicao.
                for m in composition.markers ?? [] {
                    let x = nameColumn + CGFloat(m) * pixelsPerSecond - scrollX
                    guard x >= nameColumn && x <= size.width else { continue }
                    ctx.fill(Path { p in
                        p.move(to: CGPoint(x: x - 4, y: 0))
                        p.addLine(to: CGPoint(x: x + 4, y: 0))
                        p.addLine(to: CGPoint(x: x, y: 7))
                        p.closeSubpath()
                    }, with: .color(NovaTheme.warning))
                }
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                guard g.location.x > nameColumn else { return }
                let t = Float((g.location.x - nameColumn + scrollX) / pixelsPerSecond)
                time = min(max(0, t), composition.duration)
            })
            .frame(width: geo.size.width)
            .onAppear { _ = w }
        }
        .frame(height: NovaTheme.Metrics.rulerHeight)
        .background(NovaTheme.surface2)
        .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .bottom)
    }

    private func tickStep() -> Float {
        let candidates: [Float] = [0.1, 0.25, 0.5, 1, 2, 5, 10, 15, 30, 60]
        for c in candidates where CGFloat(c) * pixelsPerSecond >= 56 { return c }
        return 120
    }

    private func label(_ t: Float) -> String {
        t < 60 ? String(format: "%.0fs", t)
               : String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    // MARK: linha de camada

    private func row(_ layer: Layer) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: layer.enabled ? "eye" : "eye.slash")
                    .font(.system(size: 9))
                    .foregroundStyle(layer.enabled ? NovaTheme.dim : NovaTheme.dim2)
                Text(layer.name).font(.system(size: 10)).lineLimit(1)
                    .foregroundStyle(selected == layer.id ? NovaTheme.text : NovaTheme.dim)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(width: nameColumn, height: NovaTheme.Metrics.timelineRowHeight)
            .background(selected == layer.id ? NovaTheme.surface2 : Color.clear)
            .onTapGesture { selected = layer.id }

            GeometryReader { geo in
                let x = CGFloat(layer.startTime) * pixelsPerSecond - scrollX
                let w = max(6, CGFloat(layer.duration) * pixelsPerSecond)
                RoundedRectangle(cornerRadius: 4)
                    .fill(NovaTheme.trackColor(layer.kind.rawValue))
                    .frame(width: w, height: NovaTheme.Metrics.timelineRowHeight - 5)
                    .overlay(RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(selected == layer.id ? Color.white : Color.white.opacity(0.1),
                                      lineWidth: selected == layer.id ? 1.4 : 1))
                    .overlay(alignment: .leading) {
                        Text(layer.name).font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.leading, 6).lineLimit(1)
                    }
                    .offset(x: x, y: 2.5)
                    .onTapGesture { selected = layer.id }
                    .onAppear { _ = geo }
            }
            .frame(height: NovaTheme.Metrics.timelineRowHeight)
            .clipped()
        }
    }

    // MARK: cursor

    private var playhead: some View {
        GeometryReader { geo in
            let x = nameColumn + CGFloat(time) * pixelsPerSecond - scrollX
            if x >= nameColumn && x <= geo.size.width {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(NovaTheme.accent)
                        .frame(width: 1.4)
                    Rectangle()
                        .fill(NovaTheme.accent)
                        .frame(width: 9, height: 7)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .offset(x: x - 0.7)
                .allowsHitTesting(false)
            }
        }
    }
}
