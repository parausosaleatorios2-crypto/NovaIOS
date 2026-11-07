// ---------------------------------------------------------------------------
// Fill Audiovisualization Led (NV)
// origem : assets/effects/nv-nodevideo-fill-audiovisualization-led.xml
// id     : nv.effect.nodevideo-fill-audiovisualization-led
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_audiovisualization_ledParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _enable_colour;
    float _speed;
    float _horizontal_count;
    float _horizontal_spacing;
    float _vertical_count;
    float _vertical_spacing;
    float _reflection;
    float _symmetry;
    float _offset;
    float _invert;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
int u_xlati1;
bool3 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool3 u_xlatb4;
float4 u_xlat5;
bool3 u_xlatb5;
float3 u_xlat6;
bool3 u_xlatb6;
float3 u_xlat7;
float3 u_xlat8;
bool3 u_xlatb8;
float2 u_xlat9;
uint u_xlatu9;
float2 u_xlat18;
int2 u_xlati18;
float u_xlat27;
int u_xlati27;
bool u_xlatb27;
float u_xlat28;

fragment float4 fx_nv_nodevideo_fill_audiovisualization_led(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_audiovisualization_ledParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = in.acScreenNorm.y + (-u._offset);
    u_xlat9.x = in.acScreenNorm.x * u._horizontal_count;
    u_xlat18.x = u_xlat9.x * 3.14159274;
    u_xlat18.x = sin(u_xlat18.x);
    u_xlat18.x = u_xlat18.x + 1.0;
    u_xlat18.x = u_xlat18.x + (-u._horizontal_spacing);
    u_xlati27 = int((0.0<u_xlat18.x) ? 0xFFFFFFFFu : uint(0));
    u_xlati18.x = int((u_xlat18.x<0.0) ? 0xFFFFFFFFu : uint(0));
    u_xlati18.x = (-u_xlati27) + u_xlati18.x;
    u_xlat18.x = float(u_xlati18.x);
    u_xlat9.x = floor(u_xlat9.x);
    u_xlat9.x = u_xlat9.x / u._horizontal_count;
    u_xlatb1.xyz = equal(int4(u._symmetry, u._invert, u._blend_mode, u._symmetry), int4(1, 1, 1, 0)).xyz;
    u_xlat27 = u_xlat9.x * 2.0 + -1.0;
    u_xlat9.x = (u_xlatb1.x) ? abs(u_xlat27) : u_xlat9.x;
    u_xlat9.x = u_xlat9.x * 31.0;
    u_xlat9.x = floor(u_xlat9.x);
    u_xlat9.x = max(u_xlat9.x, 0.0);
    u_xlat9.x = min(u_xlat9.x, 30.0);
    u_xlatu9 = uint(u_xlat9.x);
    u_xlat9.x = u_xlat18.x * _bands[int(u_xlatu9)];
    u_xlat9.y = u_xlat0.x * u._vertical_count;
    u_xlat9.xy = u_xlat9.xy * float2(0.5, 3.14159274);
    u_xlat18.x = sin(u_xlat9.y);
    u_xlat18.x = u_xlat18.x + 1.0;
    u_xlat18.x = u_xlat18.x + (-u._vertical_spacing);
    u_xlati27 = int((0.0<u_xlat18.x) ? 0xFFFFFFFFu : uint(0));
    u_xlati18.x = int((u_xlat18.x<0.0) ? 0xFFFFFFFFu : uint(0));
    u_xlati18.x = (-u_xlati27) + u_xlati18.x;
    u_xlatb27 = u._enable_colour==1;
    u_xlat1.x = u_xlat0.x + -1.0;
    u_xlat28 = (-_cur_time) * u._speed + in.acScreenNorm.x;
    u_xlat2.xyz = float3(u_xlat28) + float3(0.0, -0.333333343, -0.666666687);
    u_xlat2.xyz = fract(u_xlat2.xyz);
    u_xlat3.xyz = u_xlat2.xyz * float3(3.0, 3.0, 3.0);
    u_xlatb4.xyz = greaterThanEqual(u_xlat2.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat4.x = u_xlatb4.x ? float(1.0) : 0.0;
    u_xlat4.y = u_xlatb4.y ? float(1.0) : 0.0;
    u_xlat4.z = u_xlatb4.z ? float(1.0) : 0.0;
;
    u_xlat5.xyz = (-u_xlat2.xyz) * float3(3.0, 3.0, 3.0) + float3(1.0, 1.0, 1.0);
    u_xlatb5.xyz = greaterThanEqual(u_xlat5.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat5.x = u_xlatb5.x ? float(1.0) : 0.0;
    u_xlat5.y = u_xlatb5.y ? float(1.0) : 0.0;
    u_xlat5.z = u_xlatb5.z ? float(1.0) : 0.0;
;
    u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
    u_xlat5.xyz = u_xlat2.xyz * float3(3.0, 3.0, 3.0) + float3(-1.0, -1.0, -1.0);
    u_xlatb5.xyz = greaterThanEqual(u_xlat5.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat5.x = u_xlatb5.x ? float(1.0) : 0.0;
    u_xlat5.y = u_xlatb5.y ? float(1.0) : 0.0;
    u_xlat5.z = u_xlatb5.z ? float(1.0) : 0.0;
;
    u_xlat6.xyz = (-u_xlat2.xyz) * float3(3.0, 3.0, 3.0) + float3(2.0, 2.0, 2.0);
    u_xlatb6.xyz = greaterThanEqual(u_xlat6.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat6.x = u_xlatb6.x ? float(1.0) : 0.0;
    u_xlat6.y = u_xlatb6.y ? float(1.0) : 0.0;
    u_xlat6.z = u_xlatb6.z ? float(1.0) : 0.0;
;
    u_xlat5.xyz = u_xlat5.xyz * u_xlat6.xyz;
    u_xlat6.xyz = u_xlat2.xyz * float3(3.0, 3.0, 3.0) + float3(-2.0, -2.0, -2.0);
    u_xlatb6.xyz = greaterThanEqual(u_xlat6.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat6.x = u_xlatb6.x ? float(1.0) : 0.0;
    u_xlat6.y = u_xlatb6.y ? float(1.0) : 0.0;
    u_xlat6.z = u_xlatb6.z ? float(1.0) : 0.0;
;
    u_xlat7.xyz = (-u_xlat2.xyz) * float3(3.0, 3.0, 3.0) + float3(3.0, 3.0, 3.0);
    u_xlatb8.xyz = greaterThanEqual(u_xlat7.xyzx, float4(0.0, 0.0, 0.0, 0.0)).xyz;
    u_xlat8.x = u_xlatb8.x ? float(1.0) : 0.0;
    u_xlat8.y = u_xlatb8.y ? float(1.0) : 0.0;
    u_xlat8.z = u_xlatb8.z ? float(1.0) : 0.0;
;
    u_xlat6.xyz = u_xlat6.xyz * u_xlat8.xyz;
    u_xlat3.xyz = u_xlat3.xyz * u_xlat3.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(18.0, 18.0, 18.0);
    u_xlat2.xyz = u_xlat3.xyz * float3(-2.0, -2.0, -2.0) + u_xlat2.xyz;
    u_xlat2.xyz = u_xlat2.xyz + float3(-3.0, -3.0, -3.0);
    u_xlat2.xyz = u_xlat2.xyz * u_xlat5.xyz;
    u_xlat2.xyz = u_xlat4.xyz * u_xlat3.xyz + u_xlat2.xyz;
    u_xlat3.xyz = u_xlat7.xyz * u_xlat7.xyz;
    u_xlat2.xyz = u_xlat6.xyz * u_xlat3.xyz + u_xlat2.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(0.5, 0.5, 0.5);
    u_xlat2.xyz = abs(u_xlat1.xxx) * u_xlat2.xyz;
    u_xlat2.xyz = bool(u_xlatb27) ? u_xlat2.xyz : float3(0.0, 0.0, 0.0);
    u_xlat2.xyz = (-u_xlat2.xyz) + float3(1.0, 1.0, 1.0);
    u_xlat3.xyz = u_xlat2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u_xlat2.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat2.xyz * u_xlat3.xyz;
    u_xlat3.xyz = u_xlat2.xyz * u_xlat2.xyz;
    u_xlat2.xyz = u_xlat2.xyz * u_xlat3.xyz;
    u_xlat27 = (-u_xlat0.x) + 1.0;
    u_xlat0.x = (u_xlatb1.y) ? u_xlat27 : u_xlat0.x;
    u_xlat0.x = (-u_xlat0.x) + 0.300000012;
    u_xlati27 = int((0.0<u_xlat0.x) ? 0xFFFFFFFFu : uint(0));
    u_xlati1 = int((u_xlat0.x<0.0) ? 0xFFFFFFFFu : uint(0));
    u_xlati18.y = (-u_xlati27) + u_xlati1;
    u_xlat18.xy = float2(u_xlati18.xy);
    u_xlat27 = u_xlat18.y + 1.0;
    u_xlat27 = u_xlat27 + u_xlat27;
    u_xlatb0 = abs(u_xlat0.x)>=u_xlat9.x;
    u_xlat0.x = (u_xlatb0) ? 0.0 : u_xlat18.x;
    u_xlat1.xyw = u_xlat0.xxx * u_xlat2.xyz;
    u_xlat2.xyz = float3(u_xlat27) * u_xlat1.xyw;
    u_xlat9.x = u._reflection * -0.25 + 0.25;
    u_xlat2.xyz = (-u_xlat2.xyz) * u_xlat9.xxx + u_xlat1.xyw;
    u_xlat18.x = u_xlat27 * u_xlat0.x;
    u_xlat2.w = (-u_xlat18.x) * u_xlat9.x + u_xlat0.x;
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat3 = u_xlat0 * u_xlat2;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat2.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat1 = (u_xlatb1.z) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat2.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat1 : u_xlat3;
    if(u._use_inner_mask != 0) {
        u_xlatb2.xy = equal(int4(u._show_inner_mask, u._b_clip_mask, u._show_inner_mask, u._show_inner_mask), int4(1, 1, 0, 0)).xy;
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
