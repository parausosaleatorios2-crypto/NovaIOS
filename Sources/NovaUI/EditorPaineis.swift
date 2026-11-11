//
//  EditorPaineis.swift
//  NovaUI
//
//  Paineis que abrem embaixo da timeline, no lugar das folhas:
//
//  - PainelClipe: o clipe selecionado (aparar/dividir/som em cima; Preencher,
//    Borda e sombra, Opacidade e mesclagem; Mover e transformar, Editar forma,
//    Animar, Efeitos).
//  - PainelComTrilho: a base do painel de parametros — trilho a esquerda
//    (voltar, quadro-chave, curva, mais) e linhas com nome, regua e valor.
//  - PainelParametros, PainelTransformar, PainelOpacidade, PainelEfeitos.
//

import SwiftUI
import simd

enum PainelEditor: Equatable {
    case efeitos
    case efeito(UUID)
    case transformar
    case opacidade
}

struct PainelAberto: Equatable {
    let camada: UUID
    let tipo: PainelEditor
}

enum CoresPainel {
    static let fundo = Color(red: 0.13, green: 0.14, blue: 0.19)
    static let trilho = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let pilula = Color(red: 0.21, green: 0.23, blue: 0.35)
    static let pilulaAtiva = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let valor = Color(red: 0.17, green: 0.18, blue: 0.25)
    static let ladrilho = Color(red: 0.12, green: 0.13, blue: 0.20)
}

/// "25,0" / "0,00": uma casa a partir de 10, duas abaixo (como no APK).
func formatarValor(_ v: Float) -> String {
    let s = abs(v) >= 1000 ? String(format: "%.0f", v)
        : abs(v) >= 10 ? String(format: "%.1f", v) : String(format: "%.2f", v)
    return s.replacingOccurrences(of: ".", with: ",")
}

// MARK: - Regua

/// Regua de arrastar: o tracinho verde fica no meio e a regua corre por baixo.
/// Os tracos so existem dentro da faixa — no minimo, o lado esquerdo fica vazio.
struct Regua: View {
    let valor: Float
    let faixa: ClosedRange<Float>
    let onChange: (Float, Bool) -> Void

    @State private var inicio: Float?
    @State private var ultimo: Float = 0
    private let passo: CGFloat = 7
    private let tracos = 80

    private var unidade: Float { max((faixa.upperBound - faixa.lowerBound) / Float(tracos), 1e-6) }

    var body: some View {
        Canvas { ctx, size in
            let meio = size.width / 2
            let u = unidade
            let pos = CGFloat((valor - faixa.lowerBound) / u)
            let k0 = max(0, Int(floor(pos - meio / passo)) - 1)
            let k1 = min(tracos, Int(ceil(pos + meio / passo)) + 1)
            if k0 <= k1 {
                for k in k0...k1 {
                    let x = meio + (CGFloat(k) - pos) * passo
                    guard x >= 0, x <= size.width else { continue }
                    let alto: CGFloat = k % 10 == 0 ? 0.62 : (k % 5 == 0 ? 0.5 : 0.4)
                    let h = size.height * alto
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: (size.height - h) / 2))
                    p.addLine(to: CGPoint(x: x, y: (size.height + h) / 2))
                    ctx.stroke(p, with: .color(Color.white.opacity(k % 10 == 0 ? 0.5 : 0.32)), lineWidth: 1.2)
                }
            }
            var c = Path()
            c.move(to: CGPoint(x: meio, y: 4))
            c.addLine(to: CGPoint(x: meio, y: size.height - 4))
            ctx.stroke(c, with: .color(NovaTheme.accent.opacity(0.85)), lineWidth: 2)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { g in
                    if inicio == nil { inicio = valor }
                    var nv = (inicio ?? valor) - Float(g.translation.width / passo) * unidade
                    nv = min(max(nv, faixa.lowerBound), faixa.upperBound)
                    ultimo = nv
                    onChange(nv, false)
                }
                .onEnded { _ in
                    inicio = nil
                    onChange(ultimo, true)
                }
        )
    }
}

// MARK: - Linhas

struct PilulaNome: View {
    let titulo: String
    let selecionado: Bool
    var animado = false
    var temChave = false
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Text(titulo)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(selecionado ? NovaTheme.accent : NovaTheme.text.opacity(0.88))
                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.75)
                .padding(.horizontal, 6)
                .frame(width: 118, height: 60)
                .background(RoundedRectangle(cornerRadius: 10)
                    .fill(selecionado ? CoresPainel.pilulaAtiva : CoresPainel.pilula))
                .overlay(alignment: .topTrailing) {
                    if animado {
                        Image(systemName: temChave ? "diamond.fill" : "diamond")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(NovaTheme.accent).padding(6)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

/// Nome | regua | valor.
struct LinhaRegua: View {
    let titulo: String
    let selecionado: Bool
    var animado = false
    var temChave = false
    let valor: Float
    let faixa: ClosedRange<Float>
    let onSelecionar: () -> Void
    let onChange: (Float, Bool) -> Void

    @State private var digitando = false
    @State private var texto = ""

    var body: some View {
        HStack(spacing: 8) {
            PilulaNome(titulo: titulo, selecionado: selecionado, animado: animado,
                       temChave: temChave, acao: onSelecionar)
            Regua(valor: valor, faixa: faixa) { v, gravar in
                onChange(v, gravar)
                if !gravar && !selecionado { onSelecionar() }
            }
            .frame(height: 60)
            Button {
                texto = formatarValor(valor)
                digitando = true
            } label: {
                Text(formatarValor(valor))
                    .font(.system(size: 16, weight: .medium)).foregroundStyle(NovaTheme.text)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(width: 84, height: 60)
                    .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.valor))
            }
            .buttonStyle(.plain)
        }
        .alert(titulo, isPresented: $digitando) {
            TextField("", text: $texto).keyboardType(.numbersAndPunctuation)
            Button("Cancelar".loc, role: .cancel) {}
            Button("OK") {
                if let v = Float(texto.replacingOccurrences(of: ",", with: ".")
                                    .trimmingCharacters(in: .whitespaces)) {
                    onChange(v, true)
                }
            }
        }
    }
}

