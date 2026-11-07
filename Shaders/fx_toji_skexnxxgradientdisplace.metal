// ---------------------------------------------------------------------------
// Gradient Displace
// origem : assets/effects/toji-skexnxxgradientdisplace.xml
// id     : com.alightcreative.effects.skegradientdisplace
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxgradientdisplaceParams {
    float strength;
    float smoothing;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_skexnxxgradientdisplace(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxgradientdisplaceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm;
            float2 fragSize = float2(1.)/__nv_getTexSize(inputImg_info.size) * (u.smoothing*24.);
            float4 leftColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y));
            float4 rightColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y));
            float4 topColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y + fragSize.y));
            float4 bottomColor = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y - fragSize.y));

            float left   = length(leftColor.rgb*luminanceWeighting);
            float right  = length(rightColor.rgb*luminanceWeighting);
            float top    = length(topColor.rgb*luminanceWeighting);
            float bottom = length(bottomColor.rgb*luminanceWeighting);

            float2 gradient = normalize(float2((right - left) / (2.*fragSize.x), (top - bottom) / (2.*fragSize.y)));

            float alpha = 1.0;
            alpha = min(alpha,leftColor.a);
            alpha = min(alpha,rightColor.a);
            alpha = min(alpha,topColor.a);
            alpha = min(alpha,bottomColor.a);

            __nv_out = comp.sample(__nv_smp, st+gradient*u.strength)*alpha;
    return __nv_out;
}
