// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-internal-border-three.xml
// id     : com.alightcreative.internal.border-three
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_internal_border_threeParams {
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

fragment float4 fx_toji_internal_border_three(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_internal_border_threeParams&  u    [[buffer(1)]],
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
            float px = 1.0 / 2048.0;
            float2 fullViewSize = __nv_getTexSize(inputImg_info.size);
            float py = 1.0 / (2048.0 / (fullViewSize.x/fullViewSize.y));

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

                float4 result = original;

                int direction;
                float4 color;
                float size;

                // 0
                direction = u.b0direction;
                color = u.b0color;
                size = u.b0size;
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

                // 1
                direction = u.b1direction;
                color = u.b1color;
                size = u.b1size;
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

                // 2
                direction = u.b2direction;
                color = u.b2color;
                size = u.b2size;
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

                __nv_out = result;
            }
    return __nv_out;
}
