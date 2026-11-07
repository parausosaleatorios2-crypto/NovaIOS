// ---------------------------------------------------------------------------
// S_Glow
// origem : assets/effects/toji-s_glow.xml
// id     : com.alightcreative.effects.s_glow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_glowParams {
    float brightness;
    float threshold;
    float glowWidth;
    float widthX;
    float widthY;
    float dispersion;
    float quality;
    float blend;
};

// --- funcoes auxiliares do efeito
// S_Glow Ultra-Smooth Implementation for Alight Motion
        
        #define PI 3.14159265359
        #define GOLDEN_ANGLE 2.3999632

        static float dither(float2 uv) {
            return fract(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453) * 0.004;
        }

fragment float4 fx_toji_s_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Unifying to screen coordinates to fix squeeze/stretch issues
            float2 uv = in.acScreenNorm.xy;
            float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
            
            float4 source = inputImg.sample(__nv_smp, uv);
            
            float3 glowSum = float3(0.0);
            float totalWeight = 0.0;
            
            int samples = int(u.quality);
            
            // Scaled weights based on u.dispersion (Match: 1.0, 1.4, 2.2)
            float3 colorWeights = float3(1.0, 1.0 + u.dispersion * 0.4, 1.0 + u.dispersion * 1.2);
            
            for(int i = 0; i < 128; i++) {
                if (i >= samples) break;
                
                float fraction = float(i) / float(samples);
                float angle = float(i) * GOLDEN_ANGLE;
                
                // Non-linear distribution: pow(fraction, 0.8)
                float dist = pow(fraction, 0.8); 
                
                float2 dir = float2(cos(angle), sin(angle));
                float2 scale = float2(u.widthX, u.widthY) * u.glowWidth * 0.12;
                scale.x /= aspect; // Correct for screen resolution to keep glow circular
                
                // True Gaussian weight
                float weight = exp(-dist * dist * 5.0);
                
                // Chromatic sampling
                float2 uvR = uv + dir * dist * scale * colorWeights.r;
                float2 uvG = uv + dir * dist * scale * colorWeights.g;
                float2 uvB = uv + dir * dist * scale * colorWeights.b;
                
                // Sample and Threshold
                float r = max(inputImg.sample(__nv_smp, uvR).r - u.threshold, 0.0);
                float g = max(inputImg.sample(__nv_smp, uvG).g - u.threshold, 0.0);
                float b = max(inputImg.sample(__nv_smp, uvB).b - u.threshold, 0.0);
                
                glowSum += float3(r, g, b) * weight;
                totalWeight += weight;
            }
            
            // Normalize, Apply Brightness, and Dither
            float3 finalGlow = (glowSum / totalWeight) * u.brightness;
            finalGlow += dither(uv);
            
            // Screen Combine mode
            float3 result = 1.0 - (1.0 - source.rgb) * (1.0 - finalGlow);
            
            // Subtle contrast adjustment
            result = pow(max(result, 0.0), float3(0.95));
            
            float4 finalColor = float4(result, source.a);
            
            // Handle mixing - use original source as base to avoid global screen filling
            __nv_out = mix(source, finalColor, u.blend);
    return __nv_out;
}
