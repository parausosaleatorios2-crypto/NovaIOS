// ---------------------------------------------------------------------------
// Hand Drawn
// origem : assets/effects/toji-hand_drawn.xml
// id     : com.alightcreative.effects.hand_drawn
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_hand_drawnParams {
    float warpAmount;
    float outlineStr;
    float fps;
};

// --- funcoes auxiliares do efeito
// Simple hash function for noise
        static float hash(float2 p) {
            p = fract(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return fract(p.x * p.y);
        }

        // 2D Value Noise
        static float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            float a = hash(i);
            float b = hash(i + float2(1.0, 0.0));
            float c = hash(i + float2(0.0, 1.0));
            float d = hash(i + float2(1.0, 1.0));
            return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
        }

fragment float4 fx_toji_hand_drawn(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_hand_drawnParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalized pixel coordinates (from 0 to 1)
            float2 uv = in.acScreenNorm;

            // --- 1. Hand Drawn Warp Effect ---
            // Quantize time to simulate lower framerate
            float timeSnap = floor(eng.acTime * u.fps);
            
            // Create random offsets for X and Y using the quantized time
            float2 noiseOffset = float2(
                noise(uv * 15.0 + timeSnap),
                noise(uv * 15.0 + timeSnap + 100.0)
            );
            
            // Distort the UVs
            float2 warpedUV = uv + (noiseOffset - 0.5) * u.warpAmount;

            // --- 2. Outline Detection ---
            float2 pixel = 1.0 / eng.acScreenSize;
            
            // Sample the base color at warped coordinates
            float4 texColorFull = inputImg.sample(__nv_smp, warpedUV);
            float3 texColor = texColorFull.rgb;
            
            // Sample neighbors to detect edges
            float3 n = inputImg.sample(__nv_smp, warpedUV + float2(0.0, pixel.y)).rgb;
            float3 e = inputImg.sample(__nv_smp, warpedUV + float2(pixel.x, 0.0)).rgb;
            float3 s = inputImg.sample(__nv_smp, warpedUV - float2(0.0, pixel.y)).rgb;
            float3 w = inputImg.sample(__nv_smp, warpedUV - float2(pixel.x, 0.0)).rgb;
            
            // Convert to luminance for edge checking
            float3 luma = float3(0.299, 0.587, 0.114);
            float lumC = dot(texColor, luma);
            float lumN = dot(n, luma);
            float lumS = dot(s, luma);
            float lumE = dot(e, luma);
            float lumW = dot(w, luma);
            
            // Calculate edge intensity (gradient magnitude)
            float edge = abs(lumN - lumS) + abs(lumE - lumW);
            float outline = 1.0 - clamp(edge * u.outlineStr, 0.0, 1.0);

            // --- 3. Final Composite ---
            // Apply the black outline (multiply)
            float3 finalColor = texColor * outline;

            // Output to screen
            __nv_out = float4(finalColor, texColorFull.a);
    return __nv_out;
}
