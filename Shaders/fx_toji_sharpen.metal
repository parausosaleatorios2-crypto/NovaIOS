// ---------------------------------------------------------------------------
// @am:string/effect_sharpen_name
// origem : assets/effects/toji-sharpen.xml
// id     : com.alightcreative.effects.sharpen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_sharpenParams {
    float strength;
    float radius;
};

fragment float4 fx_toji_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 st = in.acScreenNorm;
            float2 fragSize = float2(1.)/__nv_getTexSize(inputImg_info.size) * u.radius;
            float4 w  = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x - fragSize.x, in.acScreenNorm.y));
            float4 e  = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x + fragSize.x, in.acScreenNorm.y));
            float4 n  = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y + fragSize.y));
            float4 s  = inputImg.sample(__nv_smp, float2(in.acScreenNorm.x, in.acScreenNorm.y - fragSize.y));
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            float centerWeight = 1. + u.strength*4.;
            float sideWeight = -u.strength;

            __nv_out = n*sideWeight + s*sideWeight + e*sideWeight + w*sideWeight + texColor*centerWeight;
    return __nv_out;
}
