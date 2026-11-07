// ---------------------------------------------------------------------------
// Warp Magnify
// origem : assets/effects/toji-s_warp_magnify.xml
// id     : com.alightcreative.effects.s_warp_magnify
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_s_warp_magnifyParams {
    float2 center;
    float magnifyAmount;
    float2 magnifyRel;
    float lensRadius;
    float lensEdgeWidth;
    float lensRelWidth;
    float lensRelHeight;
    float lensRotate;
    float lensEdgeShape;
    float wrapMode;
    int followLayer;
    float blend;
};

// --- funcoes auxiliares do efeito
// S_WarpMagnify implementation for Alight Motion
        
        #define PI 3.14159265359

        float2 rotate(float2 v, float angle) {
            float s = sin(angle);
            float c = cos(angle);
            return float2(v.x * c - v.y * s, v.x * s + v.y * c);
        }

        float2 applyWrap(float2 uv, int mode) {
            if (mode == 1) return fract(uv); // Tile
            if (mode == 2) return abs(__nv_mod(uv - 1.0, 2.0) - 1.0); // Reflect
            return uv; // No wrap
        }

fragment float4 fx_toji_s_warp_magnify(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_s_warp_magnifyParams&  u    [[buffer(1)]],
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
            
            // 1. Calculate relative position from u.center
            float2 p = uv - u.center;
            p.x *= aspect.x; // Correct for aspect ratio
            
            // 2. Apply Lens Rotation
            float rad = u.lensRotate * (PI / 180.0);
            p = rotate(p, rad);
            
            // 3. Apply Ellipse Scaling
            p.x /= max(0.01, u.lensRelWidth);
            p.y /= max(0.01, u.lensRelHeight);
            
            // 4. Calculate Distance and Magnification
            float d = length(p);
            float edgeSize = u.lensRadius * u.lensEdgeWidth;
            
            float magFactor = 1.0;
            
            if (d < u.lensRadius) {
                magFactor = u.magnifyAmount;
            } 
            else if (d < u.lensRadius + edgeSize) {
                float t = (d - u.lensRadius) / edgeSize;
                float curve = mix(t, smoothstep(0.0, 1.0, t), u.lensEdgeShape);
                magFactor = mix(u.magnifyAmount, 1.0, curve);
            }
            
            // 5. Warp the UVs
            float2 warpedP = p;
            warpedP /= (magFactor * u.magnifyRel);
            
            // 6. Inverse Transform
            warpedP.x *= u.lensRelWidth;
            warpedP.y *= u.lensRelHeight;
            warpedP = rotate(warpedP, -rad);
            warpedP.x /= aspect.x;
            
            float2 finalUV = u.center + warpedP;
            
            // 7. Apply Wrap and Sample
            finalUV = applyWrap(finalUV, int(u.wrapMode));
            
            float4 color = inputImg.sample(__nv_smp, finalUV);
            
            // 8. Edge Darkening
            if (d > u.lensRadius && d < u.lensRadius + edgeSize) {
                color.rgb *= mix(0.95, 1.0, (d - u.lensRadius) / edgeSize);
            }
            
            float4 base = inputImg.sample(__nv_smp, suv);
            __nv_out = mix(base, color, u.blend);
    return __nv_out;
}
