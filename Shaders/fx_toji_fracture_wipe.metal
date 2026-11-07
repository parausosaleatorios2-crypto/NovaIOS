// ---------------------------------------------------------------------------
// Fracture Wipe
// origem : assets/effects/toji-fracture_wipe.xml
// id     : com.alightcreative.effects.fracture_wipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fracture_wipeParams {
    float progress;
    float voroScale;
    float crackWidth;
    float crackAmt;
    int autoAnimate;
    float speed;
    float seed;
    int useLayerBelow;
};

// --- funcoes auxiliares do efeito
// Simple hash/noise for procedural generation
        float hash(float2 p) {
            return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
        }

        float2 h2(float2 p) {
            float n = hash(p);
            return float2(n, hash(p + float2(15.23, 37.11)));
        }

        // Adapted Voronoi Border algorithm
        float voroBorder(float2 x, out float2 id, out float2 mr) {
            float2 n = floor(x);
            float2 f = fract(x);
            float2 mg = float2(0.0);
            mr = float2(0.0);
            float md = 8.0;

            for (int j = -1; j <= 1; j++) {
                for (int i = -1; i <= 1; i++) {
                    float2 g = float2(float(i), float(j));
                    float2 r = g + h2(n + g) - f;
                    float d = dot(r, r);
                    if (d < md) {
                        md = d;
                        mr = r;
                        mg = g;
                    }
                }
            }

            id = n + mg;
            md = 8.0;

            for (int j = -2; j <= 2; j++) {
                for (int i = -2; i <= 2; i++) {
                    float2 g = mg + float2(float(i), float(j));
                    float2 r = g + h2(n + g) - f;
                    float2 v = r - mr;
                    float vv = dot(v, v);
                    if (vv > 1e-5) {
                        md = min(md, dot(0.5*(mr + r), normalize(v)));
                    }
                }
            }
            
            // Smooth edge
            md = 1.0 - (1.0 - md) * (1.0 - md);
            return md;
        }

fragment float4 fx_toji_fracture_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fracture_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> targetImg [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& targetImg_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 uv = in.acScreenNorm;
            
            // Handle aspect ratio for Voronoi
            float2 st = in.acLayerNorm.xy;
            st.x *= eng.acLayerSize.x / eng.acLayerSize.y;
            
            float t = u.autoAnimate ? eng.acTime * u.speed : u.progress;
            
            // Map t to the ranges used in the original Shadertoy
            // Original t cycles 0-1, but we use a single transition
            float seg = floor(u.seed); // Use u.seed as a base segment
            
            // Random value for variation
            float r = hash(float2(seg, 123.456));
            
            // Transition curve (tp)
            float tt = clamp((t - 0.08 * r) / max(1.0 - 0.08 * r, 1e-4), 0.0, 1.0);
            float s = smoothstep(0.0, 1.0, tt);
            float tp = mix(mix(s, pow(s, mix(1.2, 2.4, r)), 0.5), tt, 0.45);

            // Warp and distance params
            float w = 1.0 - smoothstep(0.88, 1.08, t); // Fade out at end of cycle if auto-animating
            if(!u.autoAnimate) w = 1.0; // Keep full effect for manual u.progress
            
            float rad = clamp(length(in.acLayerNorm.xy - 0.5) * 1.4, 0.0, 1.0);

            float2 p = st * u.voroScale + (h2(float2(seg + 1.23, u.seed)) * 2.0 - 1.0) * 10.0;

            float2 id, mr;
            float dist = clamp(voroBorder(p, id, mr), 0.0, 1.0);

            // Warp logic from Shadertoy
            float warp = ((0.65 * (h2(id).x * 2.0 - 1.0) + 0.35 * dot(mr, float2(0.73, 0.37))) * 0.28)
                         * smoothstep(0.0, 0.20, t) * w;

            float ph = clamp(tp + (-rad + warp + pow(1.0 - rad, 1.2) * 0.10 * smoothstep(0.0, 0.30, t)) * w, 0.0, 1.0);
            float d = dist - ph;

            // Revelation and Crack logic
            float gate = mix(smoothstep(0.0, 0.10, tp - (rad - warp)), 1.0, smoothstep(0.92, 1.0, t));
            float reveal = smoothstep(0.020, 0.0, d) * gate;
            float crack = smoothstep(u.crackWidth, 0.0, abs(d)) * gate * smoothstep(0.18, 0.30, ph);

            // Textures
            float4 colA = inputImg.sample(__nv_smp, uv);
            
            float3 finalRGB;
            float finalAlpha;

            if (u.useLayerBelow) {
                // To reveal layers below in Alight Motion, we transition to transparency
                finalRGB = colA.rgb * (1.0 - reveal);
                finalAlpha = colA.a * (1.0 - reveal);
                
                // Add the cracks as solid black (or dimmed) lines
                finalRGB = finalRGB * (1.0 - crack * u.crackAmt);
                // Ensure cracks themselves are at least somewhat opaque during the transition
                finalAlpha = max(finalAlpha, min(colA.a, crack * u.crackAmt));
            } else {
                // To reveal a specific target texture, we mix the colors
                float4 colB = targetImg.sample(__nv_smp, uv);
                finalRGB = mix(colA.rgb, colB.rgb, reveal) * (1.0 - crack * u.crackAmt);
                finalAlpha = mix(colA.a, colB.a, reveal);
            }

            __nv_out = float4(finalRGB, finalAlpha);
    return __nv_out;
}
