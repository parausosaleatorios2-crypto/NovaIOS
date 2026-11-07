// ---------------------------------------------------------------------------
// Onda de Plasma (Ultra Motion)
// origem : assets/effects/um-plasma-wave.xml
// id     : nova.effect.ultramotion.plasmawave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_plasma_waveParams {
    float scale;
    float speed;
    float intensity;
    float4 c1;
    float4 c2;
    float4 c3;
};

fragment float4 fx_um_plasma_wave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_plasma_waveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 p = (in.acScreenNorm - 0.5) * u.scale;
    float t = eng.acTime * u.speed;
    float v = sin(p.x + t);
    v += sin(p.y + t * 1.3);
    v += sin((p.x + p.y) * 0.7 + t * 0.7);
    v += sin(length(p) * 2.0 - t * 2.0);
    float a = v / 4.0 * 0.5 + 0.5;

    float3 plasma;
    if (a < 0.5) plasma = mix(u.c1.rgb, u.c2.rgb, a * 2.0);
    else         plasma = mix(u.c2.rgb, u.c3.rgb, (a - 0.5) * 2.0);

    __nv_out = float4(mix(orig.rgb, plasma, u.intensity), orig.a);
    return __nv_out;
}
