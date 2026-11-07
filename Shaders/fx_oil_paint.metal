// ---------------------------------------------------------------------------
// Pintura a óleo
// origem : assets/effects/oil-paint.xml
// id     : nova.effect.oil-paint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct oil_paintParams {
    float radius;
    float strength;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/**
 * Média e variância (pela luma) de um quadrante 3×3 começando em (ox, oy)
 * do pixel central. Retorna float4(mediaRGB, variancia).
 */
float4 quadrante(float2 uv, float2 passo, int ox, int oy) {
    float3 somaCor = float3(0.0);
    float somaLuma = 0.0;
    float somaLumaQuadrado = 0.0;
    int n = 0;
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
            float2 d = float2(float(ox + x), float(oy + y)) * passo;
            float3 c = inputImg.sample(__nv_smp, uv + d).rgb;
            somaCor += c;
            float L = luma(c);
            somaLuma += L;
            somaLumaQuadrado += L * L;
            n++;
        }
    }
    float m = somaLuma / float(n);
    float variancia = somaLumaQuadrado / float(n) - m * m;
    float3 mediaRGB = somaCor / float(n);
    return float4(mediaRGB, variancia);
}

fragment float4 fx_oil_paint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant oil_paintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 passo = u.radius / tam / 3.0;

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // 4 quadrantes 3×3 em volta do pixel central: TL, TR, BL, BR.
    float4 tl = quadrante(in.acScreenNorm, passo, -3, -3);
    float4 tr = quadrante(in.acScreenNorm, passo,  1, -3);
    float4 bl = quadrante(in.acScreenNorm, passo, -3,  1);
    float4 br = quadrante(in.acScreenNorm, passo,  1,  1);

    // Devolve a média do quadrante com menor variância.
    float3 escolhido = tl.rgb;
    float menorVar = tl.a;
    if (tr.a < menorVar) { escolhido = tr.rgb; menorVar = tr.a; }
    if (bl.a < menorVar) { escolhido = bl.rgb; menorVar = bl.a; }
    if (br.a < menorVar) { escolhido = br.rgb; menorVar = br.a; }

    float3 cor = mix(original.rgb, escolhido, u.strength);
    __nv_out = float4(cor, original.a);
    return __nv_out;
}
