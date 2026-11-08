// ---------------------------------------------------------------------------
// Optical Flares (fase 1: desenho na GPU)
// origem : assets/effects/ae-optical-flares.xml
// id     : nova.effect.aeopticalflares
//
// No APK o flare e desenhado na CPU por com.novaeditor.model.opticalflares
// (MotorDoOf, porte bit a bit do plugin da Video Copilot, ~6.000 linhas; o
// irisRender nem descompila). Este shader e a FASE 1 do porte: os mesmos
// controles do efeito (posicao da luz, centro, brilho, escala, rotacao, cor,
// modo de cor, evolucao e os tres Render Mode) desenhando os elementos
// principais do flare padrao — nucleo, halo, raios, faixa anamorfica, anel e
// ghosts no eixo luz -> centro. A fase 2 (o motor fiel, lendo o .ofp) esta em
// Docs/MAPA-APK-IOS.md.
// Escrito a mao (nao e saida do glsl2msl.py).
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_optical_flaresParams {
    float2 positionXY;
    float2 centerPosition;
    float brightness;
    float scale;
    float rotationOffset;
    float4 color;
    int colorMode;
    float animationEvolution;
    int renderMode;
    float4 flare;
};

static float2 of_rot(float2 p, float a) {
    float c = cos(a), s = sin(a);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Hexagono regular (iris de seis laminas), distancia com sinal aproximada.
static float of_hex(float2 p, float r) {
    p = abs(p);
    return max(p.x * 0.866025 + p.y * 0.5, p.y) - r;
}

fragment float4 fx_ae_optical_flares(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_optical_flaresParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float4 src = inputImg.sample(__nv_smp, uv);

    float2 res = max(eng.acScreenSize, float2(1.0));
    float aspect = res.x / res.y;
    float2 asp = float2(aspect, 1.0);

    float2 L = u.positionXY;                 // luz (0..1)
    float2 C = u.centerPosition;             // centro optico (0..1)
    float bright = max(u.brightness, 0.0) / 100.0;
    float sc = max(u.scale, 0.0) / 100.0 + 1e-4;
    float rot = u.rotationOffset * 0.0174533;
    float evo = u.animationEvolution * 0.0174533;

    float2 p = (uv - L) * asp;
    float d = length(p);
    float2 q = of_rot(p, -rot);
    float ang = atan2(q.y, q.x);

    float3 col = float3(0.0);

    // Glow: nucleo quente e halo largo.
    col += float3(1.00, 0.92, 0.82) * exp(-(d * d) / (0.0009 * sc * sc)) * 1.6;
    col += float3(1.00, 0.70, 0.40) * exp(-d / (0.10 * sc)) * 0.55;
    col += float3(0.55, 0.45, 1.00) * exp(-d / (0.35 * sc)) * 0.12;

    // Streak anamorfico horizontal (azulado), como o Streak do flare padrao.
    float strk = exp(-abs(q.y) / (0.0035 * sc)) * exp(-abs(q.x) / (0.75 * sc));
    col += float3(0.55, 0.72, 1.00) * strk * 0.9;

    // Raios (Spike Ball / Glint): 12 raios finos que giram com a evolucao.
    float raios = pow(abs(cos(ang * 6.0 + evo)), 60.0) + 0.6 * pow(abs(cos(ang * 6.0 + 0.2618 + evo * 1.7)), 120.0);
    col += float3(1.00, 0.85, 0.70) * raios * exp(-d / (0.16 * sc)) * 0.7;

    // Shimmer: brilho fino irregular em volta.
    float shim = 0.5 + 0.5 * sin(ang * 37.0 + evo * 3.0) * sin(ang * 23.0 - evo * 2.0);
    col += float3(0.9, 0.8, 1.0) * shim * exp(-d / (0.06 * sc)) * 0.25;

    // Ring: anel colorido fino em volta da luz.
    float ring = exp(-pow((d - 0.22 * sc) / (0.010 * sc), 2.0));
    col += float3(0.40, 0.85, 0.75) * ring * 0.18;

    // Ghosts no eixo luz -> centro (Multi Iris / Lens Orbs / Hoop).
    float2 axis = C - L;
    float lenAxis = length(axis * asp);
    float vis = clamp(1.0 - lenAxis * 0.35, 0.35, 1.0);   // somem um pouco com a luz longe do centro
    constexpr int N = 7;
    float  tPos[N] = { 0.45, 0.8, 1.15, 1.4, 1.65, 1.95, 2.3 };
    float  rad [N] = { 0.020, 0.045, 0.030, 0.085, 0.015, 0.060, 0.120 };
    float3 tint[N] = { float3(0.9,0.6,0.3), float3(0.3,0.8,0.6), float3(0.6,0.5,1.0), float3(0.9,0.4,0.6),
                       float3(1.0,0.9,0.6), float3(0.4,0.6,1.0), float3(0.5,0.9,0.5) };
    for (int i = 0; i < N; i++) {
        float2 g = L + axis * tPos[i];
        float2 gp = of_rot((uv - g) * asp, evo * 0.15 + float(i));
        float r = rad[i] * sc;
        float hexd = of_hex(gp, r);
        float disco = 1.0 - smoothstep(-r * 0.12, r * 0.04, hexd);
        float borda = exp(-pow(hexd / (r * 0.08 + 1e-4), 2.0));
        col += tint[i] * (disco * 0.07 + borda * 0.10) * vis;
    }

    // Hoop: arco grande do lado oposto da luz.
    float2 hp = (uv - (C + (C - L) * 0.9)) * asp;
    float hoop = exp(-pow((length(hp) - 0.30 * sc) / (0.012 * sc), 2.0));
    col += float3(0.5, 0.7, 1.0) * hoop * 0.10 * vis;

    // Cor: Tint (mistura com o branco) ou Multiply.
    float3 c = u.color.rgb;
    col = (u.colorMode == 1) ? col * c : mix(col, col * c * 1.4, 0.65);
    col *= bright;

    float4 outc;
    if (u.renderMode == 0) {            // On Black
        outc = float4(col, 1.0);
    } else if (u.renderMode == 1) {     // On Transparent
        float a = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
        outc = float4(col, a);
    } else {                            // Over Original (soma, como o Screen do plugin)
        float3 base = src.rgb;
        outc = float4(1.0 - (1.0 - base) * (1.0 - clamp(col, 0.0, 1.0)) + max(col - 1.0, 0.0), max(src.a, clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0)));
    }
    return outc;
}
