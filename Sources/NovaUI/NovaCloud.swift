//
//  NovaCloud.swift
//  NovaUI
//
//  Conta NovaVision e servidor do app, reconstruidos do APK 0.918.0 com o REA:
//
//  - Login: Firebase Identity Toolkit (projeto novavisionhub-be30f), as mesmas
//    rotas do Android: accounts:signInWithPassword / signUp / sendOobCode /
//    lookup, e securetoken.googleapis.com/v1/token para renovar.
//    DTOs do APK: SenhaRequest{email,password,returnSecureToken},
//    FirebaseAuthResponse{idToken,refreshToken,expiresIn,localId,email,photoUrl,
//    displayName}, RefreshResponse{id_token,refresh_token,expires_in,user_id},
//    OobRequest{email,requestType}, FirebaseErrorEnvelope{error{message,code}}.
//  - Servidor: novavisionhub-3.onrender.com, com o idToken do Firebase como
//    "Authorization: Bearer". POST /api/auth/sync {name, deviceId};
//    GET /api/auth/profile -> AccountProfile.
//  - Comunidade (publica para listar): GET /api/v1/presets e /api/v1/efeitos
//    (?q= busca, ?category=, ?sort=popular, ?limit=); POST .../{id}/like e
//    .../{id}/download (com conta).
//  - Biblioteca (com conta): GET /api/v1/library -> LibraryEnvelope.
//
//  O login com Google do Android usa um client id registrado para o app Android,
//  que nao vale no iOS; aqui a conta entra por e-mail e senha (mesma conta
//  Firebase).
//

import Foundation
import Security
import SwiftUI
import UIKit
import os

// MARK: - Configuracao

enum NovaCloudConfig {
    /// Chave Web publica do Firebase, a mesma embutida no APK.
    static let firebaseKey = "AIzaSyBrsTh-Fdw1pECuqQKUgrBGBQNk0oMotcY"
    static let hub = URL(string: "https://novavisionhub-3.onrender.com")!
    static let site = URL(string: "https://www.novavisionhub.com")!
    static let discord = URL(string: "https://discord.gg/VSmK8npHUe")!
    static let instagram = URL(string: "https://www.instagram.com/novavisionhub/")!
    static let youtube = URL(string: "https://www.youtube.com/@NovaVisionHubb")!
    static let privacy = URL(string: "https://www.novavisionhub.com/privacy-policy")!
    static let terms = URL(string: "https://www.novavisionhub.com/terms-of-use")!
    static let appVersion = "0.918.0"
}

enum NovaCloudError: LocalizedError {
    case http(Int, String)
    case auth(String)
    case notSignedIn
    case decode(String)

    var errorDescription: String? {
        switch self {
        case .http(let c, let m): return m.isEmpty ? "O servidor respondeu \(c)." : m
        case .auth(let m): return m
        case .notSignedIn: return "Entre na sua conta (Perfil) para continuar.".loc
        case .decode(let m): return "Resposta inesperada do servidor: \(m)"
        }
    }
}

// MARK: - Modelos (nomes de campo do APK)

public struct AutorDTO: Codable, Hashable, Sendable {
    public let name: String?
    public let avatarUrl: String?
}

/// PresetDaComunidade e EfeitoDaComunidade do APK, num tipo so.
public struct ItemDaComunidade: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let nameEn: String?
    public let category: String?
    public let tags: [String]?
    public let description: String?
    public let thumbnailUrl: String?
    public var downloads: Int?
    public var likes: Int?
    public var liked: Bool?
    public let createdAt: String?
    public let author: AutorDTO?
}

struct ListaDTO<T: Decodable>: Decodable {
    let success: Bool?
    let data: [T]?
    let message: String?
}

struct CurtidaDTO: Decodable {
    let success: Bool?
    let liked: Bool?
    let likes: Int?
}

/// AccountProfile do APK.
public struct PerfilDaConta: Codable, Sendable, Equatable {
    public var name: String?
    public var email: String?
    public var plan: String?
    public var avatarUrl: String?
    public var photoURL: String?
    public var bannerUrl: String?
    public var bio: String?
    public var balance: Double?
    public var credits: Double?
    public var freeCredits: Double?
    public var cycleState: String?
    public var subscriptionStatus: String?

