// ---------------------------------------------------------------------------
// Firey Border
// origem : assets/effects/toji-firey_border.xml
// id     : com.alightcreative.effects.firey_border
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_firey_borderParams {
    float borderSize;
    float fireIntensity;
    float fireSpeed;
    float flameDetail;
    float4 fireTint;
    float distortionStrength;
    float distortionScale;
};

// --- funcoes auxiliares do efeito
// --- NOISE FUNCTIONS ---
        static float hash(float2 p) {
            p = fract(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return fract(p.x * p.y);
        }

        // Value Noise with Smoothstep
        static float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0); // Quintic
            
            float a = hash(i);
            float b = hash(i + float2(1.0, 0.0));
            float c = hash(i + float2(0.0, 1.0));
            float d = hash(i + float2(1.0, 1.0));
            
            return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
        }

        // Fractal Brownian Motion
        static float fbm(float2 p) {
            float f = 0.0;
            float amp = 0.5;
            for(int i = 0; i < 4; i++) {
                f += amp * noise(p);
                p *= 2.0;
                amp *= 0.5;
            }
            return f;
        }

fragment float4 fx_toji_firey_border(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_firey_borderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            
            // 1. Setup Coordinates
            float2 noise_uv = uv;
            noise_uv.x *= eng.acScreenSize.x / eng.acScreenSize.y; 
            
            // 2. Generate Turbulence
            float t = eng.acTime * u.fireSpeed;
            float2 flow = float2(fbm(noise_uv * u.flameDetail + float2(0.0, t)), 
                             fbm(noise_uv * u.flameDetail + float2(t * 1.3, 0.0)));
                             
            // 3. Calculate Distance to Edge
            float dist_x = min(uv.x, 1.0 - uv.x);
            float dist_y = min(uv.y, 1.0 - uv.y);
            float dist_to_edge = min(dist_x, dist_y);
            
            // 4. Distort the Edge (Applied Settings Here)
            // We use u.distortionScale for the noise frequency
            float wave = fbm(noise_uv * u.distortionScale - t * 2.0 + flow);
            
            // We use u.distortionStrength to determine how much it affects the border
            float border_shape = dist_to_edge + (wave * u.distortionStrength); 
            
            // 5. Create the Fire Mask
            float heat = 1.0 - smoothstep(0.0, u.borderSize, border_shape);
            
            // 6. Color Mapping
            float3 col = float3(0.0);
            if(heat > 0.0) {
                // Core 
                col += float3(1.0, 1.0, 0.8) * pow(heat, 6.0);
                // Middle 
                col += float3(1.0, 0.5, 0.0) * pow(heat, 3.0) * 1.5;
                // Tips 
                col += float3(0.5, 0.0, 0.0) * heat;
            }
            
            col *= u.fireIntensity;
            col *= step(0.0, heat); 

            // Apply manual tint override (optional, but requested implicitly)
            // The original had a constant FIRE_TINT float3(1.0, 0.5, 0.2)
            // We mix towards it or multiply? Let's Multiplying it allows tinting.
            // But since default colors are reddish/orange, multiplying by orange makes it very deep orange.
            // Let's assume the user wants to filter the result.
            // Note: The original code defined FIRE_TINT but didn't use it in the mainImage provided.
            // We will leave it as an option.
            // To make it neutral by default, we can't easily. 
            // We'll just provide the uniform. If the user wants to use it, they can.
            
            // Simple transparency based on heat
            float alpha = smoothstep(0.0, 0.1, heat);
            
            __nv_out = float4(col, alpha);
    return __nv_out;
}
