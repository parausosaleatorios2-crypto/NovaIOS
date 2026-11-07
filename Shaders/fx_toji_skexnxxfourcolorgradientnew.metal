// ---------------------------------------------------------------------------
// [X] 4 Color Gradient+
// origem : assets/effects/toji-skexnxxfourcolorgradientnew.xml
// id     : com.alightcreative.fourcolorgradientnew
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxfourcolorgradientnewParams {
    float4 color1;
    float2 offset1;
    float4 color2;
    float2 offset2;
    float4 color3;
    float2 offset3;
    float4 color4;
    float2 offset4;
    float blend;
    float alpha;
    float bright;
    int blendMode;
    float alphab;
};

// --- funcoes auxiliares do efeito
static float gradientNoise(in float2 uv)
        {
            const float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
            return fract(magic.z * fract(dot(uv, magic.xy)));
        }
        
               const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
   
        float3 hsv2rgb(float3 c)
        {
            float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        float3 rgb2hsv(float3 c)
        {
            float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
            float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
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

fragment float4 fx_toji_skexnxxfourcolorgradientnew(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxfourcolorgradientnewParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;

            float2 pos = (u.offset1*float2(1,-1)) / 500.;
            float t1 = length(st - pos);

            pos = (u.offset2*float2(1,-1)) / 500.;
            float t2 = length(st - pos);

            pos = (u.offset3*float2(1,-1)) / 500.;
            float t3 = length(st - pos);

            pos = (u.offset4*float2(1,-1)) / 500.;
            float t4 = length(st - pos);

            float4 color = float4(0.0, 0.0, 0.0, 0.0);
            float sw_t1 = smoothstep(0.0, 1.0, clamp((1.0 - t1), 0.0, 1.0));
            float sw_t2 = smoothstep(0.0, 1.0, clamp((1.0 - t2), 0.0, 1.0));
            float sw_t3 = smoothstep(0.0, 1.0, clamp((1.0 - t3), 0.0, 1.0));
            float sw_t4 = smoothstep(0.0, 1.0, clamp((1.0 - t4), 0.0, 1.0));
            color += u.color1 * pow(sw_t1, 1.0/u.blend);
            color += u.color2 * pow(sw_t2, 1.0/u.blend);
            color += u.color3 * pow(sw_t3, 1.0/u.blend);
            color += u.color4 * pow(sw_t4, 1.0/u.blend);
            color /= (sw_t1 + sw_t2 + sw_t3 + sw_t4);

            color.a = 1.0;
            color += (1.0/255.0) * gradientNoise(st) - (0.5/255.0);
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            } else {
                result = float4(color.rgb,1.0)*texColor.a;
            }
            float4 __nv_out = mix(texColor,result,u.alpha);
            
        float4 texColorX = float4(0.0,0.0,0.0,1.0) * texColor.a;
    	float4 factor = mix(texColorX,__nv_out,1.0);

        float4 resultfinal;
        if( u.blendMode==0 ) {                // normal
            resultfinal = (factor * u.bright) * texColor.a;
        } else if( u.blendMode==1 ) {         // multiply
            factor *= u.bright;
            float4 c = factor + float4(1.)*(1.-factor.a);
            resultfinal = float4((texColor.rgb/texColor.a)*c.rgb,1.0) * texColor.a;
        } else if( u.blendMode==2 ) {         // screen
            factor *= u.bright;
            resultfinal = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-factor.rgb)),1.0) * texColor.a;
        } else if(u.blendMode==3 ) {
            factor *= u.bright;
            float3 t = smoothstep(0.5,0.5,texColor.rgb);
            float3 result =
                    t * (1. - (1.-2.*(texColor.rgb-0.5)) * (1.-factor.rgb)) +
                    (1.-t) * ((2.*texColor.rgb) * factor.rgb);
            resultfinal = float4(result, texColor.a) * texColor.a;
        } else if(u.blendMode==4 ) {
            float3 colorBlend = float3( (texColor.rgb * rgb2yuv).r, (factor.rgb * rgb2yuv).gb) * yuv2rgb;
            resultfinal = float4(colorBlend,texColor.a) * texColor.a;
        } else if(u.blendMode==5 ) {
            factor *=u.bright;
            resultfinal = max(factor,texColor) * texColor.a;
        } else if(u.blendMode==6 ) {
            factor *=u.bright;
            resultfinal = texColor / (1.0-factor) * texColor.a;
        } else if(u.blendMode==7 ) {
            factor *=u.bright;
            resultfinal = (1. - (1.-texColor) / factor) * texColor.a;
        } else if(u.blendMode==8 ) {
            factor *=u.bright;
            resultfinal = (texColor + factor) * texColor.a;
        } else if(u.blendMode==9 ) {
            factor *=u.bright;
            resultfinal = (texColor + factor - 1.0) * texColor.a;
        } else if(u.blendMode==10 ) {
            float3 t = smoothstep(0.5,0.5,factor.rgb);
            float3 linearLight =
                    t * (texColor.rgb + 2.*(factor.rgb-0.5)) +
                    (1.-t) * (texColor.rgb + 2.*factor.rgb - 1.);
            resultfinal = float4(linearLight,texColor.a) * texColor.a;
        } else if(u.blendMode==11 ) {
            factor *=u.bright;
            resultfinal = min(factor,texColor) * texColor.a;
        } else if(u.blendMode==12 ) {
            factor *=u.bright;
            float3 darkenColor = length(luminanceWeighting * factor.rgb) > length(luminanceWeighting * texColor.rgb) ? texColor.rgb : factor.rgb;
            resultfinal = float4(darkenColor,texColor.a) * texColor.a;
        } else if(u.blendMode==13 ) {
            factor *=u.bright;
            float3 lightenColor = length(luminanceWeighting * factor.rgb) > length(luminanceWeighting * texColor.rgb) ? factor.rgb : texColor.rgb;
            resultfinal = float4(lightenColor,texColor.a) * texColor.a;
        } else if(u.blendMode==14 ) {
            factor *=u.bright;
            float3 t = smoothstep(0.5,0.5,factor.rgb);
            float3 softLight =
                    t * (1. - (1.-texColor.rgb) * (1.-(factor.rgb-0.5))) +
                    (1.-t) * (texColor.rgb * (factor.rgb+0.5));
            resultfinal = float4(softLight,texColor.a) * texColor.a;
        } else if(u.blendMode==15 ) {
            factor *=u.bright;
            float3 t = smoothstep(0.5,0.5,texColor.rgb);
            float3 softOver =
                    t * (1. - (1.-texColor.rgb) * (1.-(factor.rgb-0.5))) +
                    (1.-t) * (texColor.rgb * (factor.rgb+0.5));
            resultfinal = float4(softOver,texColor.a) * texColor.a;
        } else if(u.blendMode==16 ) {
            factor *=u.bright;
            float3 t = smoothstep(0.5,0.5,factor.rgb);
            float3 hardLight =
                    t * (1. - (1.-texColor.rgb) * (1.-2.*(factor.rgb-0.5))) +
                    (1.-t) * (texColor.rgb * (2.*factor.rgb));
            resultfinal = float4(hardLight,texColor.a) * texColor.a;
        } else if(u.blendMode==17 ) {
            factor *=u.bright;
            float3 hueB = hsv2rgb(float3(rgb2hsv(factor.rgb).r, rgb2hsv(texColor.rgb).gb));
            resultfinal = float4(hueB,texColor.a) * texColor.a;
        } else if(u.blendMode==18 ) {
            factor *=u.bright;
            resultfinal = float4(abs(texColor.rgb*texColor.a - factor.rgb),texColor.a);
        } else if(u.blendMode==19 ) {
            factor *=u.bright;
            float3 lumin = float3( (factor.rgb * rgb2yuv).r, (texColor.rgb * rgb2yuv).gb) * yuv2rgb;
            resultfinal = float4(lumin,texColor.a) * texColor.a;
        } else if(u.blendMode==20 ) {
            factor *=u.bright;
            float3 bot_hsv = rgb2hsv(texColor.rgb);
            float3 satBlend = hsv2rgb(float3(bot_hsv.r, rgb2hsv(factor.rgb).g, bot_hsv.b));
            resultfinal = float4(satBlend,texColor.a) * texColor.a;
        } else if(u.blendMode==21 ) {
            factor *=u.bright;
            float3 t = smoothstep(0.5,0.5,factor.rgb);
            float3 vividLight =
                    t * (1. - (1.-texColor.rgb) * (2.*(factor.rgb-0.5))) +
                    (1.-t) * (texColor.rgb * (1.-2.*factor.rgb));
            resultfinal = float4(vividLight,texColor.a) * texColor.a;
        } else if(u.blendMode==22 ) {
            factor *=u.bright;
            float3 t = smoothstep(0.5,0.5,factor.rgb);
            float3 pinLight =
                    t * (max(texColor.rgb,2.*(factor.rgb-0.5))) +
                    (1.-t) * (min(texColor.rgb,2.*factor.rgb));
            resultfinal = float4(pinLight,texColor.a) * texColor.a;
        } else if(u.blendMode==23 ) {
            factor *=u.bright;
            resultfinal = (texColor / factor) * texColor.a;
        } else if(u.blendMode==24 ) {
            factor *=u.bright;
            resultfinal = (texColor - factor) * texColor.a;
        }
        
    	__nv_out = mix(__nv_out, resultfinal, u.alphab) * texColor.a;
    return __nv_out;
}
