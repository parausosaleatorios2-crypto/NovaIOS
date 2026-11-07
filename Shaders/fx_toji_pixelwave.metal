// ---------------------------------------------------------------------------
// Pixel Wave
// origem : assets/effects/toji-pixelwave.xml
// id     : com.alightcreative.effects.pixelwave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_pixelwaveParams {
    float frequency;
    float amplitude;
    float speed;
    float pixelSize;
    float2 direction;
    float4 tintColor;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
// Utility functions
        static float2 pixelate(float2 uv, float u.pixelSize) {
            return floor(uv * u.pixelSize) / u.pixelSize;
        }
        
        static float wave(float2 uv, float freq, float amp, float time, float2 dir) {
            float x = uv.x * dir.x + uv.y * dir.y;
            return sin(x * freq + time) * amp;
        }
        
        // Overlay blend mode
        static float3 blendOverlay(float3 base, float3 blend) {
            return mix(
                2.0 * base * blend,
                1.0 - 2.0 * (1.0 - base) * (1.0 - blend),
                step(0.5, base)
            );
        }

fragment float4 fx_toji_pixelwave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_pixelwaveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalize u.direction vector
            float2 dir = normalize(u.direction);
            
            // Calculate time-based animation
            float time = eng.acTime * u.speed;
            
            // Get original texture coordinates
            float2 uv = in.acScreenNorm;
            
            // Apply pixelation
            float2 pixelUV = pixelate(uv, u.pixelSize);
            
            // Apply wave distortion
            float offset = wave(pixelUV, u.frequency, u.amplitude / 1000.0, time, dir);
            float2 distortedUV = uv + float2(offset * dir.y, -offset * dir.x);
            
            // Sample the input texture with distorted coordinates
            float4 texColor = inputImg.sample(__nv_smp, distortedUV);
            float4 compColor = comp.sample(__nv_smp, distortedUV);
            
            // Apply tint color
            float3 tinted = texColor.rgb * u.tintColor.rgb;
            
            // Apply blend mode
            float3 result;
            if (u.blendMode == 0) { // Normal
                result = mix(texColor.rgb, tinted, u.tintColor.a);
            } else if (u.blendMode == 1) { // Multiply
                result = texColor.rgb * mix(float3(1.0), u.tintColor.rgb, u.tintColor.a);
            } else if (u.blendMode == 2) { // Screen
                result = 1.0 - (1.0 - texColor.rgb) * (1.0 - mix(float3(0.0), u.tintColor.rgb, u.tintColor.a));
            } else { // Overlay
                result = mix(texColor.rgb, blendOverlay(texColor.rgb, u.tintColor.rgb), u.tintColor.a);
            }
            
            // Final output with u.alpha blending
            __nv_out = mix(texColor, float4(result, texColor.a), u.alpha);
    return __nv_out;
}
