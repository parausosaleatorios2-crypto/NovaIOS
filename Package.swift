// swift-tools-version: 5.10
//
// Package.swift — para compilar e testar o motor fora do app (no Mac, em linha
// de comando). O app em si e montado pelo project.yml / Xcode, porque SwiftPM
// nao compila os .metal num alvo de aplicativo iOS.
//
import PackageDescription

let package = Package(
    name: "NovaEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "NovaEngine", targets: ["NovaEngine"]),
        .executable(name: "nova-effect-probe", targets: ["EffectProbe"]),
    ],
    targets: [
        .target(
            name: "NovaEngine",
            path: "Sources/NovaEngine"),
        // Sonda do CI: aplica cada efeito numa imagem de teste e mede o resultado.
        .executableTarget(
            name: "EffectProbe",
            dependencies: ["NovaEngine"],
            path: "Tools/EffectProbe"),
        .testTarget(
            name: "NovaEngineTests",
            dependencies: ["NovaEngine"],
            path: "Tests/NovaEngineTests"),
    ]
)
