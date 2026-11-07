// ---------------------------------------------------------------------------
// @am:string/effect_stretch_name
// origem : assets/effects/toji-stretch.xml
// id     : com.alightcreative.effects.stretch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_stretchParams {
    float scale;
    float angle;
    int contentOnly;
};

fragment float4 fx_toji_stretch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_stretchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float rad = u.angle * 0.0174533;
            float2x2 rot = float2x2(cos(rad),-sin(rad),sin(rad),cos(rad));
            float2x2 invrot = float2x2(cos(-rad),-sin(-rad),sin(-rad),cos(-rad));
            float2 sampleCoord = ((((in.acLayerNorm - 0.5) * rot) * float2((1.0/u.scale), 1.0)) * invrot) + 0.5;
            sampleCoord = (float4(sampleCoord,0.0,1.0) * eng.acLayerToScreen).xy;
            if( u.contentOnly ) {
                float4 texColor = inputImg.sample(__nv_smp, in.acScreenNorm);
                float4 newColor = inputImg.sample(__nv_smp, sampleCoord) * texColor.a;
                __nv_out = newColor + (texColor * (1.0-newColor.a));
            } else {
                __nv_out = inputImg.sample(__nv_smp, sampleCoord);
            }
    return __nv_out;
}
