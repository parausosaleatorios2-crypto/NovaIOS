// ---------------------------------------------------------------------------
// Effect Stylize Vignette (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-vignette.xml
// id     : nv.effect.nodevideo-effect-stylize-vignette
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_vignetteParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _keep_aspect;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float3 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat12;
float u_xlat18;

fragment float4 fx_nv_nodevideo_effect_stylize_vignette(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_vignetteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = (int(u._keep_aspect) != 0) ? u_xlat0.xy : u_xlat12.xy;
    u_xlat0.xy = u_xlat0.xy + u_xlat0.xy;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat0.x = (-u._amount) * u_xlat0.x + 1.0;
    u_xlat0.xyz = u_xlat0.xxx * u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3.xyz = (u_xlatb2.x) ? float3(1.0, 0.0, 1.0) : u_xlat0.xyz;
        u_xlat3.w = 1.0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat18 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat18 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = 1.0;
    }
    return __nv_out;
    return __nv_out;
}
