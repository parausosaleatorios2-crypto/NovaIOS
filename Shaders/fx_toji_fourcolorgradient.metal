// ---------------------------------------------------------------------------
// @am:string/effect_fourcolorgradient_name
// origem : assets/effects/toji-fourcolorgradient.xml
// id     : com.alightcreative.fourcolorgradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_fourcolorgradientParams {
    float4 color1;
    float2 offset1;
    float4 color2;
    float2 offset2;
    float4 color3;
    float2 offset3;
    float4 color4;
    float2 offset4;
    float blend;
    float alpha;
    int blendMode;
};

// --- funcoes auxiliares do efeito
float gradientNoise(in float2 uv)
        {
            const float3 magic = float3(0.06711056, 0.00583715, 52.9829189);
            return fract(magic.z * fract(dot(uv, magic.xy)));
        }

fragment float4 fx_toji_fourcolorgradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_fourcolorgradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float2 st = in.acLayerNorm;

            float2 pos = (u.offset1*float2(1,-1)) / 500.;
            float t1 = length(st - pos);

            pos = (u.offset2*float2(1,-1)) / 500.;
            float t2 = length(st - pos);

            pos = (u.offset3*float2(1,-1)) / 500.;
            float t3 = length(st - pos);

            pos = (u.offset4*float2(1,-1)) / 500.;
            float t4 = length(st - pos);

            float4 color = float4(0.0, 0.0, 0.0, 0.0);
            float sw_t1 = smoothstep(0.0, 1.0, clamp((1.0 - t1), 0.0, 1.0));
            float sw_t2 = smoothstep(0.0, 1.0, clamp((1.0 - t2), 0.0, 1.0));
            float sw_t3 = smoothstep(0.0, 1.0, clamp((1.0 - t3), 0.0, 1.0));
            float sw_t4 = smoothstep(0.0, 1.0, clamp((1.0 - t4), 0.0, 1.0));
            color += u.color1 * pow(sw_t1, 1.0/u.blend);
            color += u.color2 * pow(sw_t2, 1.0/u.blend);
            color += u.color3 * pow(sw_t3, 1.0/u.blend);
            color += u.color4 * pow(sw_t4, 1.0/u.blend);
            color /= (sw_t1 + sw_t2 + sw_t3 + sw_t4);

            color.a = 1.0;
            color += (1.0/255.0) * gradientNoise(st) - (0.5/255.0);
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-color.rgb)),1.0) * texColor.a;
            } else {
                result = float4(color.rgb,1.0)*texColor.a;
            }
            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
