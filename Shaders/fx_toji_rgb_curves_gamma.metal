// ---------------------------------------------------------------------------
// RGB Curves
// origem : assets/effects/toji-rgb_curves_gamma.xml
// id     : com.alightcreative.effects.rgb_curves_gamma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rgb_curves_gammaParams {
    float redGamma;
    float greenGamma;
    float blueGamma;
    float masterContrast;
};

fragment float4 fx_toji_rgb_curves_gamma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rgb_curves_gammaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float3 col = texColor.rgb;

            // Apply Gamma Curve per channel
            col.r = pow(max(col.r, 0.0), u.redGamma);
            col.g = pow(max(col.g, 0.0), u.greenGamma);
            col.b = pow(max(col.b, 0.0), u.blueGamma);

            // Apply Master Contrast
            col = (col - 0.5) * u.masterContrast + 0.5;

            // Clamp values
            col = clamp(col, 0.0, 1.0);

            __nv_out = float4(col, texColor.a);
    return __nv_out;
}
