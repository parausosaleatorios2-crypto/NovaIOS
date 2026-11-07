// ---------------------------------------------------------------------------
// @am:string/effect_hueshift_name
// origem : assets/effects/toji-hueshift.xml
// id     : com.alightcreative.effects.hueshift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_hueshiftParams {
    float hue;
};

fragment float4 fx_toji_hueshift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_hueshiftParams&  u    [[buffer(1)]],
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
            float rad = u.hue * 0.0174533;
            float3x3 huemat = float3x3(
                1.0,  0.0,       0.0,
                0.0,  cos(rad),  sin(rad),
                0.0,  -sin(rad), cos(rad)
            );
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float3 rgb = texColor.rgb;
            float a = texColor.a;
            float3 yuv = rgb * rgb2yuv;
            //yuv.yz = yuv.yz * (saturation+1.0);
            yuv = yuv * huemat;
            rgb = yuv * yuv2rgb;
            //rgb = (rgb - 0.5) * (contrast+1.0) + 0.5 + brightness;
            __nv_out = float4(rgb,a);
    return __nv_out;
}
