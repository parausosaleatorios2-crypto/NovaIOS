// ---------------------------------------------------------------------------
// Effect Trail Ripple (NV)
// origem : assets/effects/nv-nodevideo-effect-trail-ripple.xml
// id     : nv.effect.nodevideo-effect-trail-ripple
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_trail_rippleParams {
    float _path_seg_count;
    float _evolution;
    float _spread;
    float _radius;
    float _fade;
    float _decay;
    float2 _shape_center;
    float _shape_rotation;
    float _shape_scale;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
float4 u_xlat6;
int u_xlati6;
float2 u_xlat7;
int2 u_xlati7;
float4 u_xlat8;
float2 u_xlat10;
bool u_xlatb10;
float u_xlat11;
float3 u_xlat14;
float2 u_xlat15;
bool u_xlatb15;
int2 u_xlati16;
bool u_xlatb16;
float2 u_xlat17;
float u_xlat19;
int u_xlati21;
float2 u_xlat22;
float2 u_xlat24;
float2 u_xlat25;
bool u_xlatb25;
float u_xlat28;
bool u_xlatb28;
float u_xlat29;
int u_xlati30;
float u_xlat32;
float u_xlat33;
int u_xlati33;
float u_xlat34;

fragment float4 fx_nv_nodevideo_effect_trail_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_trail_rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = float4(float4(u._spread, u._spread, u._spread, u._spread)) * float4(13.8461542, 0.0, 32.3076935, 0.0);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u_xlat1 * float4(0.227027029, 0.227027029, 0.227027029, 0.227027029);
    u_xlat2 = u_xlat0.yxwz / _resolution.xyxy;
    u_xlat3 = u_xlat2 + in.acScreenNorm.xyxy;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat4 = u_xlat4 * float4(0.31621623, 0.31621623, 0.31621623, 0.31621623) + u_xlat1;
    u_xlat2 = (-u_xlat2) + in.acScreenNorm.xyxy;
    u_xlat5 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat4 = u_xlat5 * float4(0.31621623, 0.31621623, 0.31621623, 0.31621623) + u_xlat4;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat3 = u_xlat3 * float4(0.0702702701, 0.0702702701, 0.0702702701, 0.0702702701) + u_xlat4;
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat2 = u_xlat2 * float4(0.0702702701, 0.0702702701, 0.0702702701, 0.0702702701) + u_xlat3;
    u_xlat0 = u_xlat0 / _resolution.xyxy;
    u_xlat3 = u_xlat0 + in.acScreenNorm.xyxy;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat1 = u_xlat4 * float4(0.31621623, 0.31621623, 0.31621623, 0.31621623) + u_xlat1;
    u_xlat0 = (-u_xlat0) + in.acScreenNorm.xyxy;
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat1 = u_xlat4 * float4(0.31621623, 0.31621623, 0.31621623, 0.31621623) + u_xlat1;
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat1 = u_xlat3 * float4(0.0702702701, 0.0702702701, 0.0702702701, 0.0702702701) + u_xlat1;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.zw);
    u_xlat0 = u_xlat0 * float4(0.0702702701, 0.0702702701, 0.0702702701, 0.0702702701) + u_xlat1;
    u_xlat0 = u_xlat0 + u_xlat2;
    u_xlat1.x = (-u._decay) + 1.0;
    u_xlat1.x = u_xlat1.x * 0.00999999978 + 0.49000001;
    u_xlatb10 = u._fade<0;
    if(u_xlatb10){
        u_xlat10.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat2.xy = float2(u._shape_center.x, u._shape_center.y) + float2(-0.5, -0.5);
        u_xlat10.xy = u_xlat10.xy + (-u_xlat2.xy);
        u_xlat10.xy = u_xlat10.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat28 = u._shape_rotation * 0.0174532924;
        u_xlat2.x = sin(u_xlat28);
        u_xlat3.x = cos(u_xlat28);
        u_xlat4.x = sin((-u_xlat28));
        u_xlat4.y = u_xlat3.x;
        u_xlat4.z = u_xlat2.x;
        u_xlat2.x = dot(u_xlat10.xy, u_xlat4.yz);
        u_xlat2.y = dot(u_xlat10.xy, u_xlat4.xy);
        u_xlat10.xy = u_xlat2.xy / float2(float2(u._shape_scale, u._shape_scale));
        u_xlatb28 = u._evolution>=(-u._evolution);
        u_xlat2.x = fract(abs(u._evolution));
        u_xlat28 = (u_xlatb28) ? u_xlat2.x : (-u_xlat2.x);
        u_xlatb2 = u_xlat28<0.0;
        u_xlat11 = u_xlat28 + 1.0;
        u_xlat28 = (u_xlatb2) ? u_xlat11 : u_xlat28;
        u_xlat2.z = 0.0;
        u_xlat29 = 0.0;
        u_xlat3.x = float(0.0);
        u_xlat3.y = float(0.0);
        u_xlat3.z = float(as_type<float>(int(0xFFFFFFFFu)));
        u_xlati30 = int(0);
        while(true){
            u_xlatb4 = u_xlati30>=u._path_seg_count;
            if(u_xlatb4){break;}
            u_xlat4.xy = (-_path_p0s[u_xlati30].xy) + _path_p0s[u_xlati30].zw;
            u_xlat22.xy = u_xlat4.xy * float2(3.0, 3.0);
            u_xlat5 = (-_path_p0s[u_xlati30].zxwy) + _path_p1s[u_xlati30].zxwy;
            u_xlat5.xz = u_xlat5.xz * float2(3.0, 3.0) + (-u_xlat22.xy);
            u_xlat4.xy = (-u_xlat4.xy) * float2(3.0, 3.0) + u_xlat5.yw;
            u_xlat4.xy = (-u_xlat5.xz) + u_xlat4.xy;
            u_xlat2.xy = u_xlat3.xy;
            u_xlat14.x = u_xlat29;
            u_xlat32 = u_xlat3.z;
            u_xlati6 = 0;
            while(true){
                u_xlatb15 = u_xlati6>=50;
                if(u_xlatb15){break;}
                u_xlat15.x = float(u_xlati6);
                u_xlat15.x = u_xlat15.x * 0.0204081628;
                u_xlat24.x = u_xlat15.x * u_xlat15.x;
                u_xlat33 = u_xlat15.x * u_xlat24.x;
                u_xlat7.xy = u_xlat5.xz * u_xlat24.xx;
                u_xlat24.xy = u_xlat4.xy * float2(u_xlat33) + u_xlat7.xy;
                u_xlat15.xy = u_xlat22.xy * u_xlat15.xx + u_xlat24.xy;
                u_xlat15.xy = u_xlat15.xy + _path_p0s[u_xlati30].xy;
                if(uint(as_type<uint>(u_xlat32)) != uint(0)) {
                    u_xlati33 = u_xlati6 + 1;
                    u_xlat32 = 0.0;
                    u_xlat2.xy = u_xlat15.xy;
                    u_xlati6 = u_xlati33;
                    continue;
                }
                u_xlat7.xy = (-u_xlat2.xy) + u_xlat15.xy;
                u_xlat33 = dot(u_xlat7.xy, u_xlat7.xy);
                u_xlat33 = sqrt(u_xlat33);
                u_xlat14.x = u_xlat14.x + u_xlat33;
                u_xlat2.xy = u_xlat15.xy;
                u_xlati6 = u_xlati6 + 1;
                u_xlat32 = 0.0;
            }
            u_xlat29 = u_xlat14.x;
            u_xlati30 = u_xlati30 + 1;
            u_xlat3.xyz = u_xlat2.xyz;
        }
        u_xlat28 = u_xlat28 * u_xlat29;
        u_xlat2.x = float(0.0);
        u_xlat2.y = float(0.0);
        u_xlat2.z = float(0.0);
        u_xlat2.w = float(as_type<float>(int(0xFFFFFFFFu)));
        u_xlat3.x = float(0.0);
        u_xlat3.y = float(0.0);
        u_xlati21 = int(0);
        u_xlati30 = int(0);
        while(true){
            u_xlatb4 = u_xlati21>=u._path_seg_count;
            u_xlati30 = 0;
            if(u_xlatb4){break;}
            u_xlat4.xy = (-_path_p0s[u_xlati21].xy) + _path_p0s[u_xlati21].zw;
            u_xlat22.xy = u_xlat4.xy * float2(3.0, 3.0);
            u_xlat5 = (-_path_p0s[u_xlati21].zxwy) + _path_p1s[u_xlati21].zxwy;
            u_xlat5.xz = u_xlat5.xz * float2(3.0, 3.0) + (-u_xlat22.xy);
            u_xlat4.xy = (-u_xlat4.xy) * float2(3.0, 3.0) + u_xlat5.yw;
            u_xlat4.xy = (-u_xlat5.xz) + u_xlat4.xy;
            u_xlat14.xz = u_xlat3.xy;
            u_xlat6 = u_xlat2;
            u_xlati7.x = int(0);
            u_xlati16.x = int(0);
            while(true){
                u_xlatb25 = u_xlati7.x>=50;
                u_xlati16.x = 0;
                if(u_xlatb25){break;}
                u_xlat25.x = float(u_xlati7.x);
                u_xlat25.x = u_xlat25.x * 0.0204081628;
                u_xlat34 = u_xlat25.x * u_xlat25.x;
                u_xlat8.x = u_xlat25.x * u_xlat34;
                u_xlat17.xy = u_xlat5.xz * float2(u_xlat34);
                u_xlat8.xy = u_xlat4.xy * u_xlat8.xx + u_xlat17.xy;
                u_xlat25.xy = u_xlat22.xy * u_xlat25.xx + u_xlat8.xy;
                u_xlat8.yz = u_xlat25.xy + _path_p0s[u_xlati21].xy;
                if(uint(as_type<uint>(u_xlat6.w)) != uint(0)) {
                    u_xlati16.y = u_xlati7.x + 1;
                    u_xlat8.x = u_xlat6.x;
                    u_xlat6.w = 0.0;
                    u_xlati16.x = 0;
                    u_xlat6.xyz = u_xlat8.xyz;
                    u_xlati7.xy = u_xlati16.yx;
                    continue;
                }
                u_xlat25.xy = (-u_xlat6.yz) + u_xlat8.yz;
                u_xlat25.x = dot(u_xlat25.xy, u_xlat25.xy);
                u_xlat25.x = sqrt(u_xlat25.x);
                u_xlat8.w = u_xlat6.x + u_xlat25.x;
                u_xlatb25 = u_xlat8.w>=u_xlat28;
                if(u_xlatb25){
                    u_xlat6.xyz = u_xlat8.wyz;
                    u_xlat6.w = 0.0;
                    u_xlati16.x = int(0xFFFFFFFFu);
                    u_xlat14.xz = u_xlat8.yz;
                    break;
                }
                u_xlat6.xyz = u_xlat8.wyz;
                u_xlatb16 = u_xlatb25;
                u_xlati7.x = u_xlati7.x + 1;
                u_xlat6.w = 0.0;
            }
            u_xlat2 = u_xlat6;
            u_xlat3.xy = u_xlat14.xz;
            u_xlati30 = u_xlati16.x;
            if(u_xlati16.x != 0) {break;}
            u_xlati21 = u_xlati21 + 1;
            u_xlat3.xy = u_xlat14.xz;
            u_xlati30 = u_xlati16.x;
        }
        u_xlat2.xy = as_type<float>(uint2(uint(as_type<uint>(u_xlat3.x)) & uint(u_xlati30), uint(as_type<uint>(u_xlat3.y)) & uint(u_xlati30)));
        u_xlat10.xy = u_xlat10.xy + (-u_xlat2.xy);
        u_xlat10.x = dot(u_xlat10.xy, u_xlat10.xy);
        u_xlat10.x = sqrt(u_xlat10.x);
        u_xlat19 = u._radius * 0.0399999991;
        u_xlat10.x = u._radius * 0.100000001 + (-u_xlat10.x);
        u_xlat19 = float(1.0) / u_xlat19;
        u_xlat10.x = u_xlat19 * u_xlat10.x;
        u_xlat10.x = clamp(u_xlat10.x, 0.0, 1.0);
        u_xlat19 = u_xlat10.x * -2.0 + 3.0;
        u_xlat10.x = u_xlat10.x * u_xlat10.x;
        u_xlat10.x = (-u_xlat19) * u_xlat10.x + 1.0;
        u_xlat10.x = u_xlat10.x * 1.60000002;
    } else {
        u_xlat10.x = 0.0;
    }
    __nv_out = u_xlat0 * u_xlat1.xxxx + u_xlat10.xxxx;
    return __nv_out;
    return __nv_out;
}
