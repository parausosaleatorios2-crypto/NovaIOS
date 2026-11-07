// ---------------------------------------------------------------------------
// @am:string/effect_innerblur_name
// origem : assets/effects/toji-innerblur.xml
// id     : com.alightcreative.effects.innerblur
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_innerblurParams {
    float strength;
    float iter;
};

fragment float4 fx_toji_innerblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_innerblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& hblur_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            float4 baseColor = inputImg.sample(__nv_smp, in.acScreenNorm.st);
            float4 compColor =  hblur.sample(__nv_smp, in.acScreenNorm.st);
            __nv_out = float4(compColor.rgb / compColor.a,1.) * baseColor.a;
    return __nv_out;
}
