// ---------------------------------------------------------------------------
// Chromatic Aberration (NV)
// origem : assets/effects/nv-nodevideo-assetstore-chromatic-aberration.xml
// id     : nv.effect.nodevideo-assetstore-chromatic-aberration
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_chromatic_aberrationParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _separate;
    float _direction;
    float _scanline;
    float _vignette;
    float _black_white;
};

// --- funcoes auxiliares do efeito
float2 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat8;
float2 u_xlat13;
bool2 u_xlatb13;
float2 u_xlat14;
bool2 u_xlatb14;

fragment float4 fx_nv_nodevideo_assetstore_chromatic_aberration(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_chromatic_aberrationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat6.xy = float2(u._separate, u._direction) * float2(0.0500000007, 0.0174532942);
    u_xlat1.x = sin(u_xlat6.y);
    u_xlat2.x = cos(u_xlat6.y);
    u_xlat2.x = u_xlat6.x * u_xlat2.x;
    u_xlat2.y = u_xlat6.x * u_xlat1.x;
    u_xlat6.xy = u_xlat2.xy + in.acScreenNorm.xy;
    u_xlatb1.xy = lessThan(u_xlat6.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb13.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat6.xyxy).xy;
    u_xlat14.xy = fract(u_xlat6.xy);
    u_xlat14.xy = (-u_xlat14.xy) + float2(1.0, 1.0);
    u_xlat13.x = (u_xlatb13.x) ? u_xlat14.x : u_xlat6.x;
    u_xlat13.y = (u_xlatb13.y) ? u_xlat14.y : u_xlat6.y;
    {
        float3 hlslcc_movcTemp = u_xlat6;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat6.x) : u_xlat13.x;
        hlslcc_movcTemp.y = (u_xlatb1.y) ? (-u_xlat6.y) : u_xlat13.y;
        u_xlat6 = hlslcc_movcTemp;
    }
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat6.xy);
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat6.xy = (-u_xlat2.xy) + in.acScreenNorm.xy;
    u_xlatb2.xy = lessThan(u_xlat6.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb14.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat6.xyxy).xy;
    u_xlat4.xy = fract(u_xlat6.xy);
    u_xlat4.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
    u_xlat14.x = (u_xlatb14.x) ? u_xlat4.x : u_xlat6.x;
    u_xlat14.y = (u_xlatb14.y) ? u_xlat4.y : u_xlat6.y;
    {
        float3 hlslcc_movcTemp = u_xlat6;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? (-u_xlat6.x) : u_xlat14.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? (-u_xlat6.y) : u_xlat14.y;
        u_xlat6 = hlslcc_movcTemp;
    }
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat6.xy);
    u_xlat4.x = dot(u_xlat1.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat4.y = dot(u_xlat3.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat4.z = dot(u_xlat2.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat2.x = u_xlat1.x;
    u_xlat2.y = u_xlat3.y;
    u_xlat6.xyz = (-u_xlat2.xyz) + u_xlat4.xyz;
    u_xlat6.xyz = float3(float3(u._black_white, u._black_white, u._black_white)) * u_xlat6.xyz + u_xlat2.xyz;
    u_xlat1.x = max(u_xlat1.w, u_xlat3.w);
    u_xlat1.w = max(u_xlat2.w, u_xlat1.x);
    u_xlatb2.x = int(u._scanline)==1;
    u_xlat8.x = in.acScreenNorm.y * 800.0;
    u_xlat8.x = sin(u_xlat8.x);
    u_xlat8.xyz = (-u_xlat8.xxx) * float3(0.0399999991, 0.0399999991, 0.0399999991) + u_xlat6.xyz;
    u_xlat8.xyz = u_xlat1.www * u_xlat8.xyz;
    u_xlat6.xyz = (u_xlatb2.x) ? u_xlat8.xyz : u_xlat6.xyz;
    u_xlatb2.x = int(u._vignette)==1;
    u_xlat0.x = (-u_xlat0.x) * 0.5 + 1.0;
    u_xlat8.xyz = u_xlat0.xxx * u_xlat6.xyz;
    u_xlat1.xyz = (u_xlatb2.x) ? u_xlat8.xyz : u_xlat6.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb0.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb0.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat0.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb0.y) ? u_xlat0.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
