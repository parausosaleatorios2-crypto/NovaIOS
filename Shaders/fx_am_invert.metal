// ---------------------------------------------------------------------------
// Inverter (AM)
// origem : assets/effects/am-invert.xml
// id     : nova.effect.am-invert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_invertParams {
    int invertRed;
    int invertGreen;
    int invertBlue;
};

fragment float4 fx_am_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    // O AM faz alfa − (cor × alfa) na pré-multiplicada; na cor reta é 1 − cor. O alfa fica como está.
    if (u.invertRed) c.r = 1.0 - c.r;
    if (u.invertGreen) c.g = 1.0 - c.g;
    if (u.invertBlue) c.b = 1.0 - c.b;
    __nv_out = c;
    return __nv_out;
}
