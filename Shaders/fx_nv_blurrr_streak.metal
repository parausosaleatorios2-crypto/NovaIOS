// ---------------------------------------------------------------------------
// Raios Anamórficos (Blurrr)
// origem : assets/effects/nv-blurrr-streak.xml
// id     : nova.effect.blurrr.streak
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_streakParams {
    float comprimento;
    float threshold;
    float strength;
    float angle;
    float samples;
    float tintR;
    float tintG;
    float tintB;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_nv_blurrr_streak(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_streakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 o = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.comprimento <= 0.0 || u.strength <= 0.0) { __nv_out = o; return __nv_out; }

    float a = u.angle * PI / 180.0;
    float2 d = float2(cos(a), sin(a));
    d.x /= max(eng.acAspect, 1e-4);

    int n = clamp(int(u.samples), 4, 64);
    float3 soma = float3(0.0);
    float pesoTot = 0.0;
    for (int i = -64; i <= 64; i++) {
        if (i < -n || i > n) continue;
        float t = float(i) / float(n);
        float w = (1.0 - abs(t));
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm + d * u.comprimento * t);
        float luz = dot(c.rgb, LUMA);
        float k = smoothstep(u.threshold, u.threshold + 0.2, luz);
        soma += c.rgb * k * w;
        pesoTot += w;
    }
    float3 streak = (soma / max(pesoTot, 1e-4)) * float3(u.tintR, u.tintG, u.tintB) * u.strength;
    __nv_out = float4(o.rgb + streak * o.a, o.a);
    return __nv_out;
}
