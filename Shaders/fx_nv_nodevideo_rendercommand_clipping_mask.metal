// ---------------------------------------------------------------------------
// Rendercommand  Clipping Mask (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-clipping-mask.xml
// id     : nv.effect.nodevideo-rendercommand-clipping-mask
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_clipping_maskParams {
    float _clipping_channel;
    float _clipping_invert;
};

// --- funcoes auxiliares do efeito
float4 ImmCB_0[4];

float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
float u_xlat2;
bool u_xlatb4;

fragment float4 fx_nv_nodevideo_rendercommand_clipping_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_clipping_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> clip_mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

ImmCB_0[0] = float4(1.0,0.0,0.0,0.0);
ImmCB_0[1] = float4(0.0,1.0,0.0,0.0);
ImmCB_0[2] = float4(0.0,0.0,1.0,0.0);
ImmCB_0[3] = float4(0.0,0.0,0.0,1.0);
    u_xlat0 = clip_mask.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlati1 = int(u._clipping_channel);
    u_xlat0.x = dot(u_xlat0, ImmCB_0[u_xlati1]);
    u_xlat2 = (-u_xlat0.x) + 1.0;
    u_xlatb4 = int(u._clipping_invert)==1;
    u_xlat0.x = (u_xlatb4) ? u_xlat2 : u_xlat0.x;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    __nv_out = u_xlat0.xxxx * u_xlat1;
    return __nv_out;
    return __nv_out;
}
