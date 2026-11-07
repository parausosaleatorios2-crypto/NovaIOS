// ---------------------------------------------------------------------------
// Raytracing Glass Sphere (NV)
// origem : assets/effects/nv-nodevideo-raytracing-glass-sphere.xml
// id     : nv.effect.nodevideo-raytracing-glass-sphere
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_raytracing_glass_sphereParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float3 _rotation;
    float _zoom;
    float3 _color;
    float _intensity;
    float _refraction;
    float2 _tex_scale;
    float2 _tex_offset;
    float _wrap_texture;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool2 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati5;
bool u_xlatb5;
float4 u_xlat6;
bool2 u_xlatb6;
float4 u_xlat7;
bool2 u_xlatb7;
float4 u_xlat8;
float4 u_xlat9;
float u_xlat10;
float3 u_xlat11;
float3 u_xlat12;
float u_xlat13;
bool u_xlatb13;
bool u_xlatb14;
float3 u_xlat15;
bool u_xlatb15;
bool u_xlatb16;
bool u_xlatb17;
float2 u_xlat23;
bool2 u_xlatb23;
float2 u_xlat26;
float2 u_xlat27;
float u_xlat30;
bool u_xlatb30;
float u_xlat31;
bool u_xlatb31;
float u_xlat32;
bool u_xlatb32;
float u_xlat33;
bool u_xlatb33;
float u_xlat34;
bool u_xlatb34;

