// ---------------------------------------------------------------------------
// @am:string/effect_linearstreaks_name
// origem : assets/effects/toji-streaks-linear.xml
// id     : com.alightcreative.effects.streaks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_streaks_linearParams {
    float strength;
    float angle;
    float alpha;
    float bias;
    int rmode;
    int gmode;
    int bmode;
    int amode;
};

fragment float4 fx_toji_streaks_linear(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_streaks_linearParams&  u    [[buffer(1)]],
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
            //velocity *= eng.acPreviewSize/__nv_getTexSize(inputImg_info.size);
            velocity.x *= eng.acScreenSize.y / eng.acScreenSize.x;
            float speed = length(velocity / texelSize);
            int nSamples = int(clamp(speed, 1.01, 100.01));
            float4 originalColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float4 outColor = originalColor;
            outColor.rgb = outColor.a > 0.0 ? outColor.rgb/outColor.a : outColor.rgb;
            for(int i=1; i<nSamples; i++ ) {
                float2 offset = velocity * (float(i) / float(nSamples - 1) - (0.5+u.bias/2.0));
                float2 sampleCoord = in.acScreenNorm.st-offset;
                float insideTexture = step(0.0,sampleCoord.x) * step(sampleCoord.x,1.0) * step(0.0,sampleCoord.y) * step(sampleCoord.y,1.0);
                float4 c = inputImg.sample(__nv_smp, sampleCoord) * insideTexture;
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
