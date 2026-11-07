// ---------------------------------------------------------------------------
// Aberração Cromática (Blurrr)
// origem : assets/effects/nv-blurrr-chromatic-ab.xml
// id     : nova.effect.blurrr.chromab
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_chromatic_abParams {
    float strength;
    float power;
    float2 center;
};

fragment float4 fx_nv_blurrr_chromatic_ab(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_chromatic_abParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center;
    float r = length(p);
    float k = pow(r, u.power) * u.strength;
    float2 dir = (r > 1e-5) ? p / r : float2(0.0);

    float cr = inputImg.sample(__nv_smp, in.acScreenNorm + dir * k * 1.0).r;
    float cg = inputImg.sample(__nv_smp, in.acScreenNorm + dir * k * 0.5).g;
    float cb = inputImg.sample(__nv_smp, in.acScreenNorm + dir * k * 0.0).b;
    float a  = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(cr, cg, cb, a);
    return __nv_out;
}
