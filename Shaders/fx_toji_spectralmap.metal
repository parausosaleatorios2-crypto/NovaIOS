// ---------------------------------------------------------------------------
// @am:string/effect_spectralmap_name
// origem : assets/effects/toji-spectralmap.xml
// id     : com.alightcreative.spectralmap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_spectralmapParams {
    float phase;
    float repeat;
    float alpha;
    float squeeze;
    float saturation;
    float4 redColor;
    float4 greenColor;
    float4 blueColor;
    int reverse;
    int scaleBrightness;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float mapChannel(float p, float f) {
            float t = __nv_mod(p+10., 1.);
            return clamp(abs(t-0.5)*4. - f, 0., 1.);
        }

        //float mapChannelSmooth(float p, float f) {
        //    float t = __nv_mod(p+10., 1.);
        //    return (smoothstep(f*2.0,0.,t) + smoothstep(f,1.,t) - f)*2.;
        //    //return smoothstep(0.5,0.,t) + smoothstep(0.5,1.,t);
        //}

fragment float4 fx_toji_spectralmap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_spectralmapParams&  u    [[buffer(1)]],
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
            float luminance = dot(texColor.rgb, luminanceWeighting);
            float bscale = u.scaleBrightness ? luminance : 1.0;

            if(u.reverse) {
                luminance = 1.0 - luminance;
            }

            luminance = (luminance * u.repeat) + u.phase;

            //float4 aa;
            //float4 bb;
            //float4 cc;
            //
            //float f = mix(0.333, 0.1, u.squeeze );
            //
            //if(smooth) {
            //    aa = mapChannelSmooth(luminance,f)*u.redColor;
            //    bb = mapChannelSmooth(luminance-1./3.0,f)*u.greenColor;
            //    cc = mapChannelSmooth(luminance-2./3.0,f)*u.blueColor;
            //} else {
            //    aa = mapChannel(luminance,f)*u.redColor;
            //    bb = mapChannel(luminance-1./3.0,f)*u.greenColor;
            //    cc = mapChannel(luminance-2./3.0,f)*u.blueColor;
            //}

            float f = mix(0.333, 0.1, u.squeeze );

            float4 aa = mapChannel(luminance,f)*u.redColor;
            float4 bb = mapChannel(luminance-1./3.0,f)*u.greenColor;
            float4 cc = mapChannel(luminance-2./3.0,f)*u.blueColor;

            float4 result = (aa+bb+cc);

            float3 yuv = result.rgb * rgb2yuv;
            yuv.yz = yuv.yz * (u.saturation+1.0);
            result.rgb = yuv * yuv2rgb;

            __nv_out = mix( texColor, result*float4(bscale,bscale,bscale,1.)*texColor.a, u.alpha);
    return __nv_out;
}
