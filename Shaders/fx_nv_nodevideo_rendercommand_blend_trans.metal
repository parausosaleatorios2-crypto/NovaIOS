// ---------------------------------------------------------------------------
// Rendercommand  Blend Trans (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-blend-trans.xml
// id     : nv.effect.nodevideo-rendercommand-blend-trans
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_blend_transParams {
    float _blend_alpha;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float2 u_xlat0;
bool u_xlatb0;
bool2 u_xlatb1;
float3 u_xlat2;
float2 u_xlat3;
bool2 u_xlatb6;

fragment float4 fx_nv_nodevideo_rendercommand_blend_trans(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_blend_transParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * _viewport_ratio.xy;
    u_xlat3.xy = u_xlat0.yy * hlslcc_mtx4x4_trans_mat[1].xy;
    u_xlat0.xy = hlslcc_mtx4x4_trans_mat[0].xy * u_xlat0.xx + u_xlat3.xy;
    u_xlat0.xy = u_xlat0.xy + hlslcc_mtx4x4_trans_mat[3].xy;
    u_xlat0.xy = u_xlat0.xy / _viewport_ratio.xy;
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlatb6.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlatb0 = u_xlatb6.x || u_xlatb1.x;
    u_xlatb0 = u_xlatb6.y || u_xlatb0;
    u_xlatb0 = u_xlatb1.y || u_xlatb0;
    u_xlat0.x = (u_xlatb0) ? 0.0 : 1.0;
    __nv_out.xyz = u_xlat0.xxx * u_xlat2.xyz;
    __nv_out.w = u_xlat0.x * u._blend_alpha;
    return __nv_out;
    return __nv_out;
}
