// ---------------------------------------------------------------------------
// @am:string/effect_zoomblur_name
// origem : assets/effects/toji-zoomblur2.xml
// id     : com.alightcreative.effects.zoomblur2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_zoomblur2Params {
    float2 centerPoint;
    float strength;
    int adaptive;
};

fragment float4 fx_toji_zoomblur2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_zoomblur2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
            float2 center = float2(0.5 + u.centerPoint.x/500., 0.5 - u.centerPoint.y/500.);
            float2 v = in.acScreenNorm.st - (float4(center,0.0,1.0) * eng.acLayerToScreen).xy;
            float speed = length(u.strength / 2.0 / texelSize);
            if(u.adaptive)
                speed *= length( in.acLayerNorm.st - center );
            else
                speed *= smoothstep( 0.0, length(texelSize)*5.0, length( in.acLayerNorm.st - center ));
            int nSamples = int(clamp(speed, 1.01, 100.01));
            float4 outColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float2 vnorm = normalize(v)*texelSize*speed;
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = vnorm * (float(i) / float(nSamples - 1) - 0.5);
                outColor += inputImg.sample(__nv_smp, in.acScreenNorm.st-offset);
            }
            __nv_out = outColor/float(nSamples);
    return __nv_out;
}
