// ---------------------------------------------------------------------------
// toji-skexnxxrgbmoblurs.xml
// origem : assets/effects/toji-skexnxxrgbmoblurs.xml
// id     : 636f6d2e616c6967687463726561746976652e656666656374732e7267626d6f626c7572
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_skexnxxrgbmoblursParams {
    float strength;
    int centerChannel;
};

// --- funcoes auxiliares do efeito
static float4 newLayer( float4 a, float4 b) { return a * (1. - b.a) + b;  }
    static float2x2 rot2m(float a){ float s = sin(a); float c = cos(a); return float2x2(c, -s, s, c); }
    static float2 l2s( float2 v ) { return (float4(v,0.,1.)*eng.acLayerToScreen).xy; }
    #define fragCoord __nv_fragCoord.xy
    
    //////////////////////////
        const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);
    //////////////////////////

fragment float4 fx_toji_skexnxxrgbmoblurs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_skexnxxrgbmoblursParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> xcipher [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& xcipher_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        if( eng.acPass == 0 ) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.st); } else if( eng.acPass==1 ) {
            float adjStrength = u.strength / 8.0;
            
            float2 offset;
            // offset = float2(cos(rad)*adjStrength,-sin(rad)*adjStrength);
            // if(USEPOS) { 
            offset = float2(eng.acVelocity.x*adjStrength,-eng.acVelocity.y*adjStrength);
             // }
            
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
            // if(USESCALE) {
            // sampleLow *= acScaleVelocity;
            // sampleHigh *= acScaleVelocity; }
            
            float4 colorLow = inputImg.sample(__nv_smp, sampleLow);
            float4 colorHigh = inputImg.sample(__nv_smp, sampleHigh);
            float4 colorMid = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 outColor;
            if( u.centerChannel==0 ) {
                outColor = float4(colorMid.r,colorLow.g,colorHigh.b,1.0);
            } else if( u.centerChannel==1 ) {
                outColor = float4(colorLow.r,colorMid.g,colorHigh.b,1.0);
            } else {
                outColor = float4(colorLow.r,colorHigh.g,colorMid.b,1.0);
            }            
                __nv_out = float4(outColor.rgb,colorMid.a);
          }
    return __nv_out;
}
