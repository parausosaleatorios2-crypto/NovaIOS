// ---------------------------------------------------------------------------
// Redemoinho
// origem : assets/effects/twirl.xml
// id     : nova.effect.twirl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct twirlParams {
    float2 center;
    float twist;
    float radius;
};

fragment float4 fx_twirl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant twirlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float dist = length(offset);

    float falloff = 1.0 - smoothstep(0.0, max(u.radius, 0.001), dist);
    float angle = __nv_atan(offset.y, offset.x) + radians(u.twist) * falloff;

    float2 warped = float2(cos(angle), sin(angle)) * dist;
    float2 sampleUv = warped / float2(eng.acAspect, 1.0) + u.center;

    __nv_out = inputImg.sample(__nv_smp, clamp(sampleUv, 0.0, 1.0));
    return __nv_out;
}
