//
//  Theme.swift
//  NovaUI
//
//  Cores e medidas do app. Os dois primeiros valores sao literais do
//  resources.arsc do APK; o resto saiu das capturas embutidas em
//  assets/extensoes/prints/ — veja Docs/PENDENCIAS.md.
//

import SwiftUI

public enum NovaTheme {
    // color/editor_background e color/editor_surface do APK
    public static let background = Color(red: 0x05/255, green: 0x05/255, blue: 0x0b/255)
    public static let surface    = Color(red: 0x0b/255, green: 0x0d/255, blue: 0x17/255)
    public static let surface2   = Color(red: 0x11/255, green: 0x14/255, blue: 0x1f/255)
    public static let line       = Color(red: 0x1e/255, green: 0x22/255, blue: 0x31/255)
    public static let line2      = Color(red: 0x2a/255, green: 0x2f/255, blue: 0x42/255)

    public static let text       = Color(red: 0xe8/255, green: 0xeb/255, blue: 0xf2/255)
    public static let dim        = Color(red: 0x8c/255, green: 0x93/255, blue: 0xa8/255)
    public static let dim2       = Color(red: 0x5d/255, green: 0x64/255, blue: 0x78/255)

    /// Acento verde, lido das capturas. Confirmar o valor exato com o time.
    public static let accent     = Color(red: 0x00/255, green: 0xe0/255, blue: 0x7a/255)
    /// Roxo do painel Flow.
    public static let flow       = Color(red: 0xb1/255, green: 0x4c/255, blue: 0xff/255)
    public static let selection  = Color(red: 0x4a/255, green: 0x9e/255, blue: 0xff/255)
    public static let warning    = Color(red: 0xff/255, green: 0xc2/255, blue: 0x4a/255)
    public static let danger     = Color(red: 0xff/255, green: 0x5d/255, blue: 0x5d/255)

    public enum Metrics {
        public static let corner: CGFloat = 12
        public static let cornerSmall: CGFloat = 8
        public static let bottomBarHeight: CGFloat = 54
        public static let tabBarHeight: CGFloat = 58
        public static let timelineRowHeight: CGFloat = 26
        public static let rulerHeight: CGFloat = 20
        public static let transportHeight: CGFloat = 40
    }

    /// Cor da barra de uma camada na timeline, por tipo. Segue as capturas:
    /// azul para video, roxo para texto, vermelho para forma, verde para ajuste.
    public static func trackColor(_ kind: String) -> Color {
        switch kind {
        case "video", "image":  return Color(red: 0.12, green: 0.23, blue: 0.37)
        case "text":            return Color(red: 0.29, green: 0.17, blue: 0.42)
        case "shape", "solid":  return Color(red: 0.42, green: 0.17, blue: 0.17)
        case "adjustment":      return Color(red: 0.12, green: 0.30, blue: 0.23)
        case "audio":           return Color(red: 0.36, green: 0.23, blue: 0.12)
        case "camera", "light", "null": return Color(red: 0.24, green: 0.24, blue: 0.40)
        default:                return Color(red: 0.18, green: 0.20, blue: 0.28)
        }
    }
}

/// Os quatro layouts do editor, como no app Android.
/// A string original: «troca o layout (Nova, CapCut, Motion, After Effects)
/// com o jeito de editar de cada um».
public enum EditorLayout: String, CaseIterable, Identifiable, Codable, Sendable {
    case nova, capcut, motion, afterEffects

    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .nova:         return "Nova"
        case .capcut:       return "CapCut"
        case .motion:       return "Motion"
        case .afterEffects: return "After Effects"
        }
    }
    public var note: String {
        switch self {
        case .nova:         return "O layout de sempre do app"
        case .capcut:       return "As barras e o botão de transição do CapCut"
        case .motion:       return "Os painéis do AE, compactos"
        case .afterEffects: return "Os painéis do AE. Pede tela grande e deitada."
        }
    }
    /// O layout AE avisa quando a janela e pequena, como no Android.
    public var minimumSize: CGSize {
        switch self {
        case .afterEffects: return CGSize(width: 1000, height: 600)
        case .motion:       return CGSize(width: 740,  height: 480)
        default:            return CGSize(width: 320,  height: 480)
        }
    }
}
