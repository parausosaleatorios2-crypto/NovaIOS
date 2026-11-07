// ---------------------------------------------------------------------------
// Dissolve2 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-dissolve2.xml
// id     : nv.effect.nodevideo-assetstore-dissolve2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_dissolve2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _trans_center;
    float2 _trans_scale;
    float _trans_rotation;
    float _edge_behaviour;
    float _interpolation;
    float _edge_width;
    float _edge_intensity;
    float4 _edge_color;
    float _direction;
    float _inverse;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool4 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float2 u_xlat12;
bool u_xlatb12;
float2 u_xlat13;
int2 u_xlati13;
bool2 u_xlatb13;
float2 u_xlat14;
bool2 u_xlatb14;
float u_xlat18;
bool u_xlatb18;
float u_xlat20;

fragment float4 fx_nv_nodevideo_assetstore_dissolve2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_dissolve2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> pattern_tex [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = float2(1.0, 1.0) / float2(u._trans_scale.x, u._trans_scale.y);
    u_xlat0.xy = u_xlat12.xy * u_xlat0.xy;
    u_xlat12.x = u._trans_rotation * 0.0174532942;
    u_xlat1.x = sin(u_xlat12.x);
    u_xlat2.x = cos(u_xlat12.x);
    u_xlat3.x = sin((-u_xlat12.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat3.z = u_xlat1.x;
    u_xlat1.x = dot(u_xlat0.xy, u_xlat3.yz);
    u_xlat1.y = dot(u_xlat0.xy, u_xlat3.xy);
    u_xlat0.xy = u_xlat1.xy + u._trans_center.xy;
    if(int(u._edge_behaviour) != 0) {
        u_xlatb12 = int(u._edge_behaviour)==1;
        u_xlatb1.xy = greaterThanEqual(u_xlat0.xyxx, (-u_xlat0.xyxx)).xy;
        u_xlat13.xy = fract(abs(u_xlat0.xy));
        u_xlat1.x = (u_xlatb1.x) ? u_xlat13.x : (-u_xlat13.x);
        u_xlat1.y = (u_xlatb1.y) ? u_xlat13.y : (-u_xlat13.y);
        u_xlatb13.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
        u_xlat2.xy = fract(u_xlat0.xy);
        u_xlat2.xy = (-u_xlat2.xy) + float2(1.0, 1.0);
        u_xlatb14.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat0.xyxy).xy;
        u_xlati13.xy = int2(uint2((uint(u_xlatb13.x) * 0xffffffffu) | (uint(u_xlatb14.x) * 0xffffffffu), (uint(u_xlatb13.y) * 0xffffffffu) | (uint(u_xlatb14.y) * 0xffffffffu)));
        u_xlat13.x = (u_xlati13.x != 0) ? u_xlat2.x : u_xlat0.x;
        u_xlat13.y = (u_xlati13.y != 0) ? u_xlat2.y : u_xlat0.y;
        u_xlat0.xy = (bool(u_xlatb12)) ? abs(u_xlat1.xy) : u_xlat13.xy;
    }
    u_xlat0.x = pattern_tex.sample(__nv_smp, u_xlat0.xy).x;
    u_xlat6.xy = in.acScreenNorm.xy + (-u._trans_center.xy);
    u_xlatb1 = equal(int4(int(u._direction)), int4(1, 2, 3, 4));
    u_xlat6.xy = abs(u_xlat6.xy) + abs(u_xlat6.xy);
    u_xlatb2.xy = equal(int4(int(u._direction), int(u._inverse), int(u._direction), int(u._direction)), int4(5, 1, 0, 0)).xy;
    u_xlat14.xy = float2(_viewport_ratio.x, _viewport_ratio.y) * u._trans_center.xy;
    u_xlat14.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat14.xy);
    u_xlat18 = dot(u_xlat14.xy, u_xlat14.xy);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat18 = u_xlat18 + u_xlat18;
    u_xlat12.x = (u_xlatb1.w) ? u_xlat6.y : u_xlat18;
    u_xlatb18 = u_xlatb1.w || u_xlatb2.x;
    u_xlat6.x = (u_xlatb1.z) ? u_xlat6.x : u_xlat12.x;
    u_xlatb12 = u_xlatb18 || u_xlatb1.z;
    u_xlat6.x = (u_xlatb1.y) ? in.acScreenNorm.y : u_xlat6.x;
    u_xlatb12 = u_xlatb12 || u_xlatb1.y;
    u_xlat6.x = (u_xlatb1.x) ? in.acScreenNorm.x : u_xlat6.x;
    u_xlatb12 = u_xlatb12 || u_xlatb1.x;
    u_xlat6.x = u_xlatb12 ? u_xlat6.x : float(0.0);
    u_xlat12.x = (-u_xlat6.x) + 1.0;
    u_xlat6.x = (u_xlatb2.y) ? u_xlat12.x : u_xlat6.x;
    u_xlat6.x = u_xlat6.x + u_xlat0.x;
    u_xlat6.x = u_xlat6.x * 0.5;
    u_xlat0.x = (int(u._direction) != 0) ? u_xlat6.x : u_xlat0.x;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat6.xyz = u._edge_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat6.xyz = u._edge_color.xyz * u_xlat6.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat6.xyz * u._edge_color.xyz;
    u_xlat20 = (-u._edge_color.w) + 1.0;
    u_xlat6.xyz = (-u._edge_color.xyz) * u_xlat6.xyz + u_xlat1.xyz;
    u_xlat2.xyz = float3(u_xlat20) * u_xlat6.xyz + u_xlat2.xyz;
    u_xlat6.x = u_xlat0.x + (-u._interpolation);
    u_xlat12.x = float(1.0) / u._edge_width;
    u_xlat6.x = u_xlat12.x * u_xlat6.x;
    u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
    u_xlat12.x = u_xlat6.x * -2.0 + 3.0;
    u_xlat6.x = u_xlat6.x * u_xlat6.x;
    u_xlat6.x = u_xlat6.x * u_xlat12.x;
    u_xlat12.x = (-u._edge_width) + u._interpolation;
    u_xlat18 = (-u_xlat12.x) + u._interpolation;
    u_xlat0.x = (-u_xlat12.x) + u_xlat0.x;
    u_xlat12.x = float(1.0) / u_xlat18;
    u_xlat0.x = u_xlat12.x * u_xlat0.x;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat12.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat18 = u._edge_intensity * 4.0;
    u_xlat6.x = log2(u_xlat6.x);
    u_xlat6.x = u_xlat6.x * u_xlat18;
    u_xlat6.x = exp2(u_xlat6.x);
    u_xlat0.x = (-u_xlat12.x) * u_xlat0.x + 1.0;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u_xlat18;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat2.w = u_xlat1.w;
    u_xlat3 = u_xlat1 + (-u_xlat2);
    u_xlat3 = u_xlat6.xxxx * u_xlat3 + u_xlat2;
    u_xlat0 = u_xlat0.xxxx * (-u_xlat3) + u_xlat3;
    u_xlat0.w = u_xlat2.w * u_xlat0.w;
    u_xlat0 = u_xlat0.wwww * u_xlat0;
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
