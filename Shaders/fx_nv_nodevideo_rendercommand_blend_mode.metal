// ---------------------------------------------------------------------------
// Rendercommand  Blend Mode (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-blend-mode.xml
// id     : nv.effect.nodevideo-rendercommand-blend-mode
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_blend_modeParams {
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float3 u_xlat5;
float3 u_xlat8;

fragment float4 fx_nv_nodevideo_rendercommand_blend_mode(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_blend_modeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> g_OverlayTex [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.xy = equal(int4(int(u._blend_mode)), int4(1, 2, 0, 0)).xy;
    u_xlat1 = g_OverlayTex.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2 = (-u_xlat1.wxyz) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat4.xyz = (-u_xlat3.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat8.xyz = (-u_xlat2.yzw) * u_xlat4.xyz + float3(1.0, 1.0, 1.0);
    u_xlat4 = u_xlat2.xxxx * u_xlat3;
    u_xlat4 = u_xlat1 * u_xlat1.wwww + u_xlat4;
    u_xlat5.xyz = u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1 = u_xlat1 * u_xlat3;
    u_xlat3.xyz = (u_xlatb0.y) ? u_xlat5.xyz : u_xlat8.xyz;
    u_xlat0 = (u_xlatb0.x) ? u_xlat1 : u_xlat3;
    __nv_out = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat4;
    return __nv_out;
    return __nv_out;
}
