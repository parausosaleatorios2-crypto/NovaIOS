//
//  ProjectStore.swift
//  NovaUI
//
//  Lista de projetos em disco. Cada projeto e uma pasta em
//  Documentos/NovaEditor/Projetos/<nome>/ com project.json e media/ —
//  o mesmo caminho que o app Android usa para a copia de seguranca.
//

import SwiftUI
import Combine
import os

@MainActor
public final class ProjectStore: ObservableObject {
    @Published public private(set) var projects: [NovaProject] = []
    @Published public private(set) var lastError: String?

    private let log = Logger(subsystem: "com.novavision.editor", category: "ProjectStore")

    public static var root: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("NovaEditor/Projetos", isDirectory: true)
    }

    public init() {}

    public func load() async {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: Self.root, withIntermediateDirectories: true)
        } catch {
            lastError = "Não consegui criar a pasta de projetos: \(error.localizedDescription)"
            return
        }
        let dirs = (try? fm.contentsOfDirectory(at: Self.root,
                                                includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        var out: [NovaProject] = []
        for d in dirs {
            guard (try? d.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
            do {
                out.append(try NovaProjectIO.loadFolder(from: d).project)
            } catch {
                log.error("projeto ilegivel em \(d.lastPathComponent, privacy: .public)")
            }
        }
        projects = out.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    public func filtered(_ q: String) -> [NovaProject] {
        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else { return projects }
        let f = q.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return projects.filter {
            $0.name.folding(options: [.diacriticInsensitive, .caseInsensitive],
                            locale: .current).contains(f)
        }
    }

    @discardableResult
    public func create(composition: Composition) -> NovaProject? {
        let p = NovaProject(name: composition.name, composition: composition)
        let dir = Self.root.appendingPathComponent(safeName(p.name), isDirectory: true)
        do {
            try NovaProjectIO.saveFolder(p, to: dir)
            projects.insert(p, at: 0)
            return p
        } catch {
            lastError = error.localizedDescription
            log.error("criar projeto falhou: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Pasta do projeto em disco (project.json + media/).
    public func folder(for p: NovaProject) -> URL {
        Self.root.appendingPathComponent(safeName(p.name), isDirectory: true)
    }

    public func save(_ p: NovaProject) {
        let dir = Self.root.appendingPathComponent(safeName(p.name), isDirectory: true)
        do {
            try NovaProjectIO.saveFolder(p, to: dir)
            if let i = projects.firstIndex(where: { $0.id == p.id }) { projects[i] = p }
        } catch {
            lastError = error.localizedDescription
        }
    }

    public func delete(_ p: NovaProject) {
        let dir = Self.root.appendingPathComponent(safeName(p.name), isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
        projects.removeAll { $0.id == p.id }
    }

    private func safeName(_ s: String) -> String {
        let bad = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let c = s.components(separatedBy: bad).joined(separator: "-")
        return c.isEmpty ? "projeto" : c
    }
}

// MARK: - Criar projeto

/// «Criar projeto virou folha com abas Projeto e Elemento, tamanho livre,
/// resolução e plano de fundo — inclusive transparente.»
public struct CriarProjetoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nome = "Novo projeto"
    @State private var largura = 1920
    @State private var altura = 1080
    @State private var fps: Double = 30
    @State private var duracao: Double = 10
    @State private var transparente = false
    @State private var aba = 0

    let onCreate: (Composition) -> Void
    public init(onCreate: @escaping (Composition) -> Void) { self.onCreate = onCreate }

    static let presets: [(String, Int, Int)] = [
        ("16:9 · 1080p", 1920, 1080), ("9:16 · Reels", 1080, 1920),
        ("1:1 · Quadrado", 1080, 1080), ("4:5 · Feed", 1080, 1350),
        ("16:9 · 4K", 3840, 2160), ("9:16 · 4K", 2160, 3840),
    ]

    public var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $aba) {
                    Text("Projeto".loc).tag(0)
                    Text("Elemento".loc).tag(1)
                }.pickerStyle(.segmented).listRowBackground(Color.clear)

                if aba == 0 {
                    Section("Projeto".loc) {
                        TextField("Nome".loc, text: $nome)
                    }
                    Section("Tamanho".loc) {
                        ForEach(Self.presets, id: \.0) { p in
                            Button {
                                largura = p.1; altura = p.2
                            } label: {
                                HStack {
                                    Text(p.0)
                                    Spacer()
                                    if largura == p.1 && altura == p.2 {
                                        Image(systemName: "checkmark").foregroundStyle(NovaTheme.accent)
                                    }
                                }
                            }.foregroundStyle(NovaTheme.text)
                        }
                        HStack {
                            Text("Livre".loc)
                            Spacer()
                            TextField("L", value: $largura, format: .number)
                                .frame(width: 64).multilineTextAlignment(.trailing)
                            Text("×").foregroundStyle(NovaTheme.dim2)
                            TextField("A", value: $altura, format: .number)
                                .frame(width: 64).multilineTextAlignment(.trailing)
                        }
                    }
                    Section("Quadros por segundo".loc) {
                        // «Slider de quadros por segundo na criação da composição»
                        HStack {
                            Slider(value: $fps, in: 12...120, step: 1)
                            Text("\(Int(fps))").monospacedDigit().frame(width: 36)
                        }
                    }
                    Section("Duração (s)".loc) {
                        HStack {
                            Slider(value: $duracao, in: 1...600, step: 1)
                            Text("\(Int(duracao))").monospacedDigit().frame(width: 44)
                        }
                    }
                    Section("Plano de fundo".loc) {
                        Toggle("Transparente".loc, isOn: $transparente)
                    }
                } else {
                    Section("Elemento".loc) {
                        Text("A aba Elemento cria uma composição a partir de uma mídia. Depende do seletor de mídia, que ainda não está escrito.".loc)
                            .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(NovaTheme.background)
            .navigationTitle("Criar projeto".loc)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar".loc) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar".loc) {
                        var c = Composition(name: nome,
                                            width: max(16, largura), height: max(16, altura),
                                            frameRate: Float(fps), duration: Float(duracao))
                        c.backgroundColor = transparente ? SIMD4(0,0,0,0) : SIMD4(0,0,0,1)
                        onCreate(c)
                    }.disabled(nome.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
