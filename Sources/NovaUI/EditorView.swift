//
//  EditorView.swift
//  NovaUI
//
//  O editor no layout Nova: previa em cima, transporte, timeline e a barra de
//  baixo. A barra vem da string do APK: «O "Link" está na barra de baixo do
//  editor, ao lado de Biblioteca, Legendas e IA.» Drive e Layout tambem moram
//  nela, por outras duas strings. A ORDEM entre eles e reconstrucao.
//
//  Link, Drive e Achar fontes sao extensoes: so aparecem se instaladas
//  (Perfil › Extensões).
//

import SwiftUI
import MetalKit
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

public struct EditorView: View {
    @State private var project: NovaProject
    @State private var time: Float = 0
    @State private var playing = false
    @State private var selectedLayer: UUID?
    @State private var layout: EditorLayout = .nova
    @State private var sheet: EditorSheet?
    @State private var installedExtensions: Set<String> = []   // vazio: nenhuma instalada
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showPicker = false
    @State private var importing = false
    @State private var aviso: String?
    @State private var novoTexto = ""
    @State private var pedindoTexto = false
    @State private var importandoAudio = false
    @State private var manifests: [String: EffectManifest] = [:]
    /// Desfazer/refazer (UndoHistory no APK): um passo por gravacao.
    @State private var undoStack: [NovaProject] = []
    @State private var importandoFFX = false
    /// Qual arquivo o seletor esta pedindo (guardado ate a resposta chegar).
    @State private var seletorFFX = false
    /// Muda a cada batida marcada (vibra).
    @State private var batidaPiscando = false
    /// "Vista da previa" do APK: so a previa, sem a timeline.
    @State private var previaCheia = false
    /// Chip "Full" da previa: ajustar (Full) ou preencher a area (Fill).
    @State private var previaPreenche = false
    @State private var redoStack: [NovaProject] = []
    @State private var lastSaved: NovaProject?
    /// Painel aberto embaixo da timeline (efeitos, parametros, transformar…).
    @State private var painel: PainelAberto?
    @State private var renomeando = false
    @State private var nomeNovo = ""

    @Environment(\.dismiss) private var dismiss

    /// Pasta do projeto (project.json + media/).
    private let folder: URL
    private let onSave: (NovaProject) -> Void
    private var mediaRoot: URL { folder.appendingPathComponent(NovaProjectIO.mediaFolder) }

    /// Modo demonstracao (capturas do CI): roda o roteiro de DemoMode.swift.
    private let demo: Bool

    public init(project: NovaProject, folder: URL, onSave: @escaping (NovaProject) -> Void,
                demo: Bool = false) {
        self.demo = demo
        _project = State(initialValue: project)
        _lastSaved = State(initialValue: project)
        self.folder = folder
        self.onSave = onSave
    }

    private var comp: Composition { project.mainComposition ?? Composition() }

    /// Grava e registra um passo de desfazer (so se algo mudou).
    private func commit() {
        if let last = lastSaved, last != project {
            undoStack.append(last)
            if undoStack.count > 60 { undoStack.removeFirst() }
            redoStack.removeAll()
        }
        lastSaved = project
        onSave(project)
    }

