// ---------------------------------------------------------------------------
// Cor sólida
// origem : assets/effects/am-solid-color.xml
// id     : nova.effect.am-solid-color
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_solid_colorParams {
    float4 color;
    float alpha;
    int blendMode;
};

fragment float4 fx_am_solid_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_solid_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);   // alfa reto
    if (c.a <= 0.0) {
        __nv_out = c;
        return __nv_out;
    }
    float3 pintada;
    if (u.blendMode == 1) {
        pintada = c.rgb * u.color.rgb;
    } else if (u.blendMode == 2) {
        pintada = 1.0 - (1.0 - c.rgb) * (1.0 - u.color.rgb);
    } else {
        pintada = u.color.rgb;
    }
    // O AM: mix(camada, pintada, Alfa) na pré-multiplicada, as duas com o alfa da camada = a mesma mistura na reta.
    __nv_out = float4(mix(c.rgb, pintada, u.alpha), c.a);
    return __nv_out;
}