/// Nome | controle (chave, lista, cor, botao).
struct LinhaControle<C: View>: View {
    let titulo: String
    let selecionado: Bool
    var animado = false
    var temChave = false
    let onSelecionar: () -> Void
    @ViewBuilder let controle: () -> C

    var body: some View {
        HStack(spacing: 8) {
            PilulaNome(titulo: titulo, selecionado: selecionado, animado: animado,
                       temChave: temChave, acao: onSelecionar)
            HStack { controle() }
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
                .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.valor.opacity(0.6)))
        }
    }
}

// MARK: - Base com trilho

struct PainelComTrilho<Conteudo: View, Mais: View>: View {
    let onVoltar: () -> Void
    /// Quadro-chave da propriedade selecionada (nil apaga o botao).
    var onChave: (() -> Void)? = nil
    var temChave = false
    /// Curva do quadro-chave no cursor (nil quando nao ha chave aqui).
    var easing: Easing? = nil
    var onEasing: ((Easing) -> Void)? = nil
    @ViewBuilder let mais: () -> Mais
    @ViewBuilder let conteudo: () -> Conteudo

    @State private var curvaAberta = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 26) {
                Button(action: onVoltar) {
                    Image(systemName: "arrow.left").font(.system(size: 22, weight: .medium))
                        .foregroundStyle(NovaTheme.text).frame(width: 52, height: 40)
                }
                Button { onChave?() } label: {
                    ZStack {
                        Image(systemName: "diamond.fill").font(.system(size: 30))
                            .foregroundStyle(temChave ? NovaTheme.accent : NovaTheme.text)
                        Image(systemName: "plus").font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(CoresPainel.trilho)
                    }
                    .frame(width: 52, height: 40)
                    .opacity(onChave == nil ? 0.3 : 1)
                }
                .disabled(onChave == nil)
                Button { curvaAberta = true } label: {
                    CurveGlyph(easing: easing ?? .named("easeInOut"))
                        .stroke(NovaTheme.text, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                        .frame(width: 26, height: 26)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(NovaTheme.text.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2])))
                        .frame(width: 52, height: 40)
                        .opacity(onEasing == nil ? 0.3 : 1)
                }
                .disabled(onEasing == nil)
                Menu { mais() } label: {
                    Image(systemName: "ellipsis").font(.system(size: 20, weight: .bold))
                        .foregroundStyle(NovaTheme.text).frame(width: 52, height: 40)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 18)
            .frame(width: 70)
            .background(CoresPainel.trilho)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) { conteudo() }
                    .padding(.horizontal, 8).padding(.vertical, 8)
            }
            .background(CoresPainel.fundo)
        }
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
        .sheet(isPresented: $curvaAberta) {
            CurveEditorSheet(initial: easing ?? .linear) { e in onEasing?(e) }
        }
    }
}

struct CabecalhoGrupo: View {
    let texto: String
    var body: some View {
        Text(texto.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(NovaTheme.accent.opacity(0.85))
            .padding(.leading, 4).padding(.top, 6)
    }
}

// MARK: - Clipe selecionado

struct PainelClipe: View {
    let layer: Layer
    var comp: Composition? = nil
    /// Progresso do pre-render deste grupo (nil = parado).
    var preRender: Double? = nil
    let acao: (String) -> Void

    private var pai: Layer? { layer.parentID.flatMap { comp?.layer(id: $0) } }

    private var temSom: Bool { layer.kind == .video || layer.kind == .audio }