    private func desfazer() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(project)
        project = prev
        lastSaved = prev
        onSave(prev)
        if let id = selectedLayer, comp.layer(id: id) == nil { selectedLayer = nil }
    }

    private func refazer() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(project)
        project = next
        lastSaved = next
        onSave(next)
    }

    /// Altera uma camada. `save` false durante gestos e sliders (grava no fim).
    private func editLayer(_ id: UUID, _ save: Bool, _ change: (inout Layer) -> Void) {
        guard let ci = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first,
              let li = project.compositions[ci].layers.firstIndex(where: { $0.id == id }) else { return }
        change(&project.compositions[ci].layers[li])
        if save { commit() }
    }

    /// Altera a composicao principal e grava o projeto.
    private func editComp(_ change: (inout Composition) -> Void) {
        guard let i = project.compositions.firstIndex(where: { $0.id == project.mainCompositionID })
                ?? project.compositions.indices.first else { return }
        change(&project.compositions[i])
        commit()
    }

    public var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                topBar

                if layout == .afterEffects && geo.size.width < layout.minimumSize.width {
                    janelaPequena(geo.size)
                } else {
                    preview
                    alcaDivisoria
                    transport
                    if !previaCheia {
                    TimelineView(composition: comp, time: $time, selected: $selectedLayer,
                                 editLayer: { id, save, change in editLayer(id, save, change) },
                                 editComp: { change in editComp(change) })
                        .frame(height: alturaTimeline)
                    }
                }

                areaDeBaixo
            }
            .background(NovaTheme.background)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { s in
            Group {
            switch s {
            case .efeitos:
                EffectBrowserView(onPick: { e in aplicarEfeito(e); sheet = nil },
                                  onLook: { l in sheet = nil; Task { await aplicarLook(l) } })
            case .layout:   LayoutPickerSheet(selected: $layout)
            case .exportar: ExportSheet(composition: comp, mediaRoot: mediaRoot, manifests: manifests, time: time)
            case .propriedades(let id):
                LayerPropertiesSheet(comp: comp, layerID: id, time: time, manifests: manifests,
                                     edit: { id, save, change in editLayer(id, save, change) },
                                     mediaRoot: mediaRoot)
            case .propriedadesAba(let id, let aba):
                LayerPropertiesSheet(comp: comp, layerID: id, time: time, manifests: manifests,
                                     edit: { id, save, change in editLayer(id, save, change) },
                                     mediaRoot: mediaRoot, abaInicial: aba)
            case .info(let t, let m): InfoSheet(titulo: t, mensagem: m)
            case .agrupar:
                AgruparSheet(camadas: comp.layers.filter { $0.groupID == nil || $0.groupID == comp.layer(id: selectedLayer ?? UUID())?.groupID },
                             marcadas: Set([selectedLayer].compactMap { $0 })) { ids, nome in
                    var novo: UUID?
                    editComp { novo = $0.group(ids, name: nome) }
                    if let novo { selectedLayer = novo }
                }
            }
            }
            .novaPainel()
        }
        .photosPicker(isPresented: $showPicker, selection: $pickerItems,
                      maxSelectionCount: nil, selectionBehavior: .ordered,
                      matching: .any(of: [.images, .videos]),
                      preferredItemEncoding: .current)
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importar(items) }
        }
        .fileImporter(isPresented: Binding(get: { importandoAudio || importandoFFX },
                                           set: { if !$0 { importandoAudio = false; importandoFFX = false } }),
                      allowedContentTypes: seletorFFX ? AEImportador.tipos : [.audio],
                      allowsMultipleSelection: !seletorFFX) { r in
            let eraFFX = seletorFFX
            importandoAudio = false; importandoFFX = false
            guard case .success(let urls) = r, !urls.isEmpty else { return }
            if eraFFX { Task { await aplicarFFX(urls[0]) } }
            else { Task { await importarAudio(urls) } }
        }
        .alert("Nome da camada".loc, isPresented: $renomeando) {
            TextField("Nome".loc, text: $nomeNovo)
            Button("Cancelar".loc, role: .cancel) {}
            Button("OK") {
                let n = nomeNovo.trimmingCharacters(in: .whitespacesAndNewlines)
                if let id = selectedLayer, !n.isEmpty { editLayer(id, true) { $0.name = n } }
            }
        }
        .alert("Texto".loc, isPresented: $pedindoTexto) {
            TextField("Digite o texto".loc, text: $novoTexto)
            Button("Cancelar".loc, role: .cancel) {}
            Button("Adicionar".loc) { adicionarTexto(novoTexto) }
        }
        .onChange(of: importandoFFX) { _, v in if v { seletorFFX = true } }
        .onChange(of: importandoAudio) { _, v in if v { seletorFFX = false } }
        .task(id: playing) { await tocar() }
        .task { if demo { await roteiroDemo() } }
        .task(id: effectIDs) { await carregarManifestos() }
        .overlay(alignment: .top) {
            if importing || aviso != nil {
                Text(importing ? "Carregando mídia…".loc : (aviso ?? ""))
                    .font(.system(size: 11)).foregroundStyle(NovaTheme.text)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(NovaTheme.surface))
                    .padding(.top, 48)
                    .onTapGesture { aviso = nil }
            }
        }
    }

    // MARK: acoes

    private func importar(_ items: [PhotosPickerItem]) async {
        importing = true
        let start = time
        let r = await MediaImporter.importItems(items, into: mediaRoot,
                                                composition: comp, start: start)
        pickerItems = []
        importing = false
        guard !r.layers.isEmpty else {
            aviso = r.failures.first ?? "Nada foi adicionado".loc
            return
        }
        editComp { c in
            for l in r.layers { c.add(l) }
            // «A composicao termina onde a ultima camada termina» (Alight Motion).
            let fim = c.layers.map(\.endTime).max() ?? c.duration
            c.duration = max(c.duration, fim)
        }
        selectedLayer = r.layers.last?.id
        if r.failures.isEmpty {
            aviso = "Adicionar {0} mídias".loc.replacingOccurrences(of: "{0}", with: "\(r.layers.count)")
        } else {
            aviso = "Entraram {0} de {1}: {2}".loc
                .replacingOccurrences(of: "{0}", with: "\(r.layers.count)")
                .replacingOccurrences(of: "{1}", with: "\(items.count)")
                .replacingOccurrences(of: "{2}", with: r.failures.first ?? "")
        }
        Task { try? await Task.sleep(nanoseconds: 3_000_000_000); aviso = nil }
    }

    private func adicionarTexto(_ t: String) {
        let texto = t.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty else { return }
        var l = Layer(name: String(texto.prefix(24)), kind: .text)
        l.text = texto
        let fs = Float(comp.height) / 10
        l.fontSize = fs
        l.textColor = SIMD4(1, 1, 1, 1)
        let m = MediaContentProvider.measureText(texto, fontName: nil, size: CGFloat(fs))
        let size = SIMD2(Float(m.width), Float(m.height))
        l.size = size
        l.transform.anchorPoint = Animated(size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, min(5, comp.duration - time))
        novoTexto = ""
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func importarAudio(_ urls: [URL]) async {
        importing = true
        defer { importing = false }
        try? FileManager.default.createDirectory(at: mediaRoot, withIntermediateDirectories: true)
        var cursor = time
        var novas: [Layer] = []
        for u in urls {
            let ok = u.startAccessingSecurityScopedResource()
            defer { if ok { u.stopAccessingSecurityScopedResource() } }
            var name = u.lastPathComponent
            var n = 2
            while FileManager.default.fileExists(atPath: mediaRoot.appendingPathComponent(name).path) {
                name = "\(u.deletingPathExtension().lastPathComponent)-\(n).\(u.pathExtension)"; n += 1
            }
            let dst = mediaRoot.appendingPathComponent(name)
            do { try FileManager.default.copyItem(at: u, to: dst) } catch { aviso = error.localizedDescription; continue }
            let secs = Float((try? await AVURLAsset(url: dst).load(.duration).seconds) ?? 0)
            var l = Layer(name: u.deletingPathExtension().lastPathComponent, kind: .audio)
            l.mediaPath = name
            l.duration = max(0.1, secs)
            l.sourceDuration = secs
            l.startTime = cursor
            cursor += l.duration
            novas.append(l)
        }
        guard !novas.isEmpty else { return }
        editComp { c in
            for l in novas { c.add(l) }
            c.duration = max(c.duration, c.layers.map(\.endTime).max() ?? c.duration)
        }
        selectedLayer = novas.last?.id
    }

    private func adicionarForma(_ f: MaskShape) {
        var l = Layer(name: f.label.loc, kind: .shape)
        let lado = min(comp.size.x, comp.size.y) * 0.4
        let size = SIMD2<Float>(lado, lado)
        l.size = size
        l.shapeStyle = ShapeStyle(shape: f)
        l.transform.anchorPoint = Animated(size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func adicionarNulo() {
        var l = Layer(name: "Nulo".loc, kind: .null)
        l.size = SIMD2(100, 100)
        l.transform.anchorPoint = Animated(SIMD2(50, 50))
        l.transform.position = Animated(comp.size / 2)
        l.startTime = 0
        l.duration = comp.duration
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func adicionarAjuste() {
        var l = Layer(name: "Ajuste".loc, kind: .adjustment)
        l.size = comp.size
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
        aviso = "Aplique efeitos nesta camada: valem para tudo que está embaixo.".loc
    }

    private func adicionarMarcador() {
        editComp { c in
            var m = c.markers ?? []
            if !m.contains(where: { abs($0 - time) < 0.01 }) { m.append(time) }
            c.markers = m.sorted()
        }
    }

    private func adicionarSolido() {
        var l = Layer(name: "Sólido".loc, kind: .solid)
        l.solidColor = SIMD4(0.39, 0.33, 0.95, 1)
        l.size = comp.size
        l.transform.anchorPoint = Animated(comp.size / 2)
        l.transform.position = Animated(comp.size / 2)
        l.startTime = time
        l.duration = max(1, comp.duration - time)
        editComp { $0.add(l) }
        selectedLayer = l.id
    }

    private func excluirSelecionada() {
        guard let id = selectedLayer else { return }
        editComp { $0.remove(id: id) }
        selectedLayer = nil
    }

    private func aplicarEfeito(_ e: EffectIndexEntry) {
        guard let id = selectedLayer ?? comp.layers.first?.id else {
            aviso = "Adicione uma camada antes do efeito.".loc
            return
        }
        let novo = AppliedEffect(effectID: e.id)
        editComp { c in
            if let i = c.layers.firstIndex(where: { $0.id == id }) {
                c.layers[i].effects.append(novo)
            }
        }
        selectedLayer = id
        // Abre os parametros do efeito embaixo, como no APK.
        painel = PainelAberto(camada: id, tipo: .efeito(novo.id))
    }

    private var effectIDs: [String] {
        Array(Set(comp.layers.flatMap { $0.effects.map(\.effectID) })).sorted()
    }

    private func carregarManifestos() async {
        var out: [String: EffectManifest] = [:]
        for id in effectIDs {
            if let m = try? await EffectRegistry.shared.manifest(id: id) { out[id] = m }
        }
        manifests = out
    }

    /// Roteiro das capturas do CI (tempos em DemoMode.swift).
    private func roteiroDemo() async {
        // Espera que nao some se a tarefa for cancelada (Task.sleep voltava na
        // hora e o roteiro passava inteiro sem mostrar o navegador).
        func esperar(_ s: Double) async {
            await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
                DispatchQueue.main.asyncAfter(deadline: .now() + s) { c.resume() }
            }
        }
        DemoMode.log.info("demo: roteiro comecou")
        try? await EffectRegistry.shared.load()
        let todos = await EffectRegistry.shared.all
        let efeito = todos.first { $0.id.lowercased().contains("gaussian") && EffectRenderer.isAvailable("fx_\($0.slug)") }
            ?? todos.first { EffectRenderer.isAvailable("fx_\($0.slug)") && EffectVerification.isUsable($0.id) }
        time = 1
        await esperar(4); selectedLayer = comp.layers.first?.id          // texto (camada de cima)
        await esperar(2); sheet = .efeitos                              // 6 s
        DemoMode.log.info("demo: abriu o navegador")
        await esperar(6)                                                 // 12 s: deixa as miniaturas renderizarem e aplica
        if let efeito { aplicarEfeito(efeito); sheet = nil }
        await esperar(5); sheet = nil                                    // 14 s
        await esperar(4); sheet = .exportar                              // 18 s
        await esperar(4); sheet = nil                                    // 22 s
    }

    /// Avanca o tempo enquanto toca, no ritmo da composicao.
    private func tocar() async {
        guard playing else { return }
        if time >= comp.duration { time = 0 }
        // Som da previa: video e audio da composicao, a partir do cursor.
        var player: AVPlayer?
        if let item = await AudioMux.previewItem(composition: comp, mediaRoot: mediaRoot) {
            let p = AVPlayer(playerItem: item)
            await p.seek(to: CMTime(seconds: Double(time), preferredTimescale: 600),
                         toleranceBefore: .zero, toleranceAfter: .zero)
            p.play()
            player = p
        }
        defer { player?.pause() }
        let inicio = Date()
        let t0 = time
        while playing && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 / max(comp.frameRate, 1)))
            let t = t0 + Float(Date().timeIntervalSince(inicio))
            if t >= comp.duration { time = comp.duration; playing = false; break }
            time = t
        }
    }

    // MARK: topo

    /// Topo do editor do APK: seta de voltar, nome do projeto (ponto rosa com
    /// alteracoes nesta sessao), diamante da Nova Pro e o menu redondo.
    private var camadaSelecionada: Layer? { selectedLayer.flatMap { comp.layer(id: $0) } }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                if painelAtual != nil { painel = nil }
                else if selectedLayer != nil { selectedLayer = nil }
                else { dismiss() }
            } label: {
                Image(systemName: "arrow.left").font(.system(size: 19, weight: .medium))
                    .foregroundStyle(NovaTheme.dim)
                    .frame(width: 32, height: 40)
            }
            if let l = camadaSelecionada {
                // Clipe selecionado: nome com lapis, duplicar e apagar (como no APK).
                Button { nomeNovo = l.name; renomeando = true } label: {
                    HStack(spacing: 8) {
                        Text(l.name).font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(NovaTheme.text).lineLimit(1)
                        Image(systemName: "pencil").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(NovaTheme.dim)
                    }
                }
                .buttonStyle(.plain)
                Spacer(minLength: 8)
                Button { duplicarSelecionada() } label: {
                    Image(systemName: "square.on.square.dashed").font(.system(size: 19))
                        .foregroundStyle(NovaTheme.text.opacity(0.85))
                }
                Button { excluirSelecionada() } label: {
                    Image(systemName: "trash").font(.system(size: 19))
                        .foregroundStyle(NovaTheme.danger)
                }
                .padding(.horizontal, 6)
            } else {
                HStack(spacing: 6) {
                    Text(project.name).font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(NovaTheme.text).lineLimit(1)
                    if !undoStack.isEmpty {
                        Circle().fill(Color(red: 0.94, green: 0.34, blue: 0.43)).frame(width: 5, height: 5)
                    }
                }
                Spacer(minLength: 8)
            }
            Button {
                sheet = .info("Nova Pro", "Recursos Pro da Nova (IA, nuvem, marketplace) ficam em Perfil > Conta.".loc)
            } label: {
                Image(systemName: "diamond.fill").font(.system(size: 18))
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.62, green: 0.4, blue: 1),
                                                             Color(red: 0.45, green: 0.3, blue: 0.95)],
                                                    startPoint: .top, endPoint: .bottom))
            }
            Menu {
                Button { sheet = .exportar } label: { Label("Exportar".loc, systemImage: "square.and.arrow.up") }
                Button { sheet = .layout } label: { Label("Layout do editor".loc, systemImage: "rectangle.3.group") }
                Button { adicionarMarcador() } label: { Label("Marcador".loc, systemImage: "bookmark") }
                Button { sheet = .agrupar } label: { Label("Agrupar camadas (pré-comp)…".loc, systemImage: "rectangle.stack.badge.plus") }
                if let id = selectedLayer {
                    Divider()
                    Button { sheet = .propriedades(id) } label: { Label("Propriedades".loc, systemImage: "slider.horizontal.3") }
                    Button { duplicarSelecionada() } label: { Label("Duplicar camada".loc, systemImage: "plus.square.on.square") }
                    if comp.layer(id: id)?.kind == .group {
                        Button { editComp { $0.ungroup(id) }; selectedLayer = nil } label: {
                            Label("Desagrupar".loc, systemImage: "rectangle.stack.badge.minus")
                        }
                    }
                    Button(role: .destructive) { excluirSelecionada() } label: { Label("Apagar camada".loc, systemImage: "trash") }
                }
            } label: {
                Image(systemName: "ellipsis").rotationEffect(.degrees(90))
                    .font(.system(size: 17, weight: .bold)).foregroundStyle(NovaTheme.accent.opacity(0.9))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color(red: 0.07, green: 0.22, blue: 0.26)))
            }
        }
        .padding(.leading, 10).padding(.trailing, 12)
        .frame(height: 56)
        .background(NovaTheme.surface)
    }

    /// Divisoria entre a previa e a faixa, com a alca no meio (como no APK).
    private var alcaDivisoria: some View {
        ZStack {
            Rectangle().fill(NovaTheme.line).frame(height: 1)
            Capsule().fill(NovaTheme.line2).frame(width: 34, height: 4)
        }
        .frame(height: 14)
        .background(NovaTheme.background)
    }

    // MARK: previa

    private var preview: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(red: 0x10/255, green: 0x11/255, blue: 0x18/255)
            PreviewSurface(composition: comp, time: time, mediaRoot: mediaRoot, manifests: manifests)
                .overlay {
                    TransformGizmo(comp: comp, time: time, selected: $selectedLayer,
                                   edit: { id, save, change in editLayer(id, save, change) })
                }
                .aspectRatio(CGFloat(comp.width) / CGFloat(comp.height),
                             contentMode: previaPreenche ? .fill : .fit)
                .overlay(Rectangle().strokeBorder(Color.white.opacity(0.85), lineWidth: 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(previaPreenche ? 0 : 6)
                .clipped()
            Button { previaPreenche.toggle() } label: {
                Text(previaPreenche ? "Fill" : "Full")
                    .font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.text)
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.55)))
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    /// Faixa de transporte do APK (x02.E): 52 dp, cor de superficie, botoes de
    /// largura igual — Desfazer, Refazer, Ponto anterior (J), Reproduzir/Pausar,
    /// Proximo ponto (K), Copiar e colar camada, Vista da previa / acoes.
    private var transport: some View {
        HStack(spacing: 0) {
            botaoFaixa("arrow.uturn.backward", habilitado: !undoStack.isEmpty) { desfazer() }
            botaoFaixa("arrow.uturn.forward", habilitado: !redoStack.isEmpty) { refazer() }
            botaoFaixa("backward.end.fill") { irPara(pontoAnterior()) }
            Button { playing.toggle() } label: {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 26)).foregroundStyle(NovaTheme.text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            botaoFaixa("forward.end.fill") { irPara(proximoPonto()) }
            botaoFaixa("plus.square.fill.on.square.fill", habilitado: selectedLayer != nil) { duplicarSelecionada() }
            // Marcar batida: marcador no cursor (toque no ritmo da musica tocando)
            Button { adicionarMarcador(); batidaPiscando.toggle() } label: {
                Image(systemName: "metronome.fill").font(.system(size: 19))
                    .foregroundStyle(NovaTheme.warning)
                    .scaleEffect(batidaPiscando ? 1.0 : 1.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(EncolheAoTocar())
            .frame(maxWidth: .infinity)
            .sensoryFeedback(.impact(weight: .medium), trigger: batidaPiscando)
            botaoFaixa(previaCheia ? "arrow.down.right.and.arrow.up.left" : "viewfinder") {
                withAnimation(.easeInOut(duration: 0.2)) { previaCheia.toggle() }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 52)
        .background(NovaTheme.surface2)
    }

    private func botaoFaixa(_ icon: String, habilitado: Bool = true, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Image(systemName: icon).font(.system(size: 19))
                .foregroundStyle(habilitado ? NovaTheme.text.opacity(0.85) : NovaTheme.dim2.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .disabled(!habilitado)
        .frame(maxWidth: .infinity)
    }

    /// Pontos de navegacao (J/K do APK): inicio/fim das camadas, keyframes e marcadores.
    private var pontos: [Float] {
        var p: [Float] = [0, comp.duration]
        for l in comp.layers {
            p.append(l.startTime); p.append(l.endTime)
            for k in l.transform.position.keyframes { p.append(k.time) }
            for k in l.transform.scale.keyframes { p.append(k.time) }
            for k in l.transform.rotationZ.keyframes { p.append(k.time) }
            for k in l.transform.opacity.keyframes { p.append(k.time) }
        }
        p.append(contentsOf: comp.markers ?? [])
        return Array(Set(p.map { ($0 * 1000).rounded() / 1000 })).sorted()
    }
    private func pontoAnterior() -> Float { pontos.last { $0 < time - 0.001 } ?? 0 }
    private func proximoPonto() -> Float { pontos.first { $0 > time + 0.001 } ?? comp.duration }
    private func irPara(_ t: Float) { playing = false; time = min(max(0, t), comp.duration) }

    /// Look pronto (Magic Bullet Looks): a cabeca e as ferramentas na camada selecionada.
    private func aplicarLook(_ l: LookPronto) async {
        guard let id = selectedLayer ?? comp.layers.first?.id else {
            aviso = "Adicione uma camada antes do efeito.".loc; return
        }
        let efeitos = await LooksProntos.efeitos(l)
        editComp { c in
            if let i = c.layers.firstIndex(where: { $0.id == id }) { c.layers[i].effects += efeitos }
        }
        await carregarManifestos()
        selectedLayer = id
        painel = PainelAberto(camada: id, tipo: .efeitos)
    }

    /// Preset .ffx do After Effects: os efeitos vao para a camada selecionada.
    private func aplicarFFX(_ url: URL) async {
        guard let id = selectedLayer ?? comp.layers.first?.id, let l = comp.layer(id: id) else {
            aviso = "Adicione uma camada antes do efeito.".loc; return
        }
        do {
            let tam = l.size ?? SIMD2(Float(comp.width), Float(comp.height))
            let (efeitos, animacao, avisos) = try await AEImportador.efeitosDoPreset(url, tamanho: tam)
            var chaves = 0
            let t0 = time
            editComp { c in
                if let i = c.layers.firstIndex(where: { $0.id == id }) {
                    c.layers[i].effects += efeitos
                    if !animacao.isEmpty { chaves = AEImportador.aplicarAnimacao(animacao, em: &c.layers[i], aPartirDe: t0) }
                }
            }
            if !efeitos.isEmpty { await carregarManifestos() }
            var ok = String(format: "%d efeito(s) do preset aplicados em \"%@\".".loc, efeitos.count, l.name)
            if chaves > 0 { ok += " " + String(format: "Animação: %d chaves a partir do cursor.".loc, chaves) }
            aviso = avisos.isEmpty ? ok : ok + "\n\n" + avisos.prefix(8).joined(separator: "\n")
            if !efeitos.isEmpty { selectedLayer = id; painel = PainelAberto(camada: id, tipo: .efeitos) }
        } catch {
            aviso = error.localizedDescription
        }
    }

    /// "Copiar e colar camada" do APK: duplica a camada selecionada logo acima.
    private func duplicarSelecionada() {
        guard let id = selectedLayer, let l = comp.layer(id: id) else { return }
        var copia = l
        copia.id = UUID()
        copia.name = l.name + " " + "cópia".loc
        editComp { c in
            if let i = c.layers.firstIndex(where: { $0.id == id }) { c.layers.insert(copia, at: i) }
        }
        selectedLayer = copia.id
    }

    private func botao(_ icon: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(NovaTheme.dim)
        }
    }

    func timecode(_ t: Float) -> String {
        let total = Int(t * comp.frameRate)
        let f = total % Int(comp.frameRate)
        let s = total / Int(comp.frameRate)
        return String(format: "%d:%02d:%02d.%02d", s/3600, (s/60)%60, s%60, f)
    }

    // MARK: barra de baixo

    /// Painel aberto, se for da camada selecionada.
    private var painelAtual: PainelEditor? {
        guard let p = painel, p.camada == selectedLayer, comp.layer(id: p.camada) != nil else { return nil }
        return p.tipo
    }

    private var alturaTimeline: CGFloat {
        if selectedLayer == nil { return 230 }
        return painelAtual == nil ? 170 : 130
    }

    private var editar: LayerEdit { { id, save, change in editLayer(id, save, change) } }

    /// O que fica embaixo da timeline: a barra (nada selecionado), o painel do
    /// clipe (clipe selecionado) ou o painel aberto a partir dele.
    @ViewBuilder
    private var areaDeBaixo: some View {
        if let l = camadaSelecionada {
            switch painelAtual {
            case .some(.efeitos):
                PainelEfeitos(layer: l, manifests: manifests, edit: editar,
                              onVoltar: { painel = nil },
                              onAdicionar: { sheet = .efeitos },
                              onAbrir: { fx in painel = PainelAberto(camada: l.id, tipo: .efeito(fx)) })
                    .frame(height: 300)
            case .some(.efeito(let fx)):
                PainelParametros(layer: l, fxID: fx,
                                 manifest: l.effects.first(where: { $0.id == fx }).flatMap { manifests[$0.effectID] },
                                 time: time, edit: editar,
                                 onVoltar: { painel = PainelAberto(camada: l.id, tipo: .efeitos) },
                                 onAbrirCompleto: { sheet = .propriedadesAba(l.id, "efeitos") })
                    .frame(height: 300)
            case .some(.transformar):
                PainelTransformar(layer: l, comp: comp, time: time, edit: editar, onVoltar: { painel = nil })
                    .frame(height: 300)
            case .some(.opacidade):
                PainelOpacidade(layer: l, time: time, edit: editar, onVoltar: { painel = nil })
                    .frame(height: 300)
            case .none:
                PainelClipe(layer: l) { acaoClipe($0, l) }
            }
        } else {
            bottomBar
        }
    }

    private func acaoClipe(_ id: String, _ l: Layer) {
        let dentro = time > l.startTime + 0.01 && time < l.endTime - 0.01
        switch id {
        case "restaurar":
            editLayer(l.id, true) { MediaImporter.fit(&$0, in: comp) }
        case "aparaInicio":
            guard dentro else { aviso = "Ponha o cursor dentro do clipe.".loc; return }
            let t = time
            editLayer(l.id, true) { c in
                let d = t - c.startTime
                c.startTime = t
                c.duration -= d
                c.mediaOffset += d * c.speed
            }
        case "aparaFim":
            guard dentro else { aviso = "Ponha o cursor dentro do clipe.".loc; return }
            let t = time
            editLayer(l.id, true) { $0.duration = t - $0.startTime }
        case "dividir":
            guard dentro else { aviso = "Ponha o cursor dentro do clipe.".loc; return }
            var b = l
            b.id = UUID()
            let d = time - l.startTime
            b.startTime = time
            b.duration = l.duration - d
            b.mediaOffset = l.mediaOffset + d * l.speed
            editComp { c in
                if let i = c.layers.firstIndex(where: { $0.id == l.id }) {
                    c.layers[i].duration = d
                    c.layers.insert(b, at: i)
                }
            }
            selectedLayer = b.id
        case "som":
            editLayer(l.id, true) { $0.muted = !($0.muted ?? false) }
        case "transformar":
            painel = PainelAberto(camada: l.id, tipo: .transformar)
        case "opacidade":
            painel = PainelAberto(camada: l.id, tipo: .opacidade)
        case "efeitos":
            painel = PainelAberto(camada: l.id, tipo: .efeitos)
        default:
            // Preencher, Borda e sombra, Editar forma, Mascara, Animar, Velocidade:
            // o painel completo, ja na aba certa.
            sheet = .propriedadesAba(l.id, id)
        }
    }

    /// Barra de baixo sem nada selecionado, como na captura do APK: Adicionar,
    /// IA, Biblioteca, Legendas e Layout, de largura igual.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(NovaTheme.line).frame(height: 1)
            HStack(spacing: 0) {
                Menu {
                    Button { showPicker = true } label: { Label("Mídia".loc, systemImage: "photo.on.rectangle") }
                    Button { pedindoTexto = true } label: { Label("Texto".loc, systemImage: "textformat") }
                    Menu {
                        Button { adicionarForma(.rectangle) } label: { Label("Retângulo".loc, systemImage: "rectangle") }
                        Button { adicionarForma(.ellipse) } label: { Label("Elipse".loc, systemImage: "circle") }
                        Button { adicionarForma(.star) } label: { Label("Estrela".loc, systemImage: "star") }
                        Button { adicionarForma(.polygon) } label: { Label("Polígono".loc, systemImage: "hexagon") }
                    } label: { Label("Forma".loc, systemImage: "square.on.circle") }
                    Button { adicionarSolido() } label: { Label("Sólido".loc, systemImage: "square.fill") }
                    Button { importandoAudio = true } label: { Label("Áudio".loc, systemImage: "music.note") }
                    Button { adicionarAjuste() } label: { Label("Camada de ajuste".loc, systemImage: "slider.horizontal.below.rectangle") }
                    Button { adicionarNulo() } label: { Label("Nulo".loc, systemImage: "scope") }
                    Divider()
                    Button { importandoFFX = true } label: {
                        Label("Preset do After Effects (.ffx)".loc, systemImage: "wand.and.rays")
                    }
                } label: {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 13)
                            .fill(NovaTheme.accent)
                            .frame(width: 54, height: 42)
                            .overlay(Image(systemName: "plus").font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(Color.black))
                        Text("Adicionar".loc).font(.system(size: 13, weight: .medium)).foregroundStyle(NovaTheme.accent)
                    }
                    .frame(maxWidth: .infinity)
                }
                Menu {
                    ForEach(ferramentasIA, id: \.0) { f in
                        Button { tocarFerramenta(f.0) } label: { Label(f.1.loc, systemImage: f.2) }
                    }
                } label: {
                    itemBarra("sparkles", "IA")
                }
                Button { showPicker = true } label: { itemBarra("icloud.and.arrow.down.fill", "Biblioteca") }
                Button { tocarFerramenta("legendas") } label: { itemBarra("captions.bubble.fill", "Legendas") }
                Button { sheet = .layout } label: { itemBarra("square.grid.2x2.fill", "Layout") }
            }
            .buttonStyle(EncolheAoTocar())
            .frame(height: 84)
            .background(NovaTheme.surface)
        }
    }

    private func itemBarra(_ icone: String, _ nome: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icone).font(.system(size: 24))
                .foregroundStyle(NovaTheme.text.opacity(0.72))
                .frame(height: 36)
            Text(nome.loc).font(.system(size: 13)).foregroundStyle(NovaTheme.text.opacity(0.72))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    /// Ferramentas de IA do APK (enum s22), no menu do botao IA.
    private var ferramentasIA: [(String, String, String)] {
        [("ia", "Assistente", "sparkles"),
         ("removerFundo", "Remover BG", "person.crop.rectangle"),
         ("separar", "Separar partes", "square.split.2x2"),
         ("upscale", "Aumentar resolução", "sparkle.magnifyingglass"),
         ("colorizar", "Colorizar", "paintpalette"),
         ("profundidade", "Profundidade (nuvem)", "cube.transparent"),
         ("link", "Link", "link"),
         ("drive", "Drive", "externaldrive")]
    }

    private func tocarFerramenta(_ id: String) {
        let precisaConta = ["ia", "legendas", "removerFundo", "separar", "upscale", "colorizar", "profundidade"]
        let nome = ferramentasIA.first(where: { $0.0 == id })?.1 ?? (id == "legendas" ? "Legendas" : id)
        sheet = .info(nome.loc,
                      precisaConta.contains(id)
                        ? "No Android esta ferramenta roda no servidor da Nova (com a sua conta). Entre em Perfil › Conta para usar.".loc
                        : "Instale a extensão em Perfil › Extensões.".loc)
    }

    // MARK: janela pequena

    private func janelaPequena(_ size: CGSize) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "rectangle.landscape.rotate")
                .font(.system(size: 30)).foregroundStyle(NovaTheme.warning)
            Text(String(format: "Esta janela tem %.0f × %.0f pt. O layout %@ precisa de pelo menos %.0f × %.0f.",
                        size.width, size.height, layout.label,
                        layout.minimumSize.width, layout.minimumSize.height))
                .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                .multilineTextAlignment(.center).padding(.horizontal, 30)
            Button("Voltar para o layout Nova".loc) { layout = .nova }
                .font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sheets

