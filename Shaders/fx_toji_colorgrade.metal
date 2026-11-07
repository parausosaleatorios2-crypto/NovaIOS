// ---------------------------------------------------------------------------
// Advanced Color Grading
// origem : assets/effects/toji-colorgrade.xml
// id     : com.alightcreative.effects.colorgrade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colorgradeParams {
    float EXPOSURE;
    float CONTRAST;
    float SATURATION;
    float VIBRANCE;
    float4 SHADOWS_COLOR;
    float SHADOWS_STRENGTH;
    float4 MIDTONES_COLOR;
    float MIDTONES_STRENGTH;
    float4 HIGHLIGHTS_COLOR;
    float HIGHLIGHTS_STRENGTH;
    float TEMPERATURE;
    float TINT;
    float GRAIN;
    float VIGNETTE;
    float FADE;
};

// --- funcoes auxiliares do efeito
// Utility functions
    static float3 rgb2hsv(float3 c) {
        float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
        float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        
        float d = q.x - min(q.w, q.y);
        float e = 1.0e-10;
        return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
    }

    static float3 hsv2rgb(float3 c) {
        float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
        float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    // Random function for grain
    static float random(float2 st) {
        return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
    }

fragment float4 fx_toji_colorgrade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colorgradeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float2 uv = in.acScreenNorm;
        float4 color = inputImg.sample(__nv_smp, uv);
        
        // Apply temperature and tint
        float3 rgb = color.rgb;
        if (u.TEMPERATURE != 0.0) {
            float t = u.TEMPERATURE * 0.05;
            rgb.r += t;
            rgb.b -= t;
        }
        if (u.TINT != 0.0) {
            float t = u.TINT * 0.05;
            rgb.g += t;
        }
        
        // Apply exposure
        rgb *= pow(2.0, u.EXPOSURE);
        
        // Split into shadows, midtones, and highlights
        float luminance = dot(rgb, float3(0.299, 0.587, 0.114));
        float shadowsMask = 1.0 - smoothstep(0.0, 0.5, luminance);
        float highlightsMask = smoothstep(0.5, 1.0, luminance);
        float midtonesMask = 1.0 - shadowsMask - highlightsMask;
        
        // Apply color wheel tints
        float3 shadowsColor = mix(float3(1.0), u.SHADOWS_COLOR.rgb, u.SHADOWS_STRENGTH);
        float3 midtonesColor = mix(float3(1.0), u.MIDTONES_COLOR.rgb, u.MIDTONES_STRENGTH);
        float3 highlightsColor = mix(float3(1.0), u.HIGHLIGHTS_COLOR.rgb, u.HIGHLIGHTS_STRENGTH);
        
        rgb = rgb * shadowsColor * shadowsMask + 
              rgb * midtonesColor * midtonesMask + 
              rgb * highlightsColor * highlightsMask;
        
        // Apply contrast
        rgb = mix(float3(0.5), rgb, u.CONTRAST);
        
        // Convert to HSV for saturation and vibrance
        float3 hsv = rgb2hsv(rgb);
        
        // Apply saturation
        hsv.y *= u.SATURATION;
        
        // Apply vibrance (saturation that protects skin tones)
        if (u.VIBRANCE != 0.0) {
            float sat = hsv.y;
            hsv.y = mix(sat, pow(sat, 0.25), u.VIBRANCE);
        }
        
        // Convert back to RGB
        rgb = hsv2rgb(hsv);
        
        // Apply film grain
        if (u.GRAIN > 0.0) {
            float grain = random(uv * eng.acTime) * 2.0 - 1.0;
            rgb += grain * u.GRAIN;
        }
        
        // Apply vignette
        if (u.VIGNETTE > 0.0) {
            float2 center = uv - 0.5;
            float vignette = 1.0 - dot(center, center) * 1.5 * u.VIGNETTE;
            rgb *= clamp(vignette, 0.0, 1.0);
        }
        
        // Apply fade
        if (u.FADE > 0.0) {
            rgb = mix(rgb, float3(0.5, 0.5, 0.5), u.FADE);
        }
        
        __nv_out = float4(rgb, color.a);
    return __nv_out;
}
