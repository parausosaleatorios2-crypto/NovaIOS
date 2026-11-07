// ---------------------------------------------------------------------------
// Células (Voronoi)
// origem : assets/effects/voronoi.xml
// id     : nova.effect.voronoi
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct voronoiParams {
    float density;
    float jitter;
    float speed;
    float seed;
    float4 cellColor;
    float4 edgeColor;
    float edgeWidth;
    float colorByCell;
    float blend;
};

// --- funcoes auxiliares do efeito
static float2 hash2(float2 c) {
    c = float2(
        dot(c, float2(127.1, 311.7)),
        dot(c, float2(269.5, 183.3))
    ) + float2(u.seed * 13.7);
    return fract(sin(c) * 43758.5453);
}

static float hash1(float2 c) {
    return fract(sin(dot(c, float2(419.2, 371.9)) + u.seed * 13.7) * 9999.9);
}

/**
 * As duas menores distâncias (F1, F2) e a célula dona do pixel. Olha as 9 células
 * da vizinhança 3×3: a ingênua olharia TODAS, esta prende a conta no grid.
 */
static float3 voronoi(float2 p, float t) {
    float2 i = floor(p);
    float2 f = fract(p);

    float f1 = 9.0;
    float f2 = 9.0;
    float2 donaDoPixel = float2(0.0);

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 vizinha = float2(float(x), float(y));
            float2 h = hash2(i + vizinha);
            // O ponto da célula anima no círculo: `sin/cos` do tempo mantém o movimento preso dentro dela.
            float2 ponto = vizinha + 0.5 + (h - 0.5) * u.jitter + 0.35 * u.jitter * float2(
                sin(t + h.x * 6.2831),
                cos(t + h.y * 6.2831)
            );
            float d = length(ponto - f);
            if (d < f1) {
                f2 = f1;
                f1 = d;
                donaDoPixel = i + vizinha;
            } else if (d < f2) {
                f2 = d;
            }
        }
    }
    return float3(f1, f2, hash1(donaDoPixel));
}

fragment float4 fx_voronoi(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant voronoiParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y) * u.density;
    float3 v = voronoi(p, eng.acTime * u.speed);

    float f1 = v.x;
    float f2 = v.y;
    float idDaCelula = v.z;

    // A borda aparece onde F2 − F1 é pequeno: ali duas células disputam o pixel.
    float dif = f2 - f1;
    float borda = 1.0 - smoothstep(u.edgeWidth * 0.5, u.edgeWidth, dif);

    // Cor da célula: ou a cor base, ou uma tingida pelo id (shift de matiz).
    float3 corBase = u.cellColor.rgb;
    float3 corTingida = corBase * (0.5 + idDaCelula);
    float3 corDaCelula = mix(corBase, corTingida, u.colorByCell);

    // Um gradiente dentro da célula (mais escuro perto da borda): barato e dá relevo.
    float sombra = 1.0 - smoothstep(0.0, 0.6, f1);

    float3 corDoPadrao = mix(corDaCelula * (0.55 + 0.45 * sombra), u.edgeColor.rgb, borda);
    float alfaDoPadrao = mix(u.cellColor.a, u.edgeColor.a, borda);

    float3 cor = mix(original.rgb, corDoPadrao, u.blend * alfaDoPadrao);
    float alfa = mix(original.a, max(original.a, alfaDoPadrao), u.blend);

    __nv_out = float4(cor, alfa);
    return __nv_out;
}
