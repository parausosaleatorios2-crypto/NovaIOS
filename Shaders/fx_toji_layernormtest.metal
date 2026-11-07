// ---------------------------------------------------------------------------
// @string/name
// origem : assets/effects/toji-layernormtest.xml
// id     : com.alightcreative.effects.layernormtest
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_layernormtestParams {
    float f1;
    float f2;
};

fragment float4 fx_toji_layernormtest(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_layernormtestParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);


            float4 texColor = inputImg.sample(__nv_smp, (float4(__nv_mod(in.acLayerNorm, float2(1.0,1.0)),0.0,1.0)*eng.acLayerToScreen).xy);
            float p = step(0.0,in.acLayerNorm.x) * step(in.acLayerNorm.x,1.0) * step(0.0,in.acLayerNorm.y) * step(in.acLayerNorm.y,1.0);
            //float4 overlay = float4(1.0,0.5,0.0,1.0) * p;
            float4 overlay = float4(in.acLayerNorm,p,1.0) * 0.5;
            __nv_out = overlay + texColor*(1.0-overlay.a);
    return __nv_out;
}