enum EditorSheet: Identifiable {
    case efeitos, layout, exportar, agrupar
    case propriedades(UUID)
    case propriedadesAba(UUID, String)
    case info(String, String)
    var id: String {
        switch self {
        case .efeitos: return "efeitos"; case .layout: return "layout"; case .agrupar: return "agrupar"
        case .exportar: return "exportar"; case .info(let t, _): return "info-\(t)"
        case .propriedades(let u): return "prop-\(u.uuidString)"
        case .propriedadesAba(let u, let a): return "prop-\(u.uuidString)-\(a)"
        }
    }
}

struct InfoSheet: View {
    let titulo: String, mensagem: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Spacer()
                Text(mensagem).font(.system(size: 13)).foregroundStyle(NovaTheme.dim)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NovaTheme.background)
            .navigationTitle(titulo).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button("Fechar".loc) { dismiss() } } }
        }
        .presentationDetents([.height(240)])
        .preferredColorScheme(.dark)
    }
}

struct LayoutPickerSheet: View {
    @Binding var selected: EditorLayout
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(EditorLayout.allCases) { l in
                Button {
                    selected = l; dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(l.label).font(.system(size: 14, weight: .medium))
                            Text(l.note.loc).font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                        }
                        Spacer()
                        if selected == l {
                            Image(systemName: "checkmark").foregroundStyle(NovaTheme.accent)
                        }
                    }
                }.foregroundStyle(NovaTheme.text).listRowBackground(NovaTheme.surface)
            }
            .scrollContentBackground(.hidden).background(NovaTheme.background)
            .navigationTitle("Layout do editor".loc).navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Fundo xadrez

