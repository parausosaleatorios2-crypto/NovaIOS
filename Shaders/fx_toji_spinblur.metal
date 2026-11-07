// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-spinblur.xml
// id     : com.alightcreative.effects.spinblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_spinblurParams {
    float angle;
    float cx;
    float cy;
};

fragment float4 fx_toji_spinblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_spinblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float2 center = (float4(u.cx,u.cy,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 v = in.acScreenNorm.st - center;
            float r = length(v);
            float d = 6.283185*r;
            float l = d*u.angle/360.0;
            float a = u.angle * 0.0174533;
            float amin = a/2.0;
            float speed = l/texelSize.x;
            int nSamples = int(clamp(speed, 1.01, 100.01));
            float4 outColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float sampleAngle = -amin + a * float(i)/float(nSamples);
                float s = sin(sampleAngle);
                float c = cos(sampleAngle);
                float2x2 rot = float2x2(c, -s, s, c);
                outColor += inputImg.sample(__nv_smp, center + v*rot);
            }
            __nv_out = outColor/float(nSamples);
    return __nv_out;
}