    private var primeiro: (String, String, String) {
        switch layer.kind {
        case .shape, .solid, .text: return ("preencher", "Preencher", "drop.fill")
        case .video, .audio: return ("velocidade", "Velocidade e som", "speedometer")
        case .image: return ("mascara", "Máscara", "circle.circle")
        default: return ("camada", "Camada", "square.3.layers.3d")
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                mini("arrow.counterclockwise", "restaurar", "Centralizar e caber")
                mini("square.lefthalf.filled", "aparaInicio", "Aparar o começo até o cursor")
                mini("scissors", "dividir", "Dividir no cursor")
                mini("square.righthalf.filled", "aparaFim", "Aparar o fim até o cursor")
                mini(layer.muted == true ? "speaker.slash.fill" : "speaker.wave.2.fill", "som", "Som",
                     habilitado: temSom)
                vincular
            }
            HStack(spacing: 8) {
                mini("square.3.layers.3d.top.filled", "frente", "Trazer para a frente")
                mini("arrow.up.square", "subir", "Subir uma camada")
                mini("arrow.down.square", "descer", "Descer uma camada")
                mini("square.3.layers.3d.bottom.filled", "tras", "Mandar para trás")
                Button { acao("3d") } label: {
                    Text("3D").font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(layer.is3D ? Color.black : NovaTheme.text.opacity(0.85))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(RoundedRectangle(cornerRadius: 10).fill(layer.is3D ? NovaTheme.accent : CoresPainel.ladrilho))
                }
                .buttonStyle(EncolheAoTocar())
                .accessibilityLabel("Camada 3D".loc)
            }
            if layer.kind == .group { linhaDoGrupo }
            HStack(spacing: 8) {
                ladrilho(primeiro.2, primeiro.1, primeiro.0)
                ladrilho("square.dashed", "Borda e sombra", "borda")
                ladrilho("drop.halffull", "Opacidade e mesclagem", "opacidade")
            }
            HStack(spacing: 8) {
                ladrilho("arrow.up.and.down.and.arrow.left.and.right", "Mover e transformar", "transformar")
                if layer.kind == .shape {
                    ladrilho("square.on.circle", "Editar forma", "forma")
                } else {
                    ladrilho("circle.circle", "Máscara", "mascara")
                }
                ladrilho("star", "Animar", "animar")
                ladrilho("sparkles", "Efeitos", "efeitos")
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 10)
        .background(NovaTheme.background)
    }

    /// Vincular a um pai (o pick whip do AE): a camada passa a seguir o nulo (ou outra camada)
    /// sem sair do lugar.
    private var vincular: some View {
        Menu {
            Button { acao("vincular:nenhum") } label: {
                Label("Sem vínculo".loc, systemImage: layer.parentID == nil ? "checkmark" : "link.badge.plus")
            }
            if let c = comp {
                let nulos = c.paisPossiveis(para: layer.id)
                ForEach(nulos.sorted { ($0.kind == .null ? 0 : 1) < ($1.kind == .null ? 0 : 1) }) { p in
                    Button { acao("vincular:" + p.id.uuidString) } label: {
                        Label(p.name, systemImage: p.id == layer.parentID ? "checkmark"
                              : (p.kind == .null ? "arrow.up.and.down.and.arrow.left.and.right" : "square.on.square"))
                    }
                }
            }
        } label: {
            Image(systemName: layer.parentID == nil ? "link" : "link.circle.fill").font(.system(size: 19))
                .foregroundStyle(layer.parentID == nil ? NovaTheme.text.opacity(0.85) : NovaTheme.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.ladrilho))
        }
        .accessibilityLabel(pai.map { "Vinculada a ".loc + $0.name } ?? "Vincular a um pai".loc)
    }

    /// Grupo (como no Blurrr): abrir, pre-renderizar e desagrupar.
    private var linhaDoGrupo: some View {
        let valido = comp?.preRenderValido(layer) != nil
        let tem = layer.prerender != nil
        return HStack(spacing: 8) {
            ladrilho("arrow.down.right.square", "Abrir grupo", "entrarGrupo")
            if let p = preRender {
                VStack(spacing: 5) {
                    ProgressView(value: p).tint(NovaTheme.accent).padding(.horizontal, 10)
                    Text(String(format: "Pré-render %d%%".loc, Int(p * 100))).font(.system(size: 12.5))
                        .foregroundStyle(NovaTheme.text.opacity(0.9))
                }
                .frame(maxWidth: .infinity, minHeight: 62)
                .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.ladrilho))
            } else if valido {
                ladrilho("checkmark.seal.fill", "Pré-render pronto", "removerPrerender")
            } else {
                ladrilho(tem ? "arrow.clockwise.circle" : "film.stack", tem ? "Pré-render desatualizado" : "Pré-renderizar", "prerender")
            }
            ladrilho("rectangle.stack.badge.minus", "Desagrupar", "desagrupar")
        }
    }

    private func mini(_ icone: String, _ id: String, _ nome: String, habilitado: Bool = true) -> some View {
        Button { acao(id) } label: {
            Image(systemName: icone).font(.system(size: 19))
                .foregroundStyle(habilitado ? NovaTheme.text.opacity(0.85) : NovaTheme.dim2.opacity(0.5))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.ladrilho))
        }
        .buttonStyle(EncolheAoTocar())
        .disabled(!habilitado)
        .accessibilityLabel(nome.loc)
    }

    private func ladrilho(_ icone: String, _ nome: String, _ id: String) -> some View {
        Button { acao(id) } label: {
            VStack(spacing: 5) {
                Image(systemName: icone).font(.system(size: 18)).foregroundStyle(NovaTheme.text.opacity(0.9))
                Text(nome.loc).font(.system(size: 12.5)).foregroundStyle(NovaTheme.text.opacity(0.9))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity, minHeight: 62)
            .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.ladrilho))
        }
        .buttonStyle(EncolheAoTocar())
    }
}

