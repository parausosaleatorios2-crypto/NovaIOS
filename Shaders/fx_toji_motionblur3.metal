// ---------------------------------------------------------------------------
// @am:string/effect_mblur_name
// origem : assets/effects/toji-motionblur3.xml
// id     : com.alightcreative.effects.motionblur3
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_motionblur3Params {
    float tune;
    float samplesMin;
    float samplesMax;
    int usePos;
    int useScale;
    int useAngle;
};

fragment float4 fx_toji_motionblur3(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_motionblur3Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float angle = abs(eng.acAngularVelocity*u.tune);
            float cx = 0.5 + eng.acLayerPivot.x/eng.acLayerSize.x;
            float cy = 0.5 - eng.acLayerPivot.y/eng.acLayerSize.y;
            float2 image_size = __nv_getTexSize(inputImg_info.size);
            float2 texelSize = 1.0 / image_size;
            float2 center = (float4(cx,cy,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 v = in.acScreenNorm.st - center;
            v.y *= image_size.y / image_size.x;
            float r = length(v);
            float d = 6.283185*r;
            float l = d*angle/360.0;
            float a = angle * 0.0174533;
            float amin = a/2.0;
            float speed = l/texelSize.x;
            int nSamples = int(clamp(speed, u.samplesMin+0.01, u.samplesMax+0.01));
            float4 outColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float sampleAngle = -amin + a * float(i)/float(nSamples);
                float s = sin(sampleAngle);
                float c = cos(sampleAngle);
                float2x2 rot = float2x2(c, -s, s, c);
                float2 temp = v*rot;
                temp.y = temp.y * image_size.x / image_size.y;
                outColor += inputImg.sample(__nv_smp, center + temp);
            }
            __nv_out = outColor/float(nSamples);
    return __nv_out;
}
