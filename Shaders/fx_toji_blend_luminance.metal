// ---------------------------------------------------------------------------
// Blend/Color
// origem : assets/effects/toji-blend-luminance.xml
// id     : com.alightcreative.blend.luminance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_blend_luminanceParams { int __vazio; };

fragment float4 fx_toji_blend_luminance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_blend_luminanceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );

            // Setup
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 compColor = comp.sample(__nv_smp, in.acScreenNorm);
            float3 top = texColor.rgb;
            float3 bot = compColor.rgb * texColor.a;

            // Blend top, bot
            float3 result = float3( (top * rgb2yuv).r, (bot * rgb2yuv).gb) * yuv2rgb;

            // Output result
            __nv_out = float4(result,texColor.a);
    return __nv_out;
}
