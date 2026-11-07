// ---------------------------------------------------------------------------
// Rendercommand Meshwarp (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-meshwarp.xml
// id     : nv.effect.nodevideo-rendercommand-meshwarp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_meshwarpParams {
    float _opacity;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;

fragment float4 fx_nv_nodevideo_rendercommand_meshwarp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_meshwarpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    __nv_out.w = u_xlat0.w * u._opacity;
    __nv_out.xyz = u_xlat0.xyz;
    return __nv_out;
    return __nv_out;
}
