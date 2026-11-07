// ---------------------------------------------------------------------------
// Blocos de Glitch
// origem : assets/effects/nv-um-glitch-blocks.xml
// id     : nova.effect.um-glitch-blocks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_glitch_blocksParams {
    float amount;
    float blockSize;
    float speed;
    float channelShift;
};

// --- funcoes auxiliares do efeito
float2 hash2(float2 p) {
    p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

fragment float4 fx_nv_um_glitch_blocks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_glitch_blocksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 px = uv * eng.acResolution;
    float2 blockId = floor(px / u.blockSize);
    float tSlot = floor(eng.acTime * u.speed * 4.0) / 4.0;
    float2 h = hash2(blockId + tSlot);
    float ativo = step(1.0 - u.amount, h.x);

    float2 shift = (h - 0.5) * u.amount * 0.12 * ativo;
    float2 uvS = uv + shift;

    float rShift = u.channelShift * u.amount * 0.02 * ativo;
    float r = inputImg.sample(__nv_smp, uvS + float2(rShift, 0.0)).r;
    float4 g = inputImg.sample(__nv_smp, uvS);
    float b = inputImg.sample(__nv_smp, uvS - float2(rShift, 0.0)).b;

    __nv_out = float4(r, g.g, b, g.a);
    return __nv_out;
}
