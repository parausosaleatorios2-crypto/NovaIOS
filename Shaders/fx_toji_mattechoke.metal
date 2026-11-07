// ---------------------------------------------------------------------------
// @am:string/effect_mattechoke_name
// origem : assets/effects/toji-mattechoke.xml
// id     : com.alightcreative.mattechoke
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_mattechokeParams {
    float choke;
    float feather;
    int invert;
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

fragment float4 fx_toji_mattechoke(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_mattechokeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xDistBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            //float radius=max(max(innerBorderSize,outerBorderSize),centerBorderSize)*MULTISAMPLE;
            float radius=u.choke*MULTISAMPLE;

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

                float inAlpha = smoothstep((1.0-1.5/u.choke)*(1.0-u.feather),1.0,nearestInside/(u.choke/MULTISAMPLE));
                if(u.invert) {
                    inAlpha = 1. - inAlpha;
                }
                //float4 result = outColor;
                //result = original + result*(1.0-original.a);
                //result = inColor + result*(1.0-inColor.a);
                //result = midColor + result*(1.0-midColor.a);
                __nv_out = original * inAlpha;
            }
    return __nv_out;
}
