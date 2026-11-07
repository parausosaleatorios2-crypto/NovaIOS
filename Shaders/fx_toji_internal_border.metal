// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-internal-border.xml
// id     : com.alightcreative.internal.border
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_internal_borderParams {
    float maxsize;
    float b0size;
    float4 b0color;
    int b0direction;
    float b1size;
    float4 b1color;
    int b1direction;
    float b2size;
    float4 b2color;
    int b2direction;
    float b3size;
    float4 b3color;
    int b3direction;
    float b4size;
    float4 b4color;
    int b4direction;
    float b5size;
    float4 b5color;
    int b5direction;
    float b6size;
    float4 b6color;
    int b6direction;
    float b7size;
    float4 b7color;
    int b7direction;
    float b8size;
    float4 b8color;
    int b8direction;
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

        struct Border {
            int direction;
            float size;
            float4 color;
        };

fragment float4 fx_toji_internal_border(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_internal_borderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xDistBuf [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xDistBuf_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float radius=u.maxsize*MULTISAMPLE;

            int from = -max(1,int(radius));
            int to = max(1,int(radius));

            // Size of a pixel
            float2 fullViewSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/fullViewSize.x);
            float py = (1.0/fullViewSize.y);

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

                Border borders[8];
                borders[0].direction = u.b0direction;
                borders[0].size      = u.b0size;
                borders[0].color     = u.b0color;
                borders[1].direction = u.b1direction;
                borders[1].size      = u.b1size;
                borders[1].color     = u.b1color;
                borders[2].direction = u.b2direction;
                borders[2].size      = u.b2size;
                borders[2].color     = u.b2color;
                borders[3].direction = u.b3direction;
                borders[3].size      = u.b3size;
                borders[3].color     = u.b3color;
                borders[4].direction = u.b4direction;
                borders[4].size      = u.b4size;
                borders[4].color     = u.b4color;
                borders[5].direction = u.b5direction;
                borders[5].size      = u.b5size;
                borders[5].color     = u.b5color;
                borders[6].direction = u.b6direction;
                borders[6].size      = u.b6size;
                borders[6].color     = u.b6color;
                borders[7].direction = u.b7direction;
                borders[7].size      = u.b7size;
                borders[7].color     = u.b7color;

                float4 result = original;

                for( int i=0; i<8; i++ ) {
                    int direction = borders[i].direction;
                    float4 color = borders[i].color;
                    float size = borders[i].size;
                    if( size > 0.003 ) {
                        if( direction == -1 ) {
                            float4 c = mix(color,  float4(0.0), smoothstep(1.0-1.5/size,1.0,nearestInside/(size/MULTISAMPLE))) * original.a;
                            result = c + result*(1.0-c.a);
                        } else if (direction == 0) {
                            float4 c = mix(color, float4(0.0), smoothstep(1.0-1.5/size,1.0,nearestMid/(size/MULTISAMPLE)));;
                            result = c + result*(1.0-c.a);
                        } else if (direction == 1) {
                            float4 c = mix(color,  float4(0.0), smoothstep(1.0-1.5/size,1.0,nearestOutside/(size/MULTISAMPLE))) * (1.-original.a);
                            result = result + c*(1.0-result.a);
                        }
                    }
                }

                __nv_out = result;
            }
    return __nv_out;
}
