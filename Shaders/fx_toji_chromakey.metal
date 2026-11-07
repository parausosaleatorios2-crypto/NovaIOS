// ---------------------------------------------------------------------------
// @am:string/effect_chromakey_name
// origem : assets/effects/toji-chromakey.xml
// id     : com.alightcreative.effects.chromakey
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_chromakeyParams {
    float4 keyColor;
    float threshold;
    float feather;
    int defringe;
    int invert;
};

fragment float4 fx_toji_chromakey(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_chromakeyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
