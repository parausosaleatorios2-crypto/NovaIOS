//
//  NovaApp.swift
//  Nova Editor para iOS
//
//  Ponto de entrada.
//

import SwiftUI
import AVFoundation
import os

@main
struct NovaEditorApp: App {
    private let log = Logger(subsystem: "com.novavision.editor", category: "App")

    init() {
        // As 47 fontes do APK (Resources/fonts) ficam disponiveis para o texto.
        FontCatalog.registerBundled()
        // Som da previa: categoria de reproducao (o padrao, soloAmbient, fica mudo com a
        // chave do silencioso; editor de video toca o som da mesma forma que um player).
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        // Aquece o catalogo de efeitos fora da thread principal: sao 1.490 XMLs.
        Task.detached(priority: .utility) {
            do { try await EffectRegistry.shared.load() }
            catch { Logger(subsystem: "com.novavision.editor", category: "App")
                        .error("catálogo falhou: \(error.localizedDescription, privacy: .public)") }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if DemoMode.ativo { DemoRoot() } else { NavigationStack { HomeView() } }
            }
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // novaeditor://collab e novaeditor://preset, como no manifesto Android.
                    Logger(subsystem: "com.novavision.editor", category: "App")
                        .info("abriu URL \(url.absoluteString, privacy: .public)")
                }
        }
    }
}
