// ---------------------------------------------------------------------------
// Rgb Blur (NV)
// origem : assets/effects/nv-nodevideo-assetstore-rgb-blur.xml
// id     : nv.effect.nodevideo-assetstore-rgb-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_rgb_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _separate;
    float _radius;
    float _direction;
    float _black_white;
    float _red;
    float _green;
    float _blue;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
bool4 u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float u_xlat8;
bool2 u_xlatb15;
float2 u_xlat16;
bool2 u_xlatb16;
float u_xlat17;
float u_xlat18;
bool u_xlatb18;
float u_xlat22;
float u_xlat23;
bool u_xlatb23;
float u_xlat24;
bool u_xlatb24;

fragment float4 fx_nv_nodevideo_assetstore_rgb_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_rgb_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = float3(u._separate, u._direction, u._radius) * float3(0.0500000007, 0.0174532942, 200.0);
    u_xlat1.x = sin(u_xlat0.y);
    u_xlat2.x = cos(u_xlat0.y);
    u_xlat2.x = u_xlat0.x * u_xlat2.x;
    u_xlat2.y = u_xlat0.x * u_xlat1.x;
    u_xlatb0.xyw = equal(int4(int(u._red), int(u._green), int(u._red), int(u._blue)), int4(1, 1, 0, 1)).xyw;
    u_xlat1.xy = u_xlat2.xy + in.acScreenNorm.xy;
    u_xlatb15.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb16.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat1.xyxy).xy;
    u_xlat3.xy = fract(u_xlat1.xy);
    u_xlat3.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
    u_xlat16.x = (u_xlatb16.x) ? u_xlat3.x : u_xlat1.x;
    u_xlat16.y = (u_xlatb16.y) ? u_xlat3.y : u_xlat1.y;
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb15.x) ? (-u_xlat1.x) : u_xlat16.x;
        hlslcc_movcTemp.y = (u_xlatb15.y) ? (-u_xlat1.y) : u_xlat16.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlatb15.x = u._radius>=0.00499999989;
    if(u_xlatb15.x){
        u_xlat22 = float(1.0) / _resolution.x;
        u_xlat16.x = float(1.0) / u_xlat0.z;
        u_xlat3.y = 0.0;
        u_xlat4.x = float(0.0);
        u_xlat4.y = float(0.0);
        u_xlat4.z = float(0.0);
        u_xlat4.w = float(0.0);
        u_xlat23 = 0.0;
        u_xlat17 = (-u_xlat0.z);
        while(true){
            u_xlatb24 = u_xlat0.z<u_xlat17;
            if(u_xlatb24){break;}
            u_xlat3.x = u_xlat22 * u_xlat17;
            u_xlat3.xw = u_xlat1.xy + u_xlat3.xy;
            u_xlat5 = inputImg.sample(__nv_smp, u_xlat3.xw);
            u_xlat3.x = -abs(u_xlat17) * u_xlat16.x + 1.0;
            u_xlat3.x = u_xlat3.x * 2.0 + -1.0;
            u_xlat24 = abs(u_xlat3.x) * (-u_xlat3.x);
            u_xlat3.x = u_xlat24 * 0.5 + u_xlat3.x;
            u_xlat3.x = u_xlat3.x + 0.5;
            u_xlat4 = u_xlat5 * u_xlat3.xxxx + u_xlat4;
            u_xlat23 = u_xlat23 + u_xlat3.x;
            u_xlat17 = u_xlat17 + 1.0;
        }
        u_xlat3 = u_xlat4 / float4(u_xlat23);
    }
    if(!u_xlatb15.x){
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat1.xy);
    }
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat1.xy);
    u_xlat3 = (u_xlatb0.x) ? u_xlat3 : u_xlat4;
    u_xlatb1.xy = lessThan(in.acScreenNorm.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb16.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), in.acScreenNorm.xyxy).xy;
    u_xlat4.xy = fract(in.acScreenNorm.xy);
    u_xlat4.xy = (-u_xlat4.xy) + float2(1.0, 1.0);
    u_xlat16.x = (u_xlatb16.x) ? u_xlat4.x : in.acScreenNorm.x;
    u_xlat16.y = (u_xlatb16.y) ? u_xlat4.y : in.acScreenNorm.y;
    u_xlat1.x = (u_xlatb1.x) ? (-in.acScreenNorm.x) : u_xlat16.x;
    u_xlat1.y = (u_xlatb1.y) ? (-in.acScreenNorm.y) : u_xlat16.y;
    if(u_xlatb15.x){
        u_xlat0.x = float(1.0) / _resolution.x;
        u_xlat22 = float(1.0) / u_xlat0.z;
        u_xlat4.y = 0.0;
        u_xlat5.x = float(0.0);
        u_xlat5.y = float(0.0);
        u_xlat5.z = float(0.0);
        u_xlat5.w = float(0.0);
        u_xlat16.x = 0.0;
        u_xlat23 = (-u_xlat0.z);
        while(true){
            u_xlatb18 = u_xlat0.z<u_xlat23;
            if(u_xlatb18){break;}
            u_xlat4.x = u_xlat0.x * u_xlat23;
            u_xlat4.xz = u_xlat1.xy + u_xlat4.xy;
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat4.xz);
            u_xlat4.x = -abs(u_xlat23) * u_xlat22 + 1.0;
            u_xlat4.x = u_xlat4.x * 2.0 + -1.0;
            u_xlat18 = abs(u_xlat4.x) * (-u_xlat4.x);
            u_xlat4.x = u_xlat18 * 0.5 + u_xlat4.x;
            u_xlat4.x = u_xlat4.x + 0.5;
            u_xlat5 = u_xlat6 * u_xlat4.xxxx + u_xlat5;
            u_xlat16.x = u_xlat16.x + u_xlat4.x;
            u_xlat23 = u_xlat23 + 1.0;
        }
        u_xlat4 = u_xlat5 / u_xlat16.xxxx;
    }
    if(!u_xlatb15.x){
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat1.xy);
    }
    u_xlat5 = inputImg.sample(__nv_smp, u_xlat1.xy);
    u_xlat4 = (u_xlatb0.y) ? u_xlat4 : u_xlat5;
    u_xlat0.xy = (-u_xlat2.xy) + in.acScreenNorm.xy;
    u_xlatb1.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlat16.xy = fract(u_xlat0.xy);
    u_xlat2.zw = (-u_xlat16.xy) + float2(1.0, 1.0);
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat2.z : u_xlat0.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat2.w : u_xlat0.y;
        u_xlat2 = hlslcc_movcTemp;
    }
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat0.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb1.y) ? (-u_xlat0.y) : u_xlat2.y;
        u_xlat0 = hlslcc_movcTemp;
    }
    if(u_xlatb15.x){
        u_xlat1.x = float(1.0) / _resolution.x;
        u_xlat8 = float(1.0) / u_xlat0.z;
        u_xlat2.y = 0.0;
        u_xlat5.x = float(0.0);
        u_xlat5.y = float(0.0);
        u_xlat5.z = float(0.0);
        u_xlat5.w = float(0.0);
        u_xlat22 = 0.0;
        u_xlat16.x = (-u_xlat0.z);
        while(true){
            u_xlatb23 = u_xlat0.z<u_xlat16.x;
            if(u_xlatb23){break;}
            u_xlat2.x = u_xlat1.x * u_xlat16.x;
            u_xlat2.xw = u_xlat0.xy + u_xlat2.xy;
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat2.xw);
            u_xlat2.x = -abs(u_xlat16.x) * u_xlat8 + 1.0;
            u_xlat2.x = u_xlat2.x * 2.0 + -1.0;
            u_xlat23 = abs(u_xlat2.x) * (-u_xlat2.x);
            u_xlat2.x = u_xlat23 * 0.5 + u_xlat2.x;
            u_xlat2.x = u_xlat2.x + 0.5;
            u_xlat5 = u_xlat6 * u_xlat2.xxxx + u_xlat5;
            u_xlat22 = u_xlat22 + u_xlat2.x;
            u_xlat16.x = u_xlat16.x + 1.0;
        }
        u_xlat2 = u_xlat5 / float4(u_xlat22);
    }
    if(!u_xlatb15.x){
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat0.xy);
    }
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0 = (u_xlatb0.w) ? u_xlat2 : u_xlat1;
    u_xlat1.x = dot(u_xlat3.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat1.y = dot(u_xlat4.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat1.z = dot(u_xlat0.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat0.x = u_xlat3.x;
    u_xlat0.y = u_xlat4.y;
    u_xlat1.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;
    u_xlat1.xyz = float3(u._black_white) * u_xlat1.xyz + u_xlat0.xyz;
    u_xlat0.x = max(u_xlat3.w, u_xlat4.w);
    u_xlat1.w = max(u_xlat0.w, u_xlat0.x);
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
