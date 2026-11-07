// ---------------------------------------------------------------------------
// Ondulação
// origem : assets/effects/ripple.xml
// id     : nova.effect.ripple
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct rippleParams {
    float2 center;
    float amplitude;
    float frequency;
    float speed;
    float radius;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float dist = length(offset);

    float wave = sin(dist * u.frequency - eng.acTime * u.speed * TAU) * u.amplitude * 0.004;
    float falloff = 1.0 - smoothstep(0.0, max(u.radius, 0.001), dist);

    // No centro exato não existe direção: dividir por zero produziria NaN, e um
    // NaN na coordenada de amostragem vira um pixel de lixo bem no meio.
    float2 direction = dist > 0.0001 ? offset / dist : float2(0.0);
    float2 shift = direction * wave * falloff;
    shift /= float2(eng.acAspect, 1.0);

    __nv_out = inputImg.sample(__nv_smp, clamp(in.acScreenNorm + shift, 0.0, 1.0));
    return __nv_out;
}
