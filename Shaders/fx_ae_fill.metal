// ---------------------------------------------------------------------------
// Fill (AE)
// origem : assets/effects/ae-fill.xml
// id     : nova.effect.aefill
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_fillParams {
    float4 color;
    int invert;
    float opacity;
};

fragment float4 fx_ae_fill(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_fillParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float a = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0)).a;
    if (u.invert) a = 1.0 - a;
    __nv_out = float4(u.color.rgb, a * clamp(u.opacity, 0.0, 1.0));
    return __nv_out;
}
