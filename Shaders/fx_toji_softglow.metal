// ---------------------------------------------------------------------------
// @am:string/effect_soft_glow_name
// origem : assets/effects/toji-softglow.xml
// id     : com.alightcreative.effects.softglow
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_softglowParams {
    float strength;
    float brightness;
    float contrast;
    float highlights;
    float4 color;
    float blend;
    float alpha;
    float outsideAlpha;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

        float4 composite( float4 a, float4 b) {
            return a * (1. - b.a) + b;
        }

fragment float4 fx_toji_softglow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_softglowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurBuf [[texture(1)]],
    texture2d<float> comp [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& blurBuf_info [[buffer(3)]],
    constant NovaTexInfo& comp_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

        
            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 blurTexColor = blurBuf.sample(__nv_smp, in.acScreenNorm);
            float4 adjBlur = blurTexColor;
            adjBlur.rgb = min(adjBlur.rgb * u.brightness, float3(1.0,1.0,1.0));
            float luminance = min(1.0,dot(adjBlur.rgb, luminanceWeighting) * u.brightness);
            float4 blendColor = mix(adjBlur,luminance*u.color,u.blend);
            blendColor.rgb = mix(blendColor.rgb,float3(luminance,luminance,luminance),luminance*u.highlights);
            blendColor.rgb = blendColor.rgb * mix(float3(1.0),blendColor.rgb,u.contrast);
            float4 blendInside = blendColor * u.alpha;
            float4 result = saturate(float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-blendInside.rgb)),1.0) * texColor.a);
            if( u.outsideAlpha > 0. ) {
                float4 compColor = comp.sample(__nv_smp, in.acScreenNorm);
                float lum = dot(blurTexColor.rgb, luminanceWeighting);
                float4 blendOutside = mix(blurTexColor,u.color*lum,u.blend);
                float4 oc = float4( 1.-((1.-(compColor.rgb/max(0.000001,compColor.a)))*(1.-(blendOutside.rgb/max(0.000001,blendOutside.a)))),1.0) * compColor.a;
                result = composite(mix(result, oc, u.outsideAlpha * (blurTexColor.a*2.)),result);
            }
            __nv_out = result;
    return __nv_out;
}
