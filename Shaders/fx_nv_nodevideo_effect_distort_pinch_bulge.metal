// ---------------------------------------------------------------------------
// Effect Distort Pinch Bulge (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-pinch-bulge.xml
// id     : nv.effect.nodevideo-effect-distort-pinch-bulge
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_pinch_bulgeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _strength;
    float _radius;
    float _feather;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
bool4 u_xlatb0;
float4 u_xlat1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
bool u_xlatb7;
float2 u_xlat8;
float2 u_xlat12;
float u_xlat14;
float u_xlat18;
float u_xlat19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_effect_distort_pinch_bulge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_pinch_bulgeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0.xy = greaterThanEqual(in.acScreenNorm.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb0.zw = greaterThanEqual(float4(0.0, 0.0, 1.0, 1.0), in.acScreenNorm.xxxy).zw;
    u_xlat0.x = u_xlatb0.x ? float(1.0) : 0.0;
    u_xlat0.y = u_xlatb0.y ? float(1.0) : 0.0;
    u_xlat0.z = u_xlatb0.z ? float(1.0) : 0.0;
    u_xlat0.w = u_xlatb0.w ? float(1.0) : 0.0;
;
    u_xlat0.x = u_xlat0.z * u_xlat0.x;
    u_xlat0.x = u_xlat0.y * u_xlat0.x;
    u_xlat6.x = float(1.0) / u._feather;
    u_xlat6.xy = u_xlat6.xx * in.acScreenNorm.xy;
    u_xlat6.xy = clamp(u_xlat6.xy, 0.0, 1.0);
    u_xlat1.xy = u_xlat6.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat6.xy = u_xlat6.xy * u_xlat6.xy;
    u_xlat0.yz = u_xlat6.xy * u_xlat1.xy;
    u_xlat0.xy = u_xlat0.wz * u_xlat0.xy;
    u_xlat12.xy = in.acScreenNorm.xy + float2(-1.0, -1.0);
    u_xlat1.x = float(1.0) / (-u._feather);
    u_xlat12.xy = u_xlat12.xy * u_xlat1.xx;
    u_xlat12.xy = clamp(u_xlat12.xy, 0.0, 1.0);
    u_xlat1.xy = u_xlat12.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat12.xy = u_xlat12.xy * u_xlat12.xy;
    u_xlat12.xy = u_xlat12.xy * u_xlat1.xy;
    u_xlat6.x = u_xlat12.x * u_xlat0.y;
    u_xlat6.x = u_xlat12.y * u_xlat6.x;
    u_xlat1.yz = in.acScreenNorm.xy + (-u._center.xy);
    u_xlat12.x = _viewport_ratio.xxxy.z / _viewport_ratio.xxxy.w;
    u_xlat1.x = u_xlat12.x * u_xlat1.y;
    u_xlat18 = dot(u_xlat1.xz, u_xlat1.xz);
    u_xlat18 = sqrt(u_xlat18);
    u_xlatb7 = u_xlat18<u._radius;
    u_xlat19 = u_xlat18 / u._radius;
    u_xlatb2.x = 0.0<u._strength;
    u_xlat8.x = u._radius / u_xlat18;
    u_xlat8.x = float(1.0) / u_xlat8.x;
    u_xlat8.x = u_xlat19 * u_xlat8.x;
    u_xlat8.x = clamp(u_xlat8.x, 0.0, 1.0);
    u_xlat14 = u_xlat8.x * -2.0 + 3.0;
    u_xlat8.x = u_xlat8.x * u_xlat8.x;
    u_xlat20 = u._strength * 0.75;
    u_xlat8.x = u_xlat14 * u_xlat8.x + -1.0;
    u_xlat8.x = u_xlat20 * u_xlat8.x + 1.0;
    u_xlat8.xy = u_xlat1.xz * u_xlat8.xx;
    u_xlat20 = u._strength * 0.75 + 1.0;
    u_xlat3.x = log2(u_xlat19);
    u_xlat20 = u_xlat20 * u_xlat3.x;
    u_xlat20 = exp2(u_xlat20);
    u_xlat20 = u_xlat20 * u._radius;
    u_xlat18 = u_xlat20 / u_xlat18;
    u_xlat19 = (-u_xlat19) + 1.0;
    u_xlat18 = u_xlat18 + -1.0;
    u_xlat18 = u_xlat19 * u_xlat18 + 1.0;
    u_xlat3.xy = float2(u_xlat18) * u_xlat1.xz;
    u_xlat2.xy = (u_xlatb2.x) ? u_xlat8.xy : u_xlat3.xy;
    u_xlat0.x = u_xlat0.x * u_xlat6.x;
    u_xlat6.xz = (-u_xlat1.xz) + u_xlat2.xy;
    u_xlat0.xy = u_xlat0.xx * u_xlat6.xz + u_xlat1.xz;
    u_xlat1.yz = (bool(u_xlatb7)) ? u_xlat0.xy : u_xlat1.xz;
    u_xlat1.x = u_xlat1.y / u_xlat12.x;
    u_xlat0.xy = u_xlat1.xz + u._center.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
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
