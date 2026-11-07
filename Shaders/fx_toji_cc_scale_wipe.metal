// ---------------------------------------------------------------------------
// smear
// origem : assets/effects/toji-cc_scale_wipe.xml
// id     : com.alightcreative.effects.ccscalewipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cc_scale_wipeParams {
    float2 startPoint;
    float2 endPoint;
    float strength;
    float radius;
    int keepEdge;
};

// --- funcoes auxiliares do efeito
precision float;

fragment float4 fx_toji_cc_scale_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cc_scale_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalized coordinates (0.0 to 1.0)
            float2 uv = in.acScreenNorm;
            
            // Adjust for aspect ratio to make circle/distortions uniform
            float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
            float2 aspectUV = uv * float2(aspect, 1.0);

            // Convert Alight Motion point params (0-1000) to 0-1 range
            // Then apply aspect ratio correction
            float2 center = (u.startPoint / 1000.0) * float2(aspect, 1.0);
            float2 end = (u.endPoint / 1000.0) * float2(aspect, 1.0);

            float stretchStrength = u.strength * 3.0; // Scaled to match Shadertoys multiplier
            float2 dirVec = end - center;
            float2 dir = normalize(dirVec);

            // 1. Calculate how far along the stretch axis the pixel is
            float projection = dot(aspectUV - center, dir);
            
            // 2. Calculate the distance from center for the Radius mask
            float dist = length(aspectUV - center);
            
            // 3. Create the Radius Falloff (normalized u.radius)
            // Shadertoy used a raw float, here we use u.radius param
            // smoothstep(u.radius, 0.0, dist) means:
            // dist >= u.radius -> 0.0
            // dist <= 0.0 -> 1.0
            float mask = smoothstep(u.radius, 0.0, dist);

            float2 distortedUV = uv;

            if (projection > 0.0) {
                // Apply the stretch, but multiply the intensity by the mask
                float amount = (stretchStrength / (1.0 + stretchStrength)) * mask;
                // Move aspect-corrected uv back towards center
                float2 deltaDistort = dir * projection * amount;
                // Scale delta back to non-aspect space for final UV
                deltaDistort.x /= aspect;
                distortedUV -= deltaDistort;
            }

            // Sample inputImg
            float4 col = inputImg.sample(__nv_smp, distortedUV);
            
            // Edge clamping / Keep Edge logic
            if (!u.keepEdge) {
                if (distortedUV.x > 1.0 || distortedUV.x < 0.0 || distortedUV.y > 1.0 || distortedUV.y < 0.0) {
                    col = float4(0.0);
                }
            } else {
                col = inputImg.sample(__nv_smp, clamp(distortedUV, 0.0, 1.0));
            }

            __nv_out = col;
    return __nv_out;
}
