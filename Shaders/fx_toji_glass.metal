// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-glass.xml
// id     : com.alightcreative.effect.glass
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_glassParams {
    float radius;
    float angle_d;
    float angle_s;
    float4 color_d;
    float4 color_s;
    float intensity_d;
    float intensity_s;
    float elevation_d;
    float elevation_s;
    float spec;
    float refract;
    float fill;
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

fragment float4 fx_toji_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_glassParams&  u    [[buffer(1)]],
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


            //float u.radius=max(max(innerBorderSize,outerBorderSize),centerBorderSize)*MULTISAMPLE;

            int from = -max(1,int(u.radius));
            int to = max(1,int(u.radius));

            // Size of a pixel
            float2 imgSize = __nv_getTexSize(inputImg_info.size);
            float px = (1.0/imgSize.x);
            float py = (1.0/imgSize.y);

            if( eng.acPass==0 ) {

                // Calculate distance on X-axis and encode in a texture

                float nearestLeft = MAX_RADIUS;
                float nearestRight = MAX_RADIUS;

                for(int i=from; i<0; i++ ) {
                    float x = float(i);
                    float4 sample = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + x*(px/MULTISAMPLE),in.acScreenNorm.t));
                    float dist = sample.a < 0.003 ? abs(x) : u.radius*2.0;
                    nearestLeft = min(nearestLeft,dist);
                }

                for(int i=0; i<to; i++ ) {
                    float x = float(i);
                    float4 sample = inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + x*(px/MULTISAMPLE),in.acScreenNorm.t));
                    float dist = sample.a < 0.003 ? abs(x) : u.radius*2.0;
                    nearestRight = min(nearestRight,dist);
                }

                __nv_out = float4(encodeFloat(nearestLeft/MAX_RADIUS),encodeFloat(nearestRight/MAX_RADIUS));

            } else {

                float as = u.angle_s * 0.0174533;
                float ad = u.angle_d * 0.0174533;
                float3 light_s = float3( cos(as), -sin(as), -u.elevation_s );
                float3 light_d = float3( cos(ad), -sin(ad), -u.elevation_d );

                // Final pass

                float nearestTopLeft        = MAX_RADIUS;
                float nearestTopRight       = MAX_RADIUS;
                float nearestBottomLeft     = MAX_RADIUS;
                float nearestBottomRight    = MAX_RADIUS;

                for(int i=from; i<0; i++ ) {

                    float y = float(i);

                    float4 sample = xDistBuf.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + y*(py/MULTISAMPLE)));

                    float nearestLeft = decodeFloat(sample.rg) * MAX_RADIUS;
                    float nearestRight = decodeFloat(sample.ba) * MAX_RADIUS;
                    float ydist = abs(y);
                    float ldist = length(float2(nearestLeft,ydist));
                    float rdist = length(float2(nearestRight,ydist));

                    nearestBottomLeft = min(nearestBottomLeft,ldist);
                    nearestBottomRight = min(nearestBottomRight,rdist);
                }

                for(int i=0; i<to; i++ ) {

                    float y = float(i);

                    float4 sample = xDistBuf.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + y*(py/MULTISAMPLE)));

                    float nearestLeft = decodeFloat(sample.rg) * MAX_RADIUS;
                    float nearestRight = decodeFloat(sample.ba) * MAX_RADIUS;
                    float ydist = abs(y);
                    float ldist = length(float2(nearestLeft,ydist));
                    float rdist = length(float2(nearestRight,ydist));

                    nearestTopLeft = min(nearestTopLeft,ldist);
                    nearestTopRight = min(nearestTopRight,rdist);
                }

                float nearestInside = nearestTopRight;

                float4 original = inputImg.sample(__nv_smp, in.acScreenNorm.st);

                nearestTopLeft = smoothstep(0.0,1.0, nearestTopLeft/(u.radius/MULTISAMPLE));
                nearestTopRight = smoothstep(0.0,1.0, nearestTopRight/(u.radius/MULTISAMPLE));
                nearestBottomLeft = smoothstep(0.0,1.0, nearestBottomLeft/(u.radius/MULTISAMPLE));
                nearestBottomRight = smoothstep(0.0,1.0, nearestBottomRight/(u.radius/MULTISAMPLE));

                float3 v = (float3(-1.0,-1.0,-1.0)*nearestBottomLeft + float3(1.0,-1.0,-1.0)*nearestBottomRight + float3(-1.0,1.0,-1.0)*nearestTopLeft + float3(1.0,1.0,-1.0)*nearestTopRight) / 4.0; // / (u.radius/MULTISAMPLE);

                float4 refractColor = comp.sample(__nv_smp, in.acScreenNorm.st + v.xy*u.refract);


                //float4 innerBorderColor = float4(1.0,0.5,0.0,1.0);

                //float4 inColor = u.radius<0.003 ? float4(0.0)  : mix(innerBorderColor,  float4(0.0), smoothstep(1.0-1.5/u.radius,1.0,nearestInside/(u.radius/MULTISAMPLE))) * original.a;
                //float4 inColor = float4(nearestTopLeft/(u.radius/MULTISAMPLE), nearestTopRight/(u.radius/MULTISAMPLE), nearestBottomLeft/(u.radius/MULTISAMPLE), 1.0 );

                //float4 inColor = float4(float2(0.5,0.5)+v, 0.5, 1.0 )*original.a;

                float lum_s = pow(dot(normalize(v),normalize(light_s)),u.spec);
                float lum_d = dot(normalize(v),normalize(light_d));

                float4 lit_color_s = u.color_s * lum_s * u.intensity_s * original.a;
                float4 lit_color_d = u.color_d * lum_d * u.intensity_d * original.a;

                float4 over_a = original * u.fill;

                float4 result = refractColor * original.a;
                result = over_a + result*(1.0-over_a.a);
                result = lit_color_d + result*(1.0-lit_color_d.a);
                result = lit_color_s + result*(1.0-lit_color_s.a);
                __nv_out = result;
            }
    return __nv_out;
}
