// ---------------------------------------------------------------------------
// Raios em Leque (Ultra Motion)
// origem : assets/effects/um-rays-grad.xml
// id     : nova.effect.ultramotion.raysgrad
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_rays_gradParams {
    float count;
    float spin;
    float intensity;
    float falloff;
    float4 tint;
    float2 source;
};

fragment float4 fx_um_rays_grad(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_rays_gradParams&  u    [[buffer(1)]],
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
    float ang = __nv_atan(p.y, p.x) + eng.acTime * u.spin;
    float faixa = 0.5 + 0.5 * cos(ang * float(int(u.count)));
    float queda = exp(-r * u.falloff * 2.0);
    float raio = faixa * queda;
    float3 cor = orig.rgb + u.tint.rgb * u.tint.a * raio * u.intensity;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
