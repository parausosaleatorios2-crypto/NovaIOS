// ---------------------------------------------------------------------------
// Mojo
// origem : assets/effects/toji-1mojo.xml
// id     : com.alightcreative.effects.mojo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_1mojoParams {
    float mojo;
    float tint;
    float punch;
    float bleach;
    float fade;
    float blueSqueeze;
    float skinSqueeze;
    float exposure;
    float coolWarm;
    float greenMagenta;
    float skinYellowPink;
    int preserveHighlights;
    int protectSkinTones;
};

// --- funcoes auxiliares do efeito
// Mojo Cinematic Color Grading Effect
        // Professional blockbuster look with enhanced skin tones
        
        // Utility functions
        float3 rgb2hsv(float3 c) {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
            
            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }
        
        float3 hsv2rgb(float3 c) {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }
        
        // Skin tone detection
        bool isSkinTone(float3 rgb) {
            float3 hsv = rgb2hsv(rgb);
            float h = hsv.x; // Already in 0-1 range
            float s = hsv.y;
            float v = hsv.z;
            
            // Skin tone hue range (orange-red to yellow-orange) - normalized to 0-1
            // Expanded range to catch more skin tones
            bool hueRange = (h > 0.02 && h < 0.16); // 7-58 degrees normalized
            bool satRange = (s > 0.1 && s < 0.85); // More forgiving saturation range
            bool valRange = (v > 0.15 && v < 0.95); // More forgiving brightness range
            
            return hueRange && satRange && valRange;
        }
        
        // Mojo color transformation
        float3 applyMojo(float3 rgb) {
            float mojoStrength = u.mojo * 0.01;
            
            // Apply u.exposure (always applied, not dependent on u.mojo strength)
            rgb *= pow(2.0, u.exposure);
            
            // Apply cool/warm temperature shift
            if (u.coolWarm != 0.0) {
                float temp = u.coolWarm * 0.01 * mojoStrength;
                rgb.r += temp * 0.15;
                rgb.b -= temp * 0.15;
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            // Apply green/magenta tint
            if (u.greenMagenta != 0.0) {
                float tint = u.greenMagenta * 0.01 * mojoStrength;
                rgb.g += tint * 0.15;
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            // Apply u.punch (contrast enhancement)
            if (u.punch != 0.0) {
                float punchStrength = u.punch * 0.01 * mojoStrength;
                float3 contrast = mix(float3(0.5), rgb, 1.0 + punchStrength * 0.5);
                rgb = contrast;
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            // Apply u.bleach bypass effect
            if (u.bleach != 0.0) {
                float bleachStrength = u.bleach * 0.01 * mojoStrength;
                float luminance = dot(rgb, float3(0.299, 0.587, 0.114));
                float3 bleachColor = mix(rgb, float3(luminance), 0.5 * bleachStrength);
                rgb = mix(rgb, bleachColor, mojoStrength);
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            // Apply u.fade
            if (u.fade != 0.0) {
                float fadeStrength = u.fade * 0.01 * mojoStrength;
                float3 fadeColor = mix(rgb, float3(0.5, 0.5, 0.5), fadeStrength);
                rgb = fadeColor;
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            // Apply blue squeeze (cooler shadows)
            if (u.blueSqueeze != 0.0) {
                float luminance = dot(rgb, float3(0.299, 0.587, 0.114));
                float blueSqueezeStrength = u.blueSqueeze * 0.01 * mojoStrength;
                
                // Cooler shadows and midtones
                if (luminance < 0.7) {
                    float shadowFactor = (0.7 - luminance) / 0.7;
                    rgb.b += blueSqueezeStrength * shadowFactor * 0.2;
                    rgb.r -= blueSqueezeStrength * shadowFactor * 0.1;
                    rgb = clamp(rgb, 0.0, 1.0);
                }
            }
            
            // Apply skin tone squeeze
            if (u.skinSqueeze != 0.0) {
                if (isSkinTone(rgb)) {
                    float skinSqueezeStrength = u.skinSqueeze * 0.01 * mojoStrength;
                    float3 hsv = rgb2hsv(rgb);
                    
                    // Enhance skin tone saturation
                    hsv.y = mix(hsv.y, min(hsv.y * 1.3, 1.0), skinSqueezeStrength);
                    
                    // Adjust skin tone hue towards warmer tones
                    if (hsv.x < 0.04) { // Too red
                        hsv.x = mix(hsv.x, 0.08, skinSqueezeStrength * 0.3);
                    } else if (hsv.x > 0.13) { // Too yellow
                        hsv.x = mix(hsv.x, 0.10, skinSqueezeStrength * 0.3);
                    }
                    
                    rgb = hsv2rgb(hsv);
                    rgb = clamp(rgb, 0.0, 1.0);
                }
            }
            
            // Apply skin yellow/pink adjustment
            if (u.skinYellowPink != 0.0) {
                if (isSkinTone(rgb)) {
                    float skinAdjust = u.skinYellowPink * 0.01 * mojoStrength;
                    float3 hsv = rgb2hsv(rgb);
                    
                    // Yellow (lower hue) vs Pink (higher hue)
                    hsv.x = clamp(hsv.x + skinAdjust * 0.08, 0.03, 0.14);
                    
                    rgb = hsv2rgb(hsv);
                    rgb = clamp(rgb, 0.0, 1.0);
                }
            }
            
            // Apply overall tint
            if (tint != 0.0) {
                float tintStrength = tint * 0.01 * mojoStrength;
                float3 tintColor = float3(1.0 + tintStrength * 0.2, 1.0, 1.0 - tintStrength * 0.2);
                rgb *= tintColor;
                rgb = clamp(rgb, 0.0, 1.0);
            }
            
            return rgb;
        }
        
        // Highlight protection
        float3 protectHighlights(float3 rgb) {
            if (u.preserveHighlights) {
                float maxChannel = max(max(rgb.r, rgb.g), rgb.b);
                if (maxChannel > 0.95) {
                    float highlightReduction = (maxChannel - 0.95) / 0.05;
                    rgb = mix(rgb, clamp(rgb, 0.0, 0.95), highlightReduction * 0.5);
                }
            }
            return rgb;
        }

fragment float4 fx_toji_1mojo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_1mojoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float4 original = inputImg.sample(__nv_smp, uv);
            float3 rgb = original.rgb;
            
            // Apply u.mojo transformation with all parameters
            float3 mojoColor = applyMojo(rgb);
            
            // Protect highlights
            mojoColor = protectHighlights(mojoColor);
            
            // Apply final blend with u.mojo strength
            float3 finalColor = mix(rgb, mojoColor, u.mojo * 0.01);
            
            // Ensure we don't exceed valid color ranges
            finalColor = clamp(finalColor, 0.0, 1.0);
            
            // Preserve original alpha
            __nv_out = float4(finalColor, original.a);
    return __nv_out;
}
