// ---------------------------------------------------------------------------
// @am:string/effect_colorize_name
// origem : assets/effects/toji-colorize.xml
// id     : com.alightcreative.effects.colorize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colorizeParams {
    float tint;
};

// --- funcoes auxiliares do efeito
static float3 rotUV( float3 yuv, float degrees ) {
            float rad = degrees * 0.0174533;
            float3x3 rmat = float3x3(
                1.0,  0.0,       0.0,
                0.0,  cos(rad),  sin(rad),
                0.0,  -sin(rad), cos(rad)
            );
            return yuv * rmat;
        }

        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

fragment float4 fx_toji_colorize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colorizeParams&  u    [[buffer(1)]],
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

            float3 tintedYUV = (hsv2rgb(float3(u.tint.x/360.,1.,0.5)) * rgb2yuv);

            // -- Do work here in YUV space ----
            yuv.yz = mix(yuv.yz, tintedYUV.yz, u.tint.y * a);

            // -- Back to RGB and return result ---
            rgb = yuv * yuv2rgb;
            __nv_out = float4(rgb,a);
    return __nv_out;
}
