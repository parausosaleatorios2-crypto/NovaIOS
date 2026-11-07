// ---------------------------------------------------------------------------
// @am:string/effect_omino_diffusion_name
// origem : assets/effects/toji-omino-diffusion.xml
// id     : com.alightcreative.effects.ominodiff
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_omino_diffusionParams {
    float angle;
    float strength;
    float steps;
    float errorWeight;
    float errorFalloff;
    int palette;
    float alpha;
    int blendMode;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float4 color6;
};

// --- funcoes auxiliares do efeito
static float2x2 rot2(float a) {
            float s = sin(a);
            float c = cos(a);
            return float2x2(c,-s,s,c);
        }

        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float colorDiff( float3 a, float3 b ) {
            float3 d = abs(a-b);
            return d.r + d.g + d.b;
        }

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

fragment float4 fx_toji_omino_diffusion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_omino_diffusionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float2 v = float2(1.,0.) * rot2((180.0-u.angle) * 0.0174533);
            //v.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float2 dv = v * u.strength / u.steps;
            float3 accumErr = float3(0.);
            float4 outColor = float4(0.);
            for(float i=u.steps; i>=0.0; i -= 1.0 ) {
                float pct = i/u.steps;
                float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm.st + dv*i);
                float3 baseColor = saturate((texColor.a < 0.001 ? float3(0.) : texColor.rgb / texColor.a) + accumErr);
                
                float3 matchColor;
                if( u.palette == 0 ) { // Black & white
                    float luminance = dot(baseColor, luminanceWeighting);
                    matchColor = luminance < 0.5 ? float3(0.) : float3( 1. );
                } else if( u.palette == 1 ) { // RGB 2-Level Posterize
                    matchColor = floor(baseColor* 2.0);
                } else if( u.palette == 2 ) { // RGB 3-Level Posterize
                    matchColor = floor((baseColor + 0.25) * 2.0) / 2.0;
                } else if( u.palette == 3 ) { // RGB 4-Level Posterize
                    matchColor = floor((baseColor + 0.1666667) * 3.0) / 3.0;
                } else if( u.palette == 4 ) { // Gray 3 levels
                    float luminance = dot(baseColor, luminanceWeighting);
                    float adjLum = floor((luminance + 0.25) * 2.0) / 2.0;
                    matchColor = float3(adjLum);
                } else if( u.palette == 5 ) { // Gray 4 levels
                    float luminance = dot(baseColor, luminanceWeighting);
                    float adjLum = floor((luminance + 0.1666667) * 3.0) / 3.0;
                    matchColor = float3(adjLum);
                } else if( u.palette == 6 ) { // CGA Green/Red/Yellow
                    matchColor = floor(baseColor*2.0);
                    matchColor.b = 0.;
                } else if( u.palette == 7 ) { // CGA Cyan/Magenta/White
                    matchColor = floor(baseColor*2.0);
                    matchColor.b = matchColor.r > 0.1 || matchColor.g > 0.1 ? 1. : 0.;
                } else if( u.palette == 8 ) { // CGA Blue/Cyan/Magenta/White
                    matchColor = floor(baseColor*2.0);
                    matchColor.b = 1.;
                } else if( u.palette == 9 ) { // Saturate and Posterize
                    float3 yuv = baseColor * rgb2yuv;
                    yuv.gb = (yuv.gb-0.5) * 2.0 + 0.5;
                    yuv.r = floor((yuv.r + 0.166667)*3.0)/3.0;
                    matchColor = float3(yuv * yuv2rgb);
                } else if( u.palette == 11 ) {
                    matchColor = u.color1.rgb;
                } else if( u.palette == 12 ) {
                    float d1 = colorDiff(baseColor,u.color1.rgb);
                    float d2 = colorDiff(baseColor,u.color2.rgb);
                    float dmin = min(d1,d2);
                    matchColor = dmin==d1 ? u.color1.rgb : u.color2.rgb;
                } else if( u.palette == 13 ) {
                    float d1 = colorDiff(baseColor,u.color1.rgb);
                    float d2 = colorDiff(baseColor,u.color2.rgb);
                    float d3 = colorDiff(baseColor,u.color3.rgb);
                    float dmin = min(min(d1,d2),d3);
                    matchColor =
                        dmin==d1 ? u.color1.rgb :
                        dmin==d2 ? u.color2.rgb :
                        u.color3.rgb;
                } else if( u.palette == 14 ) {
                    float d1 = colorDiff(baseColor,u.color1.rgb);
                    float d2 = colorDiff(baseColor,u.color2.rgb);
                    float d3 = colorDiff(baseColor,u.color3.rgb);
                    float d4 = colorDiff(baseColor,u.color4.rgb);
                    float dmin = min(min(d1,d2),min(d3,d4));
                    matchColor =
                        dmin==d1 ? u.color1.rgb :
                        dmin==d2 ? u.color2.rgb :
                        dmin==d3 ? u.color3.rgb :
                        u.color4.rgb;
                } else if( u.palette == 15 ) {
                    float d1 = colorDiff(baseColor,u.color1.rgb);
                    float d2 = colorDiff(baseColor,u.color2.rgb);
                    float d3 = colorDiff(baseColor,u.color3.rgb);
                    float d4 = colorDiff(baseColor,u.color4.rgb);
                    float d5 = colorDiff(baseColor,u.color5.rgb);
                    float dmin = min(min(min(d1,d2),min(d3,d4)),d5);
                    matchColor =
                        dmin==d1 ? u.color1.rgb :
                        dmin==d2 ? u.color2.rgb :
                        dmin==d3 ? u.color3.rgb :
                        dmin==d4 ? u.color4.rgb :
                        u.color5.rgb;
                } else if( u.palette == 16 ) {
                    float d1 = colorDiff(baseColor,u.color1.rgb);
                    float d2 = colorDiff(baseColor,u.color2.rgb);
                    float d3 = colorDiff(baseColor,u.color3.rgb);
                    float d4 = colorDiff(baseColor,u.color4.rgb);
                    float d5 = colorDiff(baseColor,u.color5.rgb);
                    float d6 = colorDiff(baseColor,u.color6.rgb);
                    float dmin = min(min(min(d1,d2),min(d3,d4)),min(d5,d6));
                    matchColor =
                        dmin==d1 ? u.color1.rgb :
                        dmin==d2 ? u.color2.rgb :
                        dmin==d3 ? u.color3.rgb :
                        dmin==d4 ? u.color4.rgb :
                        dmin==d5 ? u.color5.rgb :
                        u.color6.rgb;
                }
                
                //matchColor *= texColor.a;
                
                outColor = float4(matchColor,1.)*texColor.a;
                float3 err = baseColor - matchColor;
                accumErr = err * u.errorWeight * mix(1.,pct*pct,u.errorFalloff);
            }
            float4 origColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float4 result;
            if( u.blendMode==1 ) { // Multiply
                float3 a = origColor.rgb / max(origColor.a,0.00001);
                float3 b = outColor.rgb / max(outColor.a,0.00001);
                result = float4(a * b, 1.) * origColor.a;
            } else if( u.blendMode==2 ) { // Screen
                float3 a = origColor.rgb / max(origColor.a,0.00001);
                float3 b = outColor.rgb / max(outColor.a,0.00001);
                result = float4(1.-((1.-a) * (1.-b)), 1.) * origColor.a;
            } else {
                result = outColor;
            }
            __nv_out = mix(origColor,result,u.alpha);
    return __nv_out;
}
