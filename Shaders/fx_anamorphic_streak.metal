// ---------------------------------------------------------------------------
// Risco anamórfico
// origem : assets/effects/anamorphic-streak.xml
// id     : nova.effect.anamorphicstreak
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct anamorphic_streakParams {
    float threshold;
    float reach;
    float angle;
    float quality;
    float intensity;
    float4 streakColor;
};

// --- funcoes auxiliares do efeito
const int MAX_SAMPLES = 64;

fragment float4 fx_anamorphic_streak(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant anamorphic_streakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float rad = radians(u.angle);
    float2 axis = float2(cos(rad), sin(rad)) * eng.acTexelSize * u.reach * eng.acEscalaDePixel;
    int samples = clamp(int(u.quality + 0.5), 1, MAX_SAMPLES);

    float3 streak = float3(0.0);
    float weightSum = 0.0;

    for (int i = 0; i < MAX_SAMPLES; i++) {
        if (i >= samples) break;
        // Vai dos dois lados a partir do pixel: o risco é simétrico.
        float t = (float(i) / float(samples - 1)) * 2.0 - 1.0;
        float4 texel = inputImg.sample(__nv_smp, clamp(in.acScreenNorm + axis * t, 0.0, 1.0));

        float luma = dot(texel.rgb, float3(0.299, 0.587, 0.114)) * texel.a;
        float bright = smoothstep(u.threshold, min(u.threshold + 0.2, 1.0), luma);

        // Peso caindo com a distância: sem isso o risco tem a mesma força na
        // ponta e no meio, e parece uma barra em vez de um brilho.
        float weight = 1.0 - abs(t);
        streak += texel.rgb * bright * weight;
        weightSum += weight;
    }

    streak *= u.intensity / max(weightSum, 0.0001);

    // Somado: luz se acumula. Misturar deixaria a imagem lavada.
    float3 result = original.rgb + streak * u.streakColor.rgb * u.streakColor.a;
    __nv_out = float4(clamp(result, 0.0, 1.0), original.a);
    return __nv_out;
}
