// ---------------------------------------------------------------------------
// Desfoque Ondulação (Blurrr)
// origem : assets/effects/nv-blurrr-ripple.xml
// id     : nova.effect.blurrr.ripple
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_rippleParams {
    float amp;
    float freq;
    float phase;
    float blur;
    float samples;
    float2 center;
};

fragment float4 fx_nv_blurrr_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center; p.x *= eng.acAspect;
    float r = length(p);
    float2 n = (r > 1e-5) ? p / r : float2(1.0, 0.0);
    float desl = sin(r * u.freq - u.phase + eng.acTime * 2.0) * u.amp;
    float2 off = n * desl; off.x /= max(eng.acAspect, 1e-4);
    float2 uv = in.acScreenNorm + off;

    int ns = clamp(int(u.samples), 2, 24);
    float4 soma = float4(0.0);
    for (int i = 0; i <= 24; i++) {
        if (i > ns) break;
        float t = (float(i)/float(ns) - 0.5) * u.blur;
        soma += inputImg.sample(__nv_smp, uv + n * t);
    }
    __nv_out = soma / float(ns + 1);
    return __nv_out;
}
