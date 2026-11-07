// ---------------------------------------------------------------------------
// Tritone
// origem : assets/effects/toji-tritone.xml
// id     : com.alightcreative.effects.tritone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_tritoneParams {
    float4 highlights;
    float4 midtones;
    float4 shadows;
    float blend;
};

fragment float4 fx_toji_tritone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_tritoneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        float2 uv = in.acScreenNorm;
        float4 src = inputImg.sample(__nv_smp, uv);
        
        // 1. Calculate Luminance (standard weights for grayscale)
        float lum = dot(src.rgb, float3(0.299, 0.587, 0.114));
        
        // 2. Map colors based on luminance
        float3 tritoneCol;
        if (lum < 0.5) {
            // Map Shadows to Midtones
            tritoneCol = mix(u.shadows.rgb, u.midtones.rgb, lum * 2.0);
        } else {
            // Map Midtones to Highlights
            tritoneCol = mix(u.midtones.rgb, u.highlights.rgb, (lum - 0.5) * 2.0);
        }
        
        // 3. Blend with original
        float3 finalCol = mix(tritoneCol, src.rgb, u.blend);
        
        // 4. Output with original alpha
        __nv_out = float4(finalCol, 1.0) * src.a;
    return __nv_out;
}
