// ---------------------------------------------------------------------------
// Separação RGB
// origem : assets/effects/nv-um-rgb-split.xml
// id     : nova.effect.um-rgb-split
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_rgb_splitParams {
    float amount;
    float angle;
    float spread;
};

fragment float4 fx_nv_um_rgb_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_rgb_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float rad = radians(u.angle);
    float2 dir = float2(cos(rad), sin(rad));
    float2 passo = dir * u.amount / eng.acResolution;

    float2 uvR = uv - passo * (1.0 + u.spread);
    float2 uvG = uv;
    float2 uvB = uv + passo * (1.0 + u.spread);

    float r = inputImg.sample(__nv_smp, uvR).r;
    float4 g = inputImg.sample(__nv_smp, uvG);
    float b = inputImg.sample(__nv_smp, uvB).b;

    __nv_out = float4(r, g.g, b, g.a);
    return __nv_out;
}
