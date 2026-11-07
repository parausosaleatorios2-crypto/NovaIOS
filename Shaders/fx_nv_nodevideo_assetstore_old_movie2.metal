// ---------------------------------------------------------------------------
// Old Movie2 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-old-movie2.xml
// id     : nv.effect.nodevideo-assetstore-old-movie2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_old_movie2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _black_white;
    float _lines_flicker;
    float _grain;
    float _brightness;
    float _vignetting;
    float _amount;
    float _blend;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool2 u_xlatb7;
float2 u_xlat8;
float2 u_xlat9;
float2 u_xlat13;
float2 u_xlat14;
bool2 u_xlatb14;
float u_xlat15;
float u_xlat19;

fragment float4 fx_nv_nodevideo_assetstore_old_movie2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_old_movie2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb1 = int(u._black_white)==1;
    if(u_xlatb1){
        u_xlat1.x = dot(float3(0.212599993, 0.715200007, 0.0722000003), u_xlat0.xyz);
        u_xlat7 = u_xlat0.y + u_xlat0.x;
        u_xlat7 = u_xlat0.z + u_xlat7;
        u_xlat2.y = u_xlat7 * 0.333299994;
        u_xlatb7.xy = equal(int4(int(u._lines_flicker), int(u._grain), int(u._lines_flicker), int(u._lines_flicker)), int4(1, 1, 0, 0)).xy;
        u_xlat14.xy = float2(float2(_cur_time, _cur_time)) * float2(9.99999975e-06, 0.100000001);
        u_xlat19 = sin(u_xlat14.x);
        u_xlat19 = u_xlat19 * 2.42000008;
        u_xlat19 = fract(u_xlat19);
        u_xlat3.x = u_xlat19 + in.acScreenNorm.x;
        u_xlat19 = u_xlat3.x * 21.5 + 10.2399998;
        u_xlat4.x = u_xlat19 * 72.2040024;
        u_xlat4.y = 168.84906;
        u_xlat3.y = 0.5;
        u_xlat19 = dot(u_xlat3.xy, u_xlat4.xy);
        u_xlat19 = u_xlat19 * 1.53199995;
        u_xlat19 = sin(u_xlat19);
        u_xlat19 = u_xlat19 * 412.240997;
        u_xlat19 = fract(u_xlat19);
        u_xlat19 = (-u_xlat19) + u_xlat3.x;
        u_xlat14.x = u._amount + 1.0;
        u_xlat14.x = 200.0 / u_xlat14.x;
        u_xlat19 = abs(u_xlat19) * u_xlat14.x;
        u_xlat19 = clamp(u_xlat19, 0.0, 1.0);
        u_xlat3.z = u_xlat19 * u_xlat2.y;
        u_xlat2.x = in.acScreenNorm.x;
        u_xlat2.xy = (u_xlatb7.x) ? u_xlat3.xz : u_xlat2.xy;
        u_xlat7 = fract(u_xlat14.y);
        u_xlat2.z = u_xlat7 + in.acScreenNorm.y;
        u_xlat7 = u_xlat2.y * 0.800000012;
        u_xlat3.xy = u_xlat2.xz * float2(21.5, 1.83000004) + float2(10.2399998, 1.42349994);
        u_xlat3.xy = u_xlat3.xy * float2(72.2040024, 72.2040024);
        u_xlat19 = dot(u_xlat2.xz, u_xlat3.xy);
        u_xlat19 = u_xlat19 * 1.53199995;
        u_xlat19 = sin(u_xlat19);
        u_xlat19 = u_xlat19 * 412.240997;
        u_xlat19 = fract(u_xlat19);
        u_xlat7 = u_xlat19 * 0.200000003 + u_xlat7;
        u_xlat7 = (u_xlatb7.y) ? u_xlat7 : u_xlat2.y;
        u_xlat13.xy = log2(in.acScreenNorm.xy);
        u_xlat13.xy = u_xlat13.xy * float2(20.0, 20.0);
        u_xlat13.xy = exp2(u_xlat13.xy);
        u_xlat13.xy = min(u_xlat13.xy, float2(1.0, 1.0));
        u_xlat2.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
        u_xlat2.xy = log2(u_xlat2.xy);
        u_xlat2.xy = u_xlat2.xy * float2(20.0, 20.0);
        u_xlat2.xy = exp2(u_xlat2.xy);
        u_xlat2.xy = min(u_xlat2.xy, float2(1.0, 1.0));
        u_xlat13.xy = u_xlat13.xy + u_xlat2.xy;
        u_xlat7 = (-u_xlat13.x) * u._vignetting + u_xlat7;
        u_xlat7 = (-u_xlat13.y) * u._vignetting + u_xlat7;
        u_xlat1.x = u_xlat1.x * u_xlat7;
        u_xlat1.xyz = u_xlat1.xxx * float3(float3(u._brightness, u._brightness, u._brightness));
    } else {
        u_xlat2.x = u_xlat0.y + u_xlat0.x;
        u_xlat2.x = u_xlat0.z + u_xlat2.x;
        u_xlat2.y = u_xlat2.x * 0.333299994;
        u_xlatb14.xy = equal(int4(int(u._lines_flicker), int(u._grain), int(u._lines_flicker), int(u._grain)), int4(1, 1, 1, 1)).xy;
        u_xlat3.xy = float2(float2(_cur_time, _cur_time)) * float2(9.99999975e-06, 0.100000001);
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 2.42000008;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat4.x = u_xlat3.x + in.acScreenNorm.x;
        u_xlat3.x = u_xlat4.x * 21.5 + 10.2399998;
        u_xlat5.x = u_xlat3.x * 72.2040024;
        u_xlat5.y = 168.84906;
        u_xlat4.y = 0.5;
        u_xlat3.x = dot(u_xlat4.xy, u_xlat5.xy);
        u_xlat3.x = u_xlat3.x * 1.53199995;
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 412.240997;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat3.x = (-u_xlat3.x) + u_xlat4.x;
        u_xlat15 = u._amount + 1.0;
        u_xlat15 = 200.0 / u_xlat15;
        u_xlat3.x = u_xlat15 * abs(u_xlat3.x);
        u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
        u_xlat4.z = u_xlat2.y * u_xlat3.x;
        u_xlat2.x = in.acScreenNorm.x;
        u_xlat2.xy = (u_xlatb14.x) ? u_xlat4.xz : u_xlat2.xy;
        u_xlat3.x = fract(u_xlat3.y);
        u_xlat2.z = u_xlat3.x + in.acScreenNorm.y;
        u_xlat3.x = u_xlat2.y * 0.800000012;
        u_xlat9.xy = u_xlat2.xz * float2(21.5, 1.83000004) + float2(10.2399998, 1.42349994);
        u_xlat9.xy = u_xlat9.xy * float2(72.2040024, 72.2040024);
        u_xlat2.x = dot(u_xlat2.xz, u_xlat9.xy);
        u_xlat2.x = u_xlat2.x * 1.53199995;
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat2.x = u_xlat2.x * 412.240997;
        u_xlat2.x = fract(u_xlat2.x);
        u_xlat2.x = u_xlat2.x * 0.200000003 + u_xlat3.x;
        u_xlat2.x = (u_xlatb14.y) ? u_xlat2.x : u_xlat2.y;
        u_xlat8.xy = log2(in.acScreenNorm.xy);
        u_xlat8.xy = u_xlat8.xy * float2(20.0, 20.0);
        u_xlat8.xy = exp2(u_xlat8.xy);
        u_xlat8.xy = min(u_xlat8.xy, float2(1.0, 1.0));
        u_xlat3.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
        u_xlat3.xy = log2(u_xlat3.xy);
        u_xlat3.xy = u_xlat3.xy * float2(20.0, 20.0);
        u_xlat3.xy = exp2(u_xlat3.xy);
        u_xlat3.xy = min(u_xlat3.xy, float2(1.0, 1.0));
        u_xlat8.xy = u_xlat8.xy + u_xlat3.xy;
        u_xlat2.x = (-u_xlat8.x) * u._vignetting + u_xlat2.x;
        u_xlat2.x = (-u_xlat8.y) * u._vignetting + u_xlat2.x;
        u_xlat2.xyz = u_xlat0.xyz * u_xlat2.xxx;
        u_xlat1.xyz = u_xlat2.xyz * float3(float3(u._brightness, u._brightness, u._brightness));
    }
    u_xlat1.w = u_xlat0.w;
    u_xlat2 = u_xlat0 + (-u_xlat1);
    u_xlat1 = float4(float4(u._blend, u._blend, u._blend, u._blend)) * u_xlat2 + u_xlat1;
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
