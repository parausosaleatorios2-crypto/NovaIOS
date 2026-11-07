// ---------------------------------------------------------------------------
// @am:string/effect_preciseboxblur_name
// origem : assets/effects/toji-boxblur2.xml
// id     : com.alightcreative.effects.boxblur2
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_boxblur2Params {
    float strength;
    float iter;
};

fragment float4 fx_toji_boxblur2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_boxblur2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( eng.acPass==0 ) {

                float angle = 0.0;
                float actualStrength = u.strength/4.0/u.iter;

                float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
                float rad = angle * 0.0174533;
                float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                float speed = length(velocity / texelSize);
                int nSamples = int(clamp(speed, 1.01, 100.01));
                float4 outColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += inputImg.sample(__nv_smp, in.acScreenNorm.st-offset);
                }
                __nv_out = outColor/float(nSamples);

            } else {

                float angle = 90.0;
                float actualStrength = u.strength/4.0/u.iter;

                float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
                float rad = angle * 0.0174533;
                float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                float speed = length(velocity / texelSize);
                int nSamples = int(clamp(speed, 1.01, 100.01));
                float4 outColor = hblur.sample(__nv_smp, in.acScreenNorm.st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += hblur.sample(__nv_smp, in.acScreenNorm.st-offset);
                }
                __nv_out = outColor/float(nSamples);

            }
            //int from = -max(1,int(u.strength));
            //int to = max(1,int(u.strength));
            //int step;
            //if( u.strength < 0.5 ) {
            //    step = 1
            //} else {
            //    step = max(1,int(log2(u.strength))-1);
            //}
            //float4 outColor = float4(0.0);
            //if( eng.acPass==0 ) {
            //    for(int i=from; i<to; i += step ) {
            //        outColor += inputImg.sample(__nv_smp, float2(in.acScreenNorm.s + float(i)*(1.0/1280.0),in.acScreenNorm.t));
            //    }
            //} else {
            //    for(int i=from; i<to; i += step ) {
            //        outColor += hblur.sample(__nv_smp, float2(in.acScreenNorm.s,in.acScreenNorm.t + float(i)*(1.0/720.0)));
            //    }
            //}
            //__nv_out = outColor/(float(to)*2.0*float(step));
    return __nv_out;
}
