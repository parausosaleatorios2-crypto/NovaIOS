// ---------------------------------------------------------------------------
// Rendercommand  Blend Mode Masking (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-blend-mode-masking.xml
// id     : nv.effect.nodevideo-rendercommand-blend-mode-masking
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_blend_mode_maskingParams {
    float _blend_mode;
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool2 u_xlatb3;
float4 u_xlat4;
float3 u_xlat5;
float3 u_xlat6;

fragment float4 fx_nv_nodevideo_rendercommand_blend_mode_masking(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_blend_mode_maskingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> g_OverlayTex [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = g_OverlayTex.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2 = u_xlat0 * u_xlat1;
    u_xlatb3.xy = equal(int4(int(u._blend_mode)), int4(1, 2, 0, 0)).xy;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat5.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat6.xyz = (-u_xlat0.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat5.xyz = (-u_xlat5.xyz) * u_xlat6.xyz + float3(1.0, 1.0, 1.0);
    u_xlat4.xyz = (u_xlatb3.y) ? u_xlat4.xyz : u_xlat5.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat3 = (u_xlatb3.x) ? u_xlat2 : u_xlat4;
    u_xlat2.xyz = u_xlat1.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat3 : u_xlat2;
    if(int(u._use_inner_mask) == 0) {
        __nv_out = u_xlat1;
        return __nv_out;
    }
    u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
    u_xlat1 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
    u_xlat3 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat4 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat0 = u_xlat0 * u_xlat4;
    u_xlat0 = u_xlat1 * u_xlat3 + u_xlat0;
    u_xlat1.x = u_xlat3.x * u_xlat0.w;
    __nv_out.w = (u_xlatb2.y) ? u_xlat1.x : u_xlat0.w;
    __nv_out.xyz = u_xlat0.xyz;
    return __nv_out;
    return __nv_out;
}
