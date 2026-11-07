// ---------------------------------------------------------------------------
// Sharpen 2
// origem : assets/effects/toji-MultiScaleSharpen.xml
// id     : com.custom.effects.multiscalesharpen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_MultiScaleSharpenParams {
    float sharpenAmp;
    float edgeThreshold;
    float smallDetailSize;
    float scaleTiny;
    float scaleSmall;
    float scaleMedium;
    float scaleLarge;
    float sharpenLuma;
    float sharpenChroma;
    float sharpenRed;
    float sharpenGreen;
    float sharpenBlue;
};

// --- funcoes auxiliares do efeito
// Color space conversion tools
    const float3 kY = float3(0.299, 0.587, 0.114);
    const float3 kI = float3(0.596, -0.275, -0.321);
    const float3 kQ = float3(0.212, -0.523, 0.311);

    static float3 rgb2yiq(float3 rgb) {
        return float3(dot(rgb, kY), dot(rgb, kI), dot(rgb, kQ));
    }

    static float3 yiq2rgb(float3 yiq) {
        float3 rgb;
        rgb.r = yiq.x + 0.956 * yiq.y + 0.621 * yiq.z;
        rgb.g = yiq.x - 0.272 * yiq.y - 0.647 * yiq.z;
        rgb.b = yiq.x - 1.105 * yiq.y + 1.702 * yiq.z;
        return rgb;
    }

    // Simple 4-tap blur for performance
    static float3 getBlur(float2 uv, float radius) {
        float2 off = float2(radius) / eng.acScreenSize;
        float3 acc = inputImg.sample(__nv_smp, uv + float2(-off.x, -off.y)).rgb;
        acc += inputImg.sample(__nv_smp, uv + float2( off.x, -off.y)).rgb;
        acc += inputImg.sample(__nv_smp, uv + float2(-off.x,  off.y)).rgb;
        acc += inputImg.sample(__nv_smp, uv + float2( off.x,  off.y)).rgb;
        return acc * 0.25;
    }

fragment float4 fx_toji_MultiScaleSharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_MultiScaleSharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float2 uv = in.acScreenNorm;
        
        // Base image
        float3 c0 = inputImg.sample(__nv_smp, uv).rgb;
        
        // --- MULTI-SCALE BANDPASS CALCULATION ---
        float s = u.smallDetailSize;
        
        // Generate blurred layers
        float3 bTiny  = getBlur(uv, s * 0.5);
        float3 bSmall = getBlur(uv, s * 1.0);
        float3 bMed   = getBlur(uv, s * 2.0);
        float3 bLarge = getBlur(uv, s * 4.0);
        
        // Isolate frequency bands (Difference of Gaussians approx)
        float3 dTiny  = c0 - bTiny;
        float3 dSmall = bTiny - bSmall;
        float3 dMed   = bSmall - bMed;
        float3 dLarge = bMed - bLarge;
        
        // Combine bands with user weights
        float3 detail = dTiny * u.scaleTiny 
                    + dSmall * u.scaleSmall 
                    + dMed * u.scaleMedium 
                    + dLarge * u.scaleLarge;
                    
        // --- THRESHOLDING ---
        float detailLuma = dot(abs(detail), kY);
        float gate = smoothstep(u.edgeThreshold, u.edgeThreshold + 0.05, detailLuma);
        detail *= gate;

        // --- LUMA / CHROMA SEPARATION ---
        float3 detailYIQ = rgb2yiq(detail);
        detailYIQ.x *= u.sharpenLuma;      // Y (Luma)
        detailYIQ.y *= u.sharpenChroma;    // I (Chroma)
        detailYIQ.z *= u.sharpenChroma;    // Q (Chroma)
        detail = yiq2rgb(detailYIQ);
        
        // --- RGB CHANNELS ---
        detail *= float3(u.sharpenRed, u.sharpenGreen, u.sharpenBlue);
        
        // --- FINAL COMPOSITION ---
        float3 result = c0 + detail * u.sharpenAmp;
        
        __nv_out = float4(result, 1.0);
    return __nv_out;
}
