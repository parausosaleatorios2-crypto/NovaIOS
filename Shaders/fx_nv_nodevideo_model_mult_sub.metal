// ---------------------------------------------------------------------------
// Model Mult Sub (NV)
// origem : assets/effects/nv-nodevideo-model-mult-sub.xml
// id     : nv.effect.nodevideo-model-mult-sub
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_mult_subParams {
    float4 _tex_tiling0;
    float4 _tex_offset0;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;

fragment float4 fx_nv_nodevideo_model_mult_sub(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_mult_subParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * u._tex_tiling0.xy + u._tex_offset0.xy;
    u_xlat0.xy = fract(abs(u_xlat0.xy));
    __nv_out = inputImg.sample(__nv_smp, u_xlat0.xy);
    return __nv_out;
    return __nv_out;
}
