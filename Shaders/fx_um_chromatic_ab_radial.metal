// ---------------------------------------------------------------------------
// Aberração Cromática Radial (Ultra Motion)
// origem : assets/effects/um-chromatic-ab-radial.xml
// id     : nova.effect.ultramotion.chromaticabradial
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_chromatic_ab_radialParams {
    float amount;
    float power;
    float2 center;
};

fragment float4 fx_um_chromatic_ab_radial(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_chromatic_ab_radialParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;
    float r = pow(length(p) / 0.7071, u.power);
    float2 dir = normalize(p + float2(1e-6));
    dir.x /= eng.acAspect;
    float2 off = dir * u.amount * r;

    float rr = inputImg.sample(__nv_smp, in.acScreenNorm + off).r;
    float gg = inputImg.sample(__nv_smp, in.acScreenNorm).g;
    float bb = inputImg.sample(__nv_smp, in.acScreenNorm - off).b;
    float aa = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(rr, gg, bb, aa);
    return __nv_out;
}
