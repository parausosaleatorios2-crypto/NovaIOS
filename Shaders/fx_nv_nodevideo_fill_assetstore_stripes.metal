// ---------------------------------------------------------------------------
// Fill Assetstore Stripes (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-stripes.xml
// id     : nv.effect.nodevideo-fill-assetstore-stripes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_stripesParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _rotation;
    float _width;
    float _smoothing;
    float _phase;
    float _shutters;
    float _count;
    float _blend_mode;
    float _gradient;
    float _invert;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float3 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool3 u_xlatb7;
float u_xlat8;
bool u_xlatb9;
float u_xlat13;
float u_xlat14;
bool u_xlatb14;
float u_xlat18;
bool u_xlatb18;
float u_xlat20;
bool u_xlatb20;

fragment float4 fx_nv_nodevideo_fill_assetstore_stripes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_stripesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u._color.xyz;
    u_xlat1.x = u._phase;
    u_xlat1.y = -0.5;
    u_xlat1.xy = u_xlat1.xy + in.acScreenNorm.xy;
    u_xlat1.z = u_xlat1.x + -0.5;
    u_xlat1.xy = u_xlat1.zy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat18 = u._rotation * 0.0174532942;
    u_xlat2.x = sin(u_xlat18);
    u_xlat3.x = cos(u_xlat18);
    u_xlat3.y = u_xlat2.x;
    u_xlat18 = dot(u_xlat1.xy, u_xlat3.xy);
    u_xlat1.x = u_xlat18 * u._count;
    u_xlatb7.xyz = equal(int4(int(u._gradient), int(u._shutters), int(u._blend_mode), int(u._blend_mode)), int4(1, 1, 1, 1)).xyz;
    u_xlat2.x = u_xlat18 * u._count + (-u._phase);
    u_xlat8 = abs(u_xlat2.x) + 1.0;
    u_xlat8 = (u_xlatb7.x) ? u_xlat8 : 1.0;
    if(u_xlatb7.y){
        if(u_xlatb7.x){
            u_xlatb7.x = 0.0<u_xlat2.x;
            u_xlat13 = (-u._smoothing) + 0.5;
            u_xlat2.x = u._smoothing + 0.5;
            u_xlat14 = u_xlat18 * u._count + (-u._count);
            u_xlatb20 = abs(u_xlat14)>=-abs(u_xlat14);
            u_xlat14 = fract(abs(u_xlat14));
            u_xlat14 = (u_xlatb20) ? u_xlat14 : (-u_xlat14);
            u_xlat20 = u._width * u_xlat8 + 0.00999999978;
            u_xlat14 = u_xlat14 + 0.00999999978;
            u_xlat20 = float(1.0) / u_xlat20;
            u_xlat14 = u_xlat20 * u_xlat14;
            u_xlat14 = clamp(u_xlat14, 0.0, 1.0);
            u_xlat3.x = u_xlat14 * -2.0 + 3.0;
            u_xlat14 = u_xlat14 * u_xlat14;
            u_xlat2.z = (-u_xlat3.x) * u_xlat14 + 1.0;
            u_xlat2.xz = (-float2(u_xlat13)) + u_xlat2.xz;
            u_xlat2.x = float(1.0) / u_xlat2.x;
            u_xlat14 = u_xlat2.x * u_xlat2.z;
            u_xlat14 = clamp(u_xlat14, 0.0, 1.0);
            u_xlat3.x = u_xlat14 * -2.0 + 3.0;
            u_xlat14 = u_xlat14 * u_xlat14;
            u_xlat14 = u_xlat14 * u_xlat3.x;
            u_xlat3.x = (-u_xlat18) * u._count + (-u._count);
            u_xlat3.x = u_xlat3.x + 1.0;
            u_xlatb9 = abs(u_xlat3.x)>=-abs(u_xlat3.x);
            u_xlat3.x = fract(abs(u_xlat3.x));
            u_xlat3.x = (u_xlatb9) ? u_xlat3.x : (-u_xlat3.x);
            u_xlat3.x = u_xlat3.x + 0.00999999978;
            u_xlat20 = u_xlat20 * u_xlat3.x;
            u_xlat20 = clamp(u_xlat20, 0.0, 1.0);
            u_xlat3.x = u_xlat20 * -2.0 + 3.0;
            u_xlat20 = u_xlat20 * u_xlat20;
            u_xlat13 = (-u_xlat3.x) * u_xlat20 + (-u_xlat13);
            u_xlat13 = u_xlat13 + 1.0;
            u_xlat13 = u_xlat2.x * u_xlat13;
            u_xlat13 = clamp(u_xlat13, 0.0, 1.0);
            u_xlat2.x = u_xlat13 * -2.0 + 3.0;
            u_xlat13 = u_xlat13 * u_xlat13;
            u_xlat13 = u_xlat13 * u_xlat2.x;
            u_xlat7 = (u_xlatb7.x) ? u_xlat14 : u_xlat13;
        } else {
            u_xlat13 = (-u._smoothing) + 0.5;
            u_xlat2.x = u._smoothing + 0.5;
            u_xlat18 = u_xlat18 * u._count + (-u._count);
            u_xlatb14 = abs(u_xlat18)>=-abs(u_xlat18);
            u_xlat18 = fract(abs(u_xlat18));
            u_xlat18 = (u_xlatb14) ? u_xlat18 : (-u_xlat18);
            u_xlat14 = u._width * u_xlat8 + 0.00999999978;
            u_xlat18 = u_xlat18 + 0.00999999978;
            u_xlat14 = float(1.0) / u_xlat14;
            u_xlat18 = u_xlat18 * u_xlat14;
            u_xlat18 = clamp(u_xlat18, 0.0, 1.0);
            u_xlat14 = u_xlat18 * -2.0 + 3.0;
            u_xlat18 = u_xlat18 * u_xlat18;
            u_xlat18 = (-u_xlat14) * u_xlat18 + 1.0;
            u_xlat2.x = (-u_xlat13) + u_xlat2.x;
            u_xlat18 = (-u_xlat13) + u_xlat18;
            u_xlat13 = float(1.0) / u_xlat2.x;
            u_xlat18 = u_xlat18 * u_xlat13;
            u_xlat18 = clamp(u_xlat18, 0.0, 1.0);
            u_xlat13 = u_xlat18 * -2.0 + 3.0;
            u_xlat18 = u_xlat18 * u_xlat18;
            u_xlat7 = u_xlat18 * u_xlat13;
        }
    } else {
        u_xlat18 = (-u._smoothing) + 0.5;
        u_xlat13 = u._smoothing + 0.5;
        u_xlat1.x = u_xlat1.x * 3.14159274;
        u_xlat1.x = sin(u_xlat1.x);
        u_xlat2.x = u._width * u_xlat8 + 0.00999999978;
        u_xlat1.x = abs(u_xlat1.x) + 0.00999999978;
        u_xlat2.x = float(1.0) / u_xlat2.x;
        u_xlat1.x = u_xlat1.x * u_xlat2.x;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat2.x = u_xlat1.x * -2.0 + 3.0;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = (-u_xlat2.x) * u_xlat1.x + 1.0;
        u_xlat13 = (-u_xlat18) + u_xlat13;
        u_xlat18 = (-u_xlat18) + u_xlat1.x;
        u_xlat1.x = float(1.0) / u_xlat13;
        u_xlat18 = u_xlat18 * u_xlat1.x;
        u_xlat18 = clamp(u_xlat18, 0.0, 1.0);
        u_xlat1.x = u_xlat18 * -2.0 + 3.0;
        u_xlat18 = u_xlat18 * u_xlat18;
        u_xlat7 = u_xlat18 * u_xlat1.x;
    }
    u_xlatb18 = 0<int(u._invert);
    u_xlat1.x = (-u_xlat7) + 1.0;
    u_xlat18 = (u_xlatb18) ? u_xlat1.x : u_xlat7;
    u_xlat2.xyz = float3(u_xlat18) * u_xlat0.xyz;
    u_xlat2.w = u_xlat18 * u._color.w;
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat18) + u_xlat3.xyz;
    u_xlat0.w = u_xlat3.w;
    u_xlat0 = (u_xlatb7.z) ? u_xlat4 : u_xlat0;
    u_xlat4.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat4;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
