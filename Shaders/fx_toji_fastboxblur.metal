// ---------------------------------------------------------------------------
// @am:string/effect_fastboxblur_name
// origem : assets/effects/toji-fastboxblur.xml
// id     : com.alightcreative.effects.fastboxblur
// passes : 4  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fastboxblurParams {
    float strength;
    float iter;
};

fragment float4 fx_toji_fastboxblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fastboxblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ds1 [[texture(1)]],
    texture2d<float> ds2 [[texture(2)]],
    texture2d<float> hblur [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& ds1_info [[buffer(3)]],
    constant NovaTexInfo& ds2_info [[buffer(4)]],
    constant NovaTexInfo& hblur_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( u.strength <= 0.005 ) {
                __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
            } else {
                if( eng.acPass==0 ) {
                    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
                } else if( eng.acPass==1 ) {
                    __nv_out = ds1.sample(__nv_smp, in.acScreenNorm);
                } else if( eng.acPass==2 ) {

                    float angle = 0.0;
                    float actualStrength = u.strength/4.0/u.iter;

                    float2 texelSize = 1.0 / float2(ds2_info.size);
                    float rad = angle * 0.0174533;
                    float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                    float speed = length(velocity / texelSize);
                    int nSamples = int(clamp(speed, 2.01, 100.01));
                    float4 outColor = ds2.sample(__nv_smp, in.acScreenNorm.st);
                    for(int i=1; i<nSamples; i++ ) {
                        float2 offset = velocity * (float(i) / float(nSamples - 1));
                        outColor += ds2.sample(__nv_smp, in.acScreenNorm.st+offset);
                        outColor += ds2.sample(__nv_smp, in.acScreenNorm.st-offset);
                    }
                    float4 result = outColor/float(nSamples*2-1);
                    __nv_out = result;
                } else {

                    float angle = 90.0;
                    float actualStrength = u.strength/4.0/u.iter;

                    float2 texelSize = 1.0 / float2(hblur_info.size);
                    float rad = angle * 0.0174533;
                    float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                    float speed = length(velocity / texelSize);
                    int nSamples = int(clamp(speed, 2.01, 100.01));
                    float4 outColor = hblur.sample(__nv_smp, in.acScreenNorm.st);
                    for(int i=1; i<nSamples; i++ ) {
                        float2 offset = velocity * (float(i) / float(nSamples - 1));
                        outColor += hblur.sample(__nv_smp, in.acScreenNorm.st+offset);
                        outColor += hblur.sample(__nv_smp, in.acScreenNorm.st-offset);
                    }
                    float4 result = outColor/float(nSamples*2-1);
                    __nv_out = result;

                }
            }
    return __nv_out;
}
