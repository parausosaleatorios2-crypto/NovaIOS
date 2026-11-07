// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-test2.xml
// id     : com.alightcreative.effects.test2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_test2Params { int __vazio; };

fragment float4 fx_toji_test2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_test2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> content [[texture(0)]],
    texture2d<float> inputImg [[texture(1)]],
    constant NovaTexInfo& content_info [[buffer(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            //float2 st = ((in.acScreenNorm*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            float2 st = ((float2(in.acScreenNorm.x,1.0-in.acScreenNorm.y)*eng.acScreenSize)-eng.acLayerCenter)/eng.acLayerSize;
            __nv_out = inputImg.sample(__nv_smp, st) * content.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
