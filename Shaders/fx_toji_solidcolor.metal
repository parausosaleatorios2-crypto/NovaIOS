// ---------------------------------------------------------------------------
// @am:string/effect_solidcolor_name
// origem : assets/effects/toji-solidcolor.xml
// id     : com.alightcreative.solidcolor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_solidcolorParams {
    float4 color;
    float alpha;
    int blendMode;
};

fragment float4 fx_toji_solidcolor(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_solidcolorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
            float4 result;
            if( u.blendMode==1 ) {
                result = float4((texColor.rgb/texColor.a)*u.color.rgb,1.0) * texColor.a;
            } else if( u.blendMode==2 ) {
                result = float4( 1.-((1.-(texColor.rgb/texColor.a))*(1.-u.color.rgb)),1.0) * texColor.a;
            } else {
                result = float4(u.color.rgb,1.0)*texColor.a;
            }
            __nv_out = mix(texColor,result,u.alpha);
    return __nv_out;
}
