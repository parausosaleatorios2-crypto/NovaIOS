// ---------------------------------------------------------------------------
// @am:string/effect_lumakey_name
// origem : assets/effects/toji-lumakey2.xml
// id     : com.alightcreative.effects.lumakey2
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lumakey2Params {
    float lowThreshold;
    float highThreshold;
    float feather;
    int invert;
    int weighted;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
        const float3 uniformWeighting = float3(0.3333, 0.3334, 0.3333);

fragment float4 fx_toji_lumakey2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lumakey2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luma = u.weighted ? length(texColor.rgb * luminanceWeighting) : length(texColor.rgb * uniformWeighting);
            //float alpha = smoothstep( threshold-u.feather/2., threshold+u.feather/2., length(texColor.rgb) );
            float lowThresholdA = clamp(u.lowThreshold-u.feather/2.,0.,1.);
            float lowThresholdB = clamp(lowThresholdA+u.feather,0.,1.);
            float highThresholdA = clamp(u.highThreshold-u.feather/2.,0.,1.);
            float highThresholdB = clamp(highThresholdA+u.feather,0.,1.);
            float lowBlend = smoothstep( lowThresholdA, lowThresholdB, luma );
            float highBlend = 1. - smoothstep( highThresholdA, highThresholdB, luma );
            float alpha = min(lowBlend,highBlend);
            if(u.invert) alpha = 1.-alpha;
            __nv_out = texColor*alpha;
    return __nv_out;
}
