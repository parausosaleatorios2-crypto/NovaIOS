// ---------------------------------------------------------------------------
// Ondas de Luz (Ultra Motion)
// origem : assets/effects/um-ripple-light.xml
// id     : nova.effect.ultramotion.ripplelight
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_ripple_lightParams {
    float2 source;
    float speed;
    float spacing;
    float width;
    float intensity;
    float4 tint;
};

fragment float4 fx_um_ripple_light(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_ripple_lightParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 p = in.acScreenNorm - u.source;
    p.x *= eng.acAspect;
    float r = length(p);
    float onda = fract((r - eng.acTime * u.speed) / u.spacing);
    float dist = min(onda, 1.0 - onda);
    float anel = smoothstep(u.width, 0.0, dist);
    float decai = exp(-r * 1.5);
    float3 cor = orig.rgb + u.tint.rgb * u.tint.a * anel * u.intensity * decai;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
