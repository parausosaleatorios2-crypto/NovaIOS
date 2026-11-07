// ---------------------------------------------------------------------------
// @am:string/effect_channelshift_name
// origem : assets/effects/toji-rgbsep.xml
// id     : com.alightcreative.effects.rgbsep
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rgbsepParams {
    float strength;
    float angle;
    int centerChannel;
    int mode;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_rgbsep(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rgbsepParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float rad = u.angle * 0.0174533;
            float adjStrength = u.strength / 8.0;
            float2 offset = float2(cos(rad)*adjStrength,-sin(rad)*adjStrength);
            float2 sampleLow = (float4(in.acLayerNorm - offset,0.0,1.0) * eng.acLayerToScreen).xy;
            float2 sampleHigh = (float4(in.acLayerNorm + offset,0.0,1.0) * eng.acLayerToScreen).xy;
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
            if( u.mode==0 ) {
                __nv_out = outColor * colorMid.a;
            } else if( u.mode==1 ) {
                float4 r = float4(outColor.r, 0.0, 0.0, outColor.r);
                float4 g = float4(0.0, outColor.g, 0.0, outColor.g);
                float4 b = float4(0.0, 0.0, outColor.b, outColor.b);
                float4 m = (r + g + b) / 3.;
                float4 c = float4(0.0,0.0,0.0,0.0);
                float4 l = float4(dot(luminanceWeighting * colorMid.rgb, float3(1.0)));
                //c = colorMid + (c*(1.0-colorMid.a));
                c = m + (c*(1.0-m.a));
                c = l + (c*(1.0-l.a));
                //c = (colorMid + m)/2.;
                //c = r + (c*(1.0-r.a));
                //c = g + (c*(1.0-g.a));
                //c = b + (c*(1.0-b.a));
                __nv_out = c;
            } else if( u.mode==2 ) {
                __nv_out = float4(outColor.rgb,colorMid.a);
            } else {
                __nv_out = outColor*((colorLow.a + colorMid.a + colorHigh.a)/3.);
            }
    return __nv_out;
}
