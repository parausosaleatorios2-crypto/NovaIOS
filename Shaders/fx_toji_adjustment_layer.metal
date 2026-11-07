// ---------------------------------------------------------------------------
// Adjustment Layer
// origem : assets/effects/toji-adjustment_layer.xml
// id     : com.alightcreative.effects.adjustment_layer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_adjustment_layerParams { int __vazio; };

fragment float4 fx_toji_adjustment_layer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_adjustment_layerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> comp [[texture(1)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& comp_info [[buffer(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

            // Use local UV coordinates (in.acLayerNorm) which are built-in.
            // This maps the full screen background to the 0-1 range of this layer.
            // When the layer is transformed (moved/scaled/shaken), the coordinates move with it.
            float4 bg = comp.sample(__nv_smp, in.acLayerNorm);
            __nv_out = bg;
    return __nv_out;
}
