// ---------------------------------------------------------------------------
// Linhas de Velocidade (Blurrr)
// origem : assets/effects/nv-blurrr-speed.xml
// id     : nova.effect.blurrr.speed
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_speedParams {
    float strength;
    float innerRadius;
    float samples;
    float2 center;
};

fragment float4 fx_nv_blurrr_speed(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_speedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center;
    float r = length(p);
    float peso = smoothstep(u.innerRadius, u.innerRadius + 0.3, r);
    if (peso <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }

    float2 dir = (r > 1e-5) ? p / r : float2(0.0);
    int n = clamp(int(u.samples), 4, 48);

    float4 soma = float4(0.0);
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        soma += inputImg.sample(__nv_smp, in.acScreenNorm - dir * u.strength * t * peso);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
