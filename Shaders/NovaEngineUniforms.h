#pragma once
#include <metal_stdlib>
using namespace metal;

// Uniforms injetados pelo motor em todo shader de efeito.
// GERADO por Tools/gerar_uniforms_h.py a partir de EngineUniforms.swift.
// NAO edite a mao: a ordem tem de ser a mesma do Swift (vai byte a byte).
struct EngineUniforms {
    float4x4  acLayerToScreen;   // +0
    float4x4  acCamadaParaTela;   // +64
    float4x4  acParaTela;   // +128
    float4x4  acLTS;   // +192
    float4x4  acScreenToLayer;   // +256
    float4x4  acCameraInvVP;   // +320
    float4x4  acCamera3D;   // +384
    float4x4  acCamadaNaTela;   // +448
    float4x4  acCamadaPropria;   // +512
    float3    acCameraOlho;   // +576
    float3    acCameraOlhoNova;   // +592
    float2    acScreenNorm;   // +608
    float2    acScreenSize;   // +616
    float2    acTela;   // +624
    float2    acTamanhoDaTela;   // +632
    float2    acResolution;   // +640
    float2    acPreviewSize;   // +648
    float2    acTexelSize;   // +656
    float2    acLayerSize;   // +664
    float2    acTamanhoDaCamada;   // +672
    float2    acLayerNorm;   // +680
    float2    acCamada;   // +688
    float2    acLayerCenter;   // +696
    float2    acLayerCenterNorm;   // +704
    float2    acEntradaDePe;   // +712
    float2    acLayerNormAm;   // +720
    float2    acPivoDoAm;   // +728
    float2    acLayerPivot;   // +736
    float2    acCentroDaCamadaPx;   // +744
    float2    acCentroDaCamada;   // +752
    float2    acCentroDaCamadaNorm;   // +760
    float2    acCaixaDoTexto;   // +768
    float2    acProjectSize;   // +776
    float2    acLayerSizeNorm;   // +784
    float2    acVelocidadeDoAm;   // +792
    float2    acVelocity;   // +800
    float2    acPontoNoBuffer;   // +808
    float2    acBufferNoPonto;   // +816
    float2    acTamanhoDoTexto;   // +824
    float2    acFolgaDaCamada;   // +832
    float2    acDirParaUv;   // +840
    float2    acEscalaPorQuadroDoAm;   // +848
    float2    acProporcaoDoNode;   // +856
    int       acPass;   // +864
    int       acIteration;   // +868
    int       acIterationCount;   // +872
    int       acAmostras;   // +876
    int       acShowGuides;   // +880
    int       acStateFresh;   // +884
    float     acTime;   // +888
    float     acAspect;   // +892
    float     acEscalaDePixel;   // +896
    float     acFrameDuration;   // +900
    float     acRascunho;   // +904
    float     acDeltaNivel;   // +908
    float     acAngularVelocity;   // +912
    float     acGiroPorQuadroDoAm;   // +916
    float     acProgress;   // +920
};
// tamanho: 928 bytes

// Dialeto Alight Motion: tamanho e transformacao de cada textura (= NovaTexInfo do Swift).
struct NovaTexInfo {
    float2   size;
    float4x4 transform;
};

struct NovaVertexOut {
    float4 position [[position]];
    float2 uv;
    // Varyings do dialeto Alight Motion / HLSLcc usados pelos efeitos traduzidos.
    float2 acScreenNorm;
    float2 acLayerNorm;
    float2 vs_TEXCOORD0;
    float4 vs_TEXCOORD1;
    float4 vs_TEXCOORD2;
    float4 vs_TEXCOORD3;
    float4 vs_TEXCOORD4;
    float4 vs_TEXCOORD5;
    float4 vs_COLOR0;
};
