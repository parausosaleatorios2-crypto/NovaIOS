// ---------------------------------------------------------------------------
// Vazamento de Luz (Ultra Motion)
// origem : assets/effects/um-light-leak.xml
// id     : nova.effect.ultramotion.lightleak
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_light_leakParams {
    float angle;
    float softness;
    float drift;
    float intensity;
    float4 tint;
};

fragment float4 fx_um_light_leak(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_light_leakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = radians(u.angle);
    float2 n = float2(cos(a), sin(a));
    float t = dot(in.acScreenNorm - 0.5, n) + 0.5 + sin(eng.acTime) * u.drift;
    float leak = smoothstep(1.0 - u.softness, 1.0 + u.softness * 0.2, t);
    // Vazamento soft-light
    float3 cor = orig.rgb + u.tint.rgb * leak * u.intensity * u.tint.a;
    // Toque de clareio onde a luz bate forte
    cor = mix(cor, 1.0 - (1.0 - cor) * (1.0 - u.tint.rgb * u.tint.a), leak * 0.5);
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
