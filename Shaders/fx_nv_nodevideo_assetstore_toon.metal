// ---------------------------------------------------------------------------
// Toon (NV)
// origem : assets/effects/nv-nodevideo-assetstore-toon.xml
// id     : nv.effect.nodevideo-assetstore-toon
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_toonParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _threshold;
    float _intensity;
    float _outline;
    float _brightness;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat8;
float u_xlat9;
float2 u_xlat14;
float2 u_xlat15;
float u_xlat19;
bool u_xlatb19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_assetstore_toon(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_toonParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = dot(u_xlat0, u_xlat0);
    u_xlat1.x = rsqrt(u_xlat1.x);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xxx;
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._brightness, u._brightness, u._brightness));
    u_xlat1.xyz = log2(abs(u_xlat1.xyz));
    u_xlat1.xyz = u_xlat1.xyz * float3(0.649999976, 0.649999976, 0.649999976);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(5.0, 5.0, 5.0);
    u_xlat1.xyz = floor(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.200000003, 0.200000003, 0.200000003);
    u_xlat1.xyz = log2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(float3(u._intensity, u._intensity, u._intensity));
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat2.xyw = (-float3(float3(u._outline, u._outline, u._outline))) * float3(0.001953125, 0.001953125, 0.001953125) + in.acScreenNorm.xyy;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat19 = dot(u_xlat3, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat2.z = u._outline * 0.001953125 + in.acScreenNorm.x;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat2.x = dot(u_xlat2, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat3.xz = (-float2(float2(u._outline, u._outline))) * float2(0.001953125, 0.001953125) + in.acScreenNorm.xx;
    u_xlat3.y = in.acScreenNorm.y;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat8.x = dot(u_xlat4, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat3.w = u._outline * 0.001953125 + in.acScreenNorm.y;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat14.x = dot(u_xlat3, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat3.x = in.acScreenNorm.x;
    u_xlat3.yzw = float3(float3(u._outline, u._outline, u._outline)) * float3(0.001953125, 0.001953125, 0.001953125) + in.acScreenNorm.yxy;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat20 = dot(u_xlat4, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat3.x = dot(u_xlat3, float4(0.112500004, 0.221249998, 0.0412499979, 0.25));
    u_xlat9 = u_xlat2.x + u_xlat3.x;
    u_xlat9 = u_xlat8.x * 2.0 + u_xlat9;
    u_xlat9 = (-u_xlat19) + u_xlat9;
    u_xlat8.x = (-u_xlat8.x) * 2.0 + u_xlat9;
    u_xlat8.x = (-u_xlat14.x) + u_xlat8.x;
    u_xlat14.x = u_xlat20 * 2.0 + u_xlat14.x;
    u_xlat14.x = u_xlat3.x + u_xlat14.x;
    u_xlat14.x = (-u_xlat19) + u_xlat14.x;
    u_xlat19 = (-u_xlat19) * 2.0 + u_xlat14.x;
    u_xlat19 = (-u_xlat2.x) + u_xlat19;
    u_xlat19 = u_xlat19 * u_xlat19;
    u_xlat19 = u_xlat8.x * u_xlat8.x + u_xlat19;
    u_xlatb19 = 0.0399999991<u_xlat19;
    u_xlat19 = u_xlatb19 ? -1.0 : float(0.0);
    u_xlat1.xyz = u_xlat1.xyz * float3(u._threshold) + float3(u_xlat19);
    u_xlat19 = u_xlat1.z + u_xlat1.x;
    u_xlat19 = u_xlat19 * 12.8000002;
    u_xlatb19 = u_xlat19<u_xlat1.y;
    u_xlat1.xyz = (bool(u_xlatb19)) ? float3(0.0, 0.0, 0.0) : u_xlat1.xyz;
    u_xlat1.z = dot(u_xlat1.xyz, float3(0.212599993, 0.715200007, 0.0722000003));
    u_xlatb2 = lessThan(float4(0.949999988, 0.75, 0.5, 0.25), u_xlat1.zzzz);
    u_xlat3 = u_xlat1.zzzz * float4(0.899999976, 0.699999988, 0.5, 0.75);
    u_xlat4.xy = u_xlat1.zz * float2(0.25, 0.5);
    u_xlat15.xy = (u_xlatb2.w) ? u_xlat3.zw : u_xlat4.xy;
    u_xlat14.xy = (u_xlatb2.z) ? u_xlat3.yx : u_xlat15.xy;
    u_xlat1.w = u_xlat1.z * 0.899999976;
    u_xlat8.xy = (u_xlatb2.y) ? u_xlat1.wz : u_xlat14.xy;
    u_xlat1.xy = (u_xlatb2.x) ? u_xlat1.zz : u_xlat8.xy;
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