struct CheckerboardBackground: View {
    var body: some View {
        Canvas { ctx, size in
            let s: CGFloat = 8
            let a = Color(red: 0.04, green: 0.05, blue: 0.09)
            let b = Color(red: 0.03, green: 0.04, blue: 0.07)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(b))
            var y: CGFloat = 0, row = 0
            while y < size.height {
                var x: CGFloat = (row % 2 == 0) ? 0 : s
                while x < size.width {
                    ctx.fill(Path(CGRect(x: x, y: y, width: s, height: s)), with: .color(a))
                    x += s * 2
                }
                y += s; row += 1
            }
        }
    }
}

/// Botao de ferramenta da barra do editor, com as medidas do APK (x02.D).
struct FerramentaBotao: View {
    let label: String
    let icon: String
    let ativa: Bool
    let habilitada: Bool
    let acao: () -> Void
    var body: some View {
        let cor: Color = !habilitada ? NovaTheme.text.opacity(0.28) : (ativa ? NovaTheme.accent : NovaTheme.text)
        Button(action: acao) {
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(NovaTheme.accent.opacity(ativa ? 0.18 : 0))
                    .overlay(RoundedRectangle(cornerRadius: 11)
                        .stroke(NovaTheme.accent.opacity(ativa ? 0.9 : 0), lineWidth: ativa ? 0.9 : 0))
                    .frame(width: 46, height: 34)
                    .overlay(Image(systemName: icon).font(.system(size: 19)).foregroundStyle(cor))
                Text(label).font(.system(size: 11)).foregroundStyle(cor)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .padding(.horizontal, 2)
            }
            .frame(width: 66)
        }
        .buttonStyle(EncolheAoTocar())
        .disabled(!habilitada)
    }
}

