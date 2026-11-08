//
//  PerfilView.swift
//  NovaUI
//
//  Aba Perfil. Do APK: «Entrar na conta NovaVision», «Criar conta», «Esqueci a
//  senha», «Mostrar a senha», «Foto do perfil», capa (bannerUrl), «Assinatura
//  PRO», «Créditos», «Email, entrada e saída, créditos», «Cache de vídeo 4K,
//  miniaturas e ativos baixados», «Instagram e YouTube entraram no perfil, ao
//  lado do Discord». Dados do perfil: GET /api/auth/profile (AccountProfile).
//

import SwiftUI

struct PerfilView: View {
    @ObservedObject private var conta = NovaConta.shared
    @State private var cache: Int64 = 0
    @State private var baixados = 0
    @State private var confirmarSaida = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if conta.entrou { cabecalho; plano } else { LoginCard() }
                secaoArmazenamento
                secaoComunidade
                secaoSobre
                if conta.entrou {
                    Button(role: .destructive) { confirmarSaida = true } label: {
                        Text("Sair da conta".loc).frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface))
                            .foregroundStyle(NovaTheme.danger)
                    }
                    .padding(.horizontal, 16)
                }
                Spacer(minLength: NovaTheme.Metrics.tabBarHeight + 20)
            }
        }
        .refreshable { await conta.carregarPerfil(); medir() }
        .task { medir(); if conta.entrou && conta.perfil == nil { await conta.carregarPerfil() } }
        .confirmationDialog("Sair da conta?".loc, isPresented: $confirmarSaida, titleVisibility: .visible) {
            Button("Sair".loc, role: .destructive) { conta.sair() }
            Button("Cancelar".loc, role: .cancel) {}
        }
    }

    private func medir() {
        cache = Baixados.tamanhoDoCache()
        baixados = Baixados.todos().count
    }

    // MARK: cabecalho

    private var cabecalho: some View {
        let p = conta.perfil
        return VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let capa = p?.capa { Miniatura(url: capa) }
                    else {
                        LinearGradient(colors: [NovaTheme.flow.opacity(0.55), NovaTheme.accent.opacity(0.25)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 120).clipped()

                HStack(alignment: .bottom, spacing: 12) {
                    Group {
                        if let foto = p?.foto { Miniatura(url: foto) }
                        else {
                            ZStack {
                                NovaTheme.surface2
                                Text(String((conta.nome ?? conta.email ?? "?").prefix(1)).uppercased())
                                    .font(.system(size: 28, weight: .bold)).foregroundStyle(NovaTheme.accent)
                            }
                        }
                    }
                    .frame(width: 72, height: 72).clipShape(Circle())
                    .overlay(Circle().strokeBorder(NovaTheme.background, lineWidth: 3))
                    .offset(y: 30)
                    Spacer()
                }.padding(.horizontal, 16)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(conta.nome ?? p?.name ?? "Sua conta".loc).font(.system(size: 18, weight: .bold))
                    if p?.isPro == true {
                        Text("PRO").font(.system(size: 10, weight: .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(NovaTheme.accent)).foregroundStyle(.black)
                    }
                    if conta.carregandoPerfil { ProgressView().scaleEffect(0.7) }
                }
                Text(conta.email ?? p?.email ?? "").font(.system(size: 12)).foregroundStyle(NovaTheme.dim)
                if let bio = p?.bio, !bio.isEmpty {
                    Text(bio).font(.system(size: 12.5)).foregroundStyle(NovaTheme.text).padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.top, 38)
        }
    }

    private var plano: some View {
        let p = conta.perfil
        return HStack(spacing: 10) {
            celula(p?.isPro == true ? "NovaVision PRO" : "Grátis".loc,
                   (p?.subscriptionStatus).map { "Assinatura: \($0)" } ?? "Plano".loc,
                   icone: "crown")
            celula(numero(p?.credits), "Créditos".loc, icone: "sparkles")
            celula(numero(p?.freeCredits), "Grátis".loc, icone: "gift")
        }
        .padding(.horizontal, 16)
    }

    private func numero(_ v: Double?) -> String {
        guard let v else { return "—" }
        return v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }

    private func celula(_ valor: String, _ rotulo: String, icone: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icone).font(.system(size: 12)).foregroundStyle(NovaTheme.accent)
            Text(valor).font(.system(size: 14, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            Text(rotulo).font(.system(size: 10)).foregroundStyle(NovaTheme.dim).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface))
    }

    // MARK: secoes

    private func secao<C: View>(_ titulo: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo.loc.uppercased()).font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(NovaTheme.dim2).padding(.horizontal, 4).padding(.bottom, 6)
            VStack(spacing: 0) { c() }
                .background(RoundedRectangle(cornerRadius: 12).fill(NovaTheme.surface))
        }
        .padding(.horizontal, 16)
    }

    private func linha(_ titulo: String, _ icone: String, valor: String? = nil) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icone).frame(width: 20).foregroundStyle(NovaTheme.dim)
            Text(titulo.loc).font(.system(size: 13)).foregroundStyle(NovaTheme.text)
            Spacer()
            if let valor { Text(valor).font(.system(size: 12)).foregroundStyle(NovaTheme.dim) }
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
    }

    private var secaoArmazenamento: some View {
        secao("Armazenamento") {
            linha("Baixadas", "arrow.down.circle", valor: "\(baixados)")
            Divider().overlay(NovaTheme.line)
            Button { Baixados.limparCache(); medir() } label: {
                linha("Limpar cache", "trash",
                      valor: ByteCountFormatter.string(fromByteCount: cache, countStyle: .file))
            }
        }
    }

    private var secaoComunidade: some View {
        secao("Comunidade") {
            Link(destination: NovaCloudConfig.discord) { linha("Discord", "bubble.left.and.bubble.right") }
            Divider().overlay(NovaTheme.line)
            Link(destination: NovaCloudConfig.instagram) { linha("Instagram", "camera") }
            Divider().overlay(NovaTheme.line)
            Link(destination: NovaCloudConfig.youtube) { linha("YouTube", "play.rectangle") }
        }
    }

    private var secaoSobre: some View {
        secao("Sobre") {
            linha("Versão", "info.circle", valor: NovaCloudConfig.appVersion)
            Divider().overlay(NovaTheme.line)
            Link(destination: NovaCloudConfig.site) { linha("Site da NovaVision", "globe") }
            Divider().overlay(NovaTheme.line)
            Link(destination: NovaCloudConfig.terms) { linha("Termos de uso", "doc.text") }
            Divider().overlay(NovaTheme.line)
            Link(destination: NovaCloudConfig.privacy) { linha("Política de privacidade", "lock.shield") }
        }
    }
}

