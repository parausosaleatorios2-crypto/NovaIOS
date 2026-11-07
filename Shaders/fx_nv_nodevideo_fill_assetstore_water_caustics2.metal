// ---------------------------------------------------------------------------
// Fill Assetstore Water Caustics2 (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-water-caustics2.xml
// id     : nv.effect.nodevideo-fill-assetstore-water-caustics2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_water_caustics2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _background_color;
    float2 _scale;
    float2 _offset;
    float _intensity;
    float _evolution;
    float _strength;
    float _dispersion;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
float2 u_xlat13;
float u_xlat18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_fill_assetstore_water_caustics2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_water_caustics2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._background_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._background_color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat13.xy = float2(_viewport_ratio.x, _viewport_ratio.y) * u._scale.xy;
    u_xlat1.xy = u_xlat1.xy * u_xlat13.xy;
    u_xlat1.xy = u_xlat1.xy * float2(10.0, 10.0) + float2(u._offset.x, u._offset.y);
    u_xlat1.xy = u_xlat1.xy + float2(0.5, 0.5);
    u_xlat1.z = u._evolution;
    u_xlat2.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat2.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat2.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat2.xyz * float3(0.400000006, 0.400000006, 0.400000006);
    u_xlat2.xyz = fract(u_xlat1.xyz);
    u_xlat2.xyz = (-u_xlat2.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat18 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat2.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat2.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat2.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat2.xyz * float3(0.300000012, 0.300000012, 0.300000012);
    u_xlat2.xyz = fract(u_xlat1.xyz);
    u_xlat2.xyz = (-u_xlat2.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat18 = min(u_xlat18, u_xlat19);
    u_xlat2.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat2.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat2.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat2.xyz * float3(0.200000003, 0.200000003, 0.200000003);
    u_xlat2.xyz = fract(u_xlat1.xyz);
    u_xlat2.xyz = (-u_xlat2.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat2.xyz, u_xlat2.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat2.x = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.400000006, 0.400000006, 0.400000006);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat18 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.300000012, 0.300000012, 0.300000012);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat18 = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.200000003, 0.200000003, 0.200000003);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat2.y = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.400000006, 0.400000006, 0.400000006);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat18 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.300000012, 0.300000012, 0.300000012);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat18 = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.200000003, 0.200000003, 0.200000003);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat2.z = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.400000006, 0.400000006, 0.400000006);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat18 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.300000012, 0.300000012, 0.300000012);
    u_xlat3.xyz = fract(u_xlat1.xyz);
    u_xlat3.xyz = (-u_xlat3.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat19 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat19 = sqrt(u_xlat19);
    u_xlat18 = min(u_xlat18, u_xlat19);
    u_xlat3.x = dot(u_xlat1.xyz, float3(-2.0, 3.0, 1.0));
    u_xlat3.y = dot(u_xlat1.xyz, float3(-1.0, -2.0, 2.0));
    u_xlat3.z = dot(u_xlat1.xzy, float3(2.0, 2.0, 1.0));
    u_xlat1.xyz = u_xlat3.xyz * float3(0.200000003, 0.200000003, 0.200000003);
    u_xlat1.xyz = fract(u_xlat1.xyz);
    u_xlat1.xyz = (-u_xlat1.xyz) + float3(0.5, 0.5, 0.5);
    u_xlat1.x = dot(u_xlat1.xyz, u_xlat1.xyz);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat18 = min(u_xlat18, u_xlat1.x);
    u_xlat1.x = u._strength * 0.100000001;
    u_xlat1.x = float(1.0) / u_xlat1.x;
    u_xlat18 = log2(u_xlat18);
    u_xlat18 = u_xlat18 * u_xlat1.x;
    u_xlat18 = exp2(u_xlat18);
    u_xlat18 = u_xlat18 * u._intensity;
    u_xlat18 = u_xlat18 * 10.0;
    u_xlat1.xy = u_xlat2.xy * float2(u_xlat18);
    u_xlat1.x = u_xlat1.y + u_xlat1.x;
    u_xlat1.x = u_xlat18 * u_xlat2.z + u_xlat1.x;
    u_xlat1.x = u_xlat1.x * 0.333333343;
    u_xlat7.xyz = float3(u_xlat18) * u_xlat2.xyz + (-u_xlat1.xxx);
    u_xlat1.xyz = float3(float3(u._dispersion, u._dispersion, u._dispersion)) * u_xlat7.xyz + u_xlat1.xxx;
    u_xlat0.xyz = u._background_color.xyz * u_xlat0.xyz + u_xlat1.xyz;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat0.w = 1.0;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat1.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat4.xyz = u_xlat0.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat4;
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
