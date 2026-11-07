// ---------------------------------------------------------------------------
// Warp Puff
// origem : assets/effects/toji-s_warp_puff.xml
// id     : com.alightcreative.effects.s_warppuff
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_warp_puffParams {
    float amount;
    float smoothness;
    float rotateWarpDir;
    int puff;
    float wrapMode;
    int followLayer;
    float blend;
};

// --- funcoes auxiliares do efeito
// S_WarpPuff implementation for Alight Motion
        
        #define PI 3.14159265359

        static float getLuma(float3 color) {
            return dot(color, float3(0.299, 0.587, 0.114));
        }

        // Helper: Sample the "Lens" with u.smoothness
        static float getSmoothLuma(AC_ImageInfo img, float2 uv, float smoothVal) {
            float luma = 0.0;
            float samples = 0.0;
            float blurRadius = smoothVal * 0.01; // Scale factor for Alight Motion
            
            for(float x = -1.0; x <= 1.0; x++) {
                for(float y = -1.0; y <= 1.0; y++) {
                    float2 offset = float2(x, y) * blurRadius;
                    luma += getLuma(img.texture.sample(__nv_smp, uv + offset).rgb);
                    samples++;
                }
            }
            return luma / samples;
        }

        static float2 applyWrap(float2 uv, int mode) {
            if (mode == 1) return fract(uv); 
            if (mode == 2) return abs(__nv_mod(uv - 1.0, 2.0) - 1.0); 
            return uv;
        }

        static float2 rotate(float2 v, float a) {
            float s = sin(a), c = cos(a);
            return float2(v.x * c - v.y * s, v.x * s + v.y * c);
        }

fragment float4 fx_toji_s_warp_puff(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_warp_puffParams&  u    [[buffer(1)]],
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
            
            // 1. Calculate Gradient
            float delta = 0.005;
            float l  = getSmoothLuma(inputImg, uv, u.smoothness);
            float lx = getSmoothLuma(inputImg, uv + float2(delta, 0.0), u.smoothness);
            float ly = getSmoothLuma(inputImg, uv + float2(0.0, delta), u.smoothness);
            
            float2 gradient = float2(lx - l, ly - l);
            
            // 2. Adjust for Aspect Ratio
            gradient.x *= aspect.x;
            
            // 3. Rotate the Warp Direction
            if (u.rotateWarpDir != 0.0) {
                gradient = rotate(gradient, u.rotateWarpDir * (PI / 180.0));
            }
            
            // 4. Calculate Displacement
            float dirMult = u.puff ? -1.0 : 1.0;
            float2 displacement = gradient * u.amount * dirMult;
            
            // 5. Apply Warp
            // Note: Displacement is in aspect-corrected space, we need to un-correct it for UV addition
            displacement.x /= aspect.x;
            float2 warpedUV = uv + displacement;
            
            // 6. Wrap and Sample final color
            warpedUV = applyWrap(warpedUV, int(u.wrapMode));
            float4 color = inputImg.sample(__nv_smp, warpedUV);
            
            float4 base = inputImg.sample(__nv_smp, suv);
            __nv_out = mix(base, color, u.blend);
    return __nv_out;
}