fragment float4 fx_nv_nodevideo_raytracing_glass_sphere(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_raytracing_glass_sphereParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.xyz = u._rotation.xyz * float3(6.28318548, 6.28318548, 6.28318548);
    u_xlat2.x = sin(u_xlat1.z);
    u_xlat3.x = cos(u_xlat1.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat5.x = cos(u_xlat1.x);
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat6.y = u_xlat2.x * u_xlat5.x;
    u_xlat3.y = (-u_xlat1.x) * u_xlat2.x;
    u_xlat2.y = u_xlat3.x * u_xlat5.x;
    u_xlat4.y = (-u_xlat1.x) * u_xlat3.x;
    u_xlat7.x = sin(u_xlat1.y);
    u_xlat8.x = cos(u_xlat1.y);
    u_xlat9.x = (-u_xlat7.x);
    u_xlat9.y = u_xlat8.x;
    u_xlat6.x = dot(u_xlat3.yx, u_xlat9.xy);
    u_xlat9.z = u_xlat7.x;
    u_xlat6.z = dot(u_xlat3.yx, u_xlat9.yz);
    u_xlat2.x = dot(u_xlat4.yx, u_xlat9.xy);
    u_xlat2.z = dot(u_xlat4.yx, u_xlat9.yz);
    u_xlat3.x = u_xlat5.x * u_xlat9.x;
    u_xlat3.z = u_xlat5.x * u_xlat8.x;
    u_xlat0.z = 1.0;
    u_xlat30 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat30 = rsqrt(u_xlat30);
    u_xlat0.xyz = float3(u_xlat30) * u_xlat0.xyz;
    u_xlat4.x = dot(u_xlat6.xyz, u_xlat0.xyz);
    u_xlat4.y = dot(u_xlat2.xyz, u_xlat0.xyz);
    u_xlat3.y = u_xlat1.x;
    u_xlat4.z = dot(u_xlat3.xyz, u_xlat0.xyz);
    u_xlat0.x = u_xlat6.z * u._zoom;
    u_xlat0.y = u_xlat2.z * u._zoom;
    u_xlat0.z = u_xlat3.z * u._zoom;
    u_xlat30 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
    u_xlat1.x = dot((-u_xlat0.xyz), u_xlat4.xyz);
    u_xlat11.x = (-u_xlat1.x) * u_xlat1.x + u_xlat30;
    u_xlat11.x = max(u_xlat11.x, 0.0);
    u_xlat11.y = as_type<float>((1.99939609>=u_xlat11.x) ? 0xFFFFFFFFu : uint(0));
    if(uint(as_type<uint>(u_xlat11.y)) != uint(0)) {
        u_xlatb30 = u_xlat30>=1.99939609;
        if(u_xlatb30){
            u_xlat30 = (-u_xlat11.x) + 1.99939609;
            u_xlat30 = sqrt(u_xlat30);
            u_xlat30 = (-u_xlat30) + u_xlat1.x;
            u_xlati1 = int((u_xlat30>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati1 != 0) {
                u_xlat0.xyz = u_xlat4.xyz * float3(u_xlat30) + u_xlat0.xyz;
                u_xlat11.xyz = u_xlat0.xyz * float3(0.707213581, 0.707213581, 0.707213581);
            }
        } else {
            u_xlati1 = 0;
        }
    } else {
        u_xlati1 = 0;
    }
    if(u_xlati1 != 0) {
        u_xlat30 = float(1.0) / u._refraction;
        u_xlat1.x = dot(u_xlat4.xyz, u_xlat11.xyz);
        u_xlat2.x = u_xlat30 * u_xlat30;
        u_xlat12.x = (-u_xlat1.x) * u_xlat1.x + 1.0;
        u_xlat2.x = (-u_xlat2.x) * u_xlat12.x + 1.0;
        u_xlat12.x = sqrt(u_xlat2.x);
        u_xlat12.x = u_xlat30 * u_xlat1.x + u_xlat12.x;
        u_xlatb2.x = u_xlat2.x>=0.0;
        u_xlat12.xyz = u_xlat11.xyz * u_xlat12.xxx;
        u_xlat12.xyz = float3(u_xlat30) * u_xlat4.xyz + (-u_xlat12.xyz);
        u_xlat2.xyz = u_xlatb2.x ? u_xlat12.xyz : float3(0.0, 0.0, 0.0);
        u_xlat30 = u_xlat1.x + u_xlat1.x;
        u_xlat11.xyz = u_xlat11.xyz * (-float3(u_xlat30)) + u_xlat4.xyz;
        u_xlat30 = dot(u_xlat11.xyz, u_xlat11.xyz);
        u_xlat30 = rsqrt(u_xlat30);
        u_xlat3.xyz = float3(u_xlat30) * u_xlat11.xyz;
        u_xlat30 = min(abs(u_xlat3.z), abs(u_xlat3.x));
        u_xlat31 = max(abs(u_xlat3.z), abs(u_xlat3.x));
        u_xlat31 = float(1.0) / u_xlat31;
        u_xlat30 = u_xlat30 * u_xlat31;
        u_xlat31 = u_xlat30 * u_xlat30;
        u_xlat32 = u_xlat31 * 0.0208350997 + -0.0851330012;
        u_xlat32 = u_xlat31 * u_xlat32 + 0.180141002;
        u_xlat32 = u_xlat31 * u_xlat32 + -0.330299497;
        u_xlat31 = u_xlat31 * u_xlat32 + 0.999866009;
        u_xlat32 = u_xlat30 * u_xlat31;
        u_xlatb33 = abs(u_xlat3.z)<abs(u_xlat3.x);
        u_xlat32 = u_xlat32 * -2.0 + 1.57079637;
        u_xlat32 = u_xlatb33 ? u_xlat32 : float(0.0);
        u_xlat30 = u_xlat30 * u_xlat31 + u_xlat32;
        u_xlatb31 = u_xlat3.z<(-u_xlat3.z);
        u_xlat31 = u_xlatb31 ? -3.14159274 : float(0.0);
        u_xlat30 = u_xlat30 + u_xlat31;
        u_xlat31 = min(u_xlat3.z, u_xlat3.x);
        u_xlat32 = max(u_xlat3.z, u_xlat3.x);
        u_xlatb31 = u_xlat31<(-u_xlat31);
        u_xlatb32 = u_xlat32>=(-u_xlat32);
        u_xlatb31 = u_xlatb31 && u_xlatb32;
        u_xlat30 = (u_xlatb31) ? (-u_xlat30) : u_xlat30;
        u_xlat4.x = u_xlat30 * 0.159154937 + 0.5;
        u_xlat4.y = u_xlat3.y * 0.5 + 0.5;
        u_xlat11.xy = u_xlat11.xy * in.acScreenNorm.xy;
        u_xlat11.xy = (int(u._wrap_texture) != 0) ? u_xlat4.xy : u_xlat11.xy;
        u_xlat11.xy = u_xlat11.xy + float2(-0.5, -0.5);
        u_xlat11.xy = u_xlat11.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
        u_xlat11.xy = u_xlat11.xy + float2(0.5, 0.5);
        u_xlatb3.xy = greaterThanEqual(u_xlat11.xyxx, (-u_xlat11.xyxx)).xy;
        u_xlat11.xy = fract(abs(u_xlat11.xy));
        {
            float3 hlslcc_movcTemp = u_xlat11;
            hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat11.x : (-u_xlat11.x);
            hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat11.y : (-u_xlat11.y);
            u_xlat11 = hlslcc_movcTemp;
        }
        u_xlatb3.xy = lessThan(u_xlat11.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat23.xy = u_xlat11.xy + float2(1.0, 1.0);
        u_xlat3.x = (u_xlatb3.x) ? u_xlat23.x : u_xlat11.x;
        u_xlat3.y = (u_xlatb3.y) ? u_xlat23.y : u_xlat11.y;
        u_xlat3.z = (-u_xlat3.y) + 1.0;
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xz);
        u_xlat30 = -abs(u_xlat1.x) + 1.0;
        u_xlat1 = float4(u_xlat30) * u_xlat3;
        u_xlat30 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
        u_xlat32 = dot((-u_xlat0.xyz), u_xlat2.xyz);
        u_xlat30 = (-u_xlat32) * u_xlat32 + u_xlat30;
        u_xlat30 = max(u_xlat30, 0.0);
        u_xlat3.x = as_type<float>((1.99939609>=u_xlat30) ? 0xFFFFFFFFu : uint(0));
        if(uint(as_type<uint>(u_xlat3.x)) != uint(0)) {
            u_xlat30 = (-u_xlat30) + 1.99939609;
            u_xlat30 = sqrt(u_xlat30);
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat30) + u_xlat0.xyz;
            u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
            u_xlat4.xyz = (-u_xlat4.xyz);
        }
        u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
        u_xlat33 = u._refraction * u._refraction;
        u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
        u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
        u_xlatb5 = u_xlat34>=0.0;
        if(u_xlatb5){
            u_xlat34 = sqrt(u_xlat34);
            u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
            u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
            u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
            u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
            u_xlat32 = rsqrt(u_xlat32);
            u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
            u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
            u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
            u_xlat34 = float(1.0) / u_xlat34;
            u_xlat32 = u_xlat32 * u_xlat34;
            u_xlat34 = u_xlat32 * u_xlat32;
            u_xlat6.x = u_xlat34 * 0.0208350997 + -0.0851330012;
            u_xlat6.x = u_xlat34 * u_xlat6.x + 0.180141002;
            u_xlat6.x = u_xlat34 * u_xlat6.x + -0.330299497;
            u_xlat34 = u_xlat34 * u_xlat6.x + 0.999866009;
            u_xlat6.x = u_xlat32 * u_xlat34;
            u_xlatb16 = abs(u_xlat15.z)<abs(u_xlat15.x);
            u_xlat6.x = u_xlat6.x * -2.0 + 1.57079637;
            u_xlat6.x = u_xlatb16 ? u_xlat6.x : float(0.0);
            u_xlat32 = u_xlat32 * u_xlat34 + u_xlat6.x;
            u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
            u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
            u_xlat32 = u_xlat32 + u_xlat34;
            u_xlat34 = min(u_xlat15.z, u_xlat15.x);
            u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
            u_xlatb34 = u_xlat34<(-u_xlat34);
            u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
            u_xlatb34 = u_xlatb34 && u_xlatb15;
            u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
            u_xlat6.x = u_xlat32 * 0.159154937 + 0.5;
            u_xlat6.y = u_xlat15.y * 0.5 + 0.5;
            u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
            u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat6.xy : u_xlat15.xy;
            u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
            u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
            u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
            u_xlatb6.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
            u_xlat15.xy = fract(abs(u_xlat15.xy));
            {
                float3 hlslcc_movcTemp = u_xlat15;
                hlslcc_movcTemp.x = (u_xlatb6.x) ? u_xlat15.x : (-u_xlat15.x);
                hlslcc_movcTemp.y = (u_xlatb6.y) ? u_xlat15.y : (-u_xlat15.y);
                u_xlat15 = hlslcc_movcTemp;
            }
            u_xlatb6.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
            u_xlat26.xy = u_xlat15.xy + float2(1.0, 1.0);
            u_xlat6.x = (u_xlatb6.x) ? u_xlat26.x : u_xlat15.x;
            u_xlat6.y = (u_xlatb6.y) ? u_xlat26.y : u_xlat15.y;
            u_xlat6.z = (-u_xlat6.y) + 1.0;
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat6.xz);
            u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
            u_xlat7 = float4(u_xlat32) * u_xlat6;
            u_xlat34 = u_xlat30 * u._intensity;
            u_xlat34 = u_xlat34 * 0.100000001;
            u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
            u_xlat8.xyz = u._color.xyz;
            u_xlat8.w = 1.0;
            u_xlat6 = (-u_xlat6) * float4(u_xlat32) + u_xlat8;
            u_xlat6 = float4(u_xlat34) * u_xlat6 + u_xlat7;
            u_xlat0.xyz = u_xlat3.xyz;
        } else {
            u_xlat6.x = float(0.0);
            u_xlat6.y = float(0.0);
            u_xlat6.z = float(0.0);
            u_xlat6.w = float(0.0);
        }
        u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
        u_xlat32 = u_xlat32 + u_xlat32;
        u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
        u_xlat0.xyz = (bool(u_xlatb5)) ? u_xlat0.xyz : u_xlat3.xyz;
        u_xlat2.xyz = (bool(u_xlatb5)) ? u_xlat2.xyz : u_xlat4.xyz;
        if(!u_xlatb5){
            if(!u_xlatb5){
                u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
                u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
                u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
                u_xlat32 = max(u_xlat32, 0.0);
                u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
                if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                    u_xlat32 = (-u_xlat32) + 1.99939609;
                    u_xlat32 = sqrt(u_xlat32);
                    u_xlat32 = u_xlat32 + u_xlat3.x;
                    u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                    u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                    u_xlat4.xyz = (-u_xlat4.xyz);
                }
                u_xlat30 = u_xlat30 + u_xlat32;
                u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
                u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
                u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
                u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
                if(u_xlati5 != 0) {
                    u_xlat34 = sqrt(u_xlat34);
                    u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                    u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                    u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                    u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                    u_xlat32 = rsqrt(u_xlat32);
                    u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                    u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                    u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                    u_xlat34 = float(1.0) / u_xlat34;
                    u_xlat32 = u_xlat32 * u_xlat34;
                    u_xlat34 = u_xlat32 * u_xlat32;
                    u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                    u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                    u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                    u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                    u_xlat7.x = u_xlat32 * u_xlat34;
                    u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                    u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                    u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                    u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                    u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                    u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                    u_xlat32 = u_xlat32 + u_xlat34;
                    u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                    u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                    u_xlatb34 = u_xlat34<(-u_xlat34);
                    u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                    u_xlatb34 = u_xlatb34 && u_xlatb15;
                    u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                    u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                    u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                    u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                    u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                    u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                    u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                    u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                    u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                    u_xlat15.xy = fract(abs(u_xlat15.xy));
                    {
                        float3 hlslcc_movcTemp = u_xlat15;
                        hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                        hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                        u_xlat15 = hlslcc_movcTemp;
                    }
                    u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                    u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                    u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                    u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                    u_xlat7.z = (-u_xlat7.y) + 1.0;
                    u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                    u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                    u_xlat8 = float4(u_xlat32) * u_xlat7;
                    u_xlat34 = u_xlat30 * u._intensity;
                    u_xlat34 = u_xlat34 * 0.100000001;
                    u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                    u_xlat9.xyz = u._color.xyz;
                    u_xlat9.w = 1.0;
                    u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                    u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                    u_xlat0.xyz = u_xlat3.xyz;
                }
                u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
                u_xlat32 = u_xlat32 + u_xlat32;
                u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
                u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
                u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
            } else {
                u_xlati5 = int(0xFFFFFFFFu);
            }
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlat3.y = as_type<float>((1.99939609>=u_xlat32) ? 0xFFFFFFFFu : uint(0));
            if(uint(as_type<uint>(u_xlat3.y)) != uint(0)) {
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat3.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat4.xyz = u_xlat3.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat4.xyz = (-u_xlat4.xyz);
            }
            u_xlat30 = u_xlat30 + u_xlat32;
            u_xlat32 = dot(u_xlat4.xyz, u_xlat2.xyz);
            u_xlat34 = (-u_xlat32) * u_xlat32 + 1.0;
            u_xlat34 = (-u_xlat33) * u_xlat34 + 1.0;
            u_xlati5 = int((u_xlat34>=0.0) ? 0xFFFFFFFFu : uint(0));
            if(u_xlati5 != 0) {
                u_xlat34 = sqrt(u_xlat34);
                u_xlat32 = u._refraction * u_xlat32 + u_xlat34;
                u_xlat15.xyz = u_xlat4.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat15.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat15.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = max(abs(u_xlat15.z), abs(u_xlat15.x));
                u_xlat34 = float(1.0) / u_xlat34;
                u_xlat32 = u_xlat32 * u_xlat34;
                u_xlat34 = u_xlat32 * u_xlat32;
                u_xlat7.x = u_xlat34 * 0.0208350997 + -0.0851330012;
                u_xlat7.x = u_xlat34 * u_xlat7.x + 0.180141002;
                u_xlat7.x = u_xlat34 * u_xlat7.x + -0.330299497;
                u_xlat34 = u_xlat34 * u_xlat7.x + 0.999866009;
                u_xlat7.x = u_xlat32 * u_xlat34;
                u_xlatb17 = abs(u_xlat15.z)<abs(u_xlat15.x);
                u_xlat7.x = u_xlat7.x * -2.0 + 1.57079637;
                u_xlat7.x = u_xlatb17 ? u_xlat7.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat34 + u_xlat7.x;
                u_xlatb34 = u_xlat15.z<(-u_xlat15.z);
                u_xlat34 = u_xlatb34 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat34;
                u_xlat34 = min(u_xlat15.z, u_xlat15.x);
                u_xlat15.x = max(u_xlat15.z, u_xlat15.x);
                u_xlatb34 = u_xlat34<(-u_xlat34);
                u_xlatb15 = u_xlat15.x>=(-u_xlat15.x);
                u_xlatb34 = u_xlatb34 && u_xlatb15;
                u_xlat32 = (u_xlatb34) ? (-u_xlat32) : u_xlat32;
                u_xlat7.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat7.y = u_xlat15.y * 0.5 + 0.5;
                u_xlat15.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat15.xy = (int(u._wrap_texture) != 0) ? u_xlat7.xy : u_xlat15.xy;
                u_xlat15.xy = u_xlat15.xy + float2(-0.5, -0.5);
                u_xlat15.xy = u_xlat15.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat15.xy = u_xlat15.xy + float2(0.5, 0.5);
                u_xlatb7.xy = greaterThanEqual(u_xlat15.xyxx, (-u_xlat15.xyxx)).xy;
                u_xlat15.xy = fract(abs(u_xlat15.xy));
                {
                    float3 hlslcc_movcTemp = u_xlat15;
                    hlslcc_movcTemp.x = (u_xlatb7.x) ? u_xlat15.x : (-u_xlat15.x);
                    hlslcc_movcTemp.y = (u_xlatb7.y) ? u_xlat15.y : (-u_xlat15.y);
                    u_xlat15 = hlslcc_movcTemp;
                }
                u_xlatb7.xy = lessThan(u_xlat15.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat27.xy = u_xlat15.xy + float2(1.0, 1.0);
                u_xlat7.x = (u_xlatb7.x) ? u_xlat27.x : u_xlat15.x;
                u_xlat7.y = (u_xlatb7.y) ? u_xlat27.y : u_xlat15.y;
                u_xlat7.z = (-u_xlat7.y) + 1.0;
                u_xlat7 = inputImg.sample(__nv_smp, u_xlat7.xz);
                u_xlat32 = dot((-u_xlat2.xyz), u_xlat4.xyz);
                u_xlat8 = float4(u_xlat32) * u_xlat7;
                u_xlat34 = u_xlat30 * u._intensity;
                u_xlat34 = u_xlat34 * 0.100000001;
                u_xlat34 = clamp(u_xlat34, 0.0, 1.0);
                u_xlat9.xyz = u._color.xyz;
                u_xlat9.w = 1.0;
                u_xlat7 = (-u_xlat7) * float4(u_xlat32) + u_xlat9;
                u_xlat6 = float4(u_xlat34) * u_xlat7 + u_xlat8;
                u_xlat0.xyz = u_xlat3.xyz;
            }
            u_xlat32 = dot(u_xlat2.xyz, u_xlat4.xyz);
            u_xlat32 = u_xlat32 + u_xlat32;
            u_xlat4.xyz = u_xlat4.xyz * (-float3(u_xlat32)) + u_xlat2.xyz;
            u_xlat0.xyz = (int(u_xlati5) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
            u_xlat2.xyz = (int(u_xlati5) != 0) ? u_xlat2.xyz : u_xlat4.xyz;
        } else {
            u_xlati5 = int(0xFFFFFFFFu);
        }
        if(u_xlati5 == 0) {
            u_xlat32 = dot((-u_xlat0.xyz), (-u_xlat0.xyz));
            u_xlat3.x = dot((-u_xlat0.xyz), u_xlat2.xyz);
            u_xlat32 = (-u_xlat3.x) * u_xlat3.x + u_xlat32;
            u_xlat32 = max(u_xlat32, 0.0);
            u_xlatb13 = 1.99939609>=u_xlat32;
            if(u_xlatb13){
                u_xlat32 = (-u_xlat32) + 1.99939609;
                u_xlat32 = sqrt(u_xlat32);
                u_xlat32 = u_xlat32 + u_xlat3.x;
                u_xlat0.xyz = u_xlat2.xyz * float3(u_xlat32) + u_xlat0.xyz;
                u_xlat0.xyz = u_xlat0.xyz * float3(0.707213581, 0.707213581, 0.707213581);
                u_xlat0.xyz = (-u_xlat0.xyz);
            }
            u_xlat3.x = dot(u_xlat0.xyz, u_xlat2.xyz);
            u_xlat13 = (-u_xlat3.x) * u_xlat3.x + 1.0;
            u_xlat13 = (-u_xlat33) * u_xlat13 + 1.0;
            u_xlatb23.x = u_xlat13>=0.0;
            if(u_xlatb23.x){
                u_xlat30 = u_xlat30 + u_xlat32;
                u_xlat32 = sqrt(u_xlat13);
                u_xlat32 = u._refraction * u_xlat3.x + u_xlat32;
                u_xlat3.xyz = u_xlat0.xyz * float3(u_xlat32);
                u_xlat2.xyz = float3(u._refraction) * u_xlat2.xyz + (-u_xlat3.xyz);
                u_xlat32 = dot(u_xlat2.xyz, u_xlat2.xyz);
                u_xlat32 = rsqrt(u_xlat32);
                u_xlat3.xyz = float3(u_xlat32) * u_xlat2.xyz;
                u_xlat32 = min(abs(u_xlat3.z), abs(u_xlat3.x));
                u_xlat33 = max(abs(u_xlat3.z), abs(u_xlat3.x));
                u_xlat33 = float(1.0) / u_xlat33;
                u_xlat32 = u_xlat32 * u_xlat33;
                u_xlat33 = u_xlat32 * u_xlat32;
                u_xlat4.x = u_xlat33 * 0.0208350997 + -0.0851330012;
                u_xlat4.x = u_xlat33 * u_xlat4.x + 0.180141002;
                u_xlat4.x = u_xlat33 * u_xlat4.x + -0.330299497;
                u_xlat33 = u_xlat33 * u_xlat4.x + 0.999866009;
                u_xlat4.x = u_xlat32 * u_xlat33;
                u_xlatb14 = abs(u_xlat3.z)<abs(u_xlat3.x);
                u_xlat4.x = u_xlat4.x * -2.0 + 1.57079637;
                u_xlat4.x = u_xlatb14 ? u_xlat4.x : float(0.0);
                u_xlat32 = u_xlat32 * u_xlat33 + u_xlat4.x;
                u_xlatb33 = u_xlat3.z<(-u_xlat3.z);
                u_xlat33 = u_xlatb33 ? -3.14159274 : float(0.0);
                u_xlat32 = u_xlat32 + u_xlat33;
                u_xlat33 = min(u_xlat3.z, u_xlat3.x);
                u_xlat3.x = max(u_xlat3.z, u_xlat3.x);
                u_xlatb23.x = u_xlat33<(-u_xlat33);
                u_xlatb3.x = u_xlat3.x>=(-u_xlat3.x);
                u_xlatb3.x = u_xlatb3.x && u_xlatb23.x;
                u_xlat32 = (u_xlatb3.x) ? (-u_xlat32) : u_xlat32;
                u_xlat4.x = u_xlat32 * 0.159154937 + 0.5;
                u_xlat4.y = u_xlat3.y * 0.5 + 0.5;
                u_xlat3.xy = u_xlat2.xy * in.acScreenNorm.xy;
                u_xlat3.xy = (int(u._wrap_texture) != 0) ? u_xlat4.xy : u_xlat3.xy;
                u_xlat3.xy = u_xlat3.xy + float2(-0.5, -0.5);
                u_xlat3.xy = u_xlat3.xy * float2(u._tex_scale.x, u._tex_scale.y) + u._tex_offset.xy;
                u_xlat3.xy = u_xlat3.xy + float2(0.5, 0.5);
                u_xlatb23.xy = greaterThanEqual(u_xlat3.xyxy, (-u_xlat3.xyxy)).xy;
                u_xlat3.xy = fract(abs(u_xlat3.xy));
                {
                    float4 hlslcc_movcTemp = u_xlat3;
                    hlslcc_movcTemp.x = (u_xlatb23.x) ? u_xlat3.x : (-u_xlat3.x);
                    hlslcc_movcTemp.y = (u_xlatb23.y) ? u_xlat3.y : (-u_xlat3.y);
                    u_xlat3 = hlslcc_movcTemp;
                }
                u_xlatb23.xy = lessThan(u_xlat3.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
                u_xlat4.xy = u_xlat3.xy + float2(1.0, 1.0);
                {
                    float4 hlslcc_movcTemp = u_xlat3;
                    hlslcc_movcTemp.x = (u_xlatb23.x) ? u_xlat4.x : u_xlat3.x;
                    hlslcc_movcTemp.y = (u_xlatb23.y) ? u_xlat4.y : u_xlat3.y;
                    u_xlat3 = hlslcc_movcTemp;
                }
                u_xlat3.z = (-u_xlat3.y) + 1.0;
                u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xz);
                u_xlat0.x = dot((-u_xlat2.xyz), u_xlat0.xyz);
                u_xlat2 = u_xlat0.xxxx * u_xlat3;
                u_xlat10 = u_xlat30 * u._intensity;
                u_xlat10 = u_xlat10 * 0.100000001;
                u_xlat10 = clamp(u_xlat10, 0.0, 1.0);
                u_xlat4.xyz = u._color.xyz;
                u_xlat4.w = 1.0;
                u_xlat3 = (-u_xlat3) * u_xlat0.xxxx + u_xlat4;
                u_xlat6 = float4(u_xlat10) * u_xlat3 + u_xlat2;
            }
        }
        u_xlat0 = u_xlat1 + u_xlat6;
    } else {
        u_xlat0.x = float(0.0);
        u_xlat0.y = float(0.0);
        u_xlat0.z = float(0.0);
        u_xlat0.w = float(0.0);
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
