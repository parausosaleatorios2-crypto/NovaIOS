// ---------------------------------------------------------------------------
// @am:string/effect_edge_glow_name
// origem : assets/effects/toji-edgeglow.xml
// id     : com.alightcreative.effects.edgeglow
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_edgeglowParams {
    float smoothing;
    float threshold;
    int invert;
    float strength;
    float spread;
    float4 fillColor;
    float blend;
    float gamma;
    float brightness;
    float4 tintColor;
    float tint;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_edgeglow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_edgeglowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> edge [[texture(1)]],
    texture2d<float> hblur [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& edge_info [[buffer(3)]],
    constant NovaTexInfo& hblur_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float3x3 rgb2yuv = float3x3(
                 0.299,     0.587,    0.114,
                -0.14713,  -0.28886,  0.436,
                 0.615,    -0.51499, -0.10001
            );
            float3x3 yuv2rgb = float3x3(
                1.0,  0.0,      1.13983,
                1.0, -0.39465, -0.58060,
                1.0,  2.03211,  0.0
            );

            float4 glow = hblur.sample(__nv_smp, in.acScreenNorm.st);
            float4 base = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            glow.rgb /= glow.a;
            base.rgb /= base.a;
            glow.rgb = pow(glow.rgb, float3(max(0.0001,3.-u.spread)));
            base.rgb = pow(base.rgb,float3(1.0/u.gamma));
            base.rgb = ((base.rgb * rgb2yuv) + float3(u.brightness,0.,0.)) * yuv2rgb;
            base.rgb = saturate(base.rgb);
            float lum = dot(luminanceWeighting, glow.rgb);
            float fill = 1.0;
            glow.rgb *= glow.a;
            base.rgb *= base.a;
            __nv_out = (mix(base,base*u.tintColor,u.tint)*fill) + mix(glow * mix(lum,1.,fill), u.fillColor*lum, max(saturate(u.blend)*(1.-lum),u.blend-1.0) );
    return __nv_out;
}
