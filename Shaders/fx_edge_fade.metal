// ---------------------------------------------------------------------------
// Desvanecer bordas
// origem : assets/effects/edge-fade.xml
// id     : nova.effect.edgefade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct edge_fadeParams {
    float fadeLeft;
    float fadeRight;
    float fadeTop;
    float fadeBottom;
    float curveF;
};

// --- funcoes auxiliares do efeito
/** 0 na borda, 1 depois de `width`. Largura 0 devolve 1: o lado fica intacto. */
static float sideMask(float distanceToEdge, float width) {
    if (width <= 0.0) return 1.0;
    return smoothstep(0.0, width, distanceToEdge);
}

fragment float4 fx_edge_fade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant edge_fadeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float mask =
        sideMask(in.acScreenNorm.x, u.fadeLeft) *
        sideMask(1.0 - in.acScreenNorm.x, u.fadeRight) *
        sideMask(in.acScreenNorm.y, u.fadeTop) *
        sideMask(1.0 - in.acScreenNorm.y, u.fadeBottom);

    __nv_out = float4(color.rgb, color.a * pow(mask, max(u.curveF, 0.01)));
    return __nv_out;
}
