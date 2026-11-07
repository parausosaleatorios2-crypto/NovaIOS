// ---------------------------------------------------------------------------
// @am:string/effect_lumakey_name
// origem : assets/effects/toji-lumakey3.xml
// id     : com.alightcreative.effects.lumakey3
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lumakey3Params {
    float lowThreshold;
    float highThreshold;
    float feather;
    int invert;
    int weighted;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        const float3 uniformWeighting = float3(0.3333, 0.3334, 0.3333);

fragment float4 fx_toji_lumakey3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lumakey3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luma = dot(texColor.rgb, u.weighted ? luminanceWeighting : uniformWeighting);

            float lowThresholdB = (u.lowThreshold*(1.0+u.feather))-0.001;
            float lowThresholdA = lowThresholdB-max(u.feather,0.00001);
            float highThresholdA = (u.highThreshold*(1.0+u.feather)-u.feather)+0.001;
            float highThresholdB = highThresholdA+max(u.feather,0.00001);

            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float alpha = min(lowBlend,highBlend);
            if(u.invert) alpha = 1.-alpha;
            __nv_out = texColor*alpha;
    return __nv_out;
}
