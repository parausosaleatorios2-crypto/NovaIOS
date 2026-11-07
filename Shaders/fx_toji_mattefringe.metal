// ---------------------------------------------------------------------------
// @am:string/effect_mattefringe_name
// origem : assets/effects/toji-mattefringe.xml
// id     : com.alightcreative.effects.mattefringe
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_mattefringeParams {
    float thickness;
    float feather;
    float4 excludeColor1;
    float threshold1;
    float4 excludeColor2;
    float threshold2;
    float4 excludeColor3;
    float threshold3;
};

// --- funcoes auxiliares do efeito
#define MULTISAMPLE 1.0
        #define MAX_RADIUS 16383.0

        float2 encodeFloat(float v) {
            float2 enc = fract(float2(1.0, 255.0)*v);
            enc.x -= enc.y/255.0;
            return enc;
        }

        float decodeFloat(float2 v) {
            return dot(v,float2(1.0,1.0/255.0));
        }

fragment float4 fx_toji_mattefringe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_mattefringeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xDistBuf [[texture(1)]],
    texture2d<float> comp [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(3)]],
    constant NovaTexInfo& comp_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            //float radius=max(max(innerBorderSize,outerBorderSize),centerBorderSize)*MULTISAMPLE;
            float radius=u.thickness*MULTISAMPLE;

            int from = -max(1,int(radius));
            int to = max(1,int(radius));

            // Size of a pixel
            float2 imgSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/imgSize.x);
            float py = (1.0/imgSize.y);

            if( eng.acPass==0 ) {

                // Calculate distance on X-axis and encode in a texture

                float nearestOutside = MAX_RADIUS;
                float nearestInside = MAX_RADIUS;

                for(int i=from; i<to; i++ ) {

                    float x = float(i);

                    float4 sample = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + x*(px/MULTISAMPLE),in.acScreenNorm.t));
                    float xdistOut = sample.a > 0.0 ? abs(x) : radius*2.0;
                    float xdistIn = sample.a < 0.003 ? abs(x) : radius*2.0;
                    nearestOutside = min(nearestOutside,xdistOut);
                    nearestInside = min(nearestInside,xdistIn);

                }

                __nv_out = float4(encodeFloat(nearestOutside/MAX_RADIUS),encodeFloat(nearestInside/MAX_RADIUS));

            } else {

                // Final pass

                float nearestOutside = MAX_RADIUS;
                float nearestInside = MAX_RADIUS;

                for(int i=from; i<to; i++ ) {

                    float y = float(i);

                    float4 sample = xDistBuf.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + y*(py/MULTISAMPLE)));

                    float xdistOut = decodeFloat(sample.rg) * MAX_RADIUS;
                    float xdistIn = decodeFloat(sample.ba) * MAX_RADIUS;
                    float ydist = abs(y);
                    float distOut = length(float2(xdistOut,ydist));
                    float distIn = length(float2(xdistIn,ydist));

                    nearestInside = min(nearestInside,distIn);
                    nearestOutside = min(nearestOutside,distOut);
                }

                float nearestMid = max(nearestInside, nearestOutside);

                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);

                //float4 outColor = outerBorderSize<0.003 ? float4(0.0)  : mix(outerBorderColor,  float4(0.0), smoothstep(1.0-1.5/outerBorderSize,1.0,nearestOutside/(outerBorderSize/MULTISAMPLE)));
                //float4 inColor = innerBorderSize<0.003 ? float4(0.0)   : mix(innerBorderColor,  float4(0.0), smoothstep(1.0-1.5/innerBorderSize,1.0,nearestInside/(innerBorderSize/MULTISAMPLE))) * original.a;
                //float4 midColor = centerBorderSize<0.003 ? float4(0.0) : mix(centerBorderColor, float4(0.0), smoothstep(1.0-1.5/centerBorderSize,1.0,nearestMid/(centerBorderSize/MULTISAMPLE)));

                float inAlpha = u.thickness > 0.0 ? smoothstep((1.0-1.5/u.thickness)*(1.0-u.feather),1.0,nearestInside/(u.thickness/MULTISAMPLE)): 1.0;
                //if(invert) {
                    inAlpha = 1. - inAlpha;
                //}
                //float4 result = outColor;
                //result = original + result*(1.0-original.a);
                //result = inColor + result*(1.0-inColor.a);
                //result = midColor + result*(1.0-midColor.a);
                
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

                float4 bg = comp.sample(__nv_smp, in.acScreenNorm);
                float3 bgyuv = bg.rgb * rgb2yuv;
                float3 fgyuv = original.rgb * rgb2yuv;
                
                float3 exclyuv1 = u.excludeColor1.rgb * rgb2yuv;
                float tt1 = smoothstep(0.0,u.threshold1,length(exclyuv1.yz - fgyuv.yz));
                
                float3 exclyuv2 = u.excludeColor2.rgb * rgb2yuv;
                float tt2 = smoothstep(0.0,u.threshold2,length(exclyuv2.yz - fgyuv.yz));

                float3 exclyuv3 = u.excludeColor3.rgb * rgb2yuv;
                float tt3 = smoothstep(0.0,u.threshold3,length(exclyuv3.yz - fgyuv.yz));

                float3 adj = float3(fgyuv.x, mix(fgyuv.yz,bgyuv.yz,inAlpha * original.a * tt1 * tt2 * tt3)) * yuv2rgb;
                
                __nv_out = float4(adj,original.a);
            }
    return __nv_out;
}