    enum CodingKeys: String, CodingKey {
        case name, email, plan, avatarUrl, photoURL, bannerUrl, bio, balance, credits,
             freeCredits, cycleState, subscriptionStatus
    }

    /// Tolerante: numero pode vir como texto, campo desconhecido vira nil.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func s(_ k: CodingKeys) -> String? {
            if let v = try? c.decodeIfPresent(String.self, forKey: k) { return v }
            if let v = try? c.decodeIfPresent(Double.self, forKey: k) { return String(v) }
            return nil
        }
        func n(_ k: CodingKeys) -> Double? {
            if let v = try? c.decodeIfPresent(Double.self, forKey: k) { return v }
            if let v = try? c.decodeIfPresent(String.self, forKey: k) { return Double(v) }
            return nil
        }
        name = s(.name); email = s(.email); plan = s(.plan); avatarUrl = s(.avatarUrl)
        photoURL = s(.photoURL); bannerUrl = s(.bannerUrl); bio = s(.bio)
        balance = n(.balance); credits = n(.credits); freeCredits = n(.freeCredits)
        cycleState = s(.cycleState); subscriptionStatus = s(.subscriptionStatus)
    }

    public var foto: URL? { (avatarUrl ?? photoURL).flatMap(URL.init(string:)) }
    public var capa: URL? { bannerUrl.flatMap(URL.init(string:)) }
    public var isPro: Bool {
        let p = (plan ?? "").lowercased(), s = (subscriptionStatus ?? "").lowercased()
        return p.contains("pro") || s == "active" || s == "ativa" || s == "trialing"
    }
}

/// LibraryAsset do APK (so os campos que a tela usa).
public struct ItemDaBiblioteca: Codable, Identifiable, Hashable, Sendable {
    public var id: String { s3Key ?? url ?? displayName ?? UUID().uuidString }
    public let s3Key: String?
    public let displayName: String?
    public let category: String?
    public let accessLevel: String?
    public let mediaKind: String?
    public let assetType: String?
    public let tags: [String]?
    public let previewKey: String?
    public let posterKey: String?
    public let url: String?
    public let videoUrl: String?
    public let downloadUrl: String?
}

struct BibliotecaDTO: Decodable {
    struct Paginacao: Decodable { let total: Int?; let page: Int?; let limit: Int?; let totalPages: Int? }
    let success: Bool?
    let data: [ItemDaBiblioteca]?
    let pagination: Paginacao?
    let message: String?
}

// MARK: - Keychain (refresh token)

enum Chaveiro {
    private static let service = "com.novavision.editor.conta"

    static func set(_ value: String?, for key: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: key]
        SecItemDelete(base as CFDictionary)
        guard let value, let data = value.data(using: .utf8) else { return }
        var add = base
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: key,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }
}

// MARK: - Conta

@MainActor
public final class NovaConta: ObservableObject {
    public static let shared = NovaConta()

    @Published public private(set) var email: String?
    @Published public private(set) var nome: String?
    @Published public private(set) var uid: String?
    @Published public private(set) var perfil: PerfilDaConta?
    @Published public private(set) var carregandoPerfil = false

    private var idToken: String?
    private var expira: Date = .distantPast
    private let log = Logger(subsystem: "com.novavision.editor", category: "Conta")

    public var entrou: Bool { uid != nil }

    private init() {
        uid = UserDefaults.standard.string(forKey: "conta.uid")
        email = UserDefaults.standard.string(forKey: "conta.email")
        nome = UserDefaults.standard.string(forKey: "conta.nome")
        if uid != nil && Chaveiro.get("refresh") == nil { limparLocal() }
    }

    // MARK: entrar / criar / sair

    public func entrar(email: String, senha: String) async throws {
        let r = try await firebase("accounts:signInWithPassword",
                                   ["email": email, "password": senha, "returnSecureToken": true])
        aplicar(r)
        await sincronizar()
        await carregarPerfil()
    }

