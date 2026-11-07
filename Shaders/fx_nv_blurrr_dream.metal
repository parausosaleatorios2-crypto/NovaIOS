// ---------------------------------------------------------------------------
// Desfoque Sonho (Blurrr)
// origem : assets/effects/nv-blurrr-dream.xml
// id     : nova.effect.blurrr.dream
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_dreamParams {
    float radius;
    float threshold;
    float strength;
    float softness;
};

// --- funcoes auxiliares do efeito
const int N = 9;
const float OFF[9] = float[9](-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0);
const float WT[9]  = float[9](0.028, 0.065, 0.121, 0.175, 0.198, 0.175, 0.121, 0.065, 0.028);
const float3  LUMA   = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_nv_blurrr_dream(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_dreamParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.radius <= 0.0) { __nv_out = original; return __nv_out; }

    float2 direction = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = direction * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);

    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        float4 c;
        if (eng.acPass == 0) {
            c = inputImg.sample(__nv_smp, uv);
            float luz = dot(c.rgb, LUMA);
            float corte = smoothstep(u.threshold, u.threshold + 0.2, luz);
            c.rgb *= mix(u.softness, 1.0, corte);
        } else {
            c = hblur.sample(__nv_smp, uv);
        }
        soma += c * WT[i];
    }

    if (eng.acPass == 0) {
        __nv_out = soma;
    } else {
        float3 glow = soma.rgb * u.strength;
        __nv_out = float4(original.rgb + glow * original.a, original.a);
    }
    return __nv_out;
}
