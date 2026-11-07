// ---------------------------------------------------------------------------
// Page Curl (NV)
// origem : assets/effects/nv-nodevideo-assetstore-page-curl.xml
// id     : nv.effect.nodevideo-assetstore-page-curl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_page_curlParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _angle;
    float _evolution;
    float _radius;
    float _invert;
    float _intensity;
    float _length;
    float4 _color;
    float _blend_mode;
    float _blend;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
bool2 u_xlatb5;
float4 u_xlat6;
bool2 u_xlatb6;
float4 u_xlat7;
float4 u_xlat8;
float4 u_xlat9;
float2 u_xlat10;
float2 u_xlat11;
float2 u_xlat14;
float2 u_xlat15;
float2 u_xlat20;
bool2 u_xlatb20;
float2 u_xlat21;
bool u_xlatb21;
float2 u_xlat24;
bool2 u_xlatb24;
float2 u_xlat25;
bool2 u_xlatb25;
float u_xlat30;
float u_xlat31;
bool u_xlatb31;
float u_xlat34;

fragment float4 fx_nv_nodevideo_assetstore_page_curl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_page_curlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat10.x = _resolution.x / _resolution.y;
    u_xlatb0.x = 0<int(u._invert);
    u_xlat30 = (-in.acScreenNorm.x) + 1.0;
    u_xlat11.x = (u_xlatb0.x) ? u_xlat30 : in.acScreenNorm.x;
    u_xlat11.y = in.acScreenNorm.y;
    u_xlat1.xy = u_xlat11.xy * _resolution.xy;
    u_xlat10.y = 1.0;
    u_xlat20.xy = u_xlat10.xy * u_xlat1.xy;
    u_xlat20.xy = u_xlat20.xy / _resolution.xy;
    u_xlat1.x = u._angle * 175.0 + 180.0;
    u_xlat1.x = u_xlat1.x * 0.0174532942;
    u_xlat11.x = sin((-u_xlat1.x));
    u_xlat11.y = cos(u_xlat1.x);
    u_xlat1.x = dot(u_xlat11.xy, u_xlat11.xy);
    u_xlat1.x = rsqrt(u_xlat1.x);
    u_xlat1.xy = u_xlat1.xx * u_xlat11.xy;
    u_xlat21.x = (-u_xlat10.x) + u._evolution;
    u_xlat21.x = u_xlat21.x + 0.5;
    u_xlat21.xy = (-u_xlat1.xy) * u_xlat21.xx + float2(0.5, 0.5);
    u_xlat2.xy = abs(u_xlat21.xx) * u_xlat1.xy;
    u_xlat2.xy = u_xlat2.xy / u_xlat1.xx;
    u_xlat2.xy = u_xlat21.xy + (-u_xlat2.xy);
    u_xlat21.xy = u_xlat21.xy + (-u_xlat2.xy);
    u_xlat21.x = dot(u_xlat21.xy, u_xlat21.xy);
    u_xlat21.x = sqrt(u_xlat21.x);
    u_xlat2.xy = u_xlat20.xy + (-u_xlat2.xy);
    u_xlat31 = dot(u_xlat2.xy, u_xlat1.xy);
    u_xlat21.x = (-u_xlat21.x) + u_xlat31;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb31 = u._radius<u_xlat21.x;
    if(u_xlatb31){
        u_xlat31 = u_xlat21.x + (-u._radius);
        u_xlat31 = clamp(u_xlat31, 0.0, 1.0);
        u_xlat31 = u_xlat31 / u._length;
        u_xlat31 = log2(u_xlat31);
        u_xlat31 = u_xlat31 * u._intensity;
        u_xlat31 = exp2(u_xlat31);
        u_xlat31 = (-u_xlat31) + 1.0;
        u_xlat3.xy = float2(u_xlat31) * float2(0.0, 1.0);
        u_xlat3.z = u_xlat2.w * u_xlat3.y;
        u_xlat3 = u_xlat3.xxxz;
    } else {
        u_xlat4.xy = (-u_xlat21.xx) * u_xlat1.xy + u_xlat20.xy;
        u_xlatb31 = u_xlat21.x>=0.0;
        if(u_xlatb31){
            u_xlat31 = u_xlat21.x / u._radius;
            u_xlat24.x = -abs(u_xlat31) + 1.0;
            u_xlat24.x = sqrt(u_xlat24.x);
            u_xlat34 = abs(u_xlat31) * -0.0187292993 + 0.0742610022;
            u_xlat34 = u_xlat34 * abs(u_xlat31) + -0.212114394;
            u_xlat34 = u_xlat34 * abs(u_xlat31) + 1.57072878;
            u_xlat5.x = u_xlat24.x * u_xlat34;
            u_xlat5.x = u_xlat5.x * -2.0 + 3.14159274;
            u_xlatb31 = u_xlat31<(-u_xlat31);
            u_xlat31 = u_xlatb31 ? u_xlat5.x : float(0.0);
            u_xlat31 = u_xlat34 * u_xlat24.x + u_xlat31;
            u_xlat31 = (-u_xlat31) + 1.57079637;
            u_xlat24.x = (-u_xlat31) + 3.14159274;
            u_xlat24.xy = u_xlat1.xy * u_xlat24.xx;
            u_xlat24.xy = u_xlat24.xy * float2(float2(u._radius, u._radius)) + u_xlat4.xy;
            u_xlat5.xy = float2(u_xlat31) * u_xlat1.xy;
            u_xlat5.xy = u_xlat5.xy * float2(float2(u._radius, u._radius)) + u_xlat4.xy;
            u_xlatb31 = u_xlat10.x>=u_xlat24.x;
            u_xlatb25.x = 1.0>=u_xlat24.y;
            u_xlatb31 = u_xlatb31 && u_xlatb25.x;
            u_xlatb25.xy = lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat24.xyxy).xy;
            u_xlatb31 = u_xlatb31 && u_xlatb25.x;
            u_xlatb31 = u_xlatb25.y && u_xlatb31;
            u_xlat24.xy = (bool(u_xlatb31)) ? u_xlat24.xy : u_xlat5.xy;
            u_xlat15.x = float(1.0) / u_xlat10.x;
            u_xlat15.y = 1.0;
            u_xlat6.yz = u_xlat24.xy * u_xlat15.xy;
            u_xlat24.x = (-u_xlat24.x) * u_xlat15.x + 1.0;
            u_xlat6.x = (u_xlatb0.x) ? u_xlat24.x : u_xlat6.y;
            u_xlat24.xy = u_xlat6.xz + float2(-0.5, -0.5);
            u_xlat24.xy = u_xlat24.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
            u_xlatb5.xy = lessThan(u_xlat24.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlatb25.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat24.xyxy).xy;
            u_xlat6.xy = fract(u_xlat24.xy);
            u_xlat6.xy = (-u_xlat6.xy) + float2(1.0, 1.0);
            u_xlat25.x = (u_xlatb25.x) ? u_xlat6.x : u_xlat24.x;
            u_xlat25.y = (u_xlatb25.y) ? u_xlat6.y : u_xlat24.y;
            {
                float2 hlslcc_movcTemp = u_xlat24;
                hlslcc_movcTemp.x = (u_xlatb5.x) ? (-u_xlat24.x) : u_xlat25.x;
                hlslcc_movcTemp.y = (u_xlatb5.y) ? (-u_xlat24.y) : u_xlat25.y;
                u_xlat24 = hlslcc_movcTemp;
            }
            u_xlat24.xy = u_xlat24.xy + float2(-0.5, -0.5);
            u_xlat24.xy = u_xlat24.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
            u_xlat5 = inputImg.sample(__nv_smp, u_xlat24.xy);
            u_xlat24.x = (-u_xlat5.w) + 1.0;
            u_xlat6 = u_xlat2 * u_xlat24.xxxx;
            u_xlat5 = u_xlat5 * u_xlat5.wwww + u_xlat6;
            u_xlat24.x = max(u_xlat5.w, 9.99999975e-06);
            u_xlat6.xyz = u_xlat5.xyz / u_xlat24.xxx;
            u_xlat24.x = max(u._color.w, 9.99999975e-06);
            u_xlat7.xyz = u._color.xyz / u_xlat24.xxx;
            u_xlat8.xyz = u_xlat6.xyz * u_xlat7.xyz;
            u_xlat8.w = 1.0;
            u_xlat8 = u_xlat8 * u._color.wwww;
            u_xlat9 = u_xlat8 * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat24.x = (-u_xlat8.w) * u._blend + 1.0;
            u_xlat8 = u_xlat5 * u_xlat24.xxxx + u_xlat9;
            u_xlatb24.xy = equal(int4(int(u._blend_mode)), int4(1, 2, 1, 2)).xy;
            u_xlat6.xyz = (-u_xlat6.xyz) + float3(1.0, 1.0, 1.0);
            u_xlat7.xyz = (-u_xlat7.xyz) + float3(1.0, 1.0, 1.0);
            u_xlat6.xyz = (-u_xlat6.xyz) * u_xlat7.xyz + float3(1.0, 1.0, 1.0);
            u_xlat6.w = 1.0;
            u_xlat6 = u_xlat6 * u._color.wwww;
            u_xlat7 = u_xlat6 * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat6.x = (-u_xlat6.w) * u._blend + 1.0;
            u_xlat6 = u_xlat5 * u_xlat6.xxxx + u_xlat7;
            u_xlat7 = u._color * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat9.x = (-u._color.w) * u._blend + 1.0;
            u_xlat7 = u_xlat5 * u_xlat9.xxxx + u_xlat7;
            u_xlat6 = (u_xlatb24.y) ? u_xlat6 : u_xlat7;
            u_xlat6 = (u_xlatb24.x) ? u_xlat8 : u_xlat6;
            u_xlat3 = (bool(u_xlatb31)) ? u_xlat6 : u_xlat5;
            u_xlat31 = (-u_xlat21.x) + u._radius;
            u_xlat31 = u_xlat31 / u._length;
            u_xlat31 = u_xlat31 / u._radius;
            u_xlat31 = clamp(u_xlat31, 0.0, 1.0);
            u_xlat31 = log2(u_xlat31);
            u_xlat31 = u_xlat31 * u._intensity;
            u_xlat31 = exp2(u_xlat31);
            u_xlat3.xyz = float3(u_xlat31) * u_xlat3.xyz;
        } else {
            u_xlat21.x = u._radius * 3.14159274 + abs(u_xlat21.x);
            u_xlat1.xy = u_xlat1.xy * u_xlat21.xx + u_xlat4.xy;
            u_xlatb21 = u_xlat10.x>=u_xlat1.x;
            u_xlatb31 = 1.0>=u_xlat1.y;
            u_xlatb21 = u_xlatb31 && u_xlatb21;
            u_xlatb4.xy = lessThan(float4(0.0, 0.0, 0.0, 0.0), u_xlat1.xyxx).xy;
            u_xlatb21 = u_xlatb21 && u_xlatb4.x;
            u_xlatb21 = u_xlatb4.y && u_xlatb21;
            u_xlat20.xy = (bool(u_xlatb21)) ? u_xlat1.xy : u_xlat20.xy;
            u_xlat14.x = float(1.0) / u_xlat10.x;
            u_xlat14.y = 1.0;
            u_xlat5.yz = u_xlat20.xy * u_xlat14.xy;
            u_xlat10.x = (-u_xlat20.x) * u_xlat14.x + 1.0;
            u_xlat5.x = (u_xlatb0.x) ? u_xlat10.x : u_xlat5.y;
            u_xlat0.xy = u_xlat5.xz + float2(-0.5, -0.5);
            u_xlat0.xy = u_xlat0.xy * float2(1.00100005, 1.00100005) + float2(0.5, 0.5);
            u_xlatb20.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
            u_xlat4.xy = fract(u_xlat0.xy);
            u_xlat4.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
            u_xlat1.x = (u_xlatb1.x) ? u_xlat4.x : u_xlat0.x;
            u_xlat1.y = (u_xlatb1.y) ? u_xlat4.y : u_xlat0.y;
            {
                float4 hlslcc_movcTemp = u_xlat0;
                hlslcc_movcTemp.x = (u_xlatb20.x) ? (-u_xlat0.x) : u_xlat1.x;
                hlslcc_movcTemp.y = (u_xlatb20.y) ? (-u_xlat0.y) : u_xlat1.y;
                u_xlat0 = hlslcc_movcTemp;
            }
            u_xlat0.xy = u_xlat0.xy + float2(-0.5, -0.5);
            u_xlat0.xy = u_xlat0.xy * float2(0.999000967, 0.999000967) + float2(0.5, 0.5);
            u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
            u_xlat1.x = max(u_xlat0.w, 9.99999975e-06);
            u_xlat1.xyw = u_xlat0.xyz / u_xlat1.xxx;
            u_xlat4.x = max(u._color.w, 9.99999975e-06);
            u_xlat4.xyz = u._color.xyz / u_xlat4.xxx;
            u_xlat5.xyz = u_xlat1.xyw * u_xlat4.xyz;
            u_xlat5.w = 1.0;
            u_xlat5 = u_xlat5 * u._color.wwww;
            u_xlat6 = u_xlat5 * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat34 = (-u_xlat5.w) * u._blend + 1.0;
            u_xlat5 = u_xlat0 * float4(u_xlat34) + u_xlat6;
            u_xlatb6.xy = equal(int4(int(u._blend_mode)), int4(1, 2, 0, 0)).xy;
            u_xlat1.xyw = (-u_xlat1.xyw) + float3(1.0, 1.0, 1.0);
            u_xlat4.xyz = (-u_xlat4.xyz) + float3(1.0, 1.0, 1.0);
            u_xlat4.xyz = (-u_xlat1.xyw) * u_xlat4.xyz + float3(1.0, 1.0, 1.0);
            u_xlat4.w = 1.0;
            u_xlat4 = u_xlat4 * u._color.wwww;
            u_xlat7 = u_xlat4 * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat1.x = (-u_xlat4.w) * u._blend + 1.0;
            u_xlat4 = u_xlat0 * u_xlat1.xxxx + u_xlat7;
            u_xlat7 = u._color * float4(float4(u._blend, u._blend, u._blend, u._blend));
            u_xlat1.x = (-u._color.w) * u._blend + 1.0;
            u_xlat7 = u_xlat0 * u_xlat1.xxxx + u_xlat7;
            u_xlat4 = (u_xlatb6.y) ? u_xlat4 : u_xlat7;
            u_xlat4 = (u_xlatb6.x) ? u_xlat5 : u_xlat4;
            u_xlat0 = (bool(u_xlatb21)) ? u_xlat4 : u_xlat0;
            u_xlat1.x = (-u_xlat0.w) + 1.0;
            u_xlat1 = u_xlat1.xxxx * u_xlat2;
            u_xlat3 = u_xlat0 * u_xlat0.wwww + u_xlat1;
        }
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlatb0.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1 = (u_xlatb0.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat3;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat1 = u_xlat1 * u_xlat4 + u_xlat2;
        u_xlat0.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb0.y) ? u_xlat0.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat3;
    }
    return __nv_out;
    return __nv_out;
}
