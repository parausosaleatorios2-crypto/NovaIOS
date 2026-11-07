// ---------------------------------------------------------------------------
// @am:string/effect_contourlines_name
// origem : assets/effects/toji-contour.xml
// id     : com.alightcreative.contour
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_contourParams {
    float4 color;
    float offset;
    float width;
    float alpha;
    float fill;
    float count;
    float phase;
    int fade;
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

fragment float4 fx_toji_contour(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_contourParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xDistBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float offset2 =u.offset * length(__nv_getTexSize(inputImg_info.size))/length(float2(1024, 1024));
            float width2 = u.width *length(__nv_getTexSize(inputImg_info.size))/length(float2(1024, 1024));

            float radius=(offset2+width2)*MULTISAMPLE;

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

                //float ow = u.offset + u.width;
                //float outer = smoothstep(1.0-1.5/ow,1.0,nearestOutside/(ow/MULTISAMPLE));
                //float inner = smoothstep(1.0-1.5/u.offset,1.0,nearestOutside/(u.offset/MULTISAMPLE));
                //float p = (1.-outer)-(1.-inner);

                float aa = 1./width2/2.;
                float p = clamp((nearestOutside-offset2) / width2,0.,1.);
                float bands = u.count * 2. - 1.;
                float mask;
                if( u.fade ) {
                    //mask = smoothstep(0.,1.,p) * smoothstep(1., 1.-aa, p); // Fade inside
                    mask = smoothstep(1.,0.,p) * smoothstep(0.,aa,p);
                } else {
                    mask = smoothstep(0.,aa,p) * smoothstep(1., 1.-aa, p);
                }
                p = smoothstep(1.+aa,1.-aa,__nv_mod(mod(p+u.phase,1.+1./(u.count*2.))*bands, 2.));
                p *= mask;

                float4 c = u.color*u.alpha*p * (1.-original.a);

                original *= u.fill;

                __nv_out = original*(1.-c.a)+c;
            }
    return __nv_out;
}
