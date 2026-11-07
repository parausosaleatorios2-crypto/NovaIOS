// ---------------------------------------------------------------------------
// Duas cores
// origem : assets/effects/duotone.xml
// id     : nova.effect.duotone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct duotoneParams {
    float4 shadowColor;
    float4 highlightColor;
    float blackPoint;
    float whitePoint;
};

fragment float4 fx_duotone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant duotoneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));

    float range = max(u.whitePoint - u.blackPoint, 0.001);
    luma = clamp((luma - u.blackPoint) / range, 0.0, 1.0);

    float3 duo = mix(u.shadowColor.rgb, u.highlightColor.rgb, luma);
    __nv_out = float4(duo, color.a);
    return __nv_out;
}
