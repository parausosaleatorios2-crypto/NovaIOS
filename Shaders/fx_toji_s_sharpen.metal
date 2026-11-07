// ---------------------------------------------------------------------------
// structure
// origem : assets/effects/toji-s_sharpen.xml
// id     : com.alightcreative.effects.s_sharpen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_sharpenParams {
    float sharpenAmp;
    float sharpenWidth;
    float edgeThreshold;
    float scaleTiny;
    float scaleSmall;
    float scaleMedium;
    float scaleLarge;
    float sharpenLuma;
    float sharpenChroma;
    float sharpenR;
    float sharpenG;
    float sharpenB;
};

// --- funcoes auxiliares do efeito
// S_Sharpen - Multi-Frequency Detail Restoration
        
        const float SmallDetailSize = 0.1;

        float getLuma(float3 rgb) {
            return dot(rgb, float3(0.299, 0.587, 0.114));
        }

        // Gaussian 5x5 approximation
        float3 blur(float2 uv, float radius) {
            float2 res = eng.acScreenSize;
            float3 col = float3(0.0);
            float total = 0.0;
            
            for(float x = -2.0; x <= 2.0; x++) {
                for(float y = -2.0; y <= 2.0; y++) {
                    float weight = exp(-(x*x + y*y) / (2.0 * radius * radius + 0.0001));
                    col += inputImg.sample(__nv_smp, uv + float2(x, y) / res * radius).rgb * weight;
                    total += weight;
                }
            }
            return col / total;
        }

fragment float4 fx_toji_s_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float4 src = inputImg.sample(__nv_smp, uv);
            float3 source = src.rgb;
            
            // Define frequency radii
            float baseR = u.sharpenWidth * 100.0;
            float rTiny   = SmallDetailSize * 0.5 * baseR;
            float rSmall  = SmallDetailSize * 1.0 * baseR;
            float rMedium = SmallDetailSize * 2.0 * baseR;
            float rLarge  = SmallDetailSize * 4.0 * baseR;
            
            // Frequency Separation
            float3 blurT = blur(uv, rTiny);
            float3 blurS = blur(uv, rSmall);
            float3 blurM = blur(uv, rMedium);
            float3 blurL = blur(uv, rLarge);
            
            float3 tinyFreq   = source - blurT;
            float3 smallFreq  = blurT - blurS;
            float3 mediumFreq = blurS - blurM;
            float3 largeFreq  = blurM - blurL;
            
            // Combine detail layers
            float3 details = (tinyFreq   * u.scaleTiny) +
                           (smallFreq  * u.scaleSmall) +
                           (mediumFreq * u.scaleMedium) +
                           (largeFreq  * u.scaleLarge);
            
            details *= u.sharpenAmp;
            
            // Coring / Edge Thresholding
            float diffLuma = getLuma(abs(details));
            float edgeMask = smoothstep(u.edgeThreshold + 0.1, u.edgeThreshold, diffLuma);
            details *= edgeMask;
            
            // Luma/Chroma Separation
            float sourceLuma = getLuma(source);
            float3 sourceChroma = source - sourceLuma;
            
            float detailLuma = getLuma(details);
            float3 detailChroma = details - detailLuma;
            
            // Assemble results
            float3 resLuma   = float3(sourceLuma + (detailLuma * u.sharpenLuma));
            float3 resChroma = sourceChroma + (detailChroma * u.sharpenChroma);
            
            float3 finalRGB = resLuma + resChroma;
            
            // Individual RGB logic
            finalRGB.r = mix(source.r, finalRGB.r, u.sharpenR);
            finalRGB.g = mix(source.g, finalRGB.g, u.sharpenG);
            finalRGB.b = mix(source.b, finalRGB.b, u.sharpenB);

            __nv_out = float4(finalRGB, src.a);
    return __nv_out;
}
