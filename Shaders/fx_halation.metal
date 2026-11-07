// ---------------------------------------------------------------------------
// Halação
// origem : assets/effects/halation.xml
// id     : nova.effect.halation
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct halationParams {
    float4 haloColor;
    float threshold;
    float softness;
    float radius;
    float intensity;
};

// --- funcoes auxiliares do efeito
const int AMOSTRAS = 16;
const float TAU = 6.2831853;

/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Só o que está acima do limiar da luz, com transição suave. */
float apenasAsLuzes(float3 c) {
    float l = luma(c);
    return smoothstep(u.threshold, u.threshold + max(u.softness, 1e-4), l);
}

fragment float4 fx_halation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant halationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 passo = u.radius / tam;

    // Borrão radial do recorte das luzes: 16 amostras num círculo.
    float acumulado = apenasAsLuzes(original.rgb) * 0.5;
    float peso = 0.5;
    for (int i = 0; i < AMOSTRAS; i++) {
        float ang = TAU * (float(i) + 0.5) / float(AMOSTRAS);
        float2 d = float2(cos(ang), sin(ang)) * passo;
        float3 cor = inputImg.sample(__nv_smp, in.acScreenNorm + d).rgb;
        acumulado += apenasAsLuzes(cor);
        peso += 1.0;
    }
    float brilhoBorrado = acumulado / peso;

    float3 halo = u.haloColor.rgb * brilhoBorrado * u.intensity * u.haloColor.a;

    // Screen: luz nunca apaga luz.
    float3 cor = 1.0 - (1.0 - original.rgb) * (1.0 - halo);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
