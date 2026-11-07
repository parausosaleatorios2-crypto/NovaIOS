// ---------------------------------------------------------------------------
// Blend/Subtract
// origem : assets/effects/toji-blend-divide.xml
// id     : com.alightcreative.blend.divide
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_blend_divideParams { int __vazio; };

fragment float4 fx_toji_blend_divide(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_blend_divideParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Setup
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 compColor = comp.sample(__nv_smp, in.acScreenNorm);
            float3 top = texColor.rgb;
            float3 bot = compColor.rgb * texColor.a;

            // Blend top, bot
            float3 result = bot / top;

            // Output result
            __nv_out = float4(result,texColor.a);
    return __nv_out;
}