/// Encolhe um pouco enquanto o dedo esta no botao, sem roubar o arraste da
/// rolagem (o gesto de antes travava a barra de ferramentas).
struct EncolheAoTocar: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// "Agrupar" (a pre-comp do AE): marca as camadas e da o nome do grupo.
struct AgruparSheet: View {
    let camadas: [Layer]
    @State var marcadas: Set<UUID>
    let onAgrupar: ([UUID], String) -> Void
    @State private var nome = "Grupo"
    @Environment(\.dismiss) private var dismiss

    init(camadas: [Layer], marcadas: Set<UUID>, onAgrupar: @escaping ([UUID], String) -> Void) {
        self.camadas = camadas
        _marcadas = State(initialValue: marcadas)
        self.onAgrupar = onAgrupar
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do grupo".loc, text: $nome)
                }
                .novaLinhas()
                Section("Camadas".loc) {
                    ForEach(camadas) { l in
                        Button {
                            if marcadas.contains(l.id) { marcadas.remove(l.id) } else { marcadas.insert(l.id) }
                        } label: {
                            HStack {
                                Image(systemName: marcadas.contains(l.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(marcadas.contains(l.id) ? NovaTheme.accent : NovaTheme.dim2)
                                Text(l.name).foregroundStyle(NovaTheme.text)
                                Spacer()
                                Text(l.kind.label.loc).font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
                            }
                        }
                    }
                }
                .novaLinhas()
                Section {
                    Text("As camadas marcadas viram um grupo que se move, recebe efeitos e mesclagem como uma camada só — como a pré-composição do After Effects. Desfaça em ⋮ › Desagrupar.".loc)
                        .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                }
                .listRowBackground(Color.clear)
            }
            .novaForm()
            .navigationTitle("Agrupar camadas".loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar".loc) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Agrupar".loc) {
                        // na ordem da timeline
                        let ids = camadas.map(\.id).filter { marcadas.contains($0) }
                        onAgrupar(ids, nome.isEmpty ? "Grupo" : nome)
                        dismiss()
                    }
                    .disabled(marcadas.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
