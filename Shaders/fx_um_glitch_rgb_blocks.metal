// ---------------------------------------------------------------------------
// Glitch RGB em Blocos (Ultra Motion)
// origem : assets/effects/um-glitch-rgb-blocks.xml
// id     : nova.effect.ultramotion.glitchrgbblocks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_glitch_rgb_blocksParams {
    float rate;
    float maxShift;
    float density;
    float rows;
};

// --- funcoes auxiliares do efeito
float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

fragment float4 fx_um_glitch_rgb_blocks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_glitch_rgb_blocksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float faixa = floor(in.acScreenNorm.y * float(int(u.rows)));
    float semente = floor(eng.acTime * u.rate) + faixa;
    float sorteio = hash21(float2(semente, 7.3));
    float ligada = step(1.0 - u.density, sorteio);
    float d = (hash21(float2(semente, 11.7)) - 0.5) * 2.0 * u.maxShift * ligada;

    float r = inputImg.sample(__nv_smp, in.acScreenNorm + float2(d, 0.0)).r;
    float g = inputImg.sample(__nv_smp, in.acScreenNorm).g;
    float b = inputImg.sample(__nv_smp, in.acScreenNorm - float2(d, 0.0)).b;
    float a = inputImg.sample(__nv_smp, in.acScreenNorm).a;
    __nv_out = float4(r, g, b, a);
    return __nv_out;
}
