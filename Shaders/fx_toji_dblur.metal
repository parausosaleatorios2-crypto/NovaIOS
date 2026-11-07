// ---------------------------------------------------------------------------
// @am:string/effect_dblur_name
// origem : assets/effects/toji-dblur.xml
// id     : com.alightcreative.effects.dblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_dblurParams {
    float strength;
    float angle;
};

fragment float4 fx_toji_dblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_dblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float rad = u.angle * 0.0174533;
            float2 velocity = float2(cos(rad)*u.strength,-sin(rad)*u.strength);
            //velocity *= eng.acPreviewSize * texelSize;
            velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 100.01));
            float4 outColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = velocity * (float(i) / float(nSamples - 1) - 0.5);
                float2 sampleCoord = in.acScreenNorm.st-offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                outColor += inputImg.sample(__nv_smp, sampleCoord) * insideTexture;
            }
            __nv_out = outColor/float(nSamples);
    return __nv_out;
}
