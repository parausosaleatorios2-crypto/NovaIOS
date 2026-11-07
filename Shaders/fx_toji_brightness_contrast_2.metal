// ---------------------------------------------------------------------------
// @am:string/effect_brightnessContrast_name
// origem : assets/effects/toji-brightness-contrast-2.xml
// id     : com.alightcreative.effects.brightcont2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_brightness_contrast_2Params {
    float brightness;
    float contrast;
};

fragment float4 fx_toji_brightness_contrast_2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_brightness_contrast_2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
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
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float3 rgb = texColor.rgb;
            float a = texColor.a;
            float3 yuv = rgb * rgb2yuv;

            yuv.x = (yuv.x-0.5*a) * (u.contrast+1.0) + 0.5*a + u.brightness*a;
            rgb = yuv * yuv2rgb;
            // ENABLE THE FOLLOWING TWO LINES FOR EFFECT TESTING
            //float s = max(sin(in.acScreenNorm.x*200.),0.);
            //return float4(rgb,a*s);
            __nv_out = float4(rgb,a);
    return __nv_out;
}