// MARK: - Login

struct LoginCard: View {
    @ObservedObject private var conta = NovaConta.shared
    @State private var criando = false
    @State private var nome = ""
    @State private var email = ""
    @State private var senha = ""
    @State private var mostrarSenha = false
    @State private var trabalhando = false
    @State private var mensagem: String?
    @State private var erro = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(criando ? "Criar conta".loc : "Entrar na conta NovaVision".loc)
                .font(.system(size: 18, weight: .bold))
            Text("Ganhe créditos grátis para a IA e baixe do acervo.".loc)
                .font(.system(size: 12)).foregroundStyle(NovaTheme.dim)

            if criando { campo("Nome".loc, text: $nome, icone: "person") }
            campo("E-mail".loc, text: $email, icone: "envelope", teclado: .emailAddress)
            HStack(spacing: 8) {
                Image(systemName: "lock").foregroundStyle(NovaTheme.dim2).frame(width: 18)
                Group {
                    if mostrarSenha { TextField("Senha".loc, text: $senha) }
                    else { SecureField("Senha".loc, text: $senha) }
                }
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                Button { mostrarSenha.toggle() } label: {
                    Image(systemName: mostrarSenha ? "eye.slash" : "eye").foregroundStyle(NovaTheme.dim2)
                }
                .accessibilityLabel(mostrarSenha ? "Esconder a senha".loc : "Mostrar a senha".loc)
            }
            .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface2))

            Button { Task { await enviar() } } label: {
                HStack {
                    if trabalhando { ProgressView().tint(.black) }
                    Text(criando ? "Criar conta".loc : "Entrar".loc).font(.system(size: 14, weight: .bold))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.accent))
                .foregroundStyle(.black)
            }
            .disabled(trabalhando || email.isEmpty || senha.isEmpty)

            HStack {
                Button(criando ? "Já tenho conta".loc : "Criar conta".loc) {
                    criando.toggle(); mensagem = nil
                }
                Spacer()
                if !criando {
                    Button("Esqueci a senha".loc) { Task { await esqueci() } }
                }
            }
            .font(.system(size: 12, weight: .medium)).foregroundStyle(NovaTheme.accent)

            if let mensagem {
                Text(mensagem).font(.system(size: 11.5))
                    .foregroundStyle(erro ? NovaTheme.danger : NovaTheme.dim)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(NovaTheme.surface))
        .padding(.horizontal, 16).padding(.top, 12)
    }

    private func campo(_ titulo: String, text: Binding<String>, icone: String,
                       teclado: UIKeyboardType = .default) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icone).foregroundStyle(NovaTheme.dim2).frame(width: 18)
            TextField(titulo, text: text)
                .keyboardType(teclado)
                .textInputAutocapitalization(teclado == .emailAddress ? .never : .words)
                .autocorrectionDisabled()
        }
        .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(NovaTheme.surface2))
    }

    private func enviar() async {
        trabalhando = true; mensagem = nil; erro = false
        defer { trabalhando = false }
        let e = email.trimmingCharacters(in: .whitespaces)
        do {
            if criando { try await conta.criarConta(nome: nome, email: e, senha: senha) }
            else { try await conta.entrar(email: e, senha: senha) }
            senha = ""
        } catch {
            mensagem = error.localizedDescription; erro = true
        }
    }

    private func esqueci() async {
        let e = email.trimmingCharacters(in: .whitespaces)
        guard !e.isEmpty else { mensagem = "Digite o e-mail primeiro.".loc; erro = true; return }
        do {
            try await conta.esqueciSenha(email: e)
            mensagem = "Mandamos um link para \(e) criar uma senha nova.".loc; erro = false
        } catch {
            mensagem = error.localizedDescription; erro = true
        }
    }
}
