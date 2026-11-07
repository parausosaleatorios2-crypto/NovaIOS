// ---------------------------------------------------------------------------
// Bloom cromático
// origem : assets/effects/chromatic-bloom.xml
// id     : nova.effect.chromatic-bloom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct chromatic_bloomParams {
    float threshold;
    float radius;
    float intensity;
    float chromaticSpread;
};

// --- funcoes auxiliares do efeito
const int AMOSTRAS = 16;
const float TAU = 6.2831853;

/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Só o que está acima do limiar, suavizado. */
float3 apenasAsLuzes(float3 c) {
    float L = luma(c);
    float f = smoothstep(u.threshold, u.threshold + 0.15, L);
    return c * f;
}

fragment float4 fx_chromatic_bloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant chromatic_bloomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 px = 1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));

    // 16 amostras num círculo com raios diferentes por canal — as luzes de
    // cada canal ficam em círculos diferentes, as bordas do halo se separam.
    float3 bloom = float3(0.0);
    for (int i = 0; i < AMOSTRAS; i++) {
        float ang = TAU * (float(i) + 0.5) / float(AMOSTRAS);
        float2 direcao = float2(cos(ang), sin(ang));

        float raioR = u.radius * (1.0 + u.chromaticSpread * 0.5);
        float raioG = u.radius;
        float raioB = u.radius * (1.0 - u.chromaticSpread * 0.5);

        bloom.r += apenasAsLuzes(inputImg.sample(__nv_smp, in.acScreenNorm + direcao * raioR * px).rgb).r;
        bloom.g += apenasAsLuzes(inputImg.sample(__nv_smp, in.acScreenNorm + direcao * raioG * px).rgb).g;
        bloom.b += apenasAsLuzes(inputImg.sample(__nv_smp, in.acScreenNorm + direcao * raioB * px).rgb).b;
    }
    bloom /= float(AMOSTRAS);

    // Mistura por adição com peso de intensidade; clampa pra não saturar branco liso.
    float3 cor = original.rgb + bloom * u.intensity;
    cor = clamp(cor, 0.0, 1.0);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
