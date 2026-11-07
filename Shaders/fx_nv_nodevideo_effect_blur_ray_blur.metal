// ---------------------------------------------------------------------------
// Effect Blur Ray Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-ray-blur.xml
// id     : nv.effect.nodevideo-effect-blur-ray-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_ray_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _start_pos;
    float _samples;
    float _brightness;
    float _amount;
    float _dispersion;
    float _enable_turbulence;
    float _evolution;
    float2 _scale;
    float _strength;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
bool u_xlatb6;
float3 u_xlat7;
bool u_xlatb7;
float4 u_xlat8;
float u_xlat16;
int u_xlati16;
float2 u_xlat18;
bool u_xlatb18;
float2 u_xlat19;
bool u_xlatb19;
float2 u_xlat20;
int u_xlati23;
bool u_xlatb27;
int u_xlati32;

fragment float4 fx_nv_nodevideo_effect_blur_ray_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_ray_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = (-in.acScreenNorm.xy) + u._start_pos.xy;
    u_xlatb18 = 0<int(u._enable_turbulence);
    if(u_xlatb18){
        u_xlat18.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat1.xy = u_xlat18.xy * u._scale.xy + float2(0.5, 0.5);
        u_xlat1.z = u._evolution;
        u_xlat18.x = dot(u_xlat1.xz, float2(0.366025418, 0.366025418));
        u_xlat18.xy = u_xlat18.xx + u_xlat1.xz;
        u_xlat18.xy = floor(u_xlat18.xy);
        u_xlat1.xw = (-u_xlat18.xy) + u_xlat1.xz;
        u_xlat2.x = dot(u_xlat18.xy, float2(0.211324871, 0.211324871));
        u_xlat1.xw = u_xlat1.xw + u_xlat2.xx;
        u_xlatb2.x = u_xlat1.w<u_xlat1.x;
        u_xlat3 = u_xlat1.xwxw + float4(0.211324871, 0.211324871, -0.577350259, -0.577350259);
        u_xlat2 = (u_xlatb2.x) ? float4(0.0, 1.0, -1.0, -0.0) : float4(1.0, 0.0, -0.0, -1.0);
        u_xlat3.xy = u_xlat2.zw + u_xlat3.xy;
        u_xlat4.xy = u_xlat18.xy * float2(0.00346020772, 0.00346020772);
        u_xlat4.xy = floor(u_xlat4.xy);
        u_xlat18.xy = (-u_xlat4.xy) * float2(289.0, 289.0) + u_xlat18.xy;
        u_xlat4.x = float(0.0);
        u_xlat4.z = float(1.0);
        u_xlat4.y = u_xlat2.x;
        u_xlat4.xyz = u_xlat18.yyy + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat5.xyz * float3(34.0, 34.0, 34.0) + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat5.xyz = floor(u_xlat5.xyz);
        u_xlat4.xyz = (-u_xlat5.xyz) * float3(289.0, 289.0, 289.0) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat18.xxx + u_xlat4.xyz;
        u_xlat2.x = float(0.0);
        u_xlat2.z = float(1.0);
        u_xlat2.xyz = u_xlat2.xyz + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat2.xyz * u_xlat2.xyz;
        u_xlat2.xyz = u_xlat4.xyz * float3(34.0, 34.0, 34.0) + u_xlat2.xyz;
        u_xlat4.xyz = u_xlat2.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat4.xyz = floor(u_xlat4.xyz);
        u_xlat2.xyz = (-u_xlat4.xyz) * float3(289.0, 289.0, 289.0) + u_xlat2.xyz;
        u_xlat4.x = dot(u_xlat1.xw, u_xlat1.xw);
        u_xlat4.y = dot(u_xlat3.xy, u_xlat3.xy);
        u_xlat4.z = dot(u_xlat3.zw, u_xlat3.zw);
        u_xlat4.xyz = (-u_xlat4.xyz) + float3(0.5, 0.5, 0.5);
        u_xlat4.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat2.xyz = u_xlat2.xyz * float3(0.024390243, 0.024390243, 0.024390243);
        u_xlat2.xyz = fract(u_xlat2.xyz);
        u_xlat5.xyz = u_xlat2.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = abs(u_xlat5.xyz) + float3(-0.5, -0.5, -0.5);
        u_xlat2.xyz = u_xlat2.xyz * float3(2.0, 2.0, 2.0) + float3(-0.5, -0.5, -0.5);
        u_xlat2.xyz = floor(u_xlat2.xyz);
        u_xlat2.xyz = (-u_xlat2.xyz) + u_xlat5.xyz;
        u_xlat5.xyz = u_xlat6.xyz * u_xlat6.xyz;
        u_xlat5.xyz = u_xlat2.xyz * u_xlat2.xyz + u_xlat5.xyz;
        u_xlat5.xyz = (-u_xlat5.xyz) * float3(0.853734732, 0.853734732, 0.853734732) + float3(1.79284286, 1.79284286, 1.79284286);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat18.x = u_xlat1.w * u_xlat6.x;
        u_xlat5.x = u_xlat2.x * u_xlat1.x + u_xlat18.x;
        u_xlat18.xy = u_xlat3.yw * u_xlat6.yz;
        u_xlat5.yz = u_xlat2.yz * u_xlat3.xz + u_xlat18.xy;
        u_xlat18.x = dot(u_xlat4.xyz, u_xlat5.xyz);
        u_xlat18.x = u_xlat18.x * u._strength;
        u_xlat0.x = u_xlat18.x * 130.0 + u_xlat0.x;
        u_xlat18.x = dot(u_xlat1.yz, float2(0.366025418, 0.366025418));
        u_xlat18.xy = u_xlat18.xx + u_xlat1.yz;
        u_xlat18.xy = floor(u_xlat18.xy);
        u_xlat1.xy = (-u_xlat18.xy) + u_xlat1.yz;
        u_xlat19.x = dot(u_xlat18.xy, float2(0.211324871, 0.211324871));
        u_xlat1.xy = u_xlat19.xx + u_xlat1.xy;
        u_xlatb19 = u_xlat1.y<u_xlat1.x;
        u_xlat2 = u_xlat1.xyxy + float4(0.211324871, 0.211324871, -0.577350259, -0.577350259);
        u_xlat3 = (bool(u_xlatb19)) ? float4(0.0, 1.0, -1.0, -0.0) : float4(1.0, 0.0, -0.0, -1.0);
        u_xlat2.xy = u_xlat2.xy + u_xlat3.zw;
        u_xlat19.xy = u_xlat18.xy * float2(0.00346020772, 0.00346020772);
        u_xlat19.xy = floor(u_xlat19.xy);
        u_xlat18.xy = (-u_xlat19.xy) * float2(289.0, 289.0) + u_xlat18.xy;
        u_xlat4.x = float(0.0);
        u_xlat4.z = float(1.0);
        u_xlat4.y = u_xlat3.x;
        u_xlat4.xyz = u_xlat18.yyy + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat5.xyz * float3(34.0, 34.0, 34.0) + u_xlat4.xyz;
        u_xlat5.xyz = u_xlat4.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat5.xyz = floor(u_xlat5.xyz);
        u_xlat4.xyz = (-u_xlat5.xyz) * float3(289.0, 289.0, 289.0) + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat18.xxx + u_xlat4.xyz;
        u_xlat3.x = float(0.0);
        u_xlat3.z = float(1.0);
        u_xlat3.xyz = u_xlat3.xyz + u_xlat4.xyz;
        u_xlat4.xyz = u_xlat3.xyz * u_xlat3.xyz;
        u_xlat3.xyz = u_xlat4.xyz * float3(34.0, 34.0, 34.0) + u_xlat3.xyz;
        u_xlat4.xyz = u_xlat3.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
        u_xlat4.xyz = floor(u_xlat4.xyz);
        u_xlat3.xyz = (-u_xlat4.xyz) * float3(289.0, 289.0, 289.0) + u_xlat3.xyz;
        u_xlat4.x = dot(u_xlat1.xy, u_xlat1.xy);
        u_xlat4.y = dot(u_xlat2.xy, u_xlat2.xy);
        u_xlat4.z = dot(u_xlat2.zw, u_xlat2.zw);
        u_xlat4.xyz = (-u_xlat4.xyz) + float3(0.5, 0.5, 0.5);
        u_xlat4.xyz = max(u_xlat4.xyz, float3(0.0, 0.0, 0.0));
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat3.xyz = u_xlat3.xyz * float3(0.024390243, 0.024390243, 0.024390243);
        u_xlat3.xyz = fract(u_xlat3.xyz);
        u_xlat5.xyz = u_xlat3.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = abs(u_xlat5.xyz) + float3(-0.5, -0.5, -0.5);
        u_xlat3.xyz = u_xlat3.xyz * float3(2.0, 2.0, 2.0) + float3(-0.5, -0.5, -0.5);
        u_xlat3.xyz = floor(u_xlat3.xyz);
        u_xlat3.xyz = (-u_xlat3.xyz) + u_xlat5.xyz;
        u_xlat5.xyz = u_xlat6.xyz * u_xlat6.xyz;
        u_xlat5.xyz = u_xlat3.xyz * u_xlat3.xyz + u_xlat5.xyz;
        u_xlat5.xyz = (-u_xlat5.xyz) * float3(0.853734732, 0.853734732, 0.853734732) + float3(1.79284286, 1.79284286, 1.79284286);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat18.x = u_xlat1.y * u_xlat6.x;
        u_xlat1.x = u_xlat3.x * u_xlat1.x + u_xlat18.x;
        u_xlat18.xy = u_xlat2.yw * u_xlat6.yz;
        u_xlat1.yz = u_xlat3.yz * u_xlat2.xz + u_xlat18.xy;
        u_xlat18.x = dot(u_xlat4.xyz, u_xlat1.xyz);
        u_xlat18.x = u_xlat18.x * u._strength;
        u_xlat0.y = u_xlat18.x * 130.0 + u_xlat0.y;
    }
    u_xlat18.x = float(int(u._samples));
    u_xlat0.xy = u_xlat0.xy / u_xlat18.xx;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.xy = u_xlat0.xy * float2(u._amount) + in.acScreenNorm.xy;
    u_xlatb27 = int(u._samples)==2;
    u_xlat3 = u_xlat1 * float4(float4(u._brightness, u._brightness, u._brightness, u._brightness));
    u_xlat3 = (bool(u_xlatb27)) ? u_xlat3 : u_xlat1;
    u_xlat20.xy = (-float2(u._amount)) + float2(1.0, 2.0);
    u_xlat4 = u_xlat3;
    u_xlat5.xy = u_xlat2.xy;
    u_xlati23 = int(u._samples);
    for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<u_xlati23 ; u_xlati_loop_1++)
    {
        u_xlat6 = inputImg.sample(__nv_smp, u_xlat5.xy);
        u_xlat7.x = float(u_xlati_loop_1);
        u_xlati16 = u_xlati23 + int(0xFFFFFFFFu);
        u_xlat16 = float(u_xlati16);
        u_xlat7.x = u_xlat7.x / u_xlat16;
        u_xlat7.z = u_xlat7.x * 3.0 + -1.5;
        u_xlat7.y = -abs(u_xlat7.z) + 1.0;
        u_xlat7.x = (-u_xlat7.z);
        u_xlat7.xyz = u_xlat7.xyz;
        u_xlat7.xyz = clamp(u_xlat7.xyz, 0.0, 1.0);
        u_xlat7.xyz = u_xlat6.xyz * u_xlat7.xyz;
        u_xlat7.xyz = u_xlat7.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat6.xyz);
        u_xlat6.xyz = float3(float3(u._dispersion, u._dispersion, u._dispersion)) * u_xlat7.xyz + u_xlat6.xyz;
        u_xlatb7 = u_xlati23==2;
        u_xlat8 = u_xlat6 * u_xlat20.xxxx + u_xlat4;
        u_xlat6 = u_xlat6 * float4(float4(u._brightness, u._brightness, u._brightness, u._brightness)) + u_xlat4;
        u_xlat4 = (bool(u_xlatb7)) ? u_xlat8 : u_xlat6;
        u_xlat5.xy = u_xlat0.xy * float2(u._amount) + u_xlat5.xy;
    }
    u_xlat2 = u_xlat4 / u_xlat20.yyyy;
    u_xlat3 = u_xlat4 / u_xlat18.xxxx;
    u_xlat0 = (bool(u_xlatb27)) ? u_xlat2 : u_xlat3;
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
