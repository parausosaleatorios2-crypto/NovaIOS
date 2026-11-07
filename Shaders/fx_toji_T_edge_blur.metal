// ---------------------------------------------------------------------------
// T_Edge Blur
// origem : assets/effects/toji-T_edge_blur.xml
// id     : com.alightcreative.effects.edgeblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_T_edge_blurParams {
    float edgeThreshold;
    float edgeGain;
    float blurRadius;
};

fragment float4 fx_toji_T_edge_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_T_edge_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            
            // 1. Setup
            // Aspect correct pixel size for sampling
            float2 texel = float2(1.0) / __nv_getTexSize(inputImg_info.size);
            
            // --- 2. Edge Detection (Sobel Operator) ---
            float gx = 0.0;
            float gy = 0.0;
            
            // Iterate over 3x3 kernel
            for(int i = -1; i <= 1; i++){
                for(int j = -1; j <= 1; j++){
                    // Sample neighbor pixel
                    float3 s = inputImg.sample(__nv_smp, uv + float2(float(i), float(j)) * texel).rgb;
                    // Convert to grayscale intensity (Luma)
                    float intensity = dot(s, float3(0.299, 0.587, 0.114));
                    
                    // Sobel X Kernel: 
                    // -1  0  1
                    // -2  0  2
                    // -1  0  1
                    if(i != 0) gx += intensity * float(i) * ((j == 0) ? 2.0 : 1.0);
                    
                    // Sobel Y Kernel:
                    // -1 -2 -1
                    //  0  0  0
                    //  1  2  1
                    if(j != 0) gy += intensity * float(j) * ((i == 0) ? 2.0 : 1.0);
                }
            }
            
            // Calculate gradient magnitude
            float edge = sqrt(gx*gx + gy*gy);
            
            // Create a smooth mask based on threshold and gain
            // 0.0 = Flat area, 1.0 = Edge
            float mask = smoothstep(u.edgeThreshold, u.edgeThreshold + 0.1, edge * u.edgeGain);
            mask = clamp(mask, 0.0, 1.0);

            // --- 3. Blur Calculation ---
            // We calculate a blurred color for the current pixel
            float3 blurCol = float3(0.0);
            float total = 0.0;
            
            // Fixed loop for consistent performance
            // We simulate a larger radius by spreading the samples
            const int R = 4; 
            
            // Adjust sample spacing based on the u.blurRadius uniform
            float2 blurStep = texel * (u.blurRadius / float(R)); 
            
            for(int x = -R; x <= R; x++) {
                for(int y = -R; y <= R; y++) {
                    blurCol += inputImg.sample(__nv_smp, uv + float2(float(x), float(y)) * blurStep).rgb;
                    total += 1.0;
                }
            }
            blurCol /= total;
            
            // --- 4. Composite ---
            float4 original = inputImg.sample(__nv_smp, uv);
            
            // Mix the original image with the blurred version using the edge mask
            // The edges become blurred, while non-edges stay sharp.
            float3 col = mix(original.rgb, blurCol, mask);
            
            // Output
            __nv_out = float4(col, original.a);
    return __nv_out;
}
