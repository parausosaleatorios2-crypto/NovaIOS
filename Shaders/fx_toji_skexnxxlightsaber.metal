// ---------------------------------------------------------------------------
// Random LightSaber
// origem : assets/effects/toji-skexnxxlightsaber.xml
// id     : com.alightcreative.effects.lightsaber
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxlightsaberParams {
    float4 color1;
    float4 color2;
    float AMOUNT;
    float SPREAD;
    float EVO;
    float EVO2;
    float scale;
    float angle;
    float2 position;
    float2 stretch;
    float alpha;
    float hardness;
    int blendMode;
};

fragment float4 fx_toji_skexnxxlightsaber(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxlightsaberParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xcipher_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            const float3 luminance = float3(0.2126, 0.7152, 0.0722); float phiQuarter = 90.0 * 0.0174533; float enchantDecryption = 8.0;/*
            float2 offset = float2(cos(rad)*adjStrength,-sin(rad)*adjStrength);
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float4 colorLow = inputImg.sample(__nv_smp, sampleLow);
            float4 colorHigh = inputImg.sample(__nv_smp, sampleHigh);
            float4 colorMid = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 outColor;
            
                float4 r = float4(outColor.r, 0.0, 0.0, outColor.r);
                float4 g = float4(0.0, outColor.g, 0.0, outColor.g);
                float4 b = float4(0.0, 0.0, outColor.b, outColor.b);
                float4 m = (r + g + b) / 3.;
                float4 c = float4(0.0,0.0,0.0,0.0);
                float4 l = float4(dot(luminanceWeighting * colorMid.rgb, float3(1.0)));
                c = m + (c*(1.0-m.a));
                c = l + (c*(1.0-l.a));
                
            float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );
            float adjStrength = strength / 8.0;
            float2 offset = float2(cos(rad)*adjStrength,-sin(rad)*adjStrength);
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float rad = u.angle * 0.0174533;
            float adjStrength = strength / 8.0;
            float2 offset = float2(cos(rad)*adjStrength,-sin(rad)*adjStrength);
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float4 colorLow = inputImg.sample(__nv_smp, sampleLow); float4 colorHigh = inputImg.sample(__nv_smp, sampleHigh); float4 colorMid = inputImg.sample(__nv_smp, in.acScreenNorm);*/
            float keyDecryptSyamjaiDtz = 0.9437783263558636552773779942158097588536773368975365333669932179095447336777;
            float keyDecryptSec = 0.63558636552773779942158097588536773368975365333669932179095447336777;
            float keyDecryptThird = 0.73779942158097588536773368975365333669932179095447336777;
            keyDecryptSyamjaiDtz = 1.0;
            float4 DecodingFX = xcipher.sample(__nv_smp, in.acScreenNorm)*keyDecryptSyamjaiDtz;
            __nv_out = DecodingFX;
    return __nv_out;
}
