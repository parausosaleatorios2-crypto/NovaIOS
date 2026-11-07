// ---------------------------------------------------------------------------
// Effect Blur Directional Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-directional-blur.xml
// id     : nv.effect.nodevideo-effect-blur-directional-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_directional_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _samples;
    float _radius;
    float _direction;
    float _enable_turbulence;
    float _evolution;
    float _strength;
    float2 _scale;
    float _dispersion;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
bool3 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float4 u_xlat7;
float4 u_xlat8;
float4 u_xlat9;
bool4 u_xlatb9;
float4 u_xlat10;
float u_xlat11;
int u_xlati11;
float u_xlat12;
int u_xlati13;
float u_xlat23;
float u_xlat24;
bool u_xlatb24;
float u_xlat33;
float u_xlat35;

fragment float4 fx_nv_nodevideo_effect_blur_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_directional_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = 0<int(u._enable_turbulence);
    if(u_xlatb0){
        u_xlat0.xy = in.acScreenNorm.xy * float2(u._scale.x, u._scale.y);
        u_xlat0.z = u._evolution;
        u_xlat33 = dot(u_xlat0.xyz, float3(0.333333343, 0.333333343, 0.333333343));
        u_xlat1.xyz = float3(u_xlat33) + u_xlat0.xyz;
        u_xlat1.xyz = floor(u_xlat1.xyz);
        u_xlat0.xyz = u_xlat0.xyz + (-u_xlat1.xyz);
        u_xlat33 = dot(u_xlat1.xyz, float3(0.166666672, 0.166666672, 0.166666672));
        u_xlat0.xyz = float3(u_xlat33) + u_xlat0.xyz;
        u_xlatb2.xyz = greaterThanEqual(u_xlat0.zxyz, u_xlat0.xyzx).xyz;
        u_xlat3.x = u_xlatb2.y ? float(1.0) : 0.0;
        u_xlat3.y = u_xlatb2.z ? float(1.0) : 0.0;
        u_xlat3.z = u_xlatb2.x ? float(1.0) : 0.0;
;
        u_xlat2.x = (u_xlatb2.x) ? float(0.0) : float(1.0);
        u_xlat2.y = (u_xlatb2.y) ? float(0.0) : float(1.0);
        u_xlat2.z = (u_xlatb2.z) ? float(0.0) : float(1.0);
        u_xlat4.xyz = min(u_xlat2.xyz, u_xlat3.xyz);
        u_xlat2.xyz = max(u_xlat2.yzx, u_xlat3.yzx);
        u_xlat3.xyz = u_xlat0.xyz + (-u_xlat4.xyz);
        u_xlat3.xyz = u_xlat3.xyz + float3(0.166666672, 0.166666672, 0.166666672);
        u_xlat5.xyz = u_xlat0.xyz + (-u_xlat2.zxy);
        u_xlat5.xyz = u_xlat5.xyz + float3(0.333333343, 0.333333343, 0.333333343);
        u_xlat6.xyz = u_xlat0.xyz + float3(-0.5, -0.5, -0.5);
        u_xlat7.xyz = u_xlat1.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat7.xyz = floor(u_xlat7.xyz);
        u_xlat1.xyz = (-u_xlat7.xyz) * float3(289.0, 289.0, 289.0) + u_xlat1.xyz;
        u_xlat7.x = float(0.0);
        u_xlat7.w = float(1.0);
        u_xlat7.y = u_xlat4.z;
        u_xlat7.z = u_xlat2.y;
        u_xlat7 = u_xlat1.zzzz + u_xlat7;
        u_xlat8 = u_xlat7 * u_xlat7;
        u_xlat7 = u_xlat8 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
        u_xlat8 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat8 = floor(u_xlat8);
        u_xlat7 = (-u_xlat8) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
        u_xlat7 = u_xlat1.yyyy + u_xlat7;
        u_xlat8.x = float(0.0);
        u_xlat8.w = float(1.0);
        u_xlat8.y = u_xlat4.y;
        u_xlat8.z = u_xlat2.x;
        u_xlat7 = u_xlat7 + u_xlat8;
        u_xlat8 = u_xlat7 * u_xlat7;
        u_xlat7 = u_xlat8 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat7;
        u_xlat8 = u_xlat7 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat8 = floor(u_xlat8);
        u_xlat7 = (-u_xlat8) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat7;
        u_xlat1 = u_xlat1.xxxx + u_xlat7;
        u_xlat2.x = float(0.0);
        u_xlat2.w = float(1.0);
        u_xlat2.y = u_xlat4.x;
        u_xlat1 = u_xlat1 + u_xlat2;
        u_xlat2 = u_xlat1 * u_xlat1;
        u_xlat1 = u_xlat2 * float4(34.0, 34.0, 34.0, 34.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.00346020772, 0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(289.0, 289.0, 289.0, 289.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.0204081647, 0.0204081647, 0.0204081647, 0.0204081647);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(49.0, 49.0, 49.0, 49.0) + u_xlat1;
        u_xlat2 = u_xlat1 * float4(0.142857149, 0.142857149, 0.142857149, 0.142857149);
        u_xlat2 = floor(u_xlat2);
        u_xlat1 = (-u_xlat2) * float4(7.0, 7.0, 7.0, 7.0) + u_xlat1;
        u_xlat2 = u_xlat2 * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat1 = u_xlat1.xzyw * float4(0.285714298, 0.285714298, 0.285714298, 0.285714298) + float4(-0.928571403, -0.928571403, -0.928571403, -0.928571403);
        u_xlat4 = -abs(u_xlat2) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat4 = -abs(u_xlat1.xzwy) + u_xlat4.xywz;
        u_xlat7.xz = floor(u_xlat2.xy);
        u_xlat7.yw = floor(u_xlat1.xz);
        u_xlat7 = u_xlat7 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat8.xz = floor(u_xlat2.zw);
        u_xlat8.yw = floor(u_xlat1.yw);
        u_xlat8 = u_xlat8 * float4(2.0, 2.0, 2.0, 2.0) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlatb9 = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat4.xywz);
        u_xlat9.x = (u_xlatb9.x) ? float(-1.0) : float(-0.0);
        u_xlat9.y = (u_xlatb9.y) ? float(-1.0) : float(-0.0);
        u_xlat9.z = (u_xlatb9.z) ? float(-1.0) : float(-0.0);
        u_xlat9.w = (u_xlatb9.w) ? float(-1.0) : float(-0.0);
        u_xlat10.xz = u_xlat2.xy;
        u_xlat10.yw = u_xlat1.xz;
        u_xlat7 = u_xlat7.zwxy * u_xlat9.yyxx + u_xlat10.zwxy;
        u_xlat1.xz = u_xlat2.zw;
        u_xlat1 = u_xlat8 * u_xlat9.zzww + u_xlat1;
        u_xlat2.xy = u_xlat7.zw;
        u_xlat2.z = u_xlat4.x;
        u_xlat33 = dot(u_xlat2.xyz, u_xlat2.xyz);
        u_xlat7.z = u_xlat4.y;
        u_xlat35 = dot(u_xlat7.xyz, u_xlat7.xyz);
        u_xlat8.xy = u_xlat1.xy;
        u_xlat8.z = u_xlat4.w;
        u_xlat1.x = dot(u_xlat8.xyz, u_xlat8.xyz);
        u_xlat4.xy = u_xlat1.zw;
        u_xlat12 = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat33 = rsqrt(u_xlat33);
        u_xlat23 = rsqrt(u_xlat35);
        u_xlat1.x = rsqrt(u_xlat1.x);
        u_xlat12 = rsqrt(u_xlat12);
        u_xlat2.xyz = float3(u_xlat33) * u_xlat2.xyz;
        u_xlat7.xyz = float3(u_xlat23) * u_xlat7.xyz;
        u_xlat1.xzw = u_xlat1.xxx * u_xlat8.xyz;
        u_xlat4.xyz = float3(u_xlat12) * u_xlat4.xyz;
        u_xlat8.x = dot(u_xlat0.xyz, u_xlat0.xyz);
        u_xlat8.y = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat8.z = dot(u_xlat5.xyz, u_xlat5.xyz);
        u_xlat8.w = dot(u_xlat6.xyz, u_xlat6.xyz);
        u_xlat8 = (-u_xlat8) + float4(0.600000024, 0.600000024, 0.600000024, 0.600000024);
        u_xlat8 = max(u_xlat8, float4(0.0, 0.0, 0.0, 0.0));
        u_xlat8 = u_xlat8 * u_xlat8;
        u_xlat8 = u_xlat8 * u_xlat8;
        u_xlat0.x = dot(u_xlat2.xyz, u_xlat0.xyz);
        u_xlat0.y = dot(u_xlat7.xyz, u_xlat3.xyz);
        u_xlat0.z = dot(u_xlat1.xzw, u_xlat5.xyz);
        u_xlat0.w = dot(u_xlat4.xyz, u_xlat6.xyz);
        u_xlat0.x = dot(u_xlat8, u_xlat0);
        u_xlat0.x = u_xlat0.x * 42.0;
    } else {
        u_xlat0.x = 1.0;
    }
    u_xlati11 = int(u._samples) + int(0xFFFFFFFFu);
    u_xlat11 = float(u_xlati11);
    u_xlat0.x = u_xlat0.x * u._strength;
    u_xlat0.x = u_xlat0.x * 90.0 + u._direction;
    u_xlat0.x = u_xlat0.x * 0.0174532942;
    u_xlat1.x = sin((-u_xlat0.x));
    u_xlat1.y = cos(u_xlat0.x);
    u_xlat0.xz = u_xlat1.xy * float2(float2(u._radius, u._radius));
    u_xlat33 = u._radius * u._dispersion;
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat1.w = float(0.0);
    u_xlat2.x = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat24 = float(u_xlati_loop_1);
        u_xlat24 = u_xlat24 / u_xlat11;
        u_xlat24 = u_xlat24 + -0.5;
        u_xlat35 = -abs(u_xlat24) * 2.0 + 1.0;
        u_xlat3.xy = u_xlat0.xz * float2(u_xlat24) + in.acScreenNorm.xy;
        u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.xy);
        u_xlat3 = float4(u_xlat35) * u_xlat3;
        u_xlat2.x = u_xlat35 + u_xlat2.x;
        u_xlat24 = (-u_xlat35) + 1.0;
        u_xlat4.z = u_xlat24 * 3.0 + -1.5;
        u_xlat4.y = -abs(u_xlat4.z) + 1.0;
        u_xlat4.x = (-u_xlat4.z);
        u_xlat4.xyz = u_xlat4.xyz;
        u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
        u_xlat4.xyz = u_xlat3.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat3.xyz);
        u_xlat3.xyz = float3(u_xlat33) * u_xlat4.xyz + u_xlat3.xyz;
        u_xlat1 = u_xlat1 + u_xlat3;
    }
    u_xlat0 = u_xlat1 / u_xlat2.xxxx;
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
