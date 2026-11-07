// ---------------------------------------------------------------------------
// Water Reflection4 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-water-reflection4.xml
// id     : nv.effect.nodevideo-assetstore-water-reflection4
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_water_reflection4Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _horizontal_line;
    float _perspective;
    float _distortion;
    float _feather;
    float _edge_blur;
    float _direction;
    float _speed;
    float _spread;
    float4 _color;
    float4 _light_color;
    float3 _light_pos;
    float _light_intensity;
    float _enable_light;
    float _complexity;
    float _octaves;
    float _turbulence;
    float _offset;
    float _intensity;
    float _enable_ripples;
    float _intensity2;
    float _duration;
    float _speed2;
    float _width;
    float _height;
    float _scale2;
    float2 _offset2;
    float _complexity2;
    float _amount;
    float _seed;
    float2 _scale;
    float _type;
    float _width1;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
bool2 u_xlatb0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool u_xlatb2;
float4 u_xlat3;
int2 u_xlati3;
float4 u_xlat4;
float4 u_xlat5;
bool4 u_xlatb5;
float4 u_xlat6;
int u_xlati6;
float4 u_xlat7;
bool u_xlatb7;
float4 u_xlat8;
float4 u_xlat9;
float4 u_xlat10;
bool u_xlatb10;
float4 u_xlat11;
float3 u_xlat12;
float3 u_xlat13;
float3 u_xlat14;
bool u_xlatb15;
float3 u_xlat16;
float3 u_xlat17;
float3 u_xlat19;
int u_xlati19;
float3 u_xlat21;
float3 u_xlat22;
float u_xlat23;
float u_xlat24;
float3 u_xlat25;
float2 u_xlat30;
float2 u_xlat31;
bool2 u_xlatb31;
float u_xlat32;
float2 u_xlat33;
float2 u_xlat34;
int u_xlati34;
bool u_xlatb34;
float2 u_xlat35;
int u_xlati35;
bool u_xlatb35;
float2 u_xlat36;
bool u_xlatb36;
float2 u_xlat37;
bool u_xlatb37;
float2 u_xlat38;
float2 u_xlat39;
float2 u_xlat40;
float2 u_xlat42;
float u_xlat45;
bool u_xlatb45;
float u_xlat46;
int u_xlati46;
bool u_xlatb46;
float u_xlat47;
int u_xlati47;
float u_xlat48;
int u_xlati48;
bool u_xlatb48;
float u_xlat49;
int u_xlati49;
bool u_xlatb49;
float u_xlat50;
int u_xlati50;
bool u_xlatb50;
float u_xlat51;
bool u_xlatb51;
float u_xlat52;
bool u_xlatb52;
float u_xlat53;
bool u_xlatb53;
float u_xlat54;
bool u_xlatb54;