    public func criarConta(nome: String, email: String, senha: String) async throws {
        guard senha.count >= 6 else {
            throw NovaCloudError.auth("A senha precisa de pelo menos 6 caracteres.".loc)
        }
        var r = try await firebase("accounts:signUp",
                                   ["email": email, "password": senha, "returnSecureToken": true])
        if !nome.isEmpty, let token = r["idToken"] as? String {
            if let u = try? await firebase("accounts:update",
                                           ["idToken": token, "displayName": nome,
                                            "returnSecureToken": true]) {
                r.merge(u) { _, n in n }
            }
            r["displayName"] = nome
        }
        aplicar(r)
        await sincronizar()
        await carregarPerfil()
    }

    public func esqueciSenha(email: String) async throws {
        _ = try await firebase("accounts:sendOobCode",
                               ["email": email, "requestType": "PASSWORD_RESET"])
    }

    public func sair() {
        limparLocal()
    }

    private func limparLocal() {
        Chaveiro.set(nil, for: "refresh")
        for k in ["conta.uid", "conta.email", "conta.nome"] { UserDefaults.standard.removeObject(forKey: k) }
        uid = nil; email = nil; nome = nil; perfil = nil; idToken = nil; expira = .distantPast
    }

    private func aplicar(_ r: [String: Any]) {
        idToken = r["idToken"] as? String
        if let s = r["expiresIn"] as? String, let n = Double(s) {
            expira = Date().addingTimeInterval(n - 60)
        }
        if let rt = r["refreshToken"] as? String { Chaveiro.set(rt, for: "refresh") }
        uid = (r["localId"] as? String) ?? uid
        email = (r["email"] as? String) ?? email
        if let n = r["displayName"] as? String, !n.isEmpty { nome = n }
        let d = UserDefaults.standard
        d.set(uid, forKey: "conta.uid"); d.set(email, forKey: "conta.email"); d.set(nome, forKey: "conta.nome")
    }

    // MARK: token

