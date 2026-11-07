// ---------------------------------------------------------------------------
// @am:string/effect_hotcolor_name
// origem : assets/effects/toji-colorhot.xml
// id     : com.alightcreative.effects.colorhot
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_colorhotParams {
    float color;
    float tint;
};

// --- funcoes auxiliares do efeito
static float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        const float3x3 rgb2yuv = float3x3(
             0.299,     0.587,    0.114,
            -0.14713,  -0.28886,  0.436,
             0.615,    -0.51499, -0.10001
        );

        const float3x3 yuv2rgb = float3x3(
            1.0,  0.0,      1.13983,
            1.0, -0.39465, -0.58060,
            1.0,  2.03211,  0.0
        );

fragment float4 fx_toji_colorhot(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_colorhotParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 source = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luminance = dot(source.rgb, luminanceWeighting);

            float gamma = u.color.z+1.0;
            luminance = pow(luminance,1.0/gamma);

            float hue = u.color.x /360.;
            float sat = u.color.y;
            float hue2 = u.tint.x /360.;
            float sat2 = u.tint.y;

            //float lowHue = hue;
            //float highHue = hue2;

            //float3 lowColor = hsv2rgb(float3(hue,sat,1.0));
            //float3 baseColor = hsv2rgb(float3((lowHue+highHue)/2.0,sat,1.0));
            //float3 highColor = hsv2rgb(float3(highHue,sat,1.0));

            float3 darkColor =  hsv2rgb(float3(hue,sat,1.0));
            float3 baseColor =  hsv2rgb(float3(hue,sat,1.0));
            float3 lightColor =  hsv2rgb(float3(hue2,sat2,1.0));
            //if( abs(hue-lowHue) > abs(hue-highHue) ) {
            //    lightColor = highColor;
            //    darkColor = lowColor;
            //} else {
            //    lightColor = lowColor;
            //    darkColor = highColor;
            //}

            float cutoff = u.tint.z / 2.0 + 0.5;
            float3 blendColor = luminance < cutoff ? mix( darkColor, baseColor, luminance/cutoff) :  mix( baseColor, lightColor, (luminance-cutoff)/(1.-cutoff));
            //float3 blendColor = luminance < cutoff ? mix( darkColor, baseColor, luminance*2.) :  mix( baseColor, lightColor, (luminance-cutoff)*(1./cutoff));

            float3 yuv = blendColor * rgb2yuv;
            yuv.x = luminance;
            yuv.yz *= luminance;
            blendColor = yuv * yuv2rgb;

            float shineStart = .85;
            float shineAmount = max(0.,luminance - shineStart) * (1./(1.-shineStart));
            shineAmount = shineAmount * shineAmount * sat;
            blendColor = mix( blendColor, float3(1.), shineAmount );

            //float3 darkColor = hsv2rgb(float3(fract(hue+.95),sat,1.0)) * rgb2yuv;
            //float3 baseColor = hsv2rgb(float3(hue,sat,1.0)) * rgb2yuv;
            //float3 brightColor = hsv2rgb(float3(fract(hue+.05),sat,1.)) * rgb2yuv;
            //
            //float3 outColor;
            //if( luminance < 0.25 ) {
            //    outColor = mix(float3(0.),darkColor,(luminance*4.));
            //} else if( luminance < 0.5 ) {
            //    outColor = mix(darkColor,baseColor,((luminance-0.25)*4.));
            //} else if( luminance < 0.75 ) {
            //    outColor = mix(baseColor,brightColor,((luminance-0.5)*4.));
            //} else {
            //    outColor = brightColor; // mix(brightColor,float3(1.,0.0,0.0),((luminance-0.75)*4.));
            //}
            //
            //outColor.x = luminance;
            //
            //float3 rgb = outColor * yuv2rgb;
            //
            //if( luminance >= 0.75 ) {
            //    rgb = mix(rgb,float3(1.),((luminance-0.75)*4.));
            //}
            __nv_out = float4(blendColor,1.0) * source.a;
    return __nv_out;
}
