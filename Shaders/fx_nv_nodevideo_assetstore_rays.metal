// ---------------------------------------------------------------------------
// Rays (NV)
// origem : assets/effects/nv-nodevideo-assetstore-rays.xml
// id     : nv.effect.nodevideo-assetstore-rays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_raysParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _samples;
    float _brightness;
    float _dispersion;
    float _amount;
    float _threshold;
    float _weight;
    float _blend;
    float4 _color;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat12;
int u_xlati14;
float u_xlat18;
int u_xlati18;
float u_xlat20;
bool u_xlatb20;

fragment float4 fx_nv_nodevideo_assetstore_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = (-in.acScreenNorm.xy) + u._center.xy;
    u_xlat12 = float(int(u._samples));
    u_xlat0.xy = u_xlat0.xy / float2(u_xlat12);
    u_xlati18 = int(u._samples) + int(0xFFFFFFFFu);
    u_xlat18 = float(u_xlati18);
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlat2.xy = in.acScreenNorm.xy;
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
        u_xlat20 = dot(u_xlat3.xyz, float3(0.300000012, 0.589999974, 0.109999999));
        u_xlatb20 = u._threshold<u_xlat20;
        u_xlat4.x = float(u_xlati_loop_1);
        u_xlat4.x = u_xlat4.x / u_xlat18;
        u_xlat4.z = u_xlat4.x * 3.0 + -1.5;
        u_xlat4.y = -abs(u_xlat4.z) + 1.0;
        u_xlat4.x = (-u_xlat4.z);
        u_xlat4.xyz = u_xlat4.xyz;
        u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
        u_xlat4.xyz = u_xlat3.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat3.xyz);
        u_xlat3.xyz = float3(u._dispersion) * u_xlat4.xyz + u_xlat3.xyz;
        u_xlat3 = u_xlat3 * float4(float4(u._brightness, u._brightness, u._brightness, u._brightness));
        u_xlat3 = u_xlat3 * u._color + u_xlat1;
        u_xlat1 = (bool(u_xlatb20)) ? u_xlat3 : u_xlat1;
        u_xlat2.xy = u_xlat0.xy * float2(float2(u._amount, u._amount)) + u_xlat2.xy;
    }
    u_xlat0 = u_xlat1 / float4(u_xlat12);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = u_xlat0 * float4(float4(u._weight, u._weight, u._weight, u._weight));
    u_xlat0 = u_xlat1 * float4(u._blend) + u_xlat0;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
