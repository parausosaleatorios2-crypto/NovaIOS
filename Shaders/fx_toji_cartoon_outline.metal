// ---------------------------------------------------------------------------
// Cartoon Outline
// origem : assets/effects/toji-cartoon_outline.xml
// id     : com.alightcreative.effects.cartoon_outline
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cartoon_outlineParams {
    float outlineWidth;
    float outlineIntensity;
    float4 outlineColor;
    float edgeThreshold;
    int smoothEdges;
    int preserveOriginal;
};

// --- funcoes auxiliares do efeito
// Cartoon Outline Effect - Creates black outline around edges
        
        static float3 rgb2gray(float3 c) {
            return float3(dot(c, float3(0.299, 0.587, 0.114)));
        }
        
        static float sobelEdge(float2 uv, float threshold) {
            float s = u.outlineWidth * 0.001;
            
            // Sobel edge detection kernel
            float gx = 0.0;
            float gy = 0.0;
            
            // Sample neighboring pixels
            float tl = rgb2gray(inputImg.sample(__nv_smp, uv + float2(-s, -s)).rgb).r;
            float tm = rgb2gray(inputImg.sample(__nv_smp, uv + float2(0.0, -s)).rgb).r;
            float tr = rgb2gray(inputImg.sample(__nv_smp, uv + float2(s, -s)).rgb).r;
            
            float ml = rgb2gray(inputImg.sample(__nv_smp, uv + float2(-s, 0.0)).rgb).r;
            float mr = rgb2gray(inputImg.sample(__nv_smp, uv + float2(s, 0.0)).rgb).r;
            
            float bl = rgb2gray(inputImg.sample(__nv_smp, uv + float2(-s, s)).rgb).r;
            float bm = rgb2gray(inputImg.sample(__nv_smp, uv + float2(0.0, s)).rgb).r;
            float br = rgb2gray(inputImg.sample(__nv_smp, uv + float2(s, s)).rgb).r;
            
            // Sobel X kernel: [-1  0  1; -2  0  2; -1  0  1]
            gx = -tl - 2.0 * ml - bl + tr + 2.0 * mr + br;
            
            // Sobel Y kernel: [-1 -2 -1;  0  0  0;  1  2  1]
            gy = -tl - 2.0 * tm - tr + bl + 2.0 * bm + br;
            
            float edge = sqrt(gx * gx + gy * gy);
            return smoothstep(threshold, threshold * 2.0, edge);
        }
        
        static float advancedEdge(float2 uv, float threshold) {
            float edge1 = sobelEdge(uv, threshold);
            
            // Additional edge detection for better outline quality
            float s2 = u.outlineWidth * 0.002;
            float center = rgb2gray(inputImg.sample(__nv_smp, uv).rgb).r;
            
            float edge2 = 0.0;
            for (int i = 0; i < 8; i++) {
                float angle = float(i) * 3.14159 / 4.0;
                float2 offset = float2(cos(angle), sin(angle)) * s2;
                float sample = rgb2gray(inputImg.sample(__nv_smp, uv + offset).rgb).r;
                edge2 += abs(center - sample);
            }
            edge2 /= 8.0;
            
            return max(edge1, smoothstep(threshold * 0.5, threshold, edge2));
        }

fragment float4 fx_toji_cartoon_outline(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cartoon_outlineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float4 originalColor = inputImg.sample(__nv_smp, uv);
            
            // Edge detection
            float edge = advancedEdge(uv, u.edgeThreshold);
            
            // Apply intensity and smoothness
            if (u.smoothEdges) {
                edge = smoothstep(0.0, 1.0, edge * u.outlineIntensity);
            } else {
                edge = step(0.1, edge * u.outlineIntensity);
            }
            
            // Create outline color
            float4 outline = float4(u.outlineColor.rgb, u.outlineColor.a * edge);
            
            // Composite with original
            float4 result;
            if (u.preserveOriginal) {
                // Blend outline over original (preserves original colors)
                result = mix(originalColor, outline, outline.a);
            } else {
                // Replace with outline where detected
                result = mix(originalColor, outline, edge);
            }
            
            // Preserve original alpha
            result.a = originalColor.a;
            
            __nv_out = result;
    return __nv_out;
}
