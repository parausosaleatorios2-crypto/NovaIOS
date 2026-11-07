// ---------------------------------------------------------------------------
// @am:string/effect_colortune_name
// origem : assets/effects/toji-colortune.xml
// id     : com.alightcreative.effects.colortune
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colortuneParams {
    float lift;
    float gamma;
    float gain;
    float offset;
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

        static float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

fragment float4 fx_toji_colortune(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colortuneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            //float hue = u.lift.x;
            //float strength = u.lift.y;
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

            //float3 liftYUV = rotUV(float3(0.5,-0.5,0.5),-u.lift.x) * u.lift.y / 2.;
            //float3 gammaYUV = rotUV(float3(0.5,-0.5,0.5),-u.gamma.x) * u.gamma.y / 2.;
            //float3 gainYUV = rotUV(float3(0.5,-0.5,0.5),-u.gain.x) * u.gain.y / 2.;

            float3 liftYUV = (hsv2rgb(float3(u.lift.x/360.,1.,0.5)) * rgb2yuv) * u.lift.y;
            float3 gammaYUV = (hsv2rgb(float3(u.gamma.x/360.,1.,0.5)) * rgb2yuv) * u.gamma.y;
            float3 gainYUV = (hsv2rgb(float3(u.gain.x/360.,1.,0.5)) * rgb2yuv) * u.gain.y;
            float3 offsetYUV = (hsv2rgb(float3(u.offset.x/360.,1.,0.5)) * rgb2yuv) * u.offset.y;


            // -- Do work here in YUV space ----

            //yuv = yuv * huemat;
            float y = yuv.x;

            float ygamma = pow(abs((y-0.5)*2.),2.);

            yuv.yz += liftYUV.yz * ((1.-y)*(1.-y)) * a;
            yuv.x += ((1.-y)*(1.-y))*u.lift.z * a;
            yuv.yz += gammaYUV.yz * ygamma * a;
            yuv.x += u.gamma.z * ygamma * a;
            yuv.yz += gainYUV.yz * (y*y) * a;
            yuv.x += u.gain.z * (y*y) * a;
            yuv.yz += offsetYUV.yz * a;
            yuv.x += u.offset.z * a;

            // -- Back to RGB and return result ---
            rgb = yuv * yuv2rgb;
            __nv_out = float4(rgb,a);
    return __nv_out;
}
