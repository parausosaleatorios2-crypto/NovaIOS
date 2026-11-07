// ---------------------------------------------------------------------------
// Fill Assetstore Heart Spread (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-heart-spread.xml
// id     : nv.effect.nodevideo-fill-assetstore-heart-spread
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_heart_spreadParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _evolution;
    float _blend_mode;
    float4 _color1;
    float4 _color2;
    float4 _color3;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool2 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float u_xlat18;

fragment float4 fx_nv_nodevideo_fill_assetstore_heart_spread(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_heart_spreadParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = _resolution.xy * float2(0.5, 0.5);
    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy + (-u_xlat0.xy);
    u_xlat0.xy = u_xlat0.xy / _resolution.yy;
    u_xlat0.xy = u_xlat0.xy * float2(0.400000006, 0.480000019);
    u_xlat18 = abs(u_xlat0.x) * abs(u_xlat0.x);
    u_xlat6.x = u_xlat18 * 1.10000002 + u_xlat0.y;
    u_xlat0.z = -abs(u_xlat0.x) * 0.660000026 + u_xlat6.x;
    u_xlat0.x = dot(u_xlat0.xz, u_xlat0.xz);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 5.0 + (-u._evolution);
    u_xlat0.x = fract(u_xlat0.x);
    u_xlat6.xyz = u._color1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat6.xyz = u._color1.xyz * u_xlat6.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat6.xyz = u_xlat6.xyz * u._color1.xyz;
    u_xlat1.xyz = u._color2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._color2.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u._color2.xyz;
    u_xlat2.xyz = u._color3.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = u._color3.xyz * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat2.xyz * u._color3.xyz;
    u_xlatb3.xy = lessThan(float4(0.330000013, 0.670000017, 0.0, 0.0), u_xlat0.xxxx).xy;
    u_xlat0.xyz = (u_xlatb3.y) ? u_xlat6.xyz : u_xlat1.xyz;
    u_xlat18 = (u_xlatb3.y) ? u._color1.w : u._color2.w;
    u_xlat1.xyz = (u_xlatb3.x) ? u_xlat0.xyz : u_xlat2.xyz;
    u_xlat1.w = (u_xlatb3.x) ? u_xlat18 : u._color3.w;
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat1.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
