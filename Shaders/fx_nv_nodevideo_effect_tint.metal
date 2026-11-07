// ---------------------------------------------------------------------------
// Effect Tint (NV)
// origem : assets/effects/nv-nodevideo-effect-tint.xml
// id     : nv.effect.nodevideo-effect-tint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_tintParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _map_black_to;
    float4 _map_white_to;
    float _amount_to_tint;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
float u_xlat19;

fragment float4 fx_nv_nodevideo_effect_tint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_tintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = dot(u_xlat0.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat7.xyz = (-u._map_black_to.xyz) + u._map_white_to.xyz;
    u_xlat1.xyz = u_xlat1.xxx * u_xlat7.xyz + u._map_black_to.xyz;
    u_xlat19 = (-u._amount_to_tint) + 1.0;
    u_xlat2.xyz = u_xlat0.xyz * float3(u_xlat19);
    u_xlat1.xyz = u_xlat1.xyz * float3(u._amount_to_tint) + u_xlat2.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1.w = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat1.xyz;
        __nv_out.w = u_xlat0.w;
    }
    return __nv_out;
    return __nv_out;
}
