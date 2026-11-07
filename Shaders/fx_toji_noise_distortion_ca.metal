// ---------------------------------------------------------------------------
// Distort RGB
// origem : assets/effects/toji-noise_distortion_ca.xml
// id     : com.alightcreative.effects.noise_distortion_ca
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_noise_distortion_caParams {
    float distortion;
    float spread;
    float chromaMix;
    float scale;
    float speed;
    float blurStrength;
    float4 highlights;
    float4 midtones;
    float4 shadows;
};

// --- funcoes auxiliares do efeito
// Simple 2D Hash function
        float2 hash2(float2 p) {
            p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
            return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
        }

        // 2D Gradient Noise
        float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);

            float2 u = f * f * (3.0 - 2.0 * f);

            return mix(mix(dot(hash2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                           dot(hash2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)), u.x),
                       mix(dot(hash2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                           dot(hash2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)), u.x), u.y);
        }

fragment float4 fx_toji_noise_distortion_ca(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_noise_distortion_caParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalized pixel coordinates (from 0 to 1)
            float2 uv = in.acLayerNorm.xy;
            
            // Fix aspect ratio for noise generation so it looks uniform
            float2 noiseUV = uv;
            noiseUV.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            
            // Calculate Noise field for displacement
            float n = noise(noiseUV * u.scale + eng.acTime * u.speed);
            float n2 = noise(noiseUV * u.scale + eng.acTime * u.speed + float2(17.3, 2.9));
            
            // Base displacement vector centered around 0
            float2 disp = float2(n, n2) * u.distortion;
            
            // --- Warp Blur & Chromatic Aberration Logic ---
            
            float3 accumulatedColor = float3(0.0);
            float totalWeight = 0.0;
            float accumulatedAlpha = 0.0;
            
            // Number of samples for the blur
            const int samples = 16;
            
            // Loop to accumulate samples along the displacement vector
            for (int i = 0; i < samples; i++) {
                // Normalized progress from 0.0 to 1.0
                float t = float(i) / float(samples - 1);
                
                // Calculate a blur offset relative to the main displacement
                // Centered around 0.5
                float2 blurOffset = disp * (t - 0.5) * u.blurStrength;
                
                // The total offset for this specific sample
                float2 currentDisp = disp + blurOffset;
                
                // Calculate Chromatic coordinates based on u.spread
                float2 uvR = uv + currentDisp * (1.0 + u.spread * 5.0);
                float2 uvG = uv + currentDisp;
                float2 uvB = uv + currentDisp * (1.0 - u.spread * 5.0);
                
                // Sample the channels and multiply by specific colors
                float r = inputImg.sample(__nv_smp, uvR).r * u.highlights.r;
                float g = inputImg.sample(__nv_smp, uvG).g * u.midtones.g;
                float b = inputImg.sample(__nv_smp, uvB).b * u.shadows.b;
                float a = inputImg.sample(__nv_smp, uvG).a;
                
                float3 col = float3(r, g, b);
                float w = 1.0; // Box blur weight
                
                accumulatedColor += col * w;
                accumulatedAlpha += a * w;
                totalWeight += w;
            }
            
            // Average the samples
            float3 chromaticBlurred = accumulatedColor / totalWeight;
            float finalAlpha = accumulatedAlpha / totalWeight;
            
            // Calculate standard non-chromatic, non-blurred center for mixing
            float2 centerUV = uv + disp;
            float3 standardColor = inputImg.sample(__nv_smp, centerUV).rgb;
            
            // Mix based on user control 'u.chromaMix'
            float3 finalColor = mix(standardColor, chromaticBlurred, u.chromaMix);

            // Output to screen
            __nv_out = float4(finalColor, finalAlpha);
    return __nv_out;
}
