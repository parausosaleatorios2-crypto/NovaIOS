// ---------------------------------------------------------------------------
// Box Blur+
// origem : assets/effects/toji-skexnxxboxblurplus.xml
// id     : com.alightcreative.effects.boxblurplus
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxboxblurplusParams {
    int mode;
    float strength;
    float fill;
};

fragment float4 fx_toji_skexnxxboxblurplus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxboxblurplusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ds1 [[texture(1)]],
    texture2d<float> comp [[texture(2)]],
    texture2d<float> hblur [[texture(3)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& ds1_info [[buffer(3)]],
    constant NovaTexInfo& comp_info [[buffer(4)]],
    constant NovaTexInfo& hblur_info [[buffer(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            if( u.strength <= 0.0001 ) {
                float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                float4 lift = mix(comp.sample(__nv_smp, in.acScreenNorm)*texColor.a,texColor,u.fill);
                __nv_out = u.mode? lift : inputImg.sample(__nv_smp, in.acScreenNorm);
            } else {
                if( eng.acPass==0 ) {
                    float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                    float4 lift = mix(comp.sample(__nv_smp, in.acScreenNorm)*texColor.a,texColor,u.fill);
                    __nv_out = u.mode? lift : inputImg.sample(__nv_smp, in.acScreenNorm);
                } else if( eng.acPass==1 ) {

                    float actualStrength = u.strength/10.0;
                    float2 texelSize = 1.0 / __nv_getTexSize(ds1_info.size);
                    float2 velocity = float2(actualStrength,0.0);
                    float speed = length(velocity / texelSize);
                    int nSamples = int(clamp(speed, 2.01, 150.01));
                    float4 outColor = ds1.sample(__nv_smp, in.acScreenNorm.st);
                    for(int i=1; i<nSamples; i++ ) {
                        float2 offset = velocity * (float(i) / float(nSamples - 1));
                        outColor += ds1.sample(__nv_smp, in.acScreenNorm.st+offset);
                        outColor += ds1.sample(__nv_smp, in.acScreenNorm.st-offset);
                    }
                    float4 result = outColor/float(nSamples*2-1);
                    __nv_out = result;
                } else {

                    float actualStrength = u.strength/10.0;

                    float2 texelSize = 1.0 / __nv_getTexSize(hblur_info.size);
                    float2 velocity = float2(0.0,actualStrength);
                    float speed = length(velocity / texelSize);
                    int nSamples = int(clamp(speed, 2.01, 150.01));
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
