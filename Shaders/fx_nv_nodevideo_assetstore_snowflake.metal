// ---------------------------------------------------------------------------
// Snowflake (NV)
// origem : assets/effects/nv-nodevideo-assetstore-snowflake.xml
// id     : nv.effect.nodevideo-assetstore-snowflake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_snowflakeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _gravity;
    float _opacity;
    float3 _direction;
    float4 _color;
    float _turbulence;
    float _size;
    float _scale;
    float _amount;
    float _flake_thickness;
    float _depth;
    float _speed;
    float2 _flake_shape_adjust1;
    float2 _flake_shape_adjust2;
    float _noise_scale;
    float _feather;
    float _evolution;
    float _rotation_over_lifetime;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
bool u_xlatb5;
float2 u_xlat6;
float u_xlat7;
float2 u_xlat8;
float3 u_xlat9;
bool2 u_xlatb9;
float3 u_xlat10;
float3 u_xlat11;
float3 u_xlat12;
float u_xlat14;
float u_xlat15;
float2 u_xlat20;
float2 u_xlat22;
float2 u_xlat26;
float u_xlat27;
float u_xlat30;
float2 u_xlat31;
float u_xlat32;
bool u_xlatb32;
float2 u_xlat33;
bool u_xlatb33;
float2 u_xlat34;
bool u_xlatb34;
float u_xlat39;
float u_xlat40;
float u_xlat41;
float u_xlat44;
float u_xlat45;
bool u_xlatb45;
float u_xlat46;
bool u_xlatb46;
float u_xlat47;

