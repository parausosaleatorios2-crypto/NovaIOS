// ---------------------------------------------------------------------------
// Tritone (AE)
// origem : assets/effects/ae-tritone.xml
// id     : nova.effect.aetritone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_tritoneParams {
    float4 highlights;
    float4 midtones;
    float4 shadows;
    float blendWithOriginal;
};

fragment float4 fx_ae_tritone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_tritoneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float y = dot(c.rgb, float3(0.299, 0.587, 0.114));
    float3 cor = y < 0.5 ? mix(u.shadows.rgb, u.midtones.rgb, clamp(y * 2.0, 0.0, 1.0))
                       : mix(u.midtones.rgb, u.highlights.rgb, clamp(y * 2.0 - 1.0, 0.0, 1.0));
    __nv_out = float4(mix(cor, c.rgb, clamp(u.blendWithOriginal / 100.0, 0.0, 1.0)), c.a);
    return __nv_out;
}
