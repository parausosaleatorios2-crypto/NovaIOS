//
//  HomeView.swift
//  NovaUI
//
//  A casca do app: quatro abas fixas embaixo — Inicio, Projetos, Marketplace e
//  Perfil — com o botao de criar no meio. Essa estrutura vem da string do APK:
//  «Quatro abas fixas embaixo — Início, Projetos, Marketplace e Perfil — com o
//  botão de criar no meio.»
//
//  O ARRANJO VISUAL de cada aba e reconstrucao: o APK nao traz captura dessas
//  telas. Veja Docs/PENDENCIAS.md.
//

import SwiftUI

public enum HomeTab: String, CaseIterable, Identifiable {
    case inicio, projetos, marketplace, perfil
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .inicio: return "Início"; case .projetos: return "Projetos"
        case .marketplace: return "Marketplace"; case .perfil: return "Perfil"
        }
    }
    public var icon: String {
        switch self {
        case .inicio: return "house"; case .projetos: return "square.stack"
        case .marketplace: return "bag"; case .perfil: return "person.crop.circle"
        }
    }
}

public struct HomeView: View {
    @State private var tab: HomeTab = .inicio
    @State private var showingCreate = false
    @StateObject private var store = ProjectStore()

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            NovaTheme.background.ignoresSafeArea()

            Group {
                switch tab {
                case .inicio:      InicioTab(store: store)
                case .projetos:    ProjetosTab(store: store)
                case .marketplace: MarketplaceTab()
                case .perfil:      PerfilTab()
                }
            }
            .padding(.bottom, NovaTheme.Metrics.tabBarHeight)

            tabBar
        }
        .preferredColorScheme(.dark)
        .tint(NovaTheme.accent)
        .sheet(isPresented: $showingCreate) {
            CriarProjetoSheet { comp in
                store.create(composition: comp)
                showingCreate = false
                tab = .projetos
            }
        }
        .task { await store.load() }
    }

    private var tabBar: some View {
        ZStack {
            HStack(spacing: 0) {
                tabButton(.inicio); tabButton(.projetos)
                Spacer().frame(width: 64)
                tabButton(.marketplace); tabButton(.perfil)
            }
            .frame(height: NovaTheme.Metrics.tabBarHeight)
            .background(NovaTheme.surface)
            .overlay(Rectangle().frame(height: 1).foregroundStyle(NovaTheme.line), alignment: .top)

            Button {
                showingCreate = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(NovaTheme.accent))
                    .shadow(color: NovaTheme.accent.opacity(0.35), radius: 10, y: 4)
            }
            .offset(y: -18)
            .accessibilityLabel("Criar projeto".loc)
        }
    }

    private func tabButton(_ t: HomeTab) -> some View {
        Button { tab = t } label: {
            VStack(spacing: 3) {
                Image(systemName: t.icon).font(.system(size: 17))
                Text(t.label.loc).font(.system(size: 9.5))
            }
            .foregroundStyle(tab == t ? NovaTheme.accent : NovaTheme.dim2)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Início

struct InicioTab: View {
    @ObservedObject var store: ProjectStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Nova Editor").font(.system(size: 19, weight: .bold))
                        Text("NovaVision").font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 10)

                // «O início tem uma lâmina só, com a arte da comunidade atrás.»
                RoundedRectangle(cornerRadius: NovaTheme.Metrics.corner)
                    .fill(LinearGradient(colors: [Color(red: 0.11, green: 0.06, blue: 0.20),
                                                  Color(red: 0.05, green: 0.11, blue: 0.20),
                                                  Color(red: 0.03, green: 0.13, blue: 0.11)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 150)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NovaVision").font(.system(size: 15, weight: .semibold))
                            Text("arte da comunidade".loc)
                                .font(.system(size: 11)).foregroundStyle(NovaTheme.dim)
                        }.padding(14)
                    }
                    .overlay(RoundedRectangle(cornerRadius: NovaTheme.Metrics.corner)
                        .strokeBorder(NovaTheme.line2))
                    .padding(.horizontal, 16)

                secao("Projetos", acao: "novo")
                if store.projects.isEmpty {
                    Text("Nenhum projeto ainda".loc)
                        .font(.system(size: 13)).foregroundStyle(NovaTheme.dim2)
                        .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 8) {
                        ForEach(store.projects.prefix(4)) { p in
                            NavigationLink {
                                EditorView(project: p, folder: store.folder(for: p),
                                           onSave: { store.save($0) })
                            } label: { ProjetoRow(project: p) }
                        }
                    }.padding(.horizontal, 16)
                }
                Spacer(minLength: 20)
            }
        }
    }

    func secao(_ titulo: String, acao: String) -> some View {
        HStack {
            Text(titulo.loc).font(.system(size: 13, weight: .semibold))
            Spacer()
            Text(acao.loc).font(.system(size: 11)).foregroundStyle(NovaTheme.accent)
        }.padding(.horizontal, 16)
    }
}

// MARK: - Projetos

struct ProjetosTab: View {
    @ObservedObject var store: ProjectStore
    @State private var busca = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Projetos".loc).font(.system(size: 19, weight: .bold))
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 12)

            if store.projects.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 34)).foregroundStyle(NovaTheme.dim2)
                    Text("Nenhum projeto ainda".loc)
                        .font(.system(size: 14)).foregroundStyle(NovaTheme.dim)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(store.filtered(busca)) { p in
                            NavigationLink { EditorView(project: p, folder: store.folder(for: p), onSave: { store.save($0) }) } label: {
                                ProjetoRow(project: p)
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 16)
                }
                .searchable(text: $busca, prompt: "Procurar".loc)
            }
        }
    }
}

struct ProjetoRow: View {
    let project: NovaProject
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: NovaTheme.Metrics.cornerSmall)
                .fill(NovaTheme.surface2)
                .frame(width: 54, height: 38)
                .overlay(RoundedRectangle(cornerRadius: NovaTheme.Metrics.cornerSmall)
                    .strokeBorder(NovaTheme.line2))
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name).font(.system(size: 13, weight: .medium))
                if let c = project.mainComposition {
                    Text("\(c.width)×\(c.height) · \(Int(c.frameRate)) fps")
                        .font(.system(size: 10)).foregroundStyle(NovaTheme.dim2)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11)).foregroundStyle(NovaTheme.dim2)
        }
        .padding(9)
        .background(RoundedRectangle(cornerRadius: NovaTheme.Metrics.corner).fill(NovaTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: NovaTheme.Metrics.corner).strokeBorder(NovaTheme.line))
    }
}

// MARK: - Marketplace e Perfil

struct MarketplaceTab: View {
    // Comunidade (presets e efeitos), Biblioteca NovaVision e Baixadas: MarketplaceView.swift
    var body: some View { MarketplaceView() }
}

struct PerfilTab: View {
    // Conta NovaVision (Firebase), plano, creditos, cache e links: PerfilView.swift
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Perfil".loc).font(.system(size: 19, weight: .bold))
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 12)
            PerfilView()
        }
    }
}

struct PlaceholderTab: View {
    let titulo: String, icone: String, nota: String
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(titulo.loc).font(.system(size: 19, weight: .bold))
                Spacer()
            }.padding(.horizontal, 16).padding(.vertical, 12)
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: icone).font(.system(size: 34)).foregroundStyle(NovaTheme.dim2)
                Text(nota)
                    .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                    .multilineTextAlignment(.center).padding(.horizontal, 36)
            }
            Spacer()
        }
    }
}
