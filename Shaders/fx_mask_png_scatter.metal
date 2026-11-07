// ---------------------------------------------------------------------------
// MaskPNGScatter
// origem : assets/effects/mask-png-scatter.xml
// id     : nova.effect.maskpngscatter
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mask_png_scatterParams {
    float pngCount;
    float pngSize;
    float randomSeed;
    float maxRotation;
    float xOffset;
    float yOffset;
    float globalRotation;
    float globalScale;
};

fragment float4 fx_mask_png_scatter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mask_png_scatterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pngLayer [[texture(1)]],
    texture2d<float> matteLayer [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
