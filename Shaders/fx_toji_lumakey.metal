// ---------------------------------------------------------------------------
// @am:string/effect_lumakey_name
// origem : assets/effects/toji-lumakey.xml
// id     : com.alightcreative.effects.lumakey
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lumakeyParams {
    float threshold;
    float feather;
    int invert;
};

fragment float4 fx_toji_lumakey(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lumakeyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float alpha = smoothstep( u.threshold-u.feather/2., u.threshold+u.feather/2., length(texColor.rgb) );
            if(u.invert) alpha = 1.-alpha;
            __nv_out = float4(texColor.rgb*alpha,alpha);
    return __nv_out;
}