// MARK: - Efeitos da camada

struct PainelEfeitos: View {
    let layer: Layer
    let manifests: [String: EffectManifest]
    let edit: LayerEdit
    let onVoltar: () -> Void
    let onAdicionar: () -> Void
    let onAbrir: (UUID) -> Void

    var body: some View {
        PainelComTrilho(onVoltar: onVoltar, mais: {
            Button(action: onAdicionar) { Label("Adicionar efeito".loc, systemImage: "plus") }
        }, conteudo: {
            Button(action: onAdicionar) {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("Adicionar efeito".loc).font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.accent))
            }
            .buttonStyle(EncolheAoTocar())
            if layer.effects.isEmpty {
                Text("Nenhum efeito nesta camada.".loc)
                    .font(.system(size: 13)).foregroundStyle(NovaTheme.dim2)
                    .frame(maxWidth: .infinity).padding(.top, 20)
            }
            ForEach(Array(layer.effects.enumerated()), id: \.element.id) { i, fx in
                HStack(spacing: 8) {
                    Button {
                        edit(layer.id, true) { $0.effects[i].enabled.toggle() }
                    } label: {
                        Image(systemName: fx.enabled ? "eye.fill" : "eye.slash")
                            .font(.system(size: 17))
                            .foregroundStyle(fx.enabled ? NovaTheme.accent : NovaTheme.dim2)
                            .frame(width: 48, height: 54)
                    }
                    .buttonStyle(.plain)
                    Button { onAbrir(fx.id) } label: {
                        HStack {
                            Text(manifests[fx.effectID]?.name ?? fx.effectID)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(fx.enabled ? NovaTheme.text : NovaTheme.dim)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(NovaTheme.dim2)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 54)
                    }
                    .buttonStyle(.plain)
                    Menu {
                        if i > 0 {
                            Button { edit(layer.id, true) { $0.effects.swapAt(i, i - 1) } } label: {
                                Label("Subir".loc, systemImage: "arrow.up")
                            }
                        }
                        if i < layer.effects.count - 1 {
                            Button { edit(layer.id, true) { $0.effects.swapAt(i, i + 1) } } label: {
                                Label("Descer".loc, systemImage: "arrow.down")
                            }
                        }
                        Button {
                            edit(layer.id, true) { l in
                                var c = l.effects[i]; c.id = UUID()
                                l.effects.insert(c, at: i + 1)
                            }
                        } label: { Label("Duplicar".loc, systemImage: "plus.square.on.square") }
                        Button(role: .destructive) {
                            edit(layer.id, true) { $0.effects.removeAll { $0.id == fx.id } }
                        } label: { Label("Remover".loc, systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold))
                            .foregroundStyle(NovaTheme.dim).frame(width: 44, height: 54)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(CoresPainel.pilula.opacity(0.55)))
            }
        })
    }
}

// MARK: - Parametros de um efeito

struct PainelParametros: View {
    let layer: Layer
    let fxID: UUID
    let manifest: EffectManifest?
    let time: Float
    let edit: LayerEdit
    let onVoltar: () -> Void
    let onAbrirCompleto: () -> Void
    /// Para a cabeca do Magic Bullet Looks: nomes das ferramentas e abrir uma delas.
    var manifests: [String: EffectManifest] = [:]
    var onAbrirEfeito: ((UUID) -> Void)? = nil

    @State private var selecionado: String?

    private var indice: Int? { layer.effects.firstIndex { $0.id == fxID } }

    var body: some View {
        if let i = indice {
            let fx = layer.effects[i]
            let sel = selecionado.flatMap { s in manifest?.params.first { $0.id == s } }
            PainelComTrilho(onVoltar: onVoltar,
                            onChave: acaoChave(i, sel),
                            temChave: sel.map { temChave(fx, $0) } ?? false,
                            easing: sel.flatMap { easing(fx, $0) },
                            onEasing: acaoEasing(i, fx, sel), mais: {
                Button { edit(layer.id, true) { $0.effects[i].enabled.toggle() } } label: {
                    Label(fx.enabled ? "Desligar efeito".loc : "Ligar efeito".loc,
                          systemImage: fx.enabled ? "eye.slash" : "eye")
                }
                Button {
                    edit(layer.id, true) { l in
                        var novo = AppliedEffect(effectID: l.effects[i].effectID)
                        novo.id = l.effects[i].id
                        l.effects[i] = novo
                    }
                } label: { Label("Restaurar padrão".loc, systemImage: "arrow.counterclockwise") }
                Button {
                    edit(layer.id, true) { l in
                        var c = l.effects[i]; c.id = UUID()
                        l.effects.insert(c, at: i + 1)
                    }
                } label: { Label("Duplicar efeito".loc, systemImage: "plus.square.on.square") }
                Button(action: onAbrirCompleto) {
                    Label("Painel completo".loc, systemImage: "slider.horizontal.3")
                }
                Button(role: .destructive) {
                    edit(layer.id, true) { $0.effects.removeAll { $0.id == fxID } }
                    onVoltar()
                } label: { Label("Remover efeito".loc, systemImage: "trash") }
            }, conteudo: {
                HStack {
                    Text(manifest?.name ?? fx.effectID)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(NovaTheme.dim)
                        .lineLimit(1)
                    Spacer()
                    if !fx.enabled {
                        Text("desligado".loc).font(.system(size: 11)).foregroundStyle(NovaTheme.warning)
                    }
                }
                .padding(.horizontal, 4)
                if let m = manifest {
                    ForEach(Array(m.params.enumerated()), id: \.element.id) { k, p in
                        if p.hidden != true {
                            if let g = p.group, k == 0 || m.params[k - 1].group != g {
                                CabecalhoGrupo(texto: g)
                            }
                            linha(i, fx, p)
                        }
                    }
                    if fx.effectID == LooksFerramentas.cabeca {
                        ferramentasDoLook(i)
                    }
                } else {
                    ProgressView().tint(NovaTheme.accent).frame(maxWidth: .infinity).padding(.top, 20)
                }
            })
        } else {
            Color.clear.onAppear { onVoltar() }
        }
    }

