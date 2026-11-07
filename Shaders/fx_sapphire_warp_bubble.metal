// ---------------------------------------------------------------------------
// S_WarpBubble
// origem : assets/effects/sapphire-warp-bubble.xml
// id     : nova.effect.swarpbubble
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_warp_bubbleParams {
    float amplitude;
    float frequency;
    float frequencyRelX;
    float octaves;
    float seed;
    float rotateWarpDir;
    float shiftStartX;
    float shiftStartY;
    float shiftSpeedX;
    float shiftSpeedY;
    float zDist;
    int wrapX;
    int wrapY;
    int useFilter;
};

fragment float4 fx_sapphire_warp_bubble(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_warp_bubbleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