fragment float4 fx_nv_nodevideo_assetstore_snowflake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_snowflakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat26.xy = _resolution.xy / _resolution.yx;
    u_xlat26.xy = max(u_xlat26.xy, float2(1.0, 1.0));
    u_xlat0.xy = u_xlat26.xy * u_xlat0.xy;
    u_xlat26.x = _cur_time * u._speed + u._evolution;
    u_xlat1.xy = u_xlat26.xx * float2(0.25, 0.5);
    u_xlat39 = sin(u_xlat1.y);
    u_xlat39 = u_xlat39 * 0.5 + 0.5;
    u_xlat39 = u_xlat39 * 0.200000003 + (-u_xlat1.x);
    u_xlat39 = u_xlat39 + u_xlat39;
    u_xlat1.x = u_xlat39 * u._direction.z;
    u_xlat26.x = u_xlat26.x * 2.5 + 100.0;
    u_xlat14 = u._amount * 0.5;
    u_xlat27 = u_xlat26.x * u._turbulence;
    u_xlat2 = float4(u._flake_shape_adjust1.x, u._flake_shape_adjust1.y, u._flake_shape_adjust2.x, u._flake_shape_adjust2.y) * float4(0.5, 0.5, 0.5, 0.5);
    u_xlat3.xz = (-u_xlat2.yw);
    u_xlat3.y = float(-0.0);
    u_xlat3.w = float(-0.0);
    u_xlat40 = u._flake_thickness * 0.0500000007;
    u_xlat40 = float(1.0) / (-u_xlat40);
    u_xlat15 = u._noise_scale * 100.0;
    u_xlat41 = float(1.0) / (-u._depth);
    u_xlat4.y = float(0.0);
    u_xlat4.w = float(0.0);
    u_xlat5.y = float(0.0);
    u_xlat31.x = float(0.0);
    u_xlat6.y = 0.0;
    u_xlat7 = float(0.0);
    u_xlat20.x = float(0.0);
    while(true){
        u_xlatb32 = u_xlat20.x>=1.0;
        if(u_xlatb32){break;}
        u_xlat32 = (-u_xlat1.x) * 0.100000001 + u_xlat20.x;
        u_xlat32 = fract(u_xlat32);
        u_xlat45 = u_xlat32 * 10.0;
        u_xlat46 = u_xlat20.x * 172.5;
        u_xlat8.xy = u_xlat0.xy * float2(u_xlat45) + float2(u_xlat46);
        u_xlat8.xy = (-float2(u_xlat39)) * (-u._direction.xy) + u_xlat8.xy;
        u_xlat8.xy = u_xlat8.xy / float2(float2(u._scale, u._scale));
        u_xlat9.x = floor(u_xlat8.x);
        u_xlat45 = u_xlat9.x * 164.360001 + 0.5;
        u_xlat45 = fract(u_xlat45);
        u_xlat45 = u_xlat45 * 46.435894;
        u_xlatb46 = u_xlat45>=(-u_xlat45);
        u_xlat45 = fract(u_xlat45);
        u_xlat45 = (u_xlatb46) ? u_xlat45 : (-u_xlat45);
        u_xlat45 = u_xlat45 * 6.28299999;
        u_xlat45 = sin(u_xlat45);
        u_xlat45 = u_xlat45 * 94.3286209;
        u_xlat45 = fract(u_xlat45);
        u_xlat45 = u_xlat45 + (-u._gravity);
        u_xlat45 = u_xlat45 + -0.5;
        u_xlat46 = u_xlat26.x * u_xlat45 + u_xlat8.y;
        u_xlat9.y = floor(u_xlat46);
        u_xlat46 = u_xlat9.y * 534.359985;
        u_xlat20.xy = u_xlat20.xx + float2(0.200000003, 1.0);
        u_xlat33.x = u_xlat20.y * u_xlat46;
        u_xlat33.x = fract(u_xlat33.x);
        u_xlat33.x = u_xlat33.x * 46.435894;
        u_xlatb46 = u_xlat33.x>=(-u_xlat33.x);
        u_xlat33.x = fract(u_xlat33.x);
        u_xlat33.x = (u_xlatb46) ? u_xlat33.x : (-u_xlat33.x);
        u_xlat33.x = u_xlat33.x * 6.28299999;
        u_xlat33.x = sin(u_xlat33.x);
        u_xlat33.x = u_xlat33.x * 94.3286209;
        u_xlat33.x = fract(u_xlat33.x);
        u_xlatb33 = u_xlat14>=u_xlat33.x;
        if(u_xlatb33){
            u_xlat33.xy = fract(u_xlat8.xy);
            u_xlat45 = u_xlat26.x * u_xlat45 + u_xlat33.y;
            u_xlat8.x = fract(u_xlat33.x);
            u_xlat8.y = fract(u_xlat45);
            u_xlat33.xy = u_xlat9.xy * float2(572.400024, 572.400024);
            u_xlat33.xy = fract(u_xlat33.xy);
            u_xlat9.x = dot(float2(0.951105714, 0.308865517), u_xlat33.xy);
            u_xlat9.y = dot(float2(-0.308865517, 0.951105714), u_xlat33.xy);
            u_xlat45 = u_xlat9.x * 46.435894;
            u_xlatb33 = u_xlat45>=(-u_xlat45);
            u_xlat45 = fract(u_xlat45);
            u_xlat45 = (u_xlatb33) ? u_xlat45 : (-u_xlat45);
            u_xlat45 = u_xlat45 * 6.28299999;
            u_xlat45 = sin(u_xlat45);
            u_xlat33.x = (-u_xlat9.x) + u_xlat9.y;
            u_xlat33.x = u_xlat9.y * u_xlat33.x;
            u_xlat33.x = u_xlat33.x * 143.64566;
            u_xlat10.x = sin(u_xlat33.x);
            u_xlat11.x = cos(u_xlat33.x);
            u_xlat12.x = sin((-u_xlat33.x));
            u_xlat12.y = u_xlat11.x;
            u_xlat12.z = u_xlat10.x;
            u_xlat10.x = dot(u_xlat12.yz, u_xlat9.xy);
            u_xlat10.y = dot(u_xlat12.xy, u_xlat9.xy);
            u_xlat33.x = u_xlat10.x * 46.435894;
            u_xlatb46 = u_xlat33.x>=(-u_xlat33.x);
            u_xlat33.x = fract(abs(u_xlat33.x));
            u_xlat33.x = (u_xlatb46) ? u_xlat33.x : (-u_xlat33.x);
            u_xlat33.x = u_xlat33.x * 6.28299999;
            u_xlat33.x = sin(u_xlat33.x);
            u_xlat46 = (-u_xlat10.y) + u_xlat10.x;
            u_xlat33.y = u_xlat10.x * u_xlat46;
            u_xlat33.xy = u_xlat33.xy * float2(94.3286209, 143.64566);
            u_xlat9.x = sin(u_xlat33.y);
            u_xlat11.x = cos(u_xlat33.y);
            u_xlat11.y = u_xlat9.x;
            u_xlat46 = dot(u_xlat11.xy, u_xlat10.xy);
            u_xlat46 = u_xlat46 * 46.435894;
            u_xlatb34 = u_xlat46>=(-u_xlat46);
            u_xlat46 = fract(abs(u_xlat46));
            u_xlat46 = (u_xlatb34) ? u_xlat46 : (-u_xlat46);
            u_xlat46 = u_xlat46 * 6.28299999;
            u_xlat46 = sin(u_xlat46);
            u_xlat45 = u_xlat45 * 94.3286209 + u_xlat33.x;
            u_xlat9.z = fract(u_xlat45);
            u_xlat45 = u_xlat46 * 94.3286209 + u_xlat33.x;
            u_xlat9.x = fract(u_xlat45);
            u_xlat33.xy = u_xlat9.xz + float2(0.00999999978, 0.00999999978);
            u_xlat34.xy = float2(u_xlat27) * u_xlat33.yx;
            u_xlat34.xy = u_xlat34.xy * float2(0.159154937, 0.159154937);
            u_xlatb9.xy = greaterThanEqual(u_xlat34.xyxx, (-u_xlat34.xyxx)).xy;
            u_xlat34.xy = fract(abs(u_xlat34.xy));
            {
                float2 hlslcc_movcTemp = u_xlat34;
                hlslcc_movcTemp.x = (u_xlatb9.x) ? u_xlat34.x : (-u_xlat34.x);
                hlslcc_movcTemp.y = (u_xlatb9.y) ? u_xlat34.y : (-u_xlat34.y);
                u_xlat34 = hlslcc_movcTemp;
            }
            u_xlat34.xy = u_xlat34.xy * float2(6.28318548, 6.28318548);
            u_xlat34.xy = sin(u_xlat34.xy);
            u_xlat45 = u_xlat26.x * u_xlat33.x;
            u_xlat45 = u_xlat45 * 0.318471313;
            u_xlatb9.x = u_xlat45>=(-u_xlat45);
            u_xlat45 = fract(abs(u_xlat45));
            u_xlat45 = (u_xlatb9.x) ? u_xlat45 : (-u_xlat45);
            u_xlat45 = u_xlat45 * 3.1400001;
            u_xlat45 = sin(u_xlat45);
            u_xlat45 = u_xlat45 * 0.5 + 0.5;
            u_xlat45 = u_xlat45 * 0.5 + 0.5;
            u_xlat9.x = u_xlat45 * u._size;
            u_xlat45 = (-u._size) * u_xlat45 + 1.0;
            u_xlat45 = u_xlat45 * 0.5;
            u_xlat22.xy = float2(u_xlat45) * u_xlat34.xy;
            u_xlat8.xy = u_xlat8.xy + float2(-0.5, -0.5);
            u_xlat8.xy = (-u_xlat34.xy) * float2(u_xlat45) + u_xlat8.xy;
            u_xlat8.xy = u_xlat8.xy / u_xlat9.xx;
            u_xlat45 = u_xlat22.y * u._rotation_over_lifetime;
            u_xlat34.x = u_xlat22.x * 31.4159279;
            u_xlat47 = u_xlat34.x * u._rotation_over_lifetime;
            u_xlat47 = cos(u_xlat47);
            u_xlat47 = float(1.0) / u_xlat47;
            u_xlat45 = u_xlat45 * 10.0;
            u_xlat9.x = sin(u_xlat45);
            u_xlat10.x = cos(u_xlat45);
            u_xlat11.x = sin((-u_xlat45));
            u_xlat11.y = u_xlat10.x;
            u_xlat11.z = u_xlat9.x;
            u_xlat45 = dot(u_xlat11.yz, u_xlat8.xy);
            u_xlat8.y = dot(u_xlat11.xy, u_xlat8.xy);
            u_xlat8.x = u_xlat45 * u_xlat47;
            u_xlat9.xy = u_xlat8.xy * float2(0.600000024, 0.600000024) + float2(0.5, 0.5);
            u_xlat33.xy = fract(u_xlat33.xy);
            u_xlat10.xz = abs(u_xlat8.xy);
            u_xlat10.y = (-u_xlat10.z);
            u_xlat45 = dot(u_xlat10.xy, float2(0.5, 0.866025388));
            u_xlat45 = min(u_xlat45, 0.0);
            u_xlat8.xy = (-float2(u_xlat45)) * float2(1.0, 1.73205078) + u_xlat10.xy;
            u_xlat45 = u_xlat8.x + -0.25;
            u_xlat10.x = abs(u_xlat45) + 0.25;
            u_xlat10.y = -abs(u_xlat8.y);
            u_xlat4.xz = u_xlat2.xz * u_xlat33.xy;
            u_xlat8.xy = (-u_xlat4.xy) + u_xlat10.xy;
            u_xlatb45 = u_xlat8.x>=0.0;
            u_xlat33.x = dot(u_xlat8.xy, float2(0.5, 0.866025388));
            u_xlat33.x = min(u_xlat33.x, 0.0);
            u_xlat8.xy = (-u_xlat33.xx) * float2(1.0, 1.73205078) + u_xlat8.xy;
            u_xlat8.xy = u_xlat4.xw + u_xlat8.xy;
            u_xlat10.xy = (bool(u_xlatb45)) ? u_xlat8.xy : u_xlat10.xy;
            u_xlat10.z = -abs(u_xlat10.y);
            u_xlat8.xy = u_xlat3.xy + u_xlat10.xz;
            u_xlatb4 = u_xlat8.x>=0.0;
            u_xlat45 = dot(u_xlat8.xy, float2(0.5, 0.866025388));
            u_xlat45 = min(u_xlat45, 0.0);
            u_xlat8.xy = (-float2(u_xlat45)) * float2(1.0, 1.73205078) + u_xlat8.xy;
            u_xlat8.x = u._flake_shape_adjust1.y * 0.5 + u_xlat8.x;
            u_xlat10.xy = (bool(u_xlatb4)) ? u_xlat8.xy : u_xlat10.xz;
            u_xlat10.z = -abs(u_xlat10.y);
            u_xlat8.xy = (-u_xlat4.zw) + u_xlat10.xz;
            u_xlatb4 = u_xlat8.x>=0.0;
            u_xlat45 = dot(u_xlat8.xy, float2(0.5, 0.866025388));
            u_xlat45 = min(u_xlat45, 0.0);
            u_xlat8.xy = (-float2(u_xlat45)) * float2(1.0, 1.73205078) + u_xlat8.xy;
            u_xlat8.xy = u_xlat4.zw + u_xlat8.xy;
            u_xlat10.xy = (bool(u_xlatb4)) ? u_xlat8.xy : u_xlat10.xz;
            u_xlat10.z = -abs(u_xlat10.y);
            u_xlat4.xz = u_xlat3.zw + u_xlat10.xz;
            u_xlatb45 = u_xlat4.x>=0.0;
            u_xlat33.x = dot(u_xlat4.xz, float2(0.5, 0.866025388));
            u_xlat33.x = min(u_xlat33.x, 0.0);
            u_xlat4.xz = (-u_xlat33.xx) * float2(1.0, 1.73205078) + u_xlat4.xz;
            u_xlat4.x = u._flake_shape_adjust2.xxxy.w * 0.5 + u_xlat4.x;
            u_xlat4.xz = (bool(u_xlatb45)) ? u_xlat4.xz : u_xlat10.xz;
            u_xlat45 = max(u_xlat4.x, 0.0);
            u_xlat5.x = min(u_xlat45, 0.5);
            u_xlat8.xy = (-u_xlat5.xy) + u_xlat4.xz;
            u_xlat5.x = dot(u_xlat8.xy, u_xlat8.xy);
            u_xlat5.x = sqrt(u_xlat5.x);
            u_xlat5.x = (-u._flake_thickness) * 0.0500000007 + u_xlat5.x;
            u_xlat5.x = u_xlat40 * u_xlat5.x;
            u_xlat5.x = clamp(u_xlat5.x, 0.0, 1.0);
            u_xlat45 = u_xlat5.x * -2.0 + 3.0;
            u_xlat5.x = u_xlat5.x * u_xlat5.x;
            u_xlat31.y = u_xlat33.y * -0.125;
            u_xlat8.xy = (-u_xlat31.xy) + float2(0.5, 0.0);
            u_xlat33.x = dot(u_xlat8.xy, u_xlat8.xy);
            u_xlat33.x = sqrt(u_xlat33.x);
            u_xlat4.xz = u_xlat4.xz + (-u_xlat31.xy);
            u_xlat10.y = 0.5 / u_xlat33.x;
            u_xlat10.z = (-u_xlat31.y) / u_xlat33.x;
            u_xlat10.x = u_xlat31.y / u_xlat33.x;
            u_xlat8.x = dot(u_xlat10.yz, u_xlat4.xz);
            u_xlat8.y = dot(u_xlat10.xy, u_xlat4.xz);
            u_xlat4.x = max(u_xlat8.x, 0.0);
            u_xlat6.x = min(u_xlat33.x, u_xlat4.x);
            u_xlat4.xz = (-u_xlat6.xy) + u_xlat8.xy;
            u_xlat4.x = dot(u_xlat4.xz, u_xlat4.xz);
            u_xlat4.x = sqrt(u_xlat4.x);
            u_xlat4.x = (-u._flake_thickness) * 0.0500000007 + u_xlat4.x;
            u_xlat4.x = u_xlat40 * u_xlat4.x;
            u_xlat4.x = clamp(u_xlat4.x, 0.0, 1.0);
            u_xlat30 = u_xlat4.x * -2.0 + 3.0;
            u_xlat4.x = u_xlat4.x * u_xlat4.x;
            u_xlat4.x = u_xlat4.x * u_xlat30;
            u_xlat4.x = u_xlat45 * u_xlat5.x + u_xlat4.x;
            u_xlat5.xw = u_xlat9.xy / float2(u_xlat15);
            u_xlat30 = texture0.sample(__nv_smp, u_xlat5.xw).x;
            u_xlat5.xw = (-u_xlat9.xy) + float2(0.5, 0.5);
            u_xlat6.x = u_xlat30 * 0.600000024;
            u_xlat30 = (-u_xlat30) * 0.5 + 1.0;
            u_xlat5.x = dot(u_xlat5.xw, u_xlat5.xw);
            u_xlat5.x = (-u_xlat5.x) * 3.1400001 + 1.0;
            u_xlat30 = (-u_xlat30) + u_xlat5.x;
            u_xlat5.x = float(1.0) / u_xlat6.x;
            u_xlat30 = u_xlat30 * u_xlat5.x;
            u_xlat30 = clamp(u_xlat30, 0.0, 1.0);
            u_xlat5.x = u_xlat30 * -2.0 + 3.0;
            u_xlat30 = u_xlat30 * u_xlat30;
            u_xlat30 = u_xlat30 * u_xlat5.x;
            u_xlatb5 = u_xlat33.y>=u._feather;
            u_xlat44 = u_xlatb5 ? 1.0 : float(0.0);
            u_xlat30 = (u_xlatb5) ? 0.0 : u_xlat30;
            u_xlat4.x = u_xlat44 * u_xlat4.x + u_xlat30;
            u_xlat30 = cos(u_xlat34.x);
            u_xlat30 = abs(u_xlat30) * 0.400000006 + 0.600000024;
            u_xlat4.x = u_xlat30 * u_xlat4.x;
        } else {
            u_xlat4.x = 0.0;
        }
        u_xlat4.x = u_xlat4.x * u._opacity;
        u_xlat30 = u_xlat32 + -1.0;
        u_xlat30 = u_xlat41 * u_xlat30;
        u_xlat30 = clamp(u_xlat30, 0.0, 1.0);
        u_xlat5.x = u_xlat30 * -2.0 + 3.0;
        u_xlat30 = u_xlat30 * u_xlat30;
        u_xlat30 = u_xlat30 * u_xlat5.x;
        u_xlat7 = u_xlat4.x * u_xlat30 + u_xlat7;
    }
    u_xlat0.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u._color.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat7);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.w = 1.0;
    u_xlat0 = u_xlat0 + u_xlat1;
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
