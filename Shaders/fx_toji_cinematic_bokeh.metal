// ---------------------------------------------------------------------------
// Bokeh Blur
// origem : assets/effects/toji-cinematic_bokeh.xml
// id     : com.creative.cinematic_bokeh
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cinematic_bokehParams {
    int blurShape;
    float blurWidth;
    float blurHeight;
    float blurRadius;
    float highlightThreshold;
    float highlightGain;
    float quality;
};

// --- funcoes auxiliares do efeito
const float GOLDEN_ANGLE = 2.39996323;
        const float PI = 3.14159265;

fragment float4 fx_toji_cinematic_bokeh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cinematic_bokehParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
            
            float r = u.blurRadius;
            float iterations = float(u.quality);
            
            float3 acc = float3(0.0);
            float tot = 0.0;
            
            // Polygon mapping function
            float sides = float(u.blurShape);
            
            for (int i = 0; i < 128; i++) 
            {
                if (float(i) >= iterations) break;

                float fi = float(i);
                float theta = fi * GOLDEN_ANGLE;
                float rad = sqrt(fi) / sqrt(iterations);
                
                // Shape modulation
                if (sides > 2.5) {
                    float deg = 2.0 * PI / sides;
                    rad *= 1.0 / cos(__nv_mod(theta, deg) - deg * 0.5);
                }

                float2 off = float2(cos(theta), sin(theta));
                
                // Anamorphic scaling and aspect correction
                float2 offset = off * rad * r;
                offset.x *= u.blurWidth / aspect;
                offset.y *= u.blurHeight;
                
                float3 col = inputImg.sample(__nv_smp, uv + offset).rgb;
                
                // Professional highlight blooming
                float lum = dot(col, float3(0.299, 0.587, 0.114));
                float weight = pow(max(0.0, (lum - u.highlightThreshold) / (1.0 - min(0.99, u.highlightThreshold))), u.highlightGain) + 0.01;
                
                acc += col * weight;
                tot += weight;
            }
            
            float3 finalCol = acc / tot;
            __nv_out = float4(finalCol, 1.0);
    return __nv_out;
}
