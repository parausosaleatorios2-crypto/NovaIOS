// ---------------------------------------------------------------------------
// @am:string/effect_maskblur_name
// origem : assets/effects/toji-maskblur.xml
// id     : com.alightcreative.effects.maskblur
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_maskblurParams {
    float strength;
    int channel;
};

fragment float4 fx_toji_maskblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_maskblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 maskColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float mask;
            if( u.channel==0 ) {
                mask = maskColor.r*0.2126 + maskColor.g*0.7152 + maskColor.b*0.0722;
            } else if( u.channel == 1 ) {
                mask = maskColor.r;
            } else if( u.channel == 2 ) {
                mask = maskColor.g;
            } else if( u.channel == 3 ) {
                mask = maskColor.b;
            } else {
                mask = maskColor.a;
            }

            if( eng.acPass==0 ) {

                float angle = 0.0;
                float actualStrength = (u.strength/4.0) * mask;

                float2 texelSize = 1.0 / float2(comp_info.size);
                float rad = angle * 0.0174533;
                float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                float speed = length(velocity / texelSize);
                int nSamples = int(clamp(speed, 1.01, 100.01));
                float4 outColor = comp.sample(__nv_smp, in.acScreenNorm.st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += comp.sample(__nv_smp, in.acScreenNorm.st-offset);
                }
                __nv_out = outColor/float(nSamples);

            } else {

                float angle = 90.0;
                float actualStrength = (u.strength/4.0) * mask;

                float2 texelSize = 1.0 / float2(comp_info.size);
                float rad = angle * 0.0174533;
                float2 velocity = float2(cos(rad)*actualStrength,-sin(rad)*actualStrength);
                float speed = length(velocity / texelSize);
                int nSamples = int(clamp(speed, 1.01, 100.01));
                float4 outColor = hblur.sample(__nv_smp, in.acScreenNorm.st);
                for(int i=1; i<nSamples; i++ ) {
                    float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                    outColor += hblur.sample(__nv_smp, in.acScreenNorm.st-offset);
                }
                __nv_out = outColor/float(nSamples) * maskColor.a;

            }
    return __nv_out;
}