    // MARK: Magic Bullet Looks

    /// As ferramentas logo depois da cabeca formam o Look (como no AE).
    private func cadeiaDoLook(_ i: Int) -> Range<Int> {
        var j = i + 1
        while j < layer.effects.count, LooksFerramentas.porManifesto[layer.effects[j].effectID] != nil {
            j += 1
        }
        return (i + 1)..<j
    }

    @ViewBuilder
    private func ferramentasDoLook(_ i: Int) -> some View {
        let faixa = cadeiaDoLook(i)
        CabecalhoGrupo(texto: "Ferramentas do Look".loc)
        if faixa.isEmpty {
            Text("Sem ferramentas o Strength não muda nada. Adicione uma abaixo.".loc)
                .font(.system(size: 12)).foregroundStyle(NovaTheme.dim2)
                .padding(.horizontal, 4)
        }
        ForEach(Array(faixa), id: \.self) { k in
            let t = layer.effects[k]
            HStack(spacing: 6) {
                Button {
                    edit(layer.id, true) { $0.effects[k].enabled.toggle() }
                } label: {
                    Image(systemName: t.enabled ? "eye.fill" : "eye.slash")
                        .font(.system(size: 15))
                        .foregroundStyle(t.enabled ? NovaTheme.accent : NovaTheme.dim2)
                        .frame(width: 40, height: 44)
                }.buttonStyle(.plain)
                Button { onAbrirEfeito?(t.id) } label: {
                    HStack {
                        Text(LooksFerramentas.nome(t.effectID, manifests[t.effectID]?.name))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(t.enabled ? NovaTheme.text : NovaTheme.dim)
                        Spacer()
                        Image(systemName: "slider.horizontal.3").font(.system(size: 13))
                            .foregroundStyle(NovaTheme.dim2)
                    }.padding(.horizontal, 10).frame(height: 44)
                }.buttonStyle(.plain)
                Button {
                    edit(layer.id, true) { $0.effects.remove(at: k) }
                } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold))
                        .foregroundStyle(NovaTheme.dim).frame(width: 40, height: 44)
                }.buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: 9).fill(CoresPainel.pilula.opacity(0.55)))
        }
        Menu {
            ForEach(LooksFerramentas.ordem, id: \.self) { id in
                Button(LooksFerramentas.nome(id, manifests[id]?.name)) {
                    edit(layer.id, true) { l in
                        let fim = min(faixa.upperBound, l.effects.count)
                        l.effects.insert(AppliedEffect(effectID: id), at: fim)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 14, weight: .bold))
                Text("Adicionar ferramenta".loc).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.accent))
        }
    }

    // MARK: valores

    private func acaoChave(_ i: Int, _ p: EffectParam?) -> (() -> Void)? {
        guard let p, podeAnimar(p) else { return nil }
        return { alternarChave(i, p) }
    }

    private func acaoEasing(_ i: Int, _ fx: AppliedEffect, _ p: EffectParam?) -> ((Easing) -> Void)? {
        guard let p, easing(fx, p) != nil else { return nil }
        return { e in mudarEasing(i, p, e) }
    }

    private func faixa(_ p: EffectParam) -> ClosedRange<Float> {
        let def = p.defaultValue.first ?? 0
        let lo = p.minValue ?? min(0, def)
        let hi = max(p.maxValue ?? max(100, def * 2), lo + 0.001)
        return lo...hi
    }

    private func podeAnimar(_ p: EffectParam) -> Bool {
        switch p.kind {
        case .slider, .spinner, .float, .hueDisc, .point, .color: return true
        default: return false
        }
    }

    private func pontoPadrao(_ p: EffectParam) -> SIMD2<Float> {
        let d = p.defaultValue
        return SIMD2(d.first ?? 0.5, d.count > 1 ? d[1] : 0.5)
    }

    private func corPadrao(_ p: EffectParam) -> SIMD4<Float> {
        let d = p.defaultValue
        return SIMD4(d.count > 0 ? d[0] : 1, d.count > 1 ? d[1] : 1, d.count > 2 ? d[2] : 1, d.count > 3 ? d[3] : 1)
    }

    private func temChave(_ fx: AppliedEffect, _ p: EffectParam) -> Bool {
        switch p.kind {
        case .point: return fx.points[p.id]?.hasKeyframe(at: time) ?? false
        case .color: return fx.colors[p.id]?.hasKeyframe(at: time) ?? false
        default: return fx.floats[p.id]?.hasKeyframe(at: time) ?? false
        }
    }

    private func animado(_ fx: AppliedEffect, _ p: EffectParam) -> Bool {
        switch p.kind {
        case .point: return !(fx.points[p.id]?.keyframes.isEmpty ?? true)
        case .color: return !(fx.colors[p.id]?.keyframes.isEmpty ?? true)
        default: return !(fx.floats[p.id]?.keyframes.isEmpty ?? true)
        }
    }

    private func easing(_ fx: AppliedEffect, _ p: EffectParam) -> Easing? {
        switch p.kind {
        case .point: return fx.points[p.id]?.easing(at: time)
        case .color: return fx.colors[p.id]?.easing(at: time)
        default: return fx.floats[p.id]?.easing(at: time)
        }
    }

    private func alternarChave(_ i: Int, _ p: EffectParam) {
        edit(layer.id, true) { l in
            switch p.kind {
            case .point:
                var a = l.effects[i].points[p.id] ?? Animated(pontoPadrao(p))
                toggleKeyframe(&a, at: time); l.effects[i].points[p.id] = a
            case .color:
                var a = l.effects[i].colors[p.id] ?? Animated(corPadrao(p))
                toggleKeyframe(&a, at: time); l.effects[i].colors[p.id] = a
            default:
                var a = l.effects[i].floats[p.id] ?? Animated(p.defaultValue.first ?? 0)
                toggleKeyframe(&a, at: time); l.effects[i].floats[p.id] = a
            }
        }
    }

    private func mudarEasing(_ i: Int, _ p: EffectParam, _ e: Easing) {
        edit(layer.id, true) { l in
            switch p.kind {
            case .point: l.effects[i].points[p.id]?.setEasing(at: time, e)
            case .color: l.effects[i].colors[p.id]?.setEasing(at: time, e)
            default: l.effects[i].floats[p.id]?.setEasing(at: time, e)
            }
        }
    }

    // MARK: linhas

    @ViewBuilder
    private func linha(_ i: Int, _ fx: AppliedEffect, _ p: EffectParam) -> some View {
        let titulo = p.label ?? p.labelEn ?? p.id
        let sel = selecionado == p.id
        let selecionar = { selecionado = p.id }
        switch p.kind {
        case .slider, .spinner, .float, .hueDisc:
            let def = p.defaultValue.first ?? 0
            LinhaRegua(titulo: titulo, selecionado: sel, animado: animado(fx, p), temChave: temChave(fx, p),
                       valor: fx.floats[p.id]?.value(at: time) ?? def, faixa: faixa(p),
                       onSelecionar: selecionar) { v, gravar in
                edit(layer.id, gravar) { l in
                    var a = l.effects[i].floats[p.id] ?? Animated(def)
                    a.set(v, at: time)
                    l.effects[i].floats[p.id] = a
                }
            }
        case .point:
            let v = fx.points[p.id]?.value(at: time) ?? pontoPadrao(p)
            let hi: Float = max(1, p.maxValue ?? 1, abs(pontoPadrao(p).x) * 2, abs(pontoPadrao(p).y) * 2)
            let r: ClosedRange<Float> = (p.minValue ?? -hi)...hi
            ForEach(0..<2, id: \.self) { eixo in
                LinhaRegua(titulo: titulo + (eixo == 0 ? " X" : " Y"), selecionado: sel,
                           animado: animado(fx, p), temChave: temChave(fx, p),
                           valor: eixo == 0 ? v.x : v.y, faixa: r, onSelecionar: selecionar) { nv, gravar in
                    edit(layer.id, gravar) { l in
                        var a = l.effects[i].points[p.id] ?? Animated(v)
                        var x = a.value(at: time)
                        if eixo == 0 { x.x = nv } else { x.y = nv }
                        a.set(x, at: time)
                        l.effects[i].points[p.id] = a
                    }
                }
            }
        case .switchParam, .checkbox:
            let on = (fx.ints[p.id] ?? Int32(p.defaultValue.first ?? 0)) != 0
            LinhaControle(titulo: titulo, selecionado: sel, onSelecionar: selecionar) {
                Text(on ? "Ligado".loc : "Desligado".loc).font(.system(size: 14)).foregroundStyle(NovaTheme.dim)
                Spacer()
                Toggle("", isOn: Binding(get: { on }, set: { nv in
                    edit(layer.id, true) { $0.effects[i].ints[p.id] = nv ? 1 : 0 }
                })).labelsHidden().tint(NovaTheme.accent)
            }
        case .selector, .cycle:
            let cur = Int(fx.ints[p.id] ?? Int32(p.defaultValue.first ?? 0))
            LinhaControle(titulo: titulo, selecionado: sel, onSelecionar: selecionar) {
                Menu {
                    let opcoes = p.options.isEmpty ? (0..<max(2, cur + 2)).map { "\($0)" } : p.options
                    ForEach(Array(opcoes.enumerated()), id: \.offset) { o in
                        Button {
                            edit(layer.id, true) { $0.effects[i].ints[p.id] = Int32(o.offset) }
                        } label: {
                            if o.offset == cur { Label(o.element, systemImage: "checkmark") } else { Text(o.element) }
                        }
                    }
                } label: {
                    HStack {
                        Text(p.options.indices.contains(cur) ? p.options[cur] : "\(cur)")
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(NovaTheme.text)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12))
                            .foregroundStyle(NovaTheme.dim)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
                }
            }
        case .color:
            let c = fx.colors[p.id]?.value(at: time) ?? corPadrao(p)
            LinhaControle(titulo: titulo, selecionado: sel, animado: animado(fx, p), temChave: temChave(fx, p),
                          onSelecionar: selecionar) {
                Text(String(format: "#%02X%02X%02X", Int(c.x * 255), Int(c.y * 255), Int(c.z * 255)))
                    .font(.system(size: 14, design: .monospaced)).foregroundStyle(NovaTheme.dim)
                Spacer()
                ColorPicker("", selection: Binding(get: { Color(rgba: c) }, set: { nc in
                    edit(layer.id, true) { l in
                        var a = l.effects[i].colors[p.id] ?? Animated(c)
                        a.set(nc.rgba, at: time)
                        l.effects[i].colors[p.id] = a
                    }
                })).labelsHidden()
            }
        case .curve, .lut, .nodeGrading, .gradacao:
            LinhaControle(titulo: titulo, selecionado: sel, onSelecionar: selecionar) {
                Button(action: onAbrirCompleto) {
                    HStack {
                        Text(p.kind == .lut ? "Escolher look…".loc : "Abrir editor…".loc)
                            .font(.system(size: 15, weight: .medium)).foregroundStyle(NovaTheme.accent)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(NovaTheme.dim2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Mover e transformar

struct PainelTransformar: View {
    let layer: Layer
    let comp: Composition
    let time: Float
    let edit: LayerEdit
    let onVoltar: () -> Void

    @State private var selecionado = "px"

    /// (id, titulo, faixa, propriedade de 1 ou 2 eixos, eixo)
    private enum Prop {
        case f(WritableKeyPath<Transform, Animated<Float>>)
        case v(WritableKeyPath<Transform, Animated<SIMD2<Float>>>, Int)   // eixo 0, 1; 2 = uniforme
    }

    private var itens: [(String, String, ClosedRange<Float>, Prop)] {
        let big = max(comp.size.x, comp.size.y) * 2
        let s = layer.size ?? comp.size
        let a = max(s.x, s.y)
        var lista: [(String, String, ClosedRange<Float>, Prop)] = [
            ("px", "Posição X", -big...big, .v(\.position, 0)),
            ("py", "Posição Y", -big...big, .v(\.position, 1)),
            ("pz", "Posição Z", -big * 4...big * 4, .f(\.positionZ)),
            ("es", "Escala", 0...400, .v(\.scale, 2)),
            ("ex", "Escala X", 0...400, .v(\.scale, 0)),
            ("ey", "Escala Y", 0...400, .v(\.scale, 1)),
            ("rz", "Rotação", -360...360, .f(\.rotationZ)),
            ("op", "Opacidade", 0...100, .f(\.opacity)),
            ("ax", "Âncora X", -a...a * 2, .v(\.anchorPoint, 0)),
            ("ay", "Âncora Y", -a...a * 2, .v(\.anchorPoint, 1)),
            ("ix", "Inclinação X", -80...80, .v(\.skewValue, 0)),
            ("iy", "Inclinação Y", -80...80, .v(\.skewValue, 1)),
            ("rx", "Rotação X", -180...180, .f(\.rotationX)),
            ("ry", "Rotação Y", -180...180, .f(\.rotationY)),
        ]
        if layer.kind == .camera {
            lista.insert(("zm", "Zoom da câmera", 50...big * 4, .f(\.zoomValue)), at: 0)
        }
        return lista
    }

    private func valor(_ p: Prop) -> Float {
        switch p {
        case .f(let kp): return layer.transform[keyPath: kp].value(at: time)
        case .v(let kp, let e):
            let v = layer.transform[keyPath: kp].value(at: time)
            return e == 1 ? v.y : v.x
        }
    }

    private func mudar(_ p: Prop, _ nv: Float, _ gravar: Bool) {
        let liga3D: Bool
        if case .f(let kp) = p, kp == \Transform.positionZ || kp == \Transform.rotationX || kp == \Transform.rotationY {
            liga3D = true
        } else { liga3D = false }
        edit(layer.id, gravar) { l in
            // mexer em Z ou na rotacao X/Y liga a camada 3D (como a chave do cubo no AE)
            if liga3D && l.kind != .camera { l.is3D = true }
            switch p {
            case .f(let kp): l.transform[keyPath: kp].set(nv, at: time)
            case .v(let kp, let e):
                var v = l.transform[keyPath: kp].value(at: time)
                switch e {
                case 0: v.x = nv
                case 1: v.y = nv
                default:
                    let r = v.x != 0 ? v.y / v.x : 1
                    v = SIMD2(nv, nv * r)
                }
                l.transform[keyPath: kp].set(v, at: time)
            }
        }
    }

    private func info(_ p: Prop) -> (animado: Bool, chave: Bool, easing: Easing?) {
        switch p {
        case .f(let kp):
            let a = layer.transform[keyPath: kp]
            return (!a.keyframes.isEmpty, a.hasKeyframe(at: time), a.easing(at: time))
        case .v(let kp, _):
            let a = layer.transform[keyPath: kp]
            return (!a.keyframes.isEmpty, a.hasKeyframe(at: time), a.easing(at: time))
        }
    }

    private func alternar(_ p: Prop) {
        edit(layer.id, true) { l in
            switch p {
            case .f(let kp): var a = l.transform[keyPath: kp]; toggleKeyframe(&a, at: time); l.transform[keyPath: kp] = a
            case .v(let kp, _): var a = l.transform[keyPath: kp]; toggleKeyframe(&a, at: time); l.transform[keyPath: kp] = a
            }
        }
    }

    private func mudarEasing(_ p: Prop, _ e: Easing) {
        edit(layer.id, true) { l in
            switch p {
            case .f(let kp): l.transform[keyPath: kp].setEasing(at: time, e)
            case .v(let kp, _): l.transform[keyPath: kp].setEasing(at: time, e)
            }
        }
    }

    var body: some View {
        let atual = itens.first { $0.0 == selecionado }?.3
        let inf = atual.map { info($0) }
        PainelComTrilho(onVoltar: onVoltar,
                        onChave: acaoChave(atual),
                        temChave: inf?.chave ?? false,
                        easing: inf?.easing,
                        onEasing: acaoEasing(atual, inf?.easing), mais: {
            Button {
                edit(layer.id, true) { MediaImporter.fit(&$0, in: comp) }
            } label: { Label("Centralizar e caber na tela".loc, systemImage: "arrow.up.left.and.arrow.down.right") }
            Button {
                edit(layer.id, true) { l in
                    l.transform.rotationZ = Animated(0); l.transform.rotationX = Animated(0)
                    l.transform.rotationY = Animated(0); l.transform.skewValue = Animated(SIMD2(0, 0))
                }
            } label: { Label("Zerar rotação e inclinação".loc, systemImage: "arrow.counterclockwise") }
        }, conteudo: {
            ForEach(itens, id: \.0) { it in
                let inf = info(it.3)
                LinhaRegua(titulo: it.1.loc, selecionado: selecionado == it.0,
                           animado: inf.animado, temChave: inf.chave,
                           valor: valor(it.3), faixa: it.2,
                           onSelecionar: { selecionado = it.0 }) { v, g in mudar(it.3, v, g) }
            }
        })
    }

    private func acaoChave(_ p: Prop?) -> (() -> Void)? {
        guard let p else { return nil }
        return { alternar(p) }
    }

    private func acaoEasing(_ p: Prop?, _ e: Easing?) -> ((Easing) -> Void)? {
        guard let p, e != nil else { return nil }
        return { novo in mudarEasing(p, novo) }
    }
}

// MARK: - Opacidade e mesclagem

struct PainelOpacidade: View {
    let layer: Layer
    let time: Float
    let edit: LayerEdit
    let onVoltar: () -> Void

    var body: some View {
        let a = layer.transform.opacity
        PainelComTrilho(onVoltar: onVoltar,
                        onChave: { edit(layer.id, true) { l in
                            var o = l.transform.opacity; toggleKeyframe(&o, at: time); l.transform.opacity = o } },
                        temChave: a.hasKeyframe(at: time),
                        easing: a.easing(at: time),
                        onEasing: acaoEasing(a), mais: {
            Button { edit(layer.id, true) { $0.blendMode = .normal } } label: {
                Label("Mesclagem normal".loc, systemImage: "arrow.counterclockwise")
            }
        }, conteudo: {
            LinhaRegua(titulo: "Opacidade".loc, selecionado: true,
                       animado: !a.keyframes.isEmpty, temChave: a.hasKeyframe(at: time),
                       valor: a.value(at: time), faixa: 0...100, onSelecionar: {}) { v, g in
                edit(layer.id, g) { $0.transform.opacity.set(v, at: time) }
            }
            CabecalhoGrupo(texto: "Mesclagem".loc)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(BlendMode.allCases, id: \.self) { b in
                    let ativo = layer.blendMode == b
                    Button { edit(layer.id, true) { $0.blendMode = b } } label: {
                        Text(b.label).font(.system(size: 13, weight: ativo ? .semibold : .regular))
                            .foregroundStyle(ativo ? Color.black : NovaTheme.text.opacity(0.88))
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(RoundedRectangle(cornerRadius: 9)
                                .fill(ativo ? NovaTheme.accent : CoresPainel.pilula))
                    }
                    .buttonStyle(EncolheAoTocar())
                }
            }
        })
    }

    private func acaoEasing(_ a: Animated<Float>) -> ((Easing) -> Void)? {
        guard a.easing(at: time) != nil else { return nil }
        return { e in edit(layer.id, true) { $0.transform.opacity.setEasing(at: time, e) } }
    }
}
