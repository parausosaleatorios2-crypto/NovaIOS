// ---------------------------------------------------------------------------
// @am:string/effect_advanced_chroma_key_name
// origem : assets/effects/toji-chromakey-advanced.xml
// id     : com.alightcreative.effects.chromakey-adv
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_chromakey_advancedParams {
    int c1active;
    int c1mode;
    float4 c1color;
    float c1threshold;
    float c1feather;
    float c1luma;
    int c2active;
    int c2mode;
    float4 c2color;
    float c2threshold;
    float c2feather;
    float c2luma;
    int c3active;
    int c3mode;
    float4 c3color;
    float c3threshold;
    float c3feather;
    float c3luma;
    int c4active;
    int c4mode;
    float4 c4color;
    float c4threshold;
    float c4feather;
    float c4luma;
    int showMask;
};

fragment float4 fx_toji_chromakey_advanced(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_chromakey_advancedParams&  u    [[buffer(1)]],
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
