// ---------------------------------------------------------------------------
// @am:string/effect_threshold_name
// origem : assets/effects/toji-threshold.xml
// id     : com.alightcreative.effects.threshold
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_thresholdParams {
    float threshold;
    float feather;
    int invert;
    int blendMode;
};

// --- funcoes auxiliares do efeito
const float3 luminanceWeighting = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_toji_threshold(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_thresholdParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float luminance = dot(texColor.rgb, luminanceWeighting);
            float f = max(min((u.feather/4.),abs(0.5-u.threshold)),0.00196);
            float t = ((u.threshold-0.5)*(1.003+f*2.))+0.5;
            float p = smoothstep(t-f, t+f, luminance);

            if( u.invert )
                p = 1.-p;

            float3 rgb;
            if( u.blendMode==1 ) {
                rgb = texColor.rgb * p;
            } else if( u.blendMode==2 ) {
                rgb = 1.-((1.-texColor.rgb)*(1.-p));
            } else {
                rgb = float3(p,p,p);
            }

            __nv_out = float4(rgb,texColor.a);
    return __nv_out;
}