fragment float4 fx_nv_nodevideo_assetstore_water_reflection4(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_water_reflection4Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> texture1 [[texture(2)]],
    texture2d<float> texture2 [[texture(3)]],
    texture2d<float> texture3 [[texture(4)]],
    texture2d<float> texture4 [[texture(5)]],
    texture2d<float> displacement_source [[texture(6)]],
    texture2d<float> Mask [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(2.0, 2.0) + float2(-1.0, -1.0);
    u_xlat30.x = u._perspective * 10.0;
    u_xlat45 = (-u._horizontal_line) + 1.0;
    u_xlat16.y = (-u._horizontal_line) + 0.5;
    u_xlat16.x = float(0.0);
    u_xlat16.z = float(1.0);
    u_xlat1.x = dot(u_xlat16.yz, u_xlat16.yz);
    u_xlat2.x = rsqrt(u_xlat1.x);
    u_xlat2.yzw = u_xlat16.xyz * u_xlat2.xxx;
    u_xlat1.xy = u_xlat2.xx * float2(1.0, 0.0);
    u_xlat1.z = 0.0;
    u_xlat46 = u_xlat1.x * u_xlat1.x;
    u_xlat46 = rsqrt(u_xlat46);
    u_xlat1.xyz = float3(u_xlat46) * u_xlat1.xyz;
    u_xlat3.xy = u_xlat1.zx * u_xlat2.zw;
    u_xlat3.z = 0.0;
    u_xlat3.xyz = (-u_xlat2.wyz) * u_xlat1.yzx + u_xlat3.xyz;
    u_xlat46 = dot(u_xlat3.yz, u_xlat3.yz);
    u_xlat46 = rsqrt(u_xlat46);
    u_xlat3.xyz = float3(u_xlat46) * u_xlat3.xyz;
    u_xlat3.xyz = u_xlat0.yyy * u_xlat3.xyz;
    u_xlat1.xyz = u_xlat0.xxx * u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.xyz = u_xlat2.xzx * float3(0.0, 2.5, 2.5) + u_xlat1.xyz;
    u_xlat0.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat0.x = rsqrt(u_xlat0.x);
    u_xlat1.xyz = u_xlat0.xxx * u_xlat1.xyz;
    u_xlat0.x = (-u_xlat30.x) / u_xlat1.y;
    u_xlatb15 = 0.0<u_xlat0.x;
    if(u_xlatb15){
        u_xlat2.xyz = u_xlat1.xyz * u_xlat0.xxx;
        if(int(u._type) == 0) {
            u_xlati3.xy = int2(float2(u._complexity, u._octaves));
            u_xlat30.x = trunc(u._complexity);
            u_xlat30.x = (-u_xlat30.x) + 1.0;
            u_xlat33.xy = u_xlat30.xx * float2(-0.378511608, 0.757023215);
            u_xlat33.xy = exp2(u_xlat33.xy);
            u_xlat30.x = u_xlat33.y * 0.25;
            u_xlat4.xy = u_xlat2.xz * float2(0.5, 0.5);
            u_xlat46 = u._direction * 0.0174532942;
            u_xlat48 = sin((-u_xlat46));
            u_xlat46 = cos(u_xlat46);
            u_xlat34.x = u._intensity * 0.100000001;
            u_xlat5.x = float(0.0);
            u_xlat5.y = float(0.0);
            u_xlat5.z = float(0.0);
            u_xlat6.x = u_xlat33.x;
            u_xlat6.y = u_xlat30.x;
            u_xlat7.x = u_xlat48;
            u_xlat7.z = u_xlat46;
            u_xlat49 = 0.0;
            u_xlati50 = u_xlati3.y;
            while(true){
                u_xlatb36 = u_xlati50>=u_xlati3.x;
                if(u_xlatb36){break;}
                u_xlat36.x = dot((-u_xlat7.xz), u_xlat4.xy);
                u_xlat51 = float(u_xlati50);
                u_xlat36.x = u_xlat51 + u_xlat36.x;
                u_xlat8.xy = u_xlat6.xx * u_xlat6.xy;
                u_xlat51 = u_xlat34.x * u_xlat8.x;
                u_xlat51 = u_xlat6.x * u_xlat51;
                u_xlat51 = u._turbulence * u_xlat6.x + u_xlat51;
                u_xlat8.xzw = u_xlat6.xxy * float3(25.0, 0.769230783, 1.68999994);
                u_xlat52 = u_xlat8.x * u_xlat8.x;
                u_xlat9.x = u_xlat8.x * u_xlat8.x + 27.0;
                u_xlat8.x = u_xlat8.x * u_xlat9.x;
                u_xlat52 = u_xlat52 * 9.0 + 27.0;
                u_xlat52 = u_xlat8.x / u_xlat52;
                u_xlat52 = max(u_xlat52, -1.0);
                u_xlat52 = min(u_xlat52, 1.0);
                u_xlat51 = u_xlat51 * u_xlat52;
                u_xlat51 = sqrt(u_xlat51);
                u_xlat51 = u_xlat51 * _cur_time;
                u_xlat51 = u_xlat51 * u._speed;
                u_xlat52 = u_xlat36.x * u_xlat6.x + u_xlat51;
                u_xlat52 = sin(u_xlat52);
                u_xlat49 = u_xlat6.y * u_xlat52 + u_xlat49;
                u_xlat36.x = (-u_xlat36.x) * u_xlat6.x + u_xlat51;
                u_xlat36.x = cos(u_xlat36.x);
                u_xlat7.y = u_xlat36.x * u_xlat8.y;
                u_xlat5.xyz = u_xlat5.xyz + u_xlat7.xyz;
                u_xlat8.x = dot(u_xlat7.xz, float2(0.49999997, 0.866025448));
                u_xlat8.y = dot(u_xlat7.xz, float2(-0.866025448, 0.49999997));
                u_xlati50 = u_xlati50 + 1;
                u_xlat6.xy = u_xlat8.zw;
                u_xlat7.xz = u_xlat8.xy;
            }
            u_xlat7.xyz = u_xlat5.xyz;
            u_xlat3.xz = u_xlat6.xy;
            u_xlat8.x = u_xlat48;
            u_xlat8.z = u_xlat46;
            u_xlat30.x = u_xlat49;
            u_xlati34 = 0;
            while(true){
                u_xlatb50 = u_xlati34>=u_xlati3.y;
                if(u_xlatb50){break;}
                u_xlat50 = dot(u_xlat8.xz, u_xlat4.xy);
                u_xlat36.x = float(u_xlati34);
                u_xlat50 = u_xlat50 + u_xlat36.x;
                u_xlat51 = u_xlat3.x * u._turbulence;
                u_xlat9.xyz = u_xlat3.xxz * float3(25.0, 0.769230783, 1.68999994);
                u_xlat52 = u_xlat9.x * u_xlat9.x;
                u_xlat53 = u_xlat9.x * u_xlat9.x + 27.0;
                u_xlat53 = u_xlat53 * u_xlat9.x;
                u_xlat52 = u_xlat52 * 9.0 + 27.0;
                u_xlat52 = u_xlat53 / u_xlat52;
                u_xlat52 = max(u_xlat52, -1.0);
                u_xlat52 = min(u_xlat52, 1.0);
                u_xlat51 = u_xlat51 * u_xlat52;
                u_xlat51 = sqrt(u_xlat51);
                u_xlat51 = u_xlat51 * _cur_time;
                u_xlat51 = u_xlat51 * u._speed;
                u_xlat50 = u_xlat50 * u_xlat3.x + u_xlat51;
                u_xlat9.x = sin(u_xlat50);
                u_xlat10.x = cos(u_xlat50);
                u_xlat30.x = u_xlat3.z * u_xlat9.x + u_xlat30.x;
                u_xlat50 = u_xlat3.x * u_xlat3.z;
                u_xlat8.y = u_xlat10.x * u_xlat50;
                u_xlat7.xyz = u_xlat7.xyz + u_xlat8.xyz;
                u_xlatb50 = u_xlat36.x>=2.0;
                u_xlat10.xyz = (bool(u_xlatb50)) ? float3(0.540302277, -0.841470957, 0.540302277) : float3(1.0, -0.0, 1.0);
                u_xlat10.xyz = u_xlat8.xzz * u_xlat10.xyz;
                u_xlat10.x = u_xlat10.y + u_xlat10.x;
                u_xlat50 = u_xlatb50 ? 0.841470957 : float(0.0);
                u_xlat10.y = u_xlat50 * u_xlat8.x + u_xlat10.z;
                u_xlati34 = u_xlati34 + 1;
                u_xlat3.xz = u_xlat9.yz;
                u_xlat8.xz = u_xlat10.xy;
            }
            u_xlat46 = dot(u_xlat7.xyz, u_xlat7.xyz);
            u_xlat46 = rsqrt(u_xlat46);
            u_xlat3.xyz = float3(u_xlat46) * u_xlat7.xyz;
            u_xlat3.w = (-u_xlat3.x);
            u_xlat46 = dot(u_xlat3.zw, u_xlat3.zw);
            u_xlat46 = rsqrt(u_xlat46);
            u_xlat4.z = u_xlat46 * u_xlat3.z;
            u_xlat4.x = 0.0;
            u_xlat4.y = u_xlat46 * (-u_xlat3.x);
            u_xlat5.xyz = u_xlat3.zxy * u_xlat4.xyz;
            u_xlat3.xyz = u_xlat3.yzx * u_xlat4.yzx + (-u_xlat5.xyz);
        } else {
            u_xlat4.w = u._perspective * 10.0 + u_xlat2.y;
            u_xlat46 = (-u._spread) + 1.0;
            u_xlat17.x = log2(u_xlat2.z);
            u_xlat17.x = u_xlat46 * u_xlat17.x;
            u_xlat2.w = exp2(u_xlat17.x);
            u_xlat17.x = _cur_time * u._speed;
            u_xlatb5 = equal(int4(int(u._type)), int4(3, 2, 4, 1));
            u_xlat6.xy = float2(u._scale.x, u._scale.y) + float2(u._scale.x, u._scale.y);
            u_xlat6.xy = (u_xlatb5.x) ? u_xlat6.xy : float2(u._scale.x, u._scale.y);
            u_xlatb48 = u_xlatb5.z || u_xlatb5.y;
            u_xlat36.xy = u_xlat6.xy * float2(0.5, 0.5);
            u_xlat6.xy = (bool(u_xlatb48)) ? u_xlat36.xy : u_xlat6.xy;
            u_xlat48 = u._direction + 25.0;
            u_xlat48 = u_xlat48 * 0.0174532942;
            u_xlat7.x = sin(u_xlat48);
            u_xlat8.x = cos(u_xlat48);
            u_xlat9.x = sin((-u_xlat48));
            u_xlat22.xyz = u_xlat17.xxx * float3(0.462000012, 0.582120001, 1.15499997);
            u_xlat9.y = u_xlat8.x;
            u_xlat8.x = dot(u_xlat9.yx, u_xlat22.xx);
            u_xlat9.z = u_xlat7.x;
            u_xlat8.y = dot(u_xlat9.zy, u_xlat22.xx);
            u_xlat36.xy = u_xlat2.xw + u_xlat8.xy;
            u_xlat36.xy = u_xlat6.xy * u_xlat36.xy;
            u_xlat36.xy = u_xlat36.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat10.xyz = texture1.sample(__nv_smp, u_xlat36.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat10.xyz = texture2.sample(__nv_smp, u_xlat36.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat10.xyz = texture3.sample(__nv_smp, u_xlat36.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb7 = int(u._type)==5;
                            if(u_xlatb7){
                                u_xlat10.xyz = texture4.sample(__nv_smp, u_xlat36.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat7.xy = fract(u_xlat36.xy);
                                    u_xlat10.xyz = displacement_source.sample(__nv_smp, u_xlat7.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
            }
            u_xlat7.x = dot(u_xlat9.yx, u_xlat22.yz);
            u_xlat7.y = dot(u_xlat9.zy, u_xlat22.yz);
            u_xlat36.xy = u_xlat2.xw + u_xlat7.xy;
            u_xlat36.xy = u_xlat6.xy * u_xlat36.xy;
            u_xlat36.xy = u_xlat36.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat11.xyz = texture1.sample(__nv_smp, u_xlat36.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat11.xyz = texture2.sample(__nv_smp, u_xlat36.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat11.xyz = texture3.sample(__nv_smp, u_xlat36.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb37 = int(u._type)==5;
                            if(u_xlatb37){
                                u_xlat11.xyz = texture4.sample(__nv_smp, u_xlat36.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat37.xy = fract(u_xlat36.xy);
                                    u_xlat11.xyz = displacement_source.sample(__nv_smp, u_xlat37.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
            }
            u_xlat36.xy = u_xlat17.xx * float2(0.76692003, 2.079);
            u_xlat12.x = dot(u_xlat9.yx, u_xlat36.xy);
            u_xlat12.y = dot(u_xlat9.zy, u_xlat36.xy);
            u_xlat17.xz = u_xlat2.xw + u_xlat12.xy;
            u_xlat17.xz = u_xlat6.xy * u_xlat17.xz;
            u_xlat17.xz = u_xlat17.xz * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat17.xz).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat17.xz).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat17.xz).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat17.xz).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb36 = int(u._type)==5;
                            if(u_xlatb36){
                                u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat17.xz).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat36.xy = fract(u_xlat17.xz);
                                    u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat36.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat17.xz).xyz;
            }
            u_xlat9.xyz = (-u_xlat9.xyz) + u_xlat11.xyz;
            u_xlat9.xyz = u_xlat9.xyz + u_xlat10.xyz;
            u_xlat17.x = u_xlat9.y + u_xlat9.x;
            u_xlat17.x = u_xlat9.z + u_xlat17.x;
            u_xlat17.x = u_xlat17.x * 0.0833333358 + u_xlat4.w;
            u_xlat17.x = u_xlat17.x + u_xlat17.x;
            u_xlat4.xy = u_xlat17.xx * u_xlat1.xz + u_xlat2.xz;
            u_xlat2.x = log2(u_xlat4.y);
            u_xlat2.x = u_xlat46 * u_xlat2.x;
            u_xlat4.z = exp2(u_xlat2.x);
            u_xlat2.xy = u_xlat8.xy + u_xlat4.xz;
            u_xlat2.xy = u_xlat6.xy * u_xlat2.xy;
            u_xlat2.xy = u_xlat2.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
                u_xlati47 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat2.xy).xyz;
                    u_xlati47 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat2.xy).xyz;
                        u_xlati47 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat2.xy).xyz;
                            u_xlati47 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat2.xy).xyz;
                                u_xlati47 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati47 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati47 != 0) {
                                    u_xlat36.xy = fract(u_xlat2.xy);
                                    u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat36.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati47 == 0) {
                u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
            }
            u_xlat36.xy = u_xlat7.xy + u_xlat4.xz;
            u_xlat36.xy = u_xlat6.xy * u_xlat36.xy;
            u_xlat6.zw = u_xlat36.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat6.zw).xyz;
                u_xlati47 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat10.xyz = texture1.sample(__nv_smp, u_xlat6.zw).xyz;
                    u_xlati47 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat10.xyz = texture2.sample(__nv_smp, u_xlat6.zw).xyz;
                        u_xlati47 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat10.xyz = texture3.sample(__nv_smp, u_xlat6.zw).xyz;
                            u_xlati47 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat10.xyz = texture4.sample(__nv_smp, u_xlat6.zw).xyz;
                                u_xlati47 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati47 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati47 != 0) {
                                    u_xlat37.xy = fract(u_xlat6.zw);
                                    u_xlat10.xyz = displacement_source.sample(__nv_smp, u_xlat37.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati47 == 0) {
                u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat6.zw).xyz;
            }
            u_xlat37.xy = u_xlat12.xy + u_xlat4.xz;
            u_xlat37.xy = u_xlat6.xy * u_xlat37.xy;
            u_xlat7.zw = u_xlat37.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat7.zw).xyz;
                u_xlati47 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat11.xyz = texture1.sample(__nv_smp, u_xlat7.zw).xyz;
                    u_xlati47 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat11.xyz = texture2.sample(__nv_smp, u_xlat7.zw).xyz;
                        u_xlati47 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat11.xyz = texture3.sample(__nv_smp, u_xlat7.zw).xyz;
                            u_xlati47 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat11.xyz = texture4.sample(__nv_smp, u_xlat7.zw).xyz;
                                u_xlati47 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati47 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati47 != 0) {
                                    u_xlat38.xy = fract(u_xlat7.zw);
                                    u_xlat11.xyz = displacement_source.sample(__nv_smp, u_xlat38.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati47 == 0) {
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat7.zw).xyz;
            }
            u_xlat10.xyz = u_xlat10.xyz + (-u_xlat11.xyz);
            u_xlat9.xyz = u_xlat9.xyz + u_xlat10.xyz;
            u_xlat47 = u_xlat9.y + u_xlat9.x;
            u_xlat47 = u_xlat9.z + u_xlat47;
            u_xlat47 = u_xlat47 * 0.0833333358 + u_xlat4.w;
            u_xlat48 = max(u._width1, 0.00999999978);
            u_xlat9.z = min(u_xlat48, 100.0);
            u_xlat9.x = float(0.0);
            u_xlat9.y = float(0.0);
            u_xlat10.xyz = u_xlat4.xwy + u_xlat9.zyy;
            u_xlat48 = log2(u_xlat10.z);
            u_xlat48 = u_xlat46 * u_xlat48;
            u_xlat10.w = exp2(u_xlat48);
            u_xlat38.xy = u_xlat8.xy + u_xlat10.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat38.xy = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat11.xyz = texture1.sample(__nv_smp, u_xlat38.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat11.xyz = texture2.sample(__nv_smp, u_xlat38.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat11.xyz = texture3.sample(__nv_smp, u_xlat38.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat11.xyz = texture4.sample(__nv_smp, u_xlat38.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat38.xy);
                                    u_xlat11.xyz = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
            }
            u_xlat38.xy = u_xlat7.xy + u_xlat10.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat38.xy = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat13.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat13.xyz = texture1.sample(__nv_smp, u_xlat38.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat13.xyz = texture2.sample(__nv_smp, u_xlat38.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat13.xyz = texture3.sample(__nv_smp, u_xlat38.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat13.xyz = texture4.sample(__nv_smp, u_xlat38.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat38.xy);
                                    u_xlat13.xyz = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat13.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
            }
            u_xlat38.xy = u_xlat12.xy + u_xlat10.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat38.xy = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat10.xzw = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat10.xzw = texture1.sample(__nv_smp, u_xlat38.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat10.xzw = texture2.sample(__nv_smp, u_xlat38.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat10.xzw = texture3.sample(__nv_smp, u_xlat38.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat10.xzw = texture4.sample(__nv_smp, u_xlat38.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat38.xy);
                                    u_xlat10.xzw = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat10.xzw = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
            }
            u_xlat10.xzw = (-u_xlat10.xzw) + u_xlat13.xyz;
            u_xlat10.xzw = u_xlat10.xzw + u_xlat11.xyz;
            u_xlat48 = u_xlat10.z + u_xlat10.x;
            u_xlat48 = u_xlat10.w + u_xlat48;
            u_xlat10.x = u_xlat48 * 0.0833333358 + u_xlat10.y;
            u_xlat11.xyz = u_xlat4.xwy + u_xlat9.yzy;
            u_xlat48 = log2(u_xlat11.z);
            u_xlat48 = u_xlat46 * u_xlat48;
            u_xlat11.w = exp2(u_xlat48);
            u_xlat38.xy = u_xlat8.xy + u_xlat11.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat38.xy = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat13.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat13.xyz = texture1.sample(__nv_smp, u_xlat38.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat13.xyz = texture2.sample(__nv_smp, u_xlat38.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat13.xyz = texture3.sample(__nv_smp, u_xlat38.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat13.xyz = texture4.sample(__nv_smp, u_xlat38.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat38.xy);
                                    u_xlat13.xyz = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat13.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
            }
            u_xlat38.xy = u_xlat7.xy + u_xlat11.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat38.xy = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat14.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat14.xyz = texture1.sample(__nv_smp, u_xlat38.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat14.xyz = texture2.sample(__nv_smp, u_xlat38.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat14.xyz = texture3.sample(__nv_smp, u_xlat38.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat14.xyz = texture4.sample(__nv_smp, u_xlat38.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat38.xy);
                                    u_xlat14.xyz = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat14.xyz = texture0.sample(__nv_smp, u_xlat38.xy).xyz;
            }
            u_xlat38.xy = u_xlat12.xy + u_xlat11.xw;
            u_xlat38.xy = u_xlat6.xy * u_xlat38.xy;
            u_xlat8.zw = u_xlat38.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat11.xzw = texture0.sample(__nv_smp, u_xlat8.zw).xyz;
                u_xlati48 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat11.xzw = texture1.sample(__nv_smp, u_xlat8.zw).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat11.xzw = texture2.sample(__nv_smp, u_xlat8.zw).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat11.xzw = texture3.sample(__nv_smp, u_xlat8.zw).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb34 = int(u._type)==5;
                            if(u_xlatb34){
                                u_xlat11.xzw = texture4.sample(__nv_smp, u_xlat8.zw).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati48 != 0) {
                                    u_xlat42.xy = fract(u_xlat8.zw);
                                    u_xlat11.xzw = displacement_source.sample(__nv_smp, u_xlat42.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati48 == 0) {
                u_xlat11.xzw = texture0.sample(__nv_smp, u_xlat8.zw).xyz;
            }
            u_xlat11.xzw = (-u_xlat11.xzw) + u_xlat14.xyz;
            u_xlat11.xzw = u_xlat11.xzw + u_xlat13.xyz;
            u_xlat48 = u_xlat11.z + u_xlat11.x;
            u_xlat48 = u_xlat11.w + u_xlat48;
            u_xlat10.y = u_xlat48 * 0.0833333358 + u_xlat11.y;
            u_xlat9.xyz = u_xlat4.xwy + u_xlat9.xyz;
            u_xlat48 = log2(u_xlat9.z);
            u_xlat46 = u_xlat46 * u_xlat48;
            u_xlat9.w = exp2(u_xlat46);
            u_xlat4.xy = u_xlat8.xy + u_xlat9.xw;
            u_xlat4.xy = u_xlat6.xy * u_xlat4.xy;
            u_xlat4.xy = u_xlat4.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat8.xyz = texture1.sample(__nv_smp, u_xlat4.xy).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat8.xyz = texture2.sample(__nv_smp, u_xlat4.xy).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat8.xyz = texture3.sample(__nv_smp, u_xlat4.xy).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat8.xyz = texture4.sample(__nv_smp, u_xlat4.xy).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat11.xy = fract(u_xlat4.xy);
                                    u_xlat8.xyz = displacement_source.sample(__nv_smp, u_xlat11.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
            }
            u_xlat4.xy = u_xlat7.xy + u_xlat9.xw;
            u_xlat4.xy = u_xlat6.xy * u_xlat4.xy;
            u_xlat4.xy = u_xlat4.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat11.xyz = texture1.sample(__nv_smp, u_xlat4.xy).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat11.xyz = texture2.sample(__nv_smp, u_xlat4.xy).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat11.xyz = texture3.sample(__nv_smp, u_xlat4.xy).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat11.xyz = texture4.sample(__nv_smp, u_xlat4.xy).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat7.xy = fract(u_xlat4.xy);
                                    u_xlat11.xyz = displacement_source.sample(__nv_smp, u_xlat7.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat11.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
            }
            u_xlat4.xy = u_xlat12.xy + u_xlat9.xw;
            u_xlat4.xy = u_xlat6.xy * u_xlat4.xy;
            u_xlat4.xy = u_xlat4.xy * float2(0.0333333351, 0.0333333351);
            if(u_xlatb5.w){
                u_xlat9.xzw = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat9.xzw = texture1.sample(__nv_smp, u_xlat4.xy).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat9.xzw = texture2.sample(__nv_smp, u_xlat4.xy).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat9.xzw = texture3.sample(__nv_smp, u_xlat4.xy).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat9.xzw = texture4.sample(__nv_smp, u_xlat4.xy).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat6.xy = fract(u_xlat4.xy);
                                    u_xlat9.xzw = displacement_source.sample(__nv_smp, u_xlat6.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat9.xzw = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
            }
            u_xlat4.xyz = (-u_xlat9.xzw) + u_xlat11.xyz;
            u_xlat4.xyz = u_xlat4.xyz + u_xlat8.xyz;
            u_xlat46 = u_xlat4.y + u_xlat4.x;
            u_xlat46 = u_xlat4.z + u_xlat46;
            u_xlat10.z = u_xlat46 * 0.0833333358 + u_xlat9.y;
            if(u_xlatb5.w){
                u_xlat4.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat4.xyz = texture1.sample(__nv_smp, u_xlat2.xy).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat4.xyz = texture2.sample(__nv_smp, u_xlat2.xy).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat4.xyz = texture3.sample(__nv_smp, u_xlat2.xy).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb48 = int(u._type)==5;
                            if(u_xlatb48){
                                u_xlat4.xyz = texture4.sample(__nv_smp, u_xlat2.xy).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat6.xy = fract(u_xlat2.xy);
                                    u_xlat4.xyz = displacement_source.sample(__nv_smp, u_xlat6.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat4.xyz = texture0.sample(__nv_smp, u_xlat2.xy).xyz;
            }
            if(u_xlatb5.w){
                u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat6.zw).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat8.xyz = texture1.sample(__nv_smp, u_xlat6.zw).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat8.xyz = texture2.sample(__nv_smp, u_xlat6.zw).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat8.xyz = texture3.sample(__nv_smp, u_xlat6.zw).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb2 = int(u._type)==5;
                            if(u_xlatb2){
                                u_xlat8.xyz = texture4.sample(__nv_smp, u_xlat6.zw).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat2.xy = fract(u_xlat6.zw);
                                    u_xlat8.xyz = displacement_source.sample(__nv_smp, u_xlat2.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat6.zw).xyz;
            }
            if(u_xlatb5.w){
                u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat7.zw).xyz;
                u_xlati46 = int(0xFFFFFFFFu);
            } else {
                if(u_xlatb5.y){
                    u_xlat6.xyz = texture1.sample(__nv_smp, u_xlat7.zw).xyz;
                    u_xlati46 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.x){
                        u_xlat6.xyz = texture2.sample(__nv_smp, u_xlat7.zw).xyz;
                        u_xlati46 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.z){
                            u_xlat6.xyz = texture3.sample(__nv_smp, u_xlat7.zw).xyz;
                            u_xlati46 = int(0xFFFFFFFFu);
                        } else {
                            u_xlatb2 = int(u._type)==5;
                            if(u_xlatb2){
                                u_xlat6.xyz = texture4.sample(__nv_smp, u_xlat7.zw).xyz;
                                u_xlati46 = int(0xFFFFFFFFu);
                            } else {
                                u_xlati46 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                if(u_xlati46 != 0) {
                                    u_xlat2.xy = fract(u_xlat7.zw);
                                    u_xlat6.xyz = displacement_source.sample(__nv_smp, u_xlat2.xy).xyz;
                                }
                            }
                        }
                    }
                }
            }
            if(u_xlati46 == 0) {
                u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat7.zw).xyz;
            }
            u_xlat5.xyz = (-u_xlat6.xyz) + u_xlat8.xyz;
            u_xlat4.xyz = u_xlat4.xyz + u_xlat5.xyz;
            u_xlat46 = u_xlat4.y + u_xlat4.x;
            u_xlat46 = u_xlat4.z + u_xlat46;
            u_xlat46 = u_xlat46 * 0.0833333358 + u_xlat4.w;
            u_xlat4.xyz = (-float3(u_xlat46)) + u_xlat10.xyz;
            u_xlat46 = dot(u_xlat4.xyz, u_xlat4.xyz);
            u_xlat46 = rsqrt(u_xlat46);
            u_xlat3.xyz = float3(u_xlat46) * u_xlat4.xyz;
            u_xlat46 = u_xlat47 * u._intensity;
            u_xlat30.x = u_xlat46 * 8.0;
        }
        u_xlat2.xy = u_xlat0.xx * float2(0.00999999978, -0.0288539007);
        u_xlat2.x = u_xlat2.x;
        u_xlat2.x = clamp(u_xlat2.x, 0.0, 1.0);
        u_xlat46 = u_xlat2.x * -2.0 + 3.0;
        u_xlat2.x = u_xlat2.x * u_xlat2.x;
        u_xlat46 = u_xlat46 * u_xlat2.x;
        u_xlat4.xyz = (-u_xlat3.xyz) + float3(0.0, 1.0, 0.0);
        u_xlat3.xyz = float3(u_xlat46) * u_xlat4.xyz + u_xlat3.xyz;
        u_xlat46 = dot(u_xlat1.xyz, u_xlat3.xyz);
        u_xlat46 = u_xlat46 + u_xlat46;
        u_xlat3.xyz = u_xlat3.xyz * (-float3(u_xlat46)) + u_xlat1.xyz;
        u_xlat46 = dot(u._light_pos.xyz, u._light_pos.xyz);
        u_xlat46 = rsqrt(u_xlat46);
        u_xlat4.xyz = float3(u_xlat46) * u._light_pos.xyz;
        u_xlat46 = dot(u_xlat3.xyz, u_xlat4.xyz);
        u_xlat46 = max(u_xlat46, 0.0);
        u_xlat4.xyz = u._light_color.xyz * float3(4.0, 4.0, 4.0);
        u_xlat46 = log2(u_xlat46);
        u_xlat46 = u_xlat46 * 900.0;
        u_xlat46 = exp2(u_xlat46);
        u_xlat4.xyz = float3(u_xlat46) * u_xlat4.xyz;
        u_xlat46 = u_xlat0.x * (-u._feather);
        u_xlat46 = u_xlat46 * 0.144269511;
        u_xlat46 = exp2(u_xlat46);
        u_xlat46 = (-u_xlat46) + 1.0;
        u_xlat2.xw = float2(u_xlat46) * (-u_xlat3.xy) + u_xlat3.xy;
        u_xlat46 = exp2(u_xlat2.y);
        u_xlat46 = (-u_xlat46) + 1.0;
        u_xlat3.xyz = float3(u_xlat46) * (-u_xlat4.xyz) + u_xlat4.xyz;
        u_xlat30.x = u_xlat30.x * 10.0;
        u_xlat30.x = u_xlat30.x / u_xlat2.z;
    } else {
        u_xlat3.x = float(0.0);
        u_xlat3.y = float(0.0);
        u_xlat3.z = float(0.0);
        u_xlat2.x = float(0.0);
        u_xlat2.w = float(0.0);
        u_xlat30.x = 0.0;
    }
    u_xlat17.xy = (-float2(u_xlat45)) + float2(1.0, 0.5);
    u_xlat45 = u_xlat17.x + (-in.acScreenNorm.y);
    u_xlat45 = u_xlat17.y * 0.600000024 + u_xlat45;
    u_xlat45 = u_xlat45 + u_xlat17.x;
    u_xlat45 = u_xlat45 + (-u._offset);
    u_xlat4.y = (u_xlatb15) ? u_xlat45 : in.acScreenNorm.y;
    u_xlat30.xy = u_xlat30.xx * u_xlat2.xw;
    u_xlat4.x = in.acScreenNorm.x;
    u_xlat30.xy = u_xlat30.xy * float2(float2(u._distortion, u._distortion)) + u_xlat4.xy;
    u_xlatb46 = 0<int(u._enable_ripples);
    if(u_xlatb46){
        if(u_xlatb15){
            u_xlat2.xyz = u_xlat1.xyz * u_xlat0.xxx;
            if(int(u._type) == 0) {
                u_xlat4.xy = as_type<float>(int2(float2(u._complexity, u._octaves)));
                u_xlat46 = trunc(u._complexity);
                u_xlat46 = (-u_xlat46) + 1.0;
                u_xlat34.xy = float2(u_xlat46) * float2(-0.378511608, 0.757023215);
                u_xlat4.zw = exp2(u_xlat34.xy);
                u_xlat46 = u_xlat4.w * 0.25;
                u_xlat5.xy = u_xlat2.xz * float2(0.5, 0.5);
                u_xlat48 = u._direction * 0.0174532942;
                u_xlat49 = sin((-u_xlat48));
                u_xlat48 = cos(u_xlat48);
                u_xlat35.x = u._intensity * 0.100000001;
                u_xlat6.y = u_xlat46;
                u_xlat7.x = u_xlat49;
                u_xlat7.y = u_xlat48;
                u_xlat50 = 0.0;
                u_xlat6.xz = u_xlat4.zy;
                while(true){
                    u_xlatb51 = as_type<int>(u_xlat6.z)>=as_type<int>(u_xlat4.x);
                    if(u_xlatb51){break;}
                    u_xlat51 = dot((-u_xlat7.xy), u_xlat5.xy);
                    u_xlat37.x = float(as_type<int>(u_xlat6.z));
                    u_xlat51 = u_xlat51 + u_xlat37.x;
                    u_xlat37.x = u_xlat6.x * u_xlat6.x;
                    u_xlat37.x = u_xlat35.x * u_xlat37.x;
                    u_xlat37.x = u_xlat6.x * u_xlat37.x;
                    u_xlat37.x = u._turbulence * u_xlat6.x + u_xlat37.x;
                    u_xlat8.xyz = u_xlat6.xxy * float3(25.0, 0.769230783, 1.68999994);
                    u_xlat52 = u_xlat8.x * u_xlat8.x;
                    u_xlat53 = u_xlat8.x * u_xlat8.x + 27.0;
                    u_xlat8.x = u_xlat53 * u_xlat8.x;
                    u_xlat52 = u_xlat52 * 9.0 + 27.0;
                    u_xlat52 = u_xlat8.x / u_xlat52;
                    u_xlat52 = max(u_xlat52, -1.0);
                    u_xlat52 = min(u_xlat52, 1.0);
                    u_xlat37.x = u_xlat52 * u_xlat37.x;
                    u_xlat37.x = sqrt(u_xlat37.x);
                    u_xlat37.x = u_xlat37.x * _cur_time;
                    u_xlat37.x = u_xlat37.x * u._speed;
                    u_xlat51 = u_xlat51 * u_xlat6.x + u_xlat37.x;
                    u_xlat51 = sin(u_xlat51);
                    u_xlat50 = u_xlat6.y * u_xlat51 + u_xlat50;
                    u_xlat9.x = dot(u_xlat7.xy, float2(0.49999997, 0.866025448));
                    u_xlat9.y = dot(u_xlat7.xy, float2(-0.866025448, 0.49999997));
                    u_xlat6.z = as_type<float>(as_type<int>(u_xlat6.z) + 1);
                    u_xlat6.xy = u_xlat8.yz;
                    u_xlat7.xy = u_xlat9.xy;
                }
                u_xlat4.xz = u_xlat6.xy;
                u_xlat7.x = u_xlat49;
                u_xlat7.y = u_xlat48;
                u_xlat46 = u_xlat50;
                u_xlati35 = 0;
                while(true){
                    u_xlatb36 = u_xlati35>=as_type<int>(u_xlat4.y);
                    if(u_xlatb36){break;}
                    u_xlat36.x = dot(u_xlat7.xy, u_xlat5.xy);
                    u_xlat51 = float(u_xlati35);
                    u_xlat36.x = u_xlat51 + u_xlat36.x;
                    u_xlat37.x = u_xlat4.x * u._turbulence;
                    u_xlat8.xyz = u_xlat4.xxz * float3(25.0, 0.769230783, 1.68999994);
                    u_xlat52 = u_xlat8.x * u_xlat8.x;
                    u_xlat53 = u_xlat8.x * u_xlat8.x + 27.0;
                    u_xlat8.x = u_xlat53 * u_xlat8.x;
                    u_xlat52 = u_xlat52 * 9.0 + 27.0;
                    u_xlat52 = u_xlat8.x / u_xlat52;
                    u_xlat52 = max(u_xlat52, -1.0);
                    u_xlat52 = min(u_xlat52, 1.0);
                    u_xlat37.x = u_xlat52 * u_xlat37.x;
                    u_xlat37.x = sqrt(u_xlat37.x);
                    u_xlat37.x = u_xlat37.x * _cur_time;
                    u_xlat37.x = u_xlat37.x * u._speed;
                    u_xlat36.x = u_xlat36.x * u_xlat4.x + u_xlat37.x;
                    u_xlat36.x = sin(u_xlat36.x);
                    u_xlat46 = u_xlat4.z * u_xlat36.x + u_xlat46;
                    u_xlatb36 = u_xlat51>=2.0;
                    u_xlat9.xyz = (bool(u_xlatb36)) ? float3(0.540302277, -0.841470957, 0.540302277) : float3(1.0, -0.0, 1.0);
                    u_xlat9.xyz = u_xlat7.xyy * u_xlat9.xyz;
                    u_xlat9.x = u_xlat9.y + u_xlat9.x;
                    u_xlat36.x = u_xlatb36 ? 0.841470957 : float(0.0);
                    u_xlat9.y = u_xlat36.x * u_xlat7.x + u_xlat9.z;
                    u_xlati35 = u_xlati35 + 1;
                    u_xlat4.xz = u_xlat8.yz;
                    u_xlat7.xy = u_xlat9.xy;
                }
            } else {
                u_xlat17.x = u._perspective * 10.0 + u_xlat2.y;
                u_xlat48 = (-u._spread) + 1.0;
                u_xlat4.x = log2(u_xlat2.z);
                u_xlat4.x = u_xlat48 * u_xlat4.x;
                u_xlat2.w = exp2(u_xlat4.x);
                u_xlat4.x = _cur_time * u._speed;
                u_xlatb5 = equal(int4(int(u._type)), int4(3, 2, 4, 1));
                u_xlat19.xy = float2(u._scale.x, u._scale.y) + float2(u._scale.x, u._scale.y);
                u_xlat19.xy = (u_xlatb5.x) ? u_xlat19.xy : float2(u._scale.x, u._scale.y);
                u_xlatb49 = u_xlatb5.z || u_xlatb5.y;
                u_xlat6.xy = u_xlat19.xy * float2(0.5, 0.5);
                u_xlat19.xy = (bool(u_xlatb49)) ? u_xlat6.xy : u_xlat19.xy;
                u_xlat49 = u._direction + 25.0;
                u_xlat49 = u_xlat49 * 0.0174532942;
                u_xlat6.x = sin(u_xlat49);
                u_xlat7.x = cos(u_xlat49);
                u_xlat8.x = sin((-u_xlat49));
                u_xlat21.xyz = u_xlat4.xxx * float3(0.462000012, 0.582120001, 1.15499997);
                u_xlat8.y = u_xlat7.x;
                u_xlat7.x = dot(u_xlat8.yx, u_xlat21.xx);
                u_xlat8.z = u_xlat6.x;
                u_xlat7.y = dot(u_xlat8.zy, u_xlat21.xx);
                u_xlat6.xy = u_xlat2.xw + u_xlat7.xy;
                u_xlat6.xy = u_xlat19.xy * u_xlat6.xy;
                u_xlat6.xy = u_xlat6.xy * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat6.xy).xyz;
                    u_xlati49 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.y){
                        u_xlat9.xyz = texture1.sample(__nv_smp, u_xlat6.xy).xyz;
                        u_xlati49 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.x){
                            u_xlat9.xyz = texture2.sample(__nv_smp, u_xlat6.xy).xyz;
                            u_xlati49 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlatb5.z){
                                u_xlat9.xyz = texture3.sample(__nv_smp, u_xlat6.xy).xyz;
                                u_xlati49 = int(0xFFFFFFFFu);
                            } else {
                                u_xlat7.z = as_type<float>((int(u._type)==5) ? 0xFFFFFFFFu : uint(0));
                                if(uint(as_type<uint>(u_xlat7.z)) != uint(0)) {
                                    u_xlat9.xyz = texture4.sample(__nv_smp, u_xlat6.xy).xyz;
                                    u_xlati49 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlati49 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(u_xlati49 != 0) {
                                        u_xlat7.zw = fract(u_xlat6.xy);
                                        u_xlat9.xyz = displacement_source.sample(__nv_smp, u_xlat7.zw).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(u_xlati49 == 0) {
                    u_xlat9.xyz = texture0.sample(__nv_smp, u_xlat6.xy).xyz;
                }
                u_xlat6.x = dot(u_xlat8.yx, u_xlat21.yz);
                u_xlat6.y = dot(u_xlat8.zy, u_xlat21.yz);
                u_xlat36.xy = u_xlat2.xw + u_xlat6.xy;
                u_xlat36.xy = u_xlat19.xy * u_xlat36.xy;
                u_xlat36.xy = u_xlat36.xy * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
                    u_xlati49 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.y){
                        u_xlat10.xyz = texture1.sample(__nv_smp, u_xlat36.xy).xyz;
                        u_xlati49 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.x){
                            u_xlat10.xyz = texture2.sample(__nv_smp, u_xlat36.xy).xyz;
                            u_xlati49 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlatb5.z){
                                u_xlat10.xyz = texture3.sample(__nv_smp, u_xlat36.xy).xyz;
                                u_xlati49 = int(0xFFFFFFFFu);
                            } else {
                                u_xlat7.z = as_type<float>((int(u._type)==5) ? 0xFFFFFFFFu : uint(0));
                                if(uint(as_type<uint>(u_xlat7.z)) != uint(0)) {
                                    u_xlat10.xyz = texture4.sample(__nv_smp, u_xlat36.xy).xyz;
                                    u_xlati49 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlati49 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(u_xlati49 != 0) {
                                        u_xlat7.zw = fract(u_xlat36.xy);
                                        u_xlat10.xyz = displacement_source.sample(__nv_smp, u_xlat7.zw).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(u_xlati49 == 0) {
                    u_xlat10.xyz = texture0.sample(__nv_smp, u_xlat36.xy).xyz;
                }
                u_xlat4.xw = u_xlat4.xx * float2(0.76692003, 2.079);
                u_xlat11.x = dot(u_xlat8.yx, u_xlat4.xw);
                u_xlat11.y = dot(u_xlat8.zy, u_xlat4.xw);
                u_xlat4.xw = u_xlat2.xw + u_xlat11.xy;
                u_xlat4.xw = u_xlat19.xy * u_xlat4.xw;
                u_xlat4.xw = u_xlat4.xw * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                    u_xlat6.z = as_type<float>(int(0xFFFFFFFFu));
                } else {
                    if(u_xlatb5.y){
                        u_xlat8.xyz = texture1.sample(__nv_smp, u_xlat4.xw).xyz;
                        u_xlat6.z = as_type<float>(int(0xFFFFFFFFu));
                    } else {
                        if(u_xlatb5.x){
                            u_xlat8.xyz = texture2.sample(__nv_smp, u_xlat4.xw).xyz;
                            u_xlat6.z = as_type<float>(int(0xFFFFFFFFu));
                        } else {
                            if(u_xlatb5.z){
                                u_xlat8.xyz = texture3.sample(__nv_smp, u_xlat4.xw).xyz;
                                u_xlat6.z = as_type<float>(int(0xFFFFFFFFu));
                            } else {
                                u_xlatb51 = int(u._type)==5;
                                if(u_xlatb51){
                                    u_xlat8.xyz = texture4.sample(__nv_smp, u_xlat4.xw).xyz;
                                    u_xlat6.z = as_type<float>(int(0xFFFFFFFFu));
                                } else {
                                    u_xlat6.z = as_type<float>((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(uint(as_type<uint>(u_xlat6.z)) != uint(0)) {
                                        u_xlat7.zw = fract(u_xlat4.xw);
                                        u_xlat8.xyz = displacement_source.sample(__nv_smp, u_xlat7.zw).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(uint(as_type<uint>(u_xlat6.z)) == uint(0)) {
                    u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                }
                u_xlat8.xyz = (-u_xlat8.xyz) + u_xlat10.xyz;
                u_xlat8.xyz = u_xlat8.xyz + u_xlat9.xyz;
                u_xlat4.x = u_xlat8.y + u_xlat8.x;
                u_xlat4.x = u_xlat8.z + u_xlat4.x;
                u_xlat4.x = u_xlat4.x * 0.0833333358 + u_xlat17.x;
                u_xlat4.x = u_xlat4.x + u_xlat4.x;
                u_xlat8.xy = u_xlat4.xx * u_xlat1.xz + u_xlat2.xz;
                u_xlat4.x = log2(u_xlat8.y);
                u_xlat48 = u_xlat48 * u_xlat4.x;
                u_xlat8.z = exp2(u_xlat48);
                u_xlat4.xw = u_xlat7.xy + u_xlat8.xz;
                u_xlat4.xw = u_xlat19.xy * u_xlat4.xw;
                u_xlat4.xw = u_xlat4.xw * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.y){
                        u_xlat7.xyz = texture1.sample(__nv_smp, u_xlat4.xw).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.x){
                            u_xlat7.xyz = texture2.sample(__nv_smp, u_xlat4.xw).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlatb5.z){
                                u_xlat7.xyz = texture3.sample(__nv_smp, u_xlat4.xw).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlat6.z = as_type<float>((int(u._type)==5) ? 0xFFFFFFFFu : uint(0));
                                if(uint(as_type<uint>(u_xlat6.z)) != uint(0)) {
                                    u_xlat7.xyz = texture4.sample(__nv_smp, u_xlat4.xw).xyz;
                                    u_xlati48 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(u_xlati48 != 0) {
                                        u_xlat6.zw = fract(u_xlat4.xw);
                                        u_xlat7.xyz = displacement_source.sample(__nv_smp, u_xlat6.zw).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(u_xlati48 == 0) {
                    u_xlat7.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                }
                u_xlat4.xw = u_xlat6.xy + u_xlat8.xz;
                u_xlat4.xw = u_xlat19.xy * u_xlat4.xw;
                u_xlat4.xw = u_xlat4.xw * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.y){
                        u_xlat6.xyz = texture1.sample(__nv_smp, u_xlat4.xw).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.x){
                            u_xlat6.xyz = texture2.sample(__nv_smp, u_xlat4.xw).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlatb5.z){
                                u_xlat6.xyz = texture3.sample(__nv_smp, u_xlat4.xw).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlatb51 = int(u._type)==5;
                                if(u_xlatb51){
                                    u_xlat6.xyz = texture4.sample(__nv_smp, u_xlat4.xw).xyz;
                                    u_xlati48 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(u_xlati48 != 0) {
                                        u_xlat8.yw = fract(u_xlat4.xw);
                                        u_xlat6.xyz = displacement_source.sample(__nv_smp, u_xlat8.yw).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(u_xlati48 == 0) {
                    u_xlat6.xyz = texture0.sample(__nv_smp, u_xlat4.xw).xyz;
                }
                u_xlat4.xw = u_xlat11.xy + u_xlat8.xz;
                u_xlat4.xy = u_xlat19.xy * u_xlat4.xw;
                u_xlat4.xy = u_xlat4.xy * float2(0.0333333351, 0.0333333351);
                if(u_xlatb5.w){
                    u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
                    u_xlati48 = int(0xFFFFFFFFu);
                } else {
                    if(u_xlatb5.y){
                        u_xlat8.xyz = texture1.sample(__nv_smp, u_xlat4.xy).xyz;
                        u_xlati48 = int(0xFFFFFFFFu);
                    } else {
                        if(u_xlatb5.x){
                            u_xlat8.xyz = texture2.sample(__nv_smp, u_xlat4.xy).xyz;
                            u_xlati48 = int(0xFFFFFFFFu);
                        } else {
                            if(u_xlatb5.z){
                                u_xlat8.xyz = texture3.sample(__nv_smp, u_xlat4.xy).xyz;
                                u_xlati48 = int(0xFFFFFFFFu);
                            } else {
                                u_xlatb34 = int(u._type)==5;
                                if(u_xlatb34){
                                    u_xlat8.xyz = texture4.sample(__nv_smp, u_xlat4.xy).xyz;
                                    u_xlati48 = int(0xFFFFFFFFu);
                                } else {
                                    u_xlati48 = int((int(u._type)==6) ? 0xFFFFFFFFu : uint(0));
                                    if(u_xlati48 != 0) {
                                        u_xlat34.xy = fract(u_xlat4.xy);
                                        u_xlat8.xyz = displacement_source.sample(__nv_smp, u_xlat34.xy).xyz;
                                    }
                                }
                            }
                        }
                    }
                }
                if(u_xlati48 == 0) {
                    u_xlat8.xyz = texture0.sample(__nv_smp, u_xlat4.xy).xyz;
                }
                u_xlat4.xyz = u_xlat6.xyz + (-u_xlat8.xyz);
                u_xlat4.xyz = u_xlat4.xyz + u_xlat7.xyz;
                u_xlat48 = u_xlat4.y + u_xlat4.x;
                u_xlat48 = u_xlat4.z + u_xlat48;
                u_xlat17.x = u_xlat48 * 0.0833333358 + u_xlat17.x;
                u_xlat46 = u_xlat17.x + u_xlat17.x;
            }
            u_xlat17.x = u_xlat0.x * u_xlat0.x;
            u_xlat17.x = (-u_xlat17.x) * 0.00100000005 + 1.0;
            u_xlat17.x = max(u_xlat17.x, 0.699999988);
            u_xlat46 = u_xlat46 * 10.0;
            u_xlat46 = u_xlat46 / u_xlat2.z;
            u_xlat46 = u_xlat17.x * u_xlat46;
            u_xlat4.xyz = u_xlat0.xxx * float3(0.00100000005, 0.00999999978, 0.0199999996);
            u_xlat4.x = u_xlat4.x;
            u_xlat4.x = clamp(u_xlat4.x, 0.0, 1.0);
            u_xlat17.x = u_xlat4.x * -2.0 + 3.0;
            u_xlat48 = u_xlat4.x * u_xlat4.x;
            u_xlat17.x = (-u_xlat17.x) * u_xlat48 + 1.0;
            u_xlat5.xy = u_xlat0.xx * float2(0.00999999978, 0.00999999978) + u_xlat2.xz;
            u_xlat5.z = u_xlat2.z;
            u_xlat5.xz = u_xlat5.xz + float2(-0.5, -0.5);
            u_xlat5.xz = u_xlat5.xz * float2(u._scale2);
            u_xlat5.xz = u_xlat5.xz * float2(0.5, 0.5) + float2(0.5, 0.5);
            u_xlat5.xz = u_xlat5.xz + (-float2(u._offset2.x, u._offset2.y));
            u_xlat48 = u._width * -0.5;
            u_xlat4.x = 12.566371 / u._width;
            u_xlat4.x = u_xlat4.x * 0.5;
            u_xlat50 = 0.0;
            u_xlati6 = 0;
            while(true){
                u_xlat21.x = float(u_xlati6);
                u_xlatb36 = u_xlat21.x>=u._complexity2;
                if(u_xlatb36){break;}
                u_xlat36.x = u_xlat21.x / u._complexity2;
                u_xlat36.x = u_xlat36.x + 1.0;
                u_xlat36.xy = u_xlat5.xz * u_xlat36.xx;
                u_xlat7.xy = u_xlat36.xy * float2(u._amount);
                u_xlat8.z = u_xlat21.x * 100.0 + u._seed;
                u_xlat7.xy = floor(u_xlat7.xy);
                u_xlat21.x = 0.0;
                u_xlat9.y = -1.0;
                while(true){
                    u_xlatb37 = 1.0<u_xlat9.y;
                    if(u_xlatb37){break;}
                    u_xlat10.x = u_xlat21.x;
                    u_xlat25.x = -1.0;
                    while(true){
                        u_xlatb37 = 1.0<u_xlat25.x;
                        if(u_xlatb37){break;}
                        u_xlat9.x = u_xlat25.x;
                        u_xlat8.xy = u_xlat7.xy + u_xlat9.xy;
                        u_xlat9.xzw = u_xlat8.xyz * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat9.xzw = fract(u_xlat9.xzw);
                        u_xlat11.xyz = u_xlat9.zxw + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat37.x = dot(u_xlat9.xzw, u_xlat11.xyz);
                        u_xlat37.xy = u_xlat37.xx + u_xlat9.zx;
                        u_xlat9.xz = u_xlat37.yy + u_xlat37.yx;
                        u_xlat37.xy = u_xlat37.xy * u_xlat9.xz;
                        u_xlat37.xy = fract(u_xlat37.xy);
                        u_xlat9.xzw = u_xlat8.xyz * float3(0.103100002, 0.103100002, 0.103100002);
                        u_xlat9.xzw = fract(u_xlat9.xzw);
                        u_xlat11.xyz = u_xlat9.zwx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat53 = dot(u_xlat9.xzw, u_xlat11.xyz);
                        u_xlat9.xzw = float3(u_xlat53) + u_xlat9.xzw;
                        u_xlat53 = u_xlat9.z + u_xlat9.x;
                        u_xlat53 = u_xlat9.w * u_xlat53;
                        u_xlat53 = fract(u_xlat53);
                        u_xlat9.x = u_xlat53 + 1.0;
                        u_xlat9.x = u_xlat9.x * u._duration;
                        u_xlat39.x = u_xlat9.x * u_xlat37.x + _cur_time;
                        u_xlat39.x = u_xlat39.x + 100.0;
                        u_xlat39.x = u_xlat39.x / u_xlat9.x;
                        u_xlatb54 = u_xlat39.x>=(-u_xlat39.x);
                        u_xlat40.x = fract(abs(u_xlat39.x));
                        u_xlat54 = (u_xlatb54) ? u_xlat40.x : (-u_xlat40.x);
                        u_xlat54 = u_xlat9.x * u_xlat54;
                        u_xlat37.x = (-u_xlat37.x) + 1.0;
                        u_xlat37.x = u_xlat37.x * 0.200000003 + 0.800000012;
                        u_xlat37.x = u_xlat37.x * u._speed2;
                        u_xlat52 = u_xlat37.y * 0.400000006 + 0.600000024;
                        u_xlat9.x = u_xlat9.x * 0.600000024;
                        u_xlat40.x = u_xlat52 / u_xlat37.x;
                        u_xlat9.x = min(u_xlat9.x, u_xlat40.x);
                        u_xlat9.x = u_xlat54 / u_xlat9.x;
                        u_xlat9.x = (-u_xlat9.x) + 1.0;
                        u_xlat9.x = clamp(u_xlat9.x, 0.0, 1.0);
                        u_xlat39.x = floor(u_xlat39.x);
                        u_xlat53 = u_xlat53 + u_xlat39.x;
                        u_xlat11.xyz = float3(u_xlat53) * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat11.xyz = fract(u_xlat11.xyz);
                        u_xlat12.xyz = u_xlat11.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat53 = dot(u_xlat11.xyz, u_xlat12.xyz);
                        u_xlat11.xyz = float3(u_xlat53) + u_xlat11.xyz;
                        u_xlat40.xy = u_xlat11.yz + u_xlat11.xx;
                        u_xlat40.xy = u_xlat11.zy * u_xlat40.xy;
                        u_xlat40.xy = fract(u_xlat40.xy);
                        u_xlat8.xy = u_xlat40.xy * float2(0.400000006, 0.400000006) + u_xlat8.xy;
                        u_xlat8.xy = (-u_xlat36.xy) * float2(u._amount) + u_xlat8.xy;
                        u_xlat8.x = dot(u_xlat8.xy, u_xlat8.xy);
                        u_xlat8.x = sqrt(u_xlat8.x);
                        u_xlat37.x = (-u_xlat37.x) * u_xlat54 + u_xlat8.x;
                        u_xlat8.x = u_xlat37.x * 0.5;
                        u_xlat23 = u_xlat4.x * u_xlat8.x;
                        u_xlat23 = sin(u_xlat23);
                        u_xlat8.y = u_xlat23 * u_xlat9.x;
                        u_xlat53 = u_xlat52 * (-u._width);
                        u_xlat9.x = u_xlat48 * u_xlat52;
                        u_xlat52 = u_xlat48 * u_xlat52 + (-u_xlat53);
                        u_xlat37.x = u_xlat37.x * 0.5 + (-u_xlat53);
                        u_xlat52 = float(1.0) / u_xlat52;
                        u_xlat37.x = u_xlat52 * u_xlat37.x;
                        u_xlat37.x = clamp(u_xlat37.x, 0.0, 1.0);
                        u_xlat52 = u_xlat37.x * -2.0 + 3.0;
                        u_xlat37.x = u_xlat37.x * u_xlat37.x;
                        u_xlat37.x = u_xlat37.x * u_xlat52;
                        u_xlat52 = float(1.0) / u_xlat9.x;
                        u_xlat52 = u_xlat52 * u_xlat8.x;
                        u_xlat52 = clamp(u_xlat52, 0.0, 1.0);
                        u_xlat8.x = u_xlat52 * -2.0 + 3.0;
                        u_xlat37.y = u_xlat52 * u_xlat52;
                        u_xlat37.xy = u_xlat37.xy * u_xlat8.yx;
                        u_xlat10.x = (-u_xlat37.x) * u_xlat37.y + u_xlat10.x;
                        u_xlat25.x = u_xlat25.x + 1.0;
                    }
                    u_xlat21.x = u_xlat10.x;
                    u_xlat9.y = u_xlat9.y + 1.0;
                }
                u_xlat50 = u_xlat21.x * 0.111111112 + u_xlat50;
                u_xlati6 = u_xlati6 + 1;
            }
            u_xlat5.x = u_xlat50 * u._height;
            u_xlat5.x = u_xlat46 * u_xlat5.x;
            u_xlat4.w = 0.0;
            u_xlat6 = u_xlat2.xzxz + (-u_xlat4.ywwy);
            u_xlat6 = u_xlat6 + float4(-0.5, -0.5, -0.5, -0.5);
            u_xlat6 = u_xlat6 * float4(u._scale2);
            u_xlat6 = u_xlat6 * float4(0.5, 0.5, 0.5, 0.5) + (-float4(u._offset2.x, u._offset2.y, u._offset2.x, u._offset2.y));
            u_xlat6 = u_xlat6 + float4(0.5, 0.5, 0.5, 0.5);
            u_xlat32 = 0.0;
            u_xlati19 = 0;
            while(true){
                u_xlat49 = float(u_xlati19);
                u_xlatb35 = u_xlat49>=u._complexity2;
                if(u_xlatb35){break;}
                u_xlat35.x = u_xlat49 / u._complexity2;
                u_xlat35.x = u_xlat35.x + 1.0;
                u_xlat35.xy = u_xlat35.xx * u_xlat6.xy;
                u_xlat7.xy = u_xlat35.xy * float2(u._amount);
                u_xlat8.z = u_xlat49 * 100.0 + u._seed;
                u_xlat7.xy = floor(u_xlat7.xy);
                u_xlat49 = 0.0;
                u_xlat9.y = -1.0;
                while(true){
                    u_xlatb37 = 1.0<u_xlat9.y;
                    if(u_xlatb37){break;}
                    u_xlat10.x = u_xlat49;
                    u_xlat25.x = -1.0;
                    while(true){
                        u_xlatb37 = 1.0<u_xlat25.x;
                        if(u_xlatb37){break;}
                        u_xlat9.x = u_xlat25.x;
                        u_xlat8.xy = u_xlat7.xy + u_xlat9.xy;
                        u_xlat9.xzw = u_xlat8.xyz * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat9.xzw = fract(u_xlat9.xzw);
                        u_xlat11.xyz = u_xlat9.zxw + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat37.x = dot(u_xlat9.xzw, u_xlat11.xyz);
                        u_xlat37.xy = u_xlat37.xx + u_xlat9.zx;
                        u_xlat9.xz = u_xlat37.yy + u_xlat37.yx;
                        u_xlat37.xy = u_xlat37.xy * u_xlat9.xz;
                        u_xlat37.xy = fract(u_xlat37.xy);
                        u_xlat9.xzw = u_xlat8.xyz * float3(0.103100002, 0.103100002, 0.103100002);
                        u_xlat9.xzw = fract(u_xlat9.xzw);
                        u_xlat11.xyz = u_xlat9.zwx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat53 = dot(u_xlat9.xzw, u_xlat11.xyz);
                        u_xlat9.xzw = float3(u_xlat53) + u_xlat9.xzw;
                        u_xlat53 = u_xlat9.z + u_xlat9.x;
                        u_xlat53 = u_xlat9.w * u_xlat53;
                        u_xlat53 = fract(u_xlat53);
                        u_xlat9.x = u_xlat53 + 1.0;
                        u_xlat9.x = u_xlat9.x * u._duration;
                        u_xlat39.x = u_xlat9.x * u_xlat37.x + _cur_time;
                        u_xlat39.x = u_xlat39.x + 100.0;
                        u_xlat39.x = u_xlat39.x / u_xlat9.x;
                        u_xlatb54 = u_xlat39.x>=(-u_xlat39.x);
                        u_xlat40.x = fract(abs(u_xlat39.x));
                        u_xlat54 = (u_xlatb54) ? u_xlat40.x : (-u_xlat40.x);
                        u_xlat54 = u_xlat9.x * u_xlat54;
                        u_xlat37.x = (-u_xlat37.x) + 1.0;
                        u_xlat37.x = u_xlat37.x * 0.200000003 + 0.800000012;
                        u_xlat37.x = u_xlat37.x * u._speed2;
                        u_xlat52 = u_xlat37.y * 0.400000006 + 0.600000024;
                        u_xlat9.x = u_xlat9.x * 0.600000024;
                        u_xlat40.x = u_xlat52 / u_xlat37.x;
                        u_xlat9.x = min(u_xlat9.x, u_xlat40.x);
                        u_xlat9.x = u_xlat54 / u_xlat9.x;
                        u_xlat9.x = (-u_xlat9.x) + 1.0;
                        u_xlat9.x = clamp(u_xlat9.x, 0.0, 1.0);
                        u_xlat39.x = floor(u_xlat39.x);
                        u_xlat53 = u_xlat53 + u_xlat39.x;
                        u_xlat11.xyz = float3(u_xlat53) * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat11.xyz = fract(u_xlat11.xyz);
                        u_xlat12.xyz = u_xlat11.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat53 = dot(u_xlat11.xyz, u_xlat12.xyz);
                        u_xlat11.xyz = float3(u_xlat53) + u_xlat11.xyz;
                        u_xlat40.xy = u_xlat11.yz + u_xlat11.xx;
                        u_xlat40.xy = u_xlat11.zy * u_xlat40.xy;
                        u_xlat40.xy = fract(u_xlat40.xy);
                        u_xlat8.xy = u_xlat40.xy * float2(0.400000006, 0.400000006) + u_xlat8.xy;
                        u_xlat8.xy = (-u_xlat35.xy) * float2(u._amount) + u_xlat8.xy;
                        u_xlat8.x = dot(u_xlat8.xy, u_xlat8.xy);
                        u_xlat8.x = sqrt(u_xlat8.x);
                        u_xlat37.x = (-u_xlat37.x) * u_xlat54 + u_xlat8.x;
                        u_xlat8.x = u_xlat37.x * 0.5;
                        u_xlat23 = u_xlat4.x * u_xlat8.x;
                        u_xlat23 = sin(u_xlat23);
                        u_xlat8.y = u_xlat23 * u_xlat9.x;
                        u_xlat53 = u_xlat52 * (-u._width);
                        u_xlat9.x = u_xlat48 * u_xlat52;
                        u_xlat52 = u_xlat48 * u_xlat52 + (-u_xlat53);
                        u_xlat37.x = u_xlat37.x * 0.5 + (-u_xlat53);
                        u_xlat52 = float(1.0) / u_xlat52;
                        u_xlat37.x = u_xlat52 * u_xlat37.x;
                        u_xlat37.x = clamp(u_xlat37.x, 0.0, 1.0);
                        u_xlat52 = u_xlat37.x * -2.0 + 3.0;
                        u_xlat37.x = u_xlat37.x * u_xlat37.x;
                        u_xlat37.x = u_xlat37.x * u_xlat52;
                        u_xlat52 = float(1.0) / u_xlat9.x;
                        u_xlat52 = u_xlat52 * u_xlat8.x;
                        u_xlat52 = clamp(u_xlat52, 0.0, 1.0);
                        u_xlat8.x = u_xlat52 * -2.0 + 3.0;
                        u_xlat37.y = u_xlat52 * u_xlat52;
                        u_xlat37.xy = u_xlat37.xy * u_xlat8.yx;
                        u_xlat10.x = (-u_xlat37.x) * u_xlat37.y + u_xlat10.x;
                        u_xlat25.x = u_xlat25.x + 1.0;
                    }
                    u_xlat49 = u_xlat10.x;
                    u_xlat9.y = u_xlat9.y + 1.0;
                }
                u_xlat32 = u_xlat49 * 0.111111112 + u_xlat32;
                u_xlati19 = u_xlati19 + 1;
            }
            u_xlat32 = u_xlat32 * u._height;
            u_xlat17.y = u_xlat46 * u_xlat32;
            u_xlat17.xy = u_xlat17.xy * float2(0.200000003, 10.0);
            u_xlat32 = u_xlat5.x * 10.0 + (-u_xlat17.y);
            u_xlat32 = u_xlat32 * (-u_xlat17.x);
            u_xlat7.x = u_xlat32 / u_xlat4.z;
            u_xlat2.w = u_xlat5.y;
            u_xlat2.xz = u_xlat2.xw + float2(-0.5, -0.5);
            u_xlat2.xz = u_xlat2.xz * float2(u._scale2);
            u_xlat2.xz = u_xlat2.xz * float2(0.5, 0.5) + (-float2(u._offset2.x, u._offset2.y));
            u_xlat2.xz = u_xlat2.xz + float2(0.5, 0.5);
            u_xlat47 = 0.0;
            u_xlati19 = 0;
            while(true){
                u_xlat49 = float(u_xlati19);
                u_xlatb5.x = u_xlat49>=u._complexity2;
                if(u_xlatb5.x){break;}
                u_xlat5.x = u_xlat49 / u._complexity2;
                u_xlat5.x = u_xlat5.x + 1.0;
                u_xlat5.xy = u_xlat2.xz * u_xlat5.xx;
                u_xlat35.xy = u_xlat5.xy * float2(u._amount);
                u_xlat8.z = u_xlat49 * 100.0 + u._seed;
                u_xlat35.xy = floor(u_xlat35.xy);
                u_xlat49 = 0.0;
                u_xlat6.y = -1.0;
                while(true){
                    u_xlatb52 = 1.0<u_xlat6.y;
                    if(u_xlatb52){break;}
                    u_xlat9.x = u_xlat49;
                    u_xlat24 = -1.0;
                    while(true){
                        u_xlatb52 = 1.0<u_xlat24;
                        if(u_xlatb52){break;}
                        u_xlat6.x = u_xlat24;
                        u_xlat8.xy = u_xlat35.xy + u_xlat6.xy;
                        u_xlat10.xyz = u_xlat8.xyz * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat10.xyz = fract(u_xlat10.xyz);
                        u_xlat11.xyz = u_xlat10.yxz + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat6.x = dot(u_xlat10.xyz, u_xlat11.xyz);
                        u_xlat39.xy = u_xlat6.xx + u_xlat10.yx;
                        u_xlat10.xy = u_xlat39.yy + u_xlat39.yx;
                        u_xlat39.xy = u_xlat39.xy * u_xlat10.xy;
                        u_xlat39.xy = fract(u_xlat39.xy);
                        u_xlat10.xyz = u_xlat8.xyz * float3(0.103100002, 0.103100002, 0.103100002);
                        u_xlat10.xyz = fract(u_xlat10.xyz);
                        u_xlat11.xyz = u_xlat10.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat6.x = dot(u_xlat10.xyz, u_xlat11.xyz);
                        u_xlat10.xyz = u_xlat6.xxx + u_xlat10.xyz;
                        u_xlat6.x = u_xlat10.y + u_xlat10.x;
                        u_xlat6.x = u_xlat10.z * u_xlat6.x;
                        u_xlat6.x = fract(u_xlat6.x);
                        u_xlat52 = u_xlat6.x + 1.0;
                        u_xlat52 = u_xlat52 * u._duration;
                        u_xlat53 = u_xlat52 * u_xlat39.x + _cur_time;
                        u_xlat53 = u_xlat53 + 100.0;
                        u_xlat53 = u_xlat53 / u_xlat52;
                        u_xlatb10 = u_xlat53>=(-u_xlat53);
                        u_xlat25.x = fract(abs(u_xlat53));
                        u_xlat10.x = (u_xlatb10) ? u_xlat25.x : (-u_xlat25.x);
                        u_xlat10.x = u_xlat52 * u_xlat10.x;
                        u_xlat39.x = (-u_xlat39.x) + 1.0;
                        u_xlat39.x = u_xlat39.x * 0.200000003 + 0.800000012;
                        u_xlat39.x = u_xlat39.x * u._speed2;
                        u_xlat54 = u_xlat39.y * 0.400000006 + 0.600000024;
                        u_xlat52 = u_xlat52 * 0.600000024;
                        u_xlat25.x = u_xlat54 / u_xlat39.x;
                        u_xlat52 = min(u_xlat52, u_xlat25.x);
                        u_xlat52 = u_xlat10.x / u_xlat52;
                        u_xlat52 = (-u_xlat52) + 1.0;
                        u_xlat52 = clamp(u_xlat52, 0.0, 1.0);
                        u_xlat53 = floor(u_xlat53);
                        u_xlat6.x = u_xlat6.x + u_xlat53;
                        u_xlat25.xyz = u_xlat6.xxx * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat25.xyz = fract(u_xlat25.xyz);
                        u_xlat11.xyz = u_xlat25.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat6.x = dot(u_xlat25.xyz, u_xlat11.xyz);
                        u_xlat25.xyz = u_xlat6.xxx + u_xlat25.xyz;
                        u_xlat11.xy = u_xlat25.yz + u_xlat25.xx;
                        u_xlat25.xy = u_xlat25.zy * u_xlat11.xy;
                        u_xlat25.xy = fract(u_xlat25.xy);
                        u_xlat8.xy = u_xlat25.xy * float2(0.400000006, 0.400000006) + u_xlat8.xy;
                        u_xlat8.xy = (-u_xlat5.xy) * float2(u._amount) + u_xlat8.xy;
                        u_xlat6.x = dot(u_xlat8.xy, u_xlat8.xy);
                        u_xlat6.x = sqrt(u_xlat6.x);
                        u_xlat6.x = (-u_xlat39.x) * u_xlat10.x + u_xlat6.x;
                        u_xlat8.x = u_xlat6.x * 0.5;
                        u_xlat23 = u_xlat4.x * u_xlat8.x;
                        u_xlat23 = sin(u_xlat23);
                        u_xlat52 = u_xlat52 * u_xlat23;
                        u_xlat23 = u_xlat54 * (-u._width);
                        u_xlat53 = u_xlat48 * u_xlat54;
                        u_xlat39.x = u_xlat48 * u_xlat54 + (-u_xlat23);
                        u_xlat6.x = u_xlat6.x * 0.5 + (-u_xlat23);
                        u_xlat23 = float(1.0) / u_xlat39.x;
                        u_xlat6.x = u_xlat6.x * u_xlat23;
                        u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
                        u_xlat23 = u_xlat6.x * -2.0 + 3.0;
                        u_xlat6.x = u_xlat6.x * u_xlat6.x;
                        u_xlat6.x = u_xlat6.x * u_xlat23;
                        u_xlat6.x = u_xlat6.x * u_xlat52;
                        u_xlat52 = float(1.0) / u_xlat53;
                        u_xlat52 = u_xlat52 * u_xlat8.x;
                        u_xlat52 = clamp(u_xlat52, 0.0, 1.0);
                        u_xlat8.x = u_xlat52 * -2.0 + 3.0;
                        u_xlat52 = u_xlat52 * u_xlat52;
                        u_xlat52 = u_xlat52 * u_xlat8.x;
                        u_xlat9.x = (-u_xlat6.x) * u_xlat52 + u_xlat9.x;
                        u_xlat24 = u_xlat24 + 1.0;
                    }
                    u_xlat49 = u_xlat9.x;
                    u_xlat6.y = u_xlat6.y + 1.0;
                }
                u_xlat47 = u_xlat49 * 0.111111112 + u_xlat47;
                u_xlati19 = u_xlati19 + 1;
            }
            u_xlat2.x = u_xlat47 * u._height;
            u_xlat2.x = u_xlat46 * u_xlat2.x;
            u_xlat32 = float(0.0);
            u_xlati47 = int(0);
            while(true){
                u_xlat19.x = float(u_xlati47);
                u_xlatb49 = u_xlat19.x>=u._complexity2;
                if(u_xlatb49){break;}
                u_xlat49 = u_xlat19.x / u._complexity2;
                u_xlat49 = u_xlat49 + 1.0;
                u_xlat5.xy = float2(u_xlat49) * u_xlat6.zw;
                u_xlat35.xy = u_xlat5.xy * float2(u._amount);
                u_xlat8.z = u_xlat19.x * 100.0 + u._seed;
                u_xlat19.xz = floor(u_xlat35.xy);
                u_xlat35.x = 0.0;
                u_xlat6.y = -1.0;
                while(true){
                    u_xlatb50 = 1.0<u_xlat6.y;
                    if(u_xlatb50){break;}
                    u_xlat9.x = u_xlat35.x;
                    u_xlat24 = -1.0;
                    while(true){
                        u_xlatb50 = 1.0<u_xlat24;
                        if(u_xlatb50){break;}
                        u_xlat6.x = u_xlat24;
                        u_xlat8.xy = u_xlat19.xz + u_xlat6.xy;
                        u_xlat10.xyz = u_xlat8.xyz * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat10.xyz = fract(u_xlat10.xyz);
                        u_xlat11.xyz = u_xlat10.yxz + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat50 = dot(u_xlat10.xyz, u_xlat11.xyz);
                        u_xlat39.xy = float2(u_xlat50) + u_xlat10.yx;
                        u_xlat10.xy = u_xlat39.yy + u_xlat39.yx;
                        u_xlat39.xy = u_xlat39.xy * u_xlat10.xy;
                        u_xlat39.xy = fract(u_xlat39.xy);
                        u_xlat10.xyz = u_xlat8.xyz * float3(0.103100002, 0.103100002, 0.103100002);
                        u_xlat10.xyz = fract(u_xlat10.xyz);
                        u_xlat11.xyz = u_xlat10.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat50 = dot(u_xlat10.xyz, u_xlat11.xyz);
                        u_xlat10.xyz = float3(u_xlat50) + u_xlat10.xyz;
                        u_xlat50 = u_xlat10.y + u_xlat10.x;
                        u_xlat50 = u_xlat10.z * u_xlat50;
                        u_xlat50 = fract(u_xlat50);
                        u_xlat6.x = u_xlat50 + 1.0;
                        u_xlat6.x = u_xlat6.x * u._duration;
                        u_xlat52 = u_xlat6.x * u_xlat39.x + _cur_time;
                        u_xlat52 = u_xlat52 + 100.0;
                        u_xlat52 = u_xlat52 / u_xlat6.x;
                        u_xlatb53 = u_xlat52>=(-u_xlat52);
                        u_xlat10.x = fract(abs(u_xlat52));
                        u_xlat53 = (u_xlatb53) ? u_xlat10.x : (-u_xlat10.x);
                        u_xlat53 = u_xlat6.x * u_xlat53;
                        u_xlat39.x = (-u_xlat39.x) + 1.0;
                        u_xlat39.x = u_xlat39.x * 0.200000003 + 0.800000012;
                        u_xlat39.x = u_xlat39.x * u._speed2;
                        u_xlat54 = u_xlat39.y * 0.400000006 + 0.600000024;
                        u_xlat6.x = u_xlat6.x * 0.600000024;
                        u_xlat10.x = u_xlat54 / u_xlat39.x;
                        u_xlat6.x = min(u_xlat6.x, u_xlat10.x);
                        u_xlat6.x = u_xlat53 / u_xlat6.x;
                        u_xlat6.x = (-u_xlat6.x) + 1.0;
                        u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
                        u_xlat52 = floor(u_xlat52);
                        u_xlat50 = u_xlat50 + u_xlat52;
                        u_xlat10.xyz = float3(u_xlat50) * float3(0.103100002, 0.103, 0.0973000005);
                        u_xlat10.xyz = fract(u_xlat10.xyz);
                        u_xlat11.xyz = u_xlat10.yzx + float3(19.1900005, 19.1900005, 19.1900005);
                        u_xlat50 = dot(u_xlat10.xyz, u_xlat11.xyz);
                        u_xlat10.xyz = float3(u_xlat50) + u_xlat10.xyz;
                        u_xlat10.xw = u_xlat10.yz + u_xlat10.xx;
                        u_xlat10.xy = u_xlat10.zy * u_xlat10.xw;
                        u_xlat10.xy = fract(u_xlat10.xy);
                        u_xlat8.xy = u_xlat10.xy * float2(0.400000006, 0.400000006) + u_xlat8.xy;
                        u_xlat8.xy = (-u_xlat5.xy) * float2(u._amount) + u_xlat8.xy;
                        u_xlat50 = dot(u_xlat8.xy, u_xlat8.xy);
                        u_xlat50 = sqrt(u_xlat50);
                        u_xlat50 = (-u_xlat39.x) * u_xlat53 + u_xlat50;
                        u_xlat52 = u_xlat50 * 0.5;
                        u_xlat8.x = u_xlat4.x * u_xlat52;
                        u_xlat8.x = sin(u_xlat8.x);
                        u_xlat6.x = u_xlat6.x * u_xlat8.x;
                        u_xlat8.x = u_xlat54 * (-u._width);
                        u_xlat23 = u_xlat48 * u_xlat54;
                        u_xlat53 = u_xlat48 * u_xlat54 + (-u_xlat8.x);
                        u_xlat50 = u_xlat50 * 0.5 + (-u_xlat8.x);
                        u_xlat8.x = float(1.0) / u_xlat53;
                        u_xlat50 = u_xlat50 * u_xlat8.x;
                        u_xlat50 = clamp(u_xlat50, 0.0, 1.0);
                        u_xlat8.x = u_xlat50 * -2.0 + 3.0;
                        u_xlat50 = u_xlat50 * u_xlat50;
                        u_xlat50 = u_xlat50 * u_xlat8.x;
                        u_xlat50 = u_xlat50 * u_xlat6.x;
                        u_xlat6.x = float(1.0) / u_xlat23;
                        u_xlat6.x = u_xlat6.x * u_xlat52;
                        u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
                        u_xlat52 = u_xlat6.x * -2.0 + 3.0;
                        u_xlat6.x = u_xlat6.x * u_xlat6.x;
                        u_xlat6.x = u_xlat6.x * u_xlat52;
                        u_xlat9.x = (-u_xlat50) * u_xlat6.x + u_xlat9.x;
                        u_xlat24 = u_xlat24 + 1.0;
                    }
                    u_xlat35.x = u_xlat9.x;
                    u_xlat6.y = u_xlat6.y + 1.0;
                }
                u_xlat32 = u_xlat35.x * 0.111111112 + u_xlat32;
                u_xlati47 = u_xlati47 + 1;
            }
            u_xlat32 = u_xlat32 * u._height;
            u_xlat46 = u_xlat46 * u_xlat32;
            u_xlat46 = u_xlat46 * 10.0;
            u_xlat46 = u_xlat2.x * 10.0 + (-u_xlat46);
            u_xlat46 = u_xlat46 * (-u_xlat17.x);
            u_xlat7.z = u_xlat46 / u_xlat4.z;
            u_xlat7.y = 1.0;
            u_xlat46 = dot(u_xlat7.xyz, u_xlat7.xyz);
            u_xlat46 = rsqrt(u_xlat46);
            u_xlat2.xyz = float3(u_xlat46) * u_xlat7.xzy;
            u_xlat1.x = dot(u_xlat1.xzy, u_xlat2.xyz);
            u_xlat1.x = u_xlat1.x + u_xlat1.x;
            u_xlat1.x = u_xlat2.y * (-u_xlat1.x) + u_xlat1.z;
            u_xlat0.x = u_xlat0.x * (-u._feather);
            u_xlat0.x = u_xlat0.x * 0.288539022;
            u_xlat0.x = exp2(u_xlat0.x);
            u_xlat0.x = (-u_xlat0.x) + 1.0;
            u_xlat0.x = u_xlat0.x * (-u_xlat1.x) + u_xlat1.x;
        } else {
            u_xlat2.x = float(0.0);
            u_xlat2.y = float(0.0);
            u_xlat0.x = 0.0;
        }
        u_xlat1.xy = u_xlat2.xy * float2(float2(u._intensity2, u._intensity2));
        u_xlat0.x = u_xlat0.x * u_xlat0.x;
        u_xlat30.xy = u_xlat0.xx * u_xlat1.xy + u_xlat30.xy;
    }
    u_xlat0.xz = u_xlat30.xy + float2(-0.5, -0.5);
    u_xlat0.xz = u_xlat0.xz * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb1.xy = lessThan(u_xlat0.xzxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb31.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat0.xzxz).xy;
    u_xlat2.xy = fract(u_xlat0.xz);
    u_xlat2.xy = (-u_xlat2.xy) + float2(1.0, 1.0);
    u_xlat31.x = (u_xlatb31.x) ? u_xlat2.x : u_xlat0.x;
    u_xlat31.y = (u_xlatb31.y) ? u_xlat2.y : u_xlat0.z;
    {
        float4 hlslcc_movcTemp = u_xlat0;
        hlslcc_movcTemp.x = (u_xlatb1.x) ? (-u_xlat0.x) : u_xlat31.x;
        hlslcc_movcTemp.z = (u_xlatb1.y) ? (-u_xlat0.z) : u_xlat31.y;
        u_xlat0 = hlslcc_movcTemp;
    }
    u_xlat0.xz = u_xlat0.xz + float2(-0.5, -0.5);
    u_xlat0.xz = u_xlat0.xz * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    u_xlatb45 = 0<int(u._enable_light);
    u_xlat45 = u_xlatb45 ? u._light_intensity : float(0.0);
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xz);
    u_xlat2.xyz = float3(u_xlat45) * u_xlat3.xyz;
    u_xlat2.w = 0.0;
    u_xlat1 = u_xlat1 + u_xlat2;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.x = (-in.acScreenNorm.y) + u._horizontal_line;
    u_xlat30.x = u._edge_blur * 0.100000001;
    u_xlat0.x = abs(u_xlat0.x) * abs(u_xlat0.x);
    u_xlat30.x = float(1.0) / u_xlat30.x;
    u_xlat0.x = u_xlat30.x * u_xlat0.x;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat30.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat30.x;
    u_xlat3.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u._color.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.xyz = u_xlat3.xyz * u._color.xyz;
    u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + (-u_xlat2.xyz);
    u_xlat0.xzw = u_xlat0.xxx * u_xlat3.xyz + u_xlat2.xyz;
    u_xlat1.xyz = (bool(u_xlatb15)) ? u_xlat0.xzw : u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb0.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb0.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat0.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb0.y) ? u_xlat0.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
