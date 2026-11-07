// ---------------------------------------------------------------------------
// Warp
// origem : assets/effects/toji-warp_styles.xml
// id     : com.alightcreative.effects.warp_styles
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_warp_stylesParams {
    int warpStyle;
    int warpVertical;
    float bend;
    float hDistortion;
    float vDistortion;
    int followLayer;
    float blend;
    int tileMode;
};

// --- funcoes auxiliares do efeito
// Multi-Style Warp Implementation for Alight Motion
        
        #define PI 3.14159265359

        static float2 applyTile(float2 uv, int mode) {
            if (mode == 1) { // Repeat
                return fract(uv);
            } else if (mode == 2) { // Mirror
                float2 m = __nv_mod(uv, 2.0);
                return mix(m, 2.0 - m, step(1.0, m));
            } else if (mode == 3) { // Clamp
                return clamp(uv, 0.0, 1.0);
            }
            return uv; // Transparent/Default
        }

fragment float4 fx_toji_warp_styles(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_warp_stylesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 luv = in.acLayerNorm.xy;
            float2 suv = in.acScreenNorm.xy;
            
            float2 uv;
            float2 aspect;
            if(u.followLayer) {
                uv = luv;
                aspect = float2(eng.acLayerSize.x / eng.acLayerSize.y, 1.0);
            } else {
                uv = suv;
                aspect = float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
            }
            
            // 1. Normalize UVs to [-1, 1] for math
            float2 p = uv * 2.0 - 1.0;
            
            // 2. Apply Horizontal and Vertical Distortion (Tapering)
            float hDist = u.hDistortion * 0.01;
            float vDist = u.vDistortion * 0.01;
            
            p.x *= (1.0 - vDist * p.y);
            p.y *= (1.0 - hDist * p.x);
            
            // 3. Axis Swap for Vertical Mode
            if (u.warpVertical) {
                p = p.yx;
            }
            
            // 4. Warp Logic
            float b = u.bend * 0.01;
            float2 warped = p;
            int style = int(u.warpStyle);
            int tMode = int(u.tileMode);
            
            float curve = (1.0 - p.x * p.x);
            
            if (style == 0) { // Arc
                warped.y += b * curve;
            } 
            else if (style == 1) { // Arc Lower
                if (p.y < 0.0) warped.y += b * curve * (abs(p.y));
            }
            else if (style == 2) { // Arc Upper
                if (p.y > 0.0) warped.y += b * curve * p.y;
            }
            else if (style == 3) { // Arch
                warped.y += b * curve;
                warped.x *= (1.0 - b * 0.5 * (1.0 + p.y));
            }
            else if (style == 4) { // Bulge
                float bulge = b * (1.0 - abs(p.x)) * (1.0 - abs(p.y));
                warped *= (1.0 - bulge);
            }
            else if (style == 5) { // Shell Lower
                warped.y += b * curve;
                warped.x *= (1.0 + b * 0.5 * (1.0 - p.y));
            }
            else if (style == 6) { // Shell Upper
                warped.y += b * curve;
                warped.x *= (1.0 + b * 0.5 * (1.0 + p.y));
            }
            else if (style == 7) { // Flag
                warped.y += b * sin(p.x * PI + 0.0);
            }
            else if (style == 8) { // Wave
                warped.y += b * sin(p.x * PI * 2.0);
            }
            else if (style == 9) { // Fish
                warped.y *= (1.0 + b * p.x);
                warped.x += b * 0.2 * (1.0 - p.y * p.y);
            }
            else if (style == 10) { // Rise
                warped.y += b * sin(p.x * PI * 0.5);
            }
            else if (style == 11) { // FishEye
                float d = length(p);
                warped = p * (1.0 + b * d);
            }
            else if (style == 12) { // Inflate
                float d = length(p);
                warped = p / (1.0 + b * (1.0 - d));
            }
            else if (style == 13) { // Twist
                float d = length(p);
                float angle = b * PI * (1.0 - d);
                float s = sin(angle), c = cos(angle);
                warped = float2(p.x * c - p.y * s, p.x * s + p.y * c);
            }
            else if (style == 14) { // Squeeze
                warped.x *= (1.0 + b * (1.0 - abs(p.y)));
                warped.y *= (1.0 + b * (1.0 - abs(p.x)));
            }
            
            // 5. Inverse Axis Swap
            if (u.warpVertical) {
                warped = warped.yx;
            }
            
            // 6. Map back to [0, 1]
            float2 finalUV = (warped + 1.0) * 0.5;
            
            // 7. Apply Tiling
            float2 tiledUV = applyTile(finalUV, tMode);
            
            // 8. Clamp and Sample
            float4 color = inputImg.sample(__nv_smp, tiledUV);
            
            // Alpha mask only if transparent mode is selected
            if (tMode == 0) {
                if (finalUV.x < 0.0 || finalUV.x > 1.0 || finalUV.y < 0.0 || finalUV.y > 1.0) {
                    color = float4(0.0);
                }
            }
            
            float4 base = inputImg.sample(__nv_smp, suv);
            __nv_out = mix(base, color, u.blend);
    return __nv_out;
}
