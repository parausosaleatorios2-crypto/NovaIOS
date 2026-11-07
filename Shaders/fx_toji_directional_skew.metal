// ---------------------------------------------------------------------------
// Directional Skew
// origem : assets/effects/toji-directional_skew.xml
// id     : com.creative.directional_skew
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_directional_skewParams {
    float skewScale;
    float skewAngle;
};

fragment float4 fx_toji_directional_skew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_directional_skewParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Normalized pixel coordinates (from 0 to 1)
            float2 uv = in.acScreenNorm;

            // --- Apply Directional Skew ---
            // Center the coordinates on the layer center
            float2 centered = uv - eng.acLayerCenterNorm;
            
            // Calculate rotation based on Angle
            float rad = radians(u.skewAngle);
            float c = cos(rad);
            float s = sin(rad);
            
            // Rotation matrices
            // float2x2(column0, column1)
            float2x2 toSkewAxis = float2x2(c, -s, s, c);
            float2x2 fromSkewAxis = float2x2(c, s, -s, c);
            
            // 1. Rotate to align with skew axis
            float2 temp = centered * toSkewAxis;
            
            // 2. Apply Skew (Shear)
            // 'u.skewScale' determines the strength of the shear
            temp.x += temp.y * u.skewScale;
            
            // 3. Rotate back
            centered = temp * fromSkewAxis;
            
            // Restore coordinates
            uv = centered + eng.acLayerCenterNorm;

            // Sample the texture
            // We ensure we dont sample outside 0-1 if needed, but standard behavior usually crops or wraps
            __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
