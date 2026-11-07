// ---------------------------------------------------------------------------
// Fill Fractalridges (NV)
// origem : assets/effects/nv-nodevideo-fill-fractalridges.xml
// id     : nv.effect.nodevideo-fill-fractalridges
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_fractalridgesParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _evolution;
    float2 _phase;
    float2 _position;
    float2 _scale;
    float _intensity;
    float _seed;
    float4 _color1;
    float4 _color2;
    float _complexity;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
float4 u_xlat7;
bool u_xlatb7;
float4 u_xlat8;
float4 u_xlat9;
bool3 u_xlatb9;
float3 u_xlat10;
float4 u_xlat11;
float3 u_xlat12;
float3 u_xlat13;
float4 u_xlat14;
float4 u_xlat15;
float4 u_xlat16;
bool4 u_xlatb16;
float4 u_xlat17;
float3 u_xlat19;
float u_xlat20;
float u_xlat21;
float u_xlat24;
float2 u_xlat37;
float u_xlat42;
float u_xlat56;
int u_xlati60;

fragment float4 fx_nv_nodevideo_fill_fractalridges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_fractalridgesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = _resolution.x / _resolution.y;
    u_xlat1.x = u_xlat1.x * in.acScreenNorm.x;
    u_xlat1.y = in.acScreenNorm.y;
    u_xlat1.xy = u._position.xy * float2(-1.0, 1.0) + u_xlat1.xy;
    u_xlat37.xy = float2(float2(u._seed, u._seed)) * float2(188.298065, 56.7870369);
    u_xlatb2.xy = greaterThanEqual(u_xlat37.xyxx, (-u_xlat37.xyxx)).xy;
    u_xlat37.xy = fract(abs(u_xlat37.xy));
    {
        float2 hlslcc_movcTemp = u_xlat37;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat37.x : (-u_xlat37.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat37.y : (-u_xlat37.y);
        u_xlat37 = hlslcc_movcTemp;
    }
    u_xlat1.xy = u_xlat37.xy * float2(4.36499977, 7.70100021) + u_xlat1.xy;
    u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy / float2(u._scale.x, u._scale.y);
    u_xlat2.z = u._evolution;
    u_xlat3.x = float(0.0);
    u_xlat3.w = float(1.0);
    u_xlat4.x = float(0.0);
    u_xlat4.w = float(1.0);
    u_xlat5.x = float(0.0);
    u_xlat5.w = float(1.0);
    u_xlat37.xy = u_xlat1.xy;
    u_xlat56 = 0.0;
    u_xlat6 = float(1.0);
    u_xlat24 = float(0.5);
    u_xlat42 = float(1.0);
    u_xlati60 = int(0);
    while(true){
        u_xlatb7 = u_xlati60>=int(u._complexity);
        if(u_xlatb7){break;}
        u_xlat2.xy = u_xlat37.xy * float2(u_xlat6);
        u_xlat7.x = dot(u_xlat2.xyz, float3(0.333333343, 0.333333343, 0.333333343));
        u_xlat7.xyz = u_xlat2.xyz + u_xlat7.xxx;
        u_xlat7.xyz = floor(u_xlat7.xyz);
        u_xlat8.xyz = u_xlat2.xyz + (-u_xlat7.xyz);
        u_xlat2.x = dot(u_xlat7.xyz, float3(0.166666672, 0.166666672, 0.166666672));
        u_xlat8.xyz = u_xlat2.xxx + u_xlat8.xyz;
        u_xlatb9.xyz = greaterThanEqual(u_xlat8.zxyz, u_xlat8.xyzx).xyz;
        u_xlat10.x = u_xlatb9.y ? float(1.0) : 0.0;
        u_xlat10.y = u_xlatb9.z ? float(1.0) : 0.0;
        u_xlat10.z = u_xlatb9.x ? float(1.0) : 0.0;
;
        u_xlat9.x = (u_xlatb9.x) ? float(0.0) : float(1.0);
        u_xlat9.y = (u_xlatb9.y) ? float(0.0) : float(1.0);
        u_xlat9.z = (u_xlatb9.z) ? float(0.0) : float(1.0);
        u_xlat11.xyz = min(u_xlat9.xyz, u_xlat10.xyz);
        u_xlat9.xyz = max(u_xlat9.xyz, u_xlat10.xyz);
        u_xlat10.xyz = u_xlat8.xyz + (-u_xlat11.xyz);
        u_xlat10.xyz = u_xlat10.xyz + float3(0.166666672, 0.166666672, 0.166666672);
        u_xlat12.xyz = u_xlat8.xyz + (-u_xlat9.xyz);
        u_xlat12.xyz = u_xlat12.xyz + float3(0.333333343, 0.333333343, 0.333333343);
        u_xlat13.xyz = u_xlat8.xyz + float3(-0.5, -0.5, -0.5);
        u_xlat14.xyz = u_xlat7.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat14.xyz = floor(u_xlat14.xyz);
        u_xlat7.xyz = (-u_xlat14.xyz) * float3(289.0, 289.0, 289.0) + u_xlat7.xyz;
        u_xlat3.y = u_xlat11.z;
        u_xlat3.z = u_xlat9.z;
        u_xlat14 = u_xlat3 + u_xlat7.zzzz;
        u_xlat15 = u_xlat14 * float4(34.0, 34.0, 34.0, 34.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat14 = u_xlat14 * u_xlat15;
        u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat15 = floor(u_xlat15);
        u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
        u_xlat14 = u_xlat7.yyyy + u_xlat14;
        u_xlat4.y = u_xlat11.y;
        u_xlat4.z = u_xlat9.y;
        u_xlat14 = u_xlat4 + u_xlat14;
        u_xlat15 = u_xlat14 * float4(34.0, 34.0, 34.0, 34.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat14 = u_xlat14 * u_xlat15;
        u_xlat15 = u_xlat14 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat15 = floor(u_xlat15);
        u_xlat14 = (-u_xlat15) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat14;
        u_xlat7 = u_xlat7.xxxx + u_xlat14;
        u_xlat5.y = u_xlat11.x;
        u_xlat5.z = u_xlat9.x;
        u_xlat7 = u_xlat5 + u_xlat7;
        u_xlat9 = u_xlat7 * float4(34.0, 34.0, 34.0, 34.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat7 = u_xlat7 * u_xlat9;
        u_xlat9 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat9 = floor(u_xlat9);
        u_xlat7 = (-u_xlat9) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
        u_xlat9 = u_xlat7 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
        u_xlat9 = floor(u_xlat9);
        u_xlat7 = (-u_xlat9) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat7;
        u_xlat9 = u_xlat7 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
        u_xlat9 = floor(u_xlat9);
        u_xlat7 = (-u_xlat9) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat7;
        u_xlat9 = u_xlat9 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat7 = u_xlat7.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat11 = -abs(u_xlat9) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat11 = -abs(u_xlat7.xzwy) + u_xlat11.xywz;
        u_xlat14.xz = floor(u_xlat9.xy);
        u_xlat14.yw = floor(u_xlat7.xz);
        u_xlat14 = u_xlat14 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat15.xz = floor(u_xlat9.zw);
        u_xlat15.yw = floor(u_xlat7.yw);
        u_xlat15 = u_xlat15 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlatb16 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat11.xywz);
        u_xlat16.x = (u_xlatb16.x) ? float(-1.0) : float(-0.0);
        u_xlat16.y = (u_xlatb16.y) ? float(-1.0) : float(-0.0);
        u_xlat16.z = (u_xlatb16.z) ? float(-1.0) : float(-0.0);
        u_xlat16.w = (u_xlatb16.w) ? float(-1.0) : float(-0.0);
        u_xlat17.xz = u_xlat9.xy;
        u_xlat17.yw = u_xlat7.xz;
        u_xlat14 = u_xlat14.zwxy * u_xlat16.yyxx + u_xlat17.zwxy;
        u_xlat7.xz = u_xlat9.zw;
        u_xlat7 = u_xlat15 * u_xlat16.zzww + u_xlat7;
        u_xlat9.xy = u_xlat14.zw;
        u_xlat9.z = u_xlat11.x;
        u_xlat15.x = dot(u_xlat9.xyz, u_xlat9.xyz);
        u_xlat14.z = u_xlat11.y;
        u_xlat15.y = dot(u_xlat14.xyz, u_xlat14.xyz);
        u_xlat16.xy = u_xlat7.xy;
        u_xlat16.z = u_xlat11.w;
        u_xlat15.z = dot(u_xlat16.xyz, u_xlat16.xyz);
        u_xlat11.xy = u_xlat7.zw;
        u_xlat15.w = dot(u_xlat11.xyz, u_xlat11.xyz);
        u_xlat7 = (-u_xlat15) * float4(0.853734732, 0.853734732, 0.853734732, 0.853734732) + float4(1.79284286, 1.79284286, 1.79284286, 1.79284286);
        u_xlat9.xyz = u_xlat7.xxx * u_xlat9.xyz;
        u_xlat14.xyz = u_xlat7.yyy * u_xlat14.xyz;
        u_xlat7.xyz = u_xlat7.zzz * u_xlat16.xyz;
        u_xlat11.xyz = u_xlat7.www * u_xlat11.xyz;
        u_xlat15.x = dot(u_xlat8.xyz, u_xlat8.xyz);
        u_xlat15.y = dot(u_xlat10.xyz, u_xlat10.xyz);
        u_xlat15.z = dot(u_xlat12.xyz, u_xlat12.xyz);
        u_xlat15.w = dot(u_xlat13.xyz, u_xlat13.xyz);
        u_xlat15 = (-u_xlat15) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
        u_xlat15 = max(u_xlat15, float4(0.0, 0.0, 0.0, 0.0));
        u_xlat15 = u_xlat15 * u_xlat15;
        u_xlat15 = u_xlat15 * u_xlat15;
        u_xlat8.x = dot(u_xlat9.xyz, u_xlat8.xyz);
        u_xlat8.y = dot(u_xlat14.xyz, u_xlat10.xyz);
        u_xlat8.z = dot(u_xlat7.xyz, u_xlat12.xyz);
        u_xlat8.w = dot(u_xlat11.xyz, u_xlat13.xyz);
        u_xlat2.x = dot(u_xlat15, u_xlat8);
        u_xlat2.x = u_xlat2.x * 42.0;
        u_xlat2.x = -abs(u_xlat2.x) + 0.899999976;
        u_xlat2.x = u_xlat2.x * u_xlat2.x;
        u_xlat20 = u_xlat24 * u_xlat2.x;
        u_xlat21 = u_xlat2.x * u_xlat24 + u_xlat56;
        u_xlat56 = u_xlat20 * u_xlat42 + u_xlat21;
        u_xlat6 = u_xlat6 + u_xlat6;
        u_xlat37.xy = float2(u._phase.x, u._phase.y) * float2(-1.0, 1.0) + u_xlat37.xy;
        u_xlat24 = u_xlat24 * 0.5;
        u_xlati60 = u_xlati60 + 1;
        u_xlat42 = u_xlat2.x;
    }
    u_xlat1.x = u_xlat56 * u._intensity;
    u_xlat19.xyz = u._color1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat19.xyz = u._color1.xyz * u_xlat19.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat19.xyz * u._color1.xyz;
    u_xlat19.xyz = u._color2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat19.xyz = u._color2.xyz * u_xlat19.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.w = u._color1.w;
    u_xlat3.xyz = u._color2.xyz * u_xlat19.xyz + (-u_xlat2.xyz);
    u_xlat3.w = (-u_xlat2.w) + u._color2.w;
    u_xlat1 = u_xlat1.xxxx * u_xlat3 + u_xlat2;
    u_xlat2 = u_xlat0.wwww * u_xlat1;
    u_xlat1.x = (-u_xlat1.w) * u_xlat0.w + 1.0;
    u_xlat1 = u_xlat0 * u_xlat1.xxxx + u_xlat2;
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
