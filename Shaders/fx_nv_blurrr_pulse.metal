// ---------------------------------------------------------------------------
// Pulso (Blurrr)
// origem : assets/effects/nv-blurrr-pulse.xml
// id     : nova.effect.blurrr.pulse
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_pulseParams {
    float amount;
    float rate;
    float samples;
    float2 center;
};

fragment float4 fx_nv_blurrr_pulse(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_pulseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int n = clamp(int(u.samples), 4, 32);
    float pulso = 0.5 + 0.5 * sin(eng.acTime * u.rate * 6.2831853);
    float s = u.amount * pulso;
    if (s <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }

    float2 p = in.acScreenNorm - u.center;
    float4 soma = float4(0.0);
    for (int i = 0; i <= 32; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float2 u = u.center + p * (1.0 - s * t);
        soma += inputImg.sample(__nv_smp, u);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