    /// idToken valido, renovado pelo refresh token quando vence (1 hora no Firebase).
    public func token() async throws -> String {
        if let idToken, Date() < expira { return idToken }
        guard let rt = Chaveiro.get("refresh") else { throw NovaCloudError.notSignedIn }
        var req = URLRequest(url: URL(string: "https://securetoken.googleapis.com/v1/token?key=\(NovaCloudConfig.firebaseKey)")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let corpo = "grant_type=refresh_token&refresh_token=" +
            (rt.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? rt)
        req.httpBody = corpo.data(using: .utf8)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (resp as? HTTPURLResponse)?.statusCode == 200, let t = json["id_token"] as? String else {
            limparLocal()
            throw NovaCloudError.auth("Sua sessão expirou. Entre de novo.".loc)
        }
        idToken = t
        if let s = json["expires_in"] as? String, let n = Double(s) { expira = Date().addingTimeInterval(n - 60) }
        if let nrt = json["refresh_token"] as? String { Chaveiro.set(nrt, for: "refresh") }
        return t
    }

    // MARK: servidor

    /// POST /api/auth/sync {name, deviceId}: cria/atualiza a conta no servidor.
    func sincronizar() async {
        let device = UIDevice.current.identifierForVendor?.uuidString ?? "ios"
        _ = try? await NovaHub.shared.post("/api/auth/sync",
                                           body: ["name": nome ?? email ?? "", "deviceId": device],
                                           auth: true)
    }

    public func carregarPerfil() async {
        guard entrou else { return }
        carregandoPerfil = true
        defer { carregandoPerfil = false }
        do {
            let data = try await NovaHub.shared.get("/api/auth/profile", auth: true)
            perfil = try NovaHub.decodeFlexivel(PerfilDaConta.self, data,
                                                chaves: ["profile", "user", "data"])
            if let n = perfil?.name, !n.isEmpty { nome = n }
        } catch {
            log.error("perfil falhou: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: Firebase

    private func firebase(_ rota: String, _ corpo: [String: Any]) async throws -> [String: Any] {
        var req = URLRequest(url: URL(string: "https://identitytoolkit.googleapis.com/v1/\(rota)?key=\(NovaCloudConfig.firebaseKey)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: corpo)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if (resp as? HTTPURLResponse)?.statusCode == 200 { return json }
        let codigo = ((json["error"] as? [String: Any])?["message"] as? String) ?? "ERRO"
        throw NovaCloudError.auth(Self.traduzir(codigo))
    }

    static func traduzir(_ codigo: String) -> String {
        let c = codigo.split(separator: " ").first.map(String.init) ?? codigo
        switch c {
        case "EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
            return "E-mail ou senha incorretos.".loc
        case "EMAIL_EXISTS": return "Já existe uma conta com esse e-mail.".loc
        case "INVALID_EMAIL": return "Esse e-mail não é válido.".loc
        case "WEAK_PASSWORD": return "A senha precisa de pelo menos 6 caracteres.".loc
        case "USER_DISABLED": return "Essa conta foi desativada.".loc
        case "TOO_MANY_ATTEMPTS_TRY_LATER": return "Muitas tentativas. Tente de novo daqui a pouco.".loc
        case "MISSING_PASSWORD": return "Digite a senha.".loc
        default: return codigo
        }
    }
}

// MARK: - Servidor NovaVision

public final class NovaHub: @unchecked Sendable {
    public static let shared = NovaHub()
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 60     // o servidor do Render demora para acordar
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: c)
    }()

    func request(_ path: String, query: [String: String] = [:], method: String = "GET",
                 body: [String: Any]? = nil, auth: Bool) async throws -> Data {
        var comp = URLComponents(url: NovaCloudConfig.hub.appendingPathComponent(path),
                                 resolvingAgainstBaseURL: false)!
        if !query.isEmpty {
            comp.queryItems = query.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comp.url!)
        req.httpMethod = method
        req.setValue("NovaEditor-iOS/\(NovaCloudConfig.appVersion)", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if auth {
            let t = try await NovaConta.shared.token()
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        } else if let t = try? await NovaConta.shared.tokenSeEntrou() {
            // Listas publicas: com conta, o servidor marca o que voce curtiu.
            req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        let (data, resp) = try await session.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            let msg = ((try? JSONSerialization.jsonObject(with: data)) as? [String: Any])?["message"] as? String
            if code == 401 { throw NovaCloudError.notSignedIn }
            throw NovaCloudError.http(code, msg ?? "")
        }
        return data
    }

    func get(_ path: String, query: [String: String] = [:], auth: Bool = false) async throws -> Data {
        try await request(path, query: query, auth: auth)
    }

    func post(_ path: String, body: [String: Any] = [:], auth: Bool = true) async throws -> Data {
        try await request(path, method: "POST", body: body, auth: auth)
    }

    /// Decodifica `T` na raiz ou dentro de uma das `chaves` (o servidor varia o envelope).
    static func decodeFlexivel<T: Decodable>(_ t: T.Type, _ data: Data, chaves: [String]) throws -> T {
        let dec = JSONDecoder()
        if let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
            for k in chaves {
                if let inner = obj[k] as? [String: Any],
                   let d = try? JSONSerialization.data(withJSONObject: inner),
                   let v = try? dec.decode(T.self, from: d) { return v }
            }
        }
        do { return try dec.decode(T.self, from: data) }
        catch { throw NovaCloudError.decode(error.localizedDescription) }
    }

    // MARK: comunidade

    public enum Tipo: String, CaseIterable, Sendable {
        case presets, efeitos
        var rota: String { self == .presets ? "/api/v1/presets" : "/api/v1/efeitos" }
    }

    public func comunidade(_ tipo: Tipo, busca: String = "", categoria: String? = nil,
                           populares: Bool = false, limite: Int = 60) async throws -> [ItemDaComunidade] {
        var q = ["limit": "\(limite)"]
        if !busca.trimmingCharacters(in: .whitespaces).isEmpty { q["q"] = busca }
        if let categoria { q["category"] = categoria }
        if populares { q["sort"] = "popular" }
        let data = try await get(tipo.rota, query: q)
        let r = try JSONDecoder().decode(ListaDTO<ItemDaComunidade>.self, from: data)
        return r.data ?? []
    }

    public func curtir(_ tipo: Tipo, id: String) async throws -> (liked: Bool, likes: Int?) {
        let data = try await post("\(tipo.rota)/\(id)/like")
        let r = try JSONDecoder().decode(CurtidaDTO.self, from: data)
        return (r.liked ?? true, r.likes)
    }

    /// POST .../download. Preset devolve {name, payload}; efeito devolve {name, xml}.
    public func baixar(_ tipo: Tipo, item: ItemDaComunidade) async throws -> URL {
        let data = try await post("\(tipo.rota)/\(item.id)/download")
        guard let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw NovaCloudError.decode("download")
        }
        if let ok = obj["success"] as? Bool, !ok {
            throw NovaCloudError.http(200, obj["message"] as? String ?? "")
        }
        return try Baixados.salvar(tipo: tipo, item: item, resposta: obj)
    }

    // MARK: biblioteca

    public func biblioteca(busca: String = "", pagina: Int = 1) async throws -> [ItemDaBiblioteca] {
        var q = ["page": "\(pagina)", "limit": "40"]
        if !busca.isEmpty { q["q"] = busca }
        let data = try await get("/api/v1/library", query: q, auth: true)
        return try JSONDecoder().decode(BibliotecaDTO.self, from: data).data ?? []
    }
}

extension NovaConta {
    /// Token so se ja entrou; nao forca login.
    nonisolated func tokenSeEntrou() async throws -> String? {
        guard Chaveiro.get("refresh") != nil else { return nil }
        return try await token()
    }
}

// MARK: - Baixados

public enum Baixados {
    public static var pasta: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NovaEditor/Comunidade", isDirectory: true)
    }

    public struct Item: Codable, Identifiable, Hashable, Sendable {
        public let id: String
        public let tipo: String
        public let nome: String
        public let arquivo: String
        public let miniatura: String?
        public let autor: String?
        public let baixadoEm: Date
    }

    static func salvar(tipo: NovaHub.Tipo, item: ItemDaComunidade,
                       resposta: [String: Any]) throws -> URL {
        let dir = pasta.appendingPathComponent(tipo.rawValue, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url: URL
        if tipo == .efeitos, let xml = resposta["xml"] as? String {
            url = dir.appendingPathComponent("\(item.id).xml")
            try xml.write(to: url, atomically: true, encoding: .utf8)
        } else {
            url = dir.appendingPathComponent("\(item.id).json")
            let payload = resposta["payload"] ?? resposta
            let d = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            try d.write(to: url, options: .atomic)
        }
        var lista = todos()
        lista.removeAll { $0.id == item.id }
        lista.insert(Item(id: item.id, tipo: tipo.rawValue,
                          nome: (resposta["name"] as? String) ?? item.name,
                          arquivo: url.lastPathComponent, miniatura: item.thumbnailUrl,
                          autor: item.author?.name, baixadoEm: Date()), at: 0)
        gravar(lista)
        return url
    }

    public static func todos() -> [Item] {
        let u = pasta.appendingPathComponent("indice.json")
        guard let d = try? Data(contentsOf: u) else { return [] }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([Item].self, from: d)) ?? []
    }

    public static func contem(_ id: String) -> Bool { todos().contains { $0.id == id } }

    public static func apagar(_ item: Item) {
        let f = pasta.appendingPathComponent(item.tipo).appendingPathComponent(item.arquivo)
        try? FileManager.default.removeItem(at: f)
        gravar(todos().filter { $0.id != item.id })
    }

    static func gravar(_ lista: [Item]) {
        try? FileManager.default.createDirectory(at: pasta, withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        if let d = try? enc.encode(lista) { try? d.write(to: pasta.appendingPathComponent("indice.json")) }
    }

    /// Tamanho em disco de baixados + caches de video/miniaturas.
    public static func tamanhoDoCache() -> Int64 {
        var total: Int64 = 0
        let fm = FileManager.default
        for base in [pasta, fm.urls(for: .cachesDirectory, in: .userDomainMask)[0], fm.temporaryDirectory] {
            if let e = fm.enumerator(at: base, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let u as URL in e {
                    total += Int64((try? u.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                }
            }
        }
        return total
    }

    /// Limpa caches temporarios (miniaturas, exportacoes antigas). Nao apaga baixados.
    public static func limparCache() {
        let fm = FileManager.default
        URLCache.shared.removeAllCachedResponses()
        for base in [fm.urls(for: .cachesDirectory, in: .userDomainMask)[0], fm.temporaryDirectory] {
            for u in (try? fm.contentsOfDirectory(at: base, includingPropertiesForKeys: nil)) ?? [] {
                try? fm.removeItem(at: u)
            }
        }
    }
}
