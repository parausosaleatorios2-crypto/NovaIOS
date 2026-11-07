// ---------------------------------------------------------------------------
// @am:string/effect_rays_name
// origem : assets/effects/toji-rays.xml
// id     : com.alightcreative.effects.rays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_raysParams {
    float2 centerPoint;
    float strength;
    float intensity;
    float threshold;
    float4 thresholdColor;
    float4 fillColor;
    float blend;
    float quality;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_raysParams&  u    [[buffer(1)]],
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
            speed *= length( in.acLayerNorm.st - center );
            //int nSamples = int(clamp(speed, 1.01, 200.01));
            int nSamples = int(u.quality);
            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float2 vnorm = normalize(v)*texelSize*speed;
            float2 offsetScale = float2(1., 1.);
            if( eng.acScreenSize.y > eng.acScreenSize.x ) {
                offsetScale.x *= eng.acScreenSize.x / eng.acScreenSize.y;
            } else {
                offsetScale.y *= eng.acScreenSize.y / eng.acScreenSize.x;
            }

            float actualSamples = 1.0;
            float4 outColor = float4(0.);
            for(int i=1; i<nSamples; i++ ) {
                float p = float(i) / float(nSamples - 1);
                float2 offs = vnorm * p;
                offs *= offsetScale;

                float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm.st-offs);

                float luminance = dot(texColor.rgb - u.thresholdColor.rgb, luminanceWeighting);

                outColor += luminance > u.threshold ? mix(texColor,u.fillColor,u.blend)*(1.-p) : float4(0.0);
                actualSamples += luminance > u.threshold ? 1.0 : 0.0;
            }
            __nv_out = baseColor + outColor * u.intensity / float(nSamples);
    return __nv_out;
}
