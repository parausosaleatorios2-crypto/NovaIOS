// ---------------------------------------------------------------------------
// Spot Exposure
// origem : assets/effects/toji-spot_exposure.xml
// id     : com.alightcreative.effects.spot_exposure
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_spot_exposureParams {
    float exposure;
    float spotBoost;
    float spotRadius;
    float spotSoftness;
    float centerX;
    float centerY;
};

fragment float4 fx_toji_spot_exposure(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_spot_exposureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalized screen coordinates (0 to 1)
            float2 uv = in.acScreenNorm;

            // Fix aspect ratio so the spot is a perfect circle
            float aspect = eng.acScreenSize.x / eng.acScreenSize.y;
            float2 p = uv;
            p.x *= aspect;

            // Handle center position
            float2 m = float2(u.centerX, u.centerY);
            m.x *= aspect;

            // Calculate distance from center
            float dist = length(p - m);

            // Create the spot mask using smoothstep for softness
            // 1.0 inside the spot, falling off to 0.0 outside
            float spotMask = smoothstep(u.spotRadius + u.spotSoftness, u.spotRadius, dist);

            // Sample the input channel
            float4 texColor = inputImg.sample(__nv_smp, uv);

            // Calculate final u.exposure
            // Mixes between Base Exposure and (Base + Boost) based on the mask
            float currentExposure = u.exposure + (u.spotBoost * spotMask);

            // Apply u.exposure to the color (preserving alpha)
            float3 finalColor = texColor.rgb * currentExposure;

            // Output to screen
            __nv_out = float4(finalColor, texColor.a);
    return __nv_out;
}
