#pragma once
#include <metal_stdlib>
using namespace metal;

// Uniforms injetados pelo motor em todo shader de efeito.
struct EngineUniforms {
    int acAmostras;
    float acAngularVelocity;
    float acAspect;
    float2 acBufferNoPonto;
    float2 acCaixaDoTexto;
    float2 acCamada;
    float4x4 acCamadaNaTela;
    float4x4 acCamadaParaTela;
    float4x4 acCamadaPropria;
    float4x4 acCamera3D;
    float4x4 acCameraInvVP;
    float3 acCameraOlho;
    float3 acCameraOlhoNova;
    float2 acCentroDaCamada;
    float2 acCentroDaCamadaNorm;
    float2 acCentroDaCamadaPx;
    float acDeltaNivel;
    float2 acEntradaDePe;
    float acEscalaDePixel;
    float2 acEscalaPorQuadroDoAm;
    float2 acFolgaDaCamada;
    float acFrameDuration;
    float acGiroPorQuadroDoAm;
    int acIteration;
    int acIterationCount;
    float4x4 acLTS;
    float2 acLayerCenter;
    float2 acLayerCenterNorm;
    float2 acLayerNormAm;
    float2 acLayerPivot;
    float2 acLayerSize;
    float2 acLayerSizeNorm;
    float4x4 acLayerToScreen;
    float4x4 acParaTela;
    int acPass;
    float2 acPivoDoAm;
    float2 acPontoNoBuffer;
    float2 acPreviewSize;
    float acProgress;
    float2 acProjectSize;
    float2 acProporcaoDoNode;
    float acRascunho;
    float2 acResolution;
    float2 acScreenSize;
    float4x4 acScreenToLayer;
    int acShowGuides;
    int acStateFresh;
    float2 acTamanhoDaCamada;
    float2 acTamanhoDaTela;
    float2 acTamanhoDoTexto;
    float2 acTela;
    float2 acTexelSize;
    float acTime;
    float2 acVelocidadeDoAm;
    float2 acVelocity;
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
