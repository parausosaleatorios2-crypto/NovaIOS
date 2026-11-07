// ---------------------------------------------------------------------------
// Model Blitmesh (NV)
// origem : assets/effects/nv-nodevideo-model-blitmesh.xml
// id     : nv.effect.nodevideo-model-blitmesh
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_blitmeshParams {
    float4 _color;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;

fragment float4 fx_nv_nodevideo_model_blitmesh(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_blitmeshParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * _viewport_ratio.xy + float2(0.5, 0.5);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    __nv_out = u_xlat0 * u._color;
    return __nv_out;
    return __nv_out;
}
