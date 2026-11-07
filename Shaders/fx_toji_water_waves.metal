// ---------------------------------------------------------------------------
// Water Waves
// origem : assets/effects/toji-water_waves.xml
// id     : com.alightcreative.effects.waterwaves
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_water_wavesParams {
    float progress;
    float warp;
    float frequency;
    float detail;
    float brightness;
    float2 stretch;
    float blend;
    float4 bgColor;
    float4 wavesColor;
};

// --- funcoes auxiliares do efeito
precision float;

        #define TAU 6.28318530718
        #define MAX_ITER 12

        float waterHighlight(float2 p, float time, float foaminess, float u.detail) {
            float2 i = float2(p);
            float c = 0.0;
            float foaminess_factor = mix(1.0, 6.0, foaminess);
            float inten = .005 * foaminess_factor;

            int iterations = int(clamp(u.detail, 1.0, float(MAX_ITER)));

            for (int n = 0; n < MAX_ITER; n++) {
                if (n >= iterations) break;
                float f_n = float(n + 1);
                float t = time * (0.0 - (3.5 / f_n));
                i = p + float2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
                c += 1.0 / length(float2(p.x / (sin(i.x + t)), p.y / (cos(i.y + t))));
            }
            c = 0.2 + c / (inten * float(iterations));
            c = 1.17 - pow(abs(c), 1.4);
            c = pow(abs(c), 8.0);
            return c / sqrt(foaminess_factor);
        }

fragment float4 fx_toji_water_waves(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_water_wavesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Use in.acLayerNorm to make it follow the layer
            float2 uv = in.acLayerNorm.xy;
            
            // Bounds check to prevent effect from spilling out of the layer area
            float boundsMask = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
            
            float aspect = eng.acLayerSize.x / eng.acLayerSize.y;
            float2 uv_square = float2(uv.x * aspect, uv.y);
            
            // Center is relative to the layer (0.5, 0.5)
            float dist_center = pow(1.0 * length(uv - 0.5), 0.5);
            float foaminess = smoothstep(0.4, 8.0, dist_center);
            float clearness = 0.9 + 0.5 * smoothstep(0.5, 0.1, dist_center);
            
            // Time driven by eng.acTime + manual u.progress
            float time = (eng.acTime * 0.02) + (u.progress * 0.1) + 23.0;
            
            // Apply u.stretch factor (500,500 is neutral)
            float2 stretchFactor = u.stretch / 500.0;
            float2 p_uv = (uv_square / max(stretchFactor, 0.01)) * TAU * u.frequency;
            float2 p = __nv_mod(p_uv, TAU) - 250.0;
            
            // Calculate caustic value for highlight and u.warp
            float c = waterHighlight(p, time, foaminess, u.detail);
            
            // Calculate gradient for warping (simple finite difference)
            float eps = 0.05;
            float c_x = waterHighlight(p + float2(eps, 0.0), time, foaminess, u.detail);
            float c_y = waterHighlight(p + float2(0.0, eps), time, foaminess, u.detail);
            
            // Displacement vector based on wave slope
            float2 displacement = float2(c - c_x, c - c_y) * u.warp;
            displacement.x /= aspect; // Correct for layer aspect ratio
            
            // Sample and distort input layer
            float2 distortedUV = uv + displacement;
            
            // Clamping check for edges within the layer space
            float4 base = inputImg.sample(__nv_smp, distortedUV);
            if (distortedUV.x > 1.0 || distortedUV.x < 0.0 || distortedUV.y > 1.0 || distortedUV.y < 0.0) {
                base = float4(0.0);
            }

            // Mix caustic highlights on top
            float3 highlightColor = mix(u.bgColor.rgb, u.wavesColor.rgb, clamp(c, 0.0, 1.0));
            // Apply clearness/masking
            highlightColor = mix(u.bgColor.rgb, highlightColor, clearness);
            
            // Final composite: (Warped Image) + (Layered Caustics)
            float3 finalColor = mix(base.rgb, highlightColor * u.brightness, u.blend);
            
            // Ensure the effect only appears on the text/layer pixels and within layer bounds
            float finalAlpha = base.a * boundsMask;
            __nv_out = float4(finalColor, finalAlpha);
    return __nv_out;
}
