// ---------------------------------------------------------------------------
// @am:string/effect_texttransform_name
// origem : assets/effects/toji-text-transform.xml
// id     : com.alightcreative.effects.texttransform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_text_transformParams {
    float start;
    float end;
    float phase;
    int component;
    int anchor;
    float2 offset;
    float angle;
    float scale;
    float stretch;
    float alpha;
    int useFillColor;
    float4 fillColor;
    float easeIn;
    float easeOut;
    float overlap;
    int shape;
    int randomOrder;
    float seed;
};

fragment float4 fx_toji_text_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_text_transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
