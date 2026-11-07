// ---------------------------------------------------------------------------
// Esticar Borda (Blurrr)
// origem : assets/effects/nv-blurrr-stretch.xml
// id     : nova.effect.blurrr.stretch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_stretchParams {
    float amount;
    float samples;
    float power;
};

fragment float4 fx_nv_blurrr_stretch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_stretchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - 0.5;
    float r = length(p);
    float2 dir = (r > 1e-5) ? p / r : float2(0.0);
    float k = pow(r * 2.0, u.power) * u.amount;

    int n = clamp(int(u.samples), 4, 32);
    float4 soma = float4(0.0);
    for (int i = 0; i <= 32; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        soma += inputImg.sample(__nv_smp, in.acScreenNorm - dir * k * t);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
