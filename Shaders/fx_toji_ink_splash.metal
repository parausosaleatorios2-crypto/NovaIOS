// ---------------------------------------------------------------------------
// Ink Splash
// origem : assets/effects/toji-ink_splash.xml
// id     : com.alightcreative.effects.ink_splash
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_ink_splashParams {
    float expansion;
    float roughness;
    float bleed;
    float speed;
    float seed;
    float4 inkColor;
    float4 paperColor;
    int alphaMode;
};

// --- funcoes auxiliares do efeito
// Random hash function
        float hash(float2 p) {
            p = fract(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return fract(p.x * p.y);
        }

        // 2D Value Noise
        float noise(float2 p) {
            float2 i = floor(p);
            float2 f = fract(p);
            f = f * f * (3.0 - 2.0 * f);
            float a = hash(i + float2(0.0, 0.0));
            float b = hash(i + float2(1.0, 0.0));
            float c = hash(i + float2(0.0, 1.0));
            float d = hash(i + float2(1.0, 1.0));
            return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
        }

        // Fractal Brownian Motion (6 octaves)
        float fbm(float2 p) {
            float total = 0.0;
            float amp = 0.5;
            // Rotation matrix to reduce grid artifacts
            float2x2 rot = float2x2(0.877582, 0.479426, -0.479426, 0.877582); // cos(0.5), sin(0.5)
            
            for (int i = 0; i < 6; i++) {
                total += noise(p) * amp;
                p = rot * p * 2.0 + 100.0;
                amp *= 0.5;
            }
            return total;
        }

fragment float4 fx_toji_ink_splash(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_ink_splashParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acLayerNorm.xy - 0.5;
            uv.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            
            float t = eng.acTime * u.speed + u.seed;

            // --- Domain Warping ---
            float2 q = float2(0.0);
            q.x = fbm(uv + float2(0.0, 0.0) + 0.05 * t);
            q.y = fbm(uv + float2(5.2, 1.3) + 0.05 * t);

            float2 r = float2(0.0);
            r.x = fbm(uv + 4.0 * q + float2(1.7, 9.2) + 0.15 * t);
            r.y = fbm(uv + 4.0 * q + float2(8.3, 2.8) + 0.126 * t);

            // Final noise value based on warped coordinates
            float f = fbm(uv + 4.0 * r);

            // --- Shape Creation ---
            float dist = length(uv);
            
            // Combine radial with warped noise
            // u.expansion * 0.5 replicates the iResolution based sizing
            float inkShape = (u.expansion * 0.3) - dist + (f - 0.5) * (u.roughness * 0.2);

            // --- Coloring ---
            // Using a slightly higher minimum for u.bleed to prevent hard artifacts
            float safeBleed = max(u.bleed, 0.001);
            float mask = smoothstep(-safeBleed, 0.0, inkShape);
            
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);

            if (u.alphaMode) {
                // In Alpha mode, we treat the ink as the layer visibility
                __nv_out = float4(texColor.rgb, texColor.a * mask);
            } else {
                // In Color mode, we mix the Paper and Ink colors
                float3 finalCol = mix(u.paperColor.rgb, u.inkColor.rgb, mask);
                __nv_out = float4(finalCol, 1.0);
            }
    return __nv_out;
}
