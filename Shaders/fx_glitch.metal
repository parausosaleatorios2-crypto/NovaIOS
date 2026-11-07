// ---------------------------------------------------------------------------
// Falha digital
// origem : assets/effects/glitch.xml
// id     : nova.effect.glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct glitchParams {
    float amount;
    float blockCount;
    float density;
    float rate;
    float separation;
};

// --- funcoes auxiliares do efeito
float hash(float n) {
    return fract(sin(n * 12.9898) * 43758.5453);
}

fragment float4 fx_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float rows = max(u.blockCount, 1.0);
    float row = floor(in.acScreenNorm.y * rows);

    // Quantizar o tempo é o que dá o "degrau". Com eng.acTime cru, cada fatia
    // deslizaria continuamente e o resultado pareceria água, não defeito.
    float tick = floor(eng.acTime * max(u.rate, 0.01));
    float seed = hash(row * 1.7 + tick * 17.3);

    float glitching = step(1.0 - u.density, seed);
    float shift = (hash(seed * 7.13) - 0.5) * u.amount * 0.2 * glitching;

    float2 uv = clamp(in.acScreenNorm + float2(shift, 0.0), 0.0, 1.0);
    float split = u.separation * 0.004 * glitching;

    float4 result;
    result.r = inputImg.sample(__nv_smp, clamp(uv + float2(split, 0.0), 0.0, 1.0)).r;
    result.g = inputImg.sample(__nv_smp, uv).g;
    result.b = inputImg.sample(__nv_smp, clamp(uv - float2(split, 0.0), 0.0, 1.0)).b;
    result.a = inputImg.sample(__nv_smp, uv).a;

    __nv_out = result;
    return __nv_out;
}
