// ---------------------------------------------------------------------------
// @am:string/effect_glow_name
// origem : assets/effects/toji-glow.xml
// id     : com.alightcreative.glow
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_glowParams {
    float radius;
    float alpha;
    float hardness;
    float4 color;
    int blendMode;
};

// --- funcoes auxiliares do efeito
#define MULTISAMPLE 1.0
        #define MAX_RADIUS 16383.0

        static float2 encodeFloat(float v) {
            float2 enc = fract(float2(1.0, 255.0)*v);
            enc.x -= enc.y/255.0;
            return enc;
        }

        static float decodeFloat(float2 v) {
            return dot(v,float2(1.0,1.0/255.0));
        }

fragment float4 fx_toji_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> xDistBuf [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float radius2 = u.radius * length(__nv_getTexSize(inputImg_info.size)) / length(float2(1024, 1024));
            if( radius2 < 0.5 ) {
                __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                return __nv_out;
            }

            //float q = 11.0 - quality;
            float q = max(pow(radius2,1.24)/radius2,radius2/40.0);

            float sdx = 0.0;
            float sdy = 0.0;

            int from = -max(1,int(radius2/q));
            int to = max(1,int(radius2/q));

            // Size of a pixel
            float2 imgSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/imgSize.x);
            float py = (1.0/imgSize.y);

            if( eng.acPass==0 ) {

                // Calculate distance on X-axis and encode in a texture

                float nearestOutside = MAX_RADIUS;
                float nearestInside = MAX_RADIUS;

                for(int i=from; i<to; i++ ) {
                    float x = float(i)*q;
                    float4 sample = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + (x-sdx)*(px/MULTISAMPLE),in.acScreenNorm.t));
                    float xdistOut = sample.a > 0.0 ? abs(x) : radius2*2.0;
                    float xdistIn = sample.a < 0.003 ? abs(x) : radius2*2.0;
                    nearestOutside = min(nearestOutside,xdistOut);
                    nearestInside = min(nearestInside,xdistIn);
                }

                __nv_out = float4(encodeFloat(nearestOutside/MAX_RADIUS),encodeFloat(nearestInside/MAX_RADIUS));

            } else {

                float nearestOutside = MAX_RADIUS;
                float nearestInside = MAX_RADIUS;

                for(int i=from; i<to; i++ ) {
                    float y = float(i)*q;

                    float4 sample = xDistBuf.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + (y+sdy)*(py/MULTISAMPLE)));
                    float xdistOut = decodeFloat(sample.rg) * MAX_RADIUS;
                    float xdistIn = decodeFloat(sample.ba) * MAX_RADIUS;
                    float ydist = abs(y);
                    float distOut = length(float2(xdistOut,ydist));
                    float distIn = length(float2(xdistIn,ydist));
                    nearestInside = min(nearestInside,distIn);
                    nearestOutside = min(nearestOutside,distOut);
                }

                float pIn = nearestInside/(radius2/MULTISAMPLE);
                float pOut = nearestOutside/(radius2/MULTISAMPLE);
                float p = 0.5 + pIn - pOut;
                if( p <= 0.0001 )
                    discard_fragment();

                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                float4 compColor = comp.sample(__nv_smp, in.acScreenNorm.st);
                //float4 offsetOriginal = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + (-sdx)*(px/MULTISAMPLE),in.acScreenNorm.t + (sdy)*(py/MULTISAMPLE)));

                //float nearestMid = max(nearestInside, nearestOutside);
                //float qr = ((radius2/MULTISAMPLE)/4.0);
                //float hr = ((radius2/MULTISAMPLE)/2.0);
                //float nearestSolidInner = (max(0.0,hr - nearestInside) * (1.0-offsetOriginal.a))-max(0.0,nearestOutside-hr);

                //float4 outColor = radius2<0.003 ? float4(0.0)  : mix(u.color*u.alpha,  float4(0.0), smoothstep((1.0-1.5/radius2)*u.hardness,1.0,nearestOutside/(radius2/MULTISAMPLE)));

                float4 blendColor;

                if( u.blendMode==0 ) {
                    blendColor = float4(u.color.rgb, 1.0);
                } else if( u.blendMode==1 ) {
                    blendColor = float4( compColor.rgb * u.color.rgb, 1.0 );
                } else {
                    blendColor = float4( 1.-( 1.-compColor.rgb) * (1.-u.color.rgb) , 1.0 );
                }

                float4 outColor = radius2<0.003 ? float4(0.0)  : mix(blendColor*u.alpha,  float4(0.0), smoothstep((1.0-1.5/radius2)*u.hardness,1.0,1.0-p));

                float4 result = u.blendMode==0 ? float4(outColor.rgb, outColor.a * u.color.a) : outColor;
                result = original + result*(1.0-original.a);
                __nv_out = result;
            }
    return __nv_out;
}
