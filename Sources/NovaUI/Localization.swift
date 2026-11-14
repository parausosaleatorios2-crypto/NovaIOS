//
//  Localization.swift
//  NovaUI
//
//  As 6.872 strings do app vem do mesmo Resources/i18n/en.json do APK:
//  a chave e o texto em portugues, o valor e a traducao em ingles.
//  Nao ha .strings — usamos o arquivo original, sem conversao.
//

import Foundation
import os

public final class Loc {
    public static let shared = Loc()
    private var map: [String: String] = [:]
    private var useEnglish = false
    private let log = Logger(subsystem: "com.novavision.editor", category: "Loc")

    private init() {
        // O app inteiro em ingles, qualquer que seja o idioma do aparelho.
        // UserDefaults "nova.idioma" = "pt" volta para o portugues.
        useEnglish = UserDefaults.standard.string(forKey: "nova.idioma") != "pt"
        load()
    }

    /// true quando a UI esta em ingles.
    public var isEnglish: Bool { useEnglish }

    private func load() {
        guard let url = Bundle.main.url(forResource: "en", withExtension: "json",
                                        subdirectory: "i18n")
              ?? Bundle.main.url(forResource: "i18n/en", withExtension: "json") else {
            log.warning("i18n/en.json nao esta no bundle; a UI fica so em portugues")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            map = try JSONDecoder().decode([String: String].self, from: data)
            log.info("i18n carregado: \(self.map.count) strings")
        } catch {
            log.error("i18n falhou: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Traduz uma string em portugues. Sem entrada, devolve o original —
    /// e o comportamento do app Android.
    public func t(_ pt: String) -> String {
        guard useEnglish else { return pt }
        guard let v = map[pt] else { return pt }
        return v.trimmingCharacters(in: .whitespaces).isEmpty ? pt : v
    }

    public var count: Int { map.count }
}

/// Nome do efeito e rotulo do parametro no idioma da UI (o XML traz name-en / label-en).
public extension EffectManifest {
    var titulo: String { Loc.shared.isEnglish ? (nameEn ?? name.loc) : name }
}
public extension EffectIndexEntry {
    var titulo: String { Loc.shared.isEnglish ? (nameEn ?? name.loc) : name }
}
public extension EffectParam {
    var titulo: String {
        Loc.shared.isEnglish ? (labelEn ?? label?.loc ?? id) : (label ?? labelEn ?? id)
    }
}

/// Atalho: `"Camadas".loc`
public extension String {
    var loc: String { Loc.shared.t(self) }
}
