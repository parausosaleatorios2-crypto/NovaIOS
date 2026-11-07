// ---------------------------------------------------------------------------
// @am:string/effect_zoomstreaks_name
// origem : assets/effects/toji-streaks-zoom.xml
// id     : com.alightcreative.effects.streaks-zoom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_streaks_zoomParams {
    float2 centerPoint;
    float strength;
    float alpha;
    float bias;
    int adaptive;
    int rmode;
    int gmode;
    int bmode;
    int amode;
};

fragment float4 fx_toji_streaks_zoom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_streaks_zoomParams&  u    [[buffer(1)]],
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
            float4 originalColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float4 outColor = originalColor;
            float2 vnorm = normalize(v)*texelSize*speed;
            float2 offsetScale = float2(1., 1.);
            if( eng.acScreenSize.y > eng.acScreenSize.x ) {
                offsetScale.x *= eng.acScreenSize.x / eng.acScreenSize.y;
            } else {
                offsetScale.y *= eng.acScreenSize.y / eng.acScreenSize.x;
            }

            outColor.rgb = outColor.a > 0.0 ? outColor.rgb/outColor.a : outColor.rgb;
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = vnorm * (float(i) / float(nSamples - 1) - (0.5+u.bias/2.0));
                offset *= offsetScale;

                float4 c = inputImg.sample(__nv_smp, in.acScreenNorm.st-offset);
                
                float r;
                float g;
                float b;
                float a;
                if( u.rmode == 0 ) {
                    r = min(outColor.r,c.r);
                } else if( u.rmode == 1 ) {
                    r = max(outColor.r,c.r);
                } else if( u.rmode == 3 ) {
                    r = outColor.r + c.r;
                } else {
                    r = outColor.r;
                }
                if( u.gmode == 0 ) {
                    g = min(outColor.g,c.g);
                } else if( u.gmode == 1 ) {
                    g = max(outColor.g,c.g);
                } else if( u.gmode == 3 ) {
                    g = outColor.g + c.g;
                } else {
                    g = outColor.g;
                }
                if( u.bmode == 0 ) {
                    b = min(outColor.b,c.b);
                } else if( u.bmode == 1 ) {
                    b = max(outColor.b,c.b);
                } else if( u.bmode == 3 ) {
                    b = outColor.b + c.b;
                } else {
                    b = outColor.b;
                }
                if( u.amode == 0 ) {
                    a = min(outColor.a,c.a);
                } else if( u.amode == 1 ) {
                    a = max(outColor.a,c.a);
                } else if( u.amode == 3 ) {
                    a = outColor.a + c.a;
                } else {
                    a = outColor.a;
                }
                outColor = float4(r,g,b,a);
            }
            outColor = outColor / float4(
                u.rmode == 3 ? float(nSamples) : 1.0,
                u.gmode == 3 ? float(nSamples) : 1.0,
                u.bmode == 3 ? float(nSamples) : 1.0,
                u.amode == 3 ? float(nSamples) : 1.0
            );
            outColor.rgb *= outColor.a;
            __nv_out = mix(originalColor,outColor,u.alpha);
    return __nv_out;
}
