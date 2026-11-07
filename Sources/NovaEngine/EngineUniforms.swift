//
//  EngineUniforms.swift
//  NovaEngine
//
//  Espelho em Swift do struct EngineUniforms do Metal. A ordem e o alinhamento
//  tem de bater com Shaders/NovaEngineUniforms.h — os dois sao gerados a partir
//  da mesma tabela em Tools/glsl2msl.py.
//
//  Regras de alinhamento do MSL: float2 alinha em 8, float3/float4 e float4x4 em 16.
//  O struct abaixo esta ordenado para nao precisar de padding manual.
//

import simd
import Foundation

public struct EngineUniforms {
    // --- float4x4 (16 bytes de alinhamento, primeiro) ---
    public var acLayerToScreen   = matrix_identity_float4x4
    public var acCamadaParaTela  = matrix_identity_float4x4
    public var acParaTela        = matrix_identity_float4x4
    public var acLTS             = matrix_identity_float4x4
    public var acScreenToLayer   = matrix_identity_float4x4
    public var acCameraInvVP     = matrix_identity_float4x4
    public var acCamera3D        = matrix_identity_float4x4
    public var acCamadaNaTela    = matrix_identity_float4x4
    public var acCamadaPropria   = matrix_identity_float4x4

    // --- float3 ---
    public var acCameraOlho      = SIMD3<Float>(0, 0, 0)
    public var acCameraOlhoNova  = SIMD3<Float>(0, 0, 0)

    // --- float2 ---
    public var acScreenNorm         = SIMD2<Float>(0, 0)
    public var acScreenSize         = SIMD2<Float>(1920, 1080)
    public var acTela               = SIMD2<Float>(1920, 1080)
    public var acTamanhoDaTela      = SIMD2<Float>(1920, 1080)
    public var acResolution         = SIMD2<Float>(1920, 1080)
    public var acPreviewSize        = SIMD2<Float>(1920, 1080)
    public var acTexelSize          = SIMD2<Float>(1.0/1920, 1.0/1080)
    public var acLayerSize          = SIMD2<Float>(1920, 1080)
    public var acTamanhoDaCamada    = SIMD2<Float>(1920, 1080)
    public var acLayerNorm          = SIMD2<Float>(0, 0)
    public var acCamada             = SIMD2<Float>(0, 0)
    public var acLayerCenter        = SIMD2<Float>(960, 540)
    public var acLayerCenterNorm    = SIMD2<Float>(0.5, 0.5)
    public var acEntradaDePe        = SIMD2<Float>(0, 0)
    public var acLayerNormAm        = SIMD2<Float>(0, 0)
    public var acPivoDoAm           = SIMD2<Float>(0.5, 0.5)
    public var acLayerPivot         = SIMD2<Float>(0.5, 0.5)
    public var acCentroDaCamadaPx   = SIMD2<Float>(960, 540)
    public var acCentroDaCamada     = SIMD2<Float>(960, 540)
    public var acCentroDaCamadaNorm = SIMD2<Float>(0.5, 0.5)
    public var acCaixaDoTexto       = SIMD2<Float>(0, 0)
    public var acProjectSize        = SIMD2<Float>(1920, 1080)
    public var acLayerSizeNorm      = SIMD2<Float>(1, 1)
    public var acVelocidadeDoAm     = SIMD2<Float>(0, 0)
    public var acVelocity           = SIMD2<Float>(0, 0)
    public var acPontoNoBuffer      = SIMD2<Float>(0, 0)
    public var acBufferNoPonto      = SIMD2<Float>(0, 0)
    public var acTamanhoDoTexto     = SIMD2<Float>(0, 0)
    public var acFolgaDaCamada      = SIMD2<Float>(0, 0)
    public var acDirParaUv          = SIMD2<Float>(1, 0)
    public var acEscalaPorQuadroDoAm = SIMD2<Float>(1, 1)
    public var acProporcaoDoNode    = SIMD2<Float>(1, 1)

    // --- int ---
    public var acPass           : Int32 = 0
    public var acIteration      : Int32 = 0
    public var acIterationCount : Int32 = 1
    public var acAmostras       : Int32 = 1
    public var acShowGuides     : Int32 = 0
    public var acStateFresh     : Int32 = 1

    // --- float ---
    public var acTime              : Float = 0
    public var acAspect            : Float = 16.0/9.0
    public var acEscalaDePixel     : Float = 1
    public var acFrameDuration     : Float = 1.0/30.0
    public var acRascunho          : Float = 0
    public var acDeltaNivel        : Float = 0
    public var acAngularVelocity   : Float = 0
    public var acGiroPorQuadroDoAm : Float = 0
    public var acProgress          : Float = 0

    public init() {}

    /// Preenche os campos derivados do tamanho da tela e da camada.
    /// Chamado pelo renderer antes de cada pass para nao deixar nada inconsistente.
    public mutating func sync(screenSize: SIMD2<Float>,
                              layerSize: SIMD2<Float>,
                              layerCenter: SIMD2<Float>,
                              pixelScale: Float,
                              time: Float,
                              frameDuration: Float) {
        let sw = max(screenSize.x, 1), sh = max(screenSize.y, 1)
        acScreenSize    = SIMD2(sw, sh)
        acTela          = acScreenSize
        acTamanhoDaTela = acScreenSize
        acResolution    = acScreenSize
        acPreviewSize   = acScreenSize
        acProjectSize   = acScreenSize
        acTexelSize     = SIMD2(1 / sw, 1 / sh)
        acAspect        = sw / sh

        let lw = max(layerSize.x, 1), lh = max(layerSize.y, 1)
        acLayerSize        = SIMD2(lw, lh)
        acTamanhoDaCamada  = acLayerSize
        acLayerSizeNorm    = SIMD2(lw / sw, lh / sh)
        acProporcaoDoNode  = SIMD2(lw / lh, 1)

        acLayerCenter        = layerCenter
        acCentroDaCamada     = layerCenter
        acCentroDaCamadaPx   = layerCenter
        acLayerCenterNorm    = SIMD2(layerCenter.x / sw, layerCenter.y / sh)
        acCentroDaCamadaNorm = acLayerCenterNorm

        acEscalaDePixel = pixelScale
        acTime          = time
        acFrameDuration = frameDuration
    }
}

/// Dialeto Alight Motion: cada textura carrega tamanho e transformacao.
public struct NovaTexInfo {
    public var size      = SIMD2<Float>(1, 1)
    public var transform = matrix_identity_float4x4
    public init() {}
    public init(size: SIMD2<Float>, transform: simd_float4x4 = matrix_identity_float4x4) {
        self.size = size; self.transform = transform
    }
}
