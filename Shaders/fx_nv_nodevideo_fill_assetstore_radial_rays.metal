// ---------------------------------------------------------------------------
// Fill Assetstore Radial Rays (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-radial-rays.xml
// id     : nv.effect.nodevideo-fill-assetstore-radial-rays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_radial_raysParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _amount;
    float _angle;
    float2 _center;
    float _feather;
    float _twirl;
    float _width;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
bool u_xlatb6;
float2 u_xlat12;
bool u_xlatb12;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_fill_assetstore_radial_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_radial_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = float2(u._center.x, u._center.y) + float2(-0.5, -0.5);
    u_xlat0.xy = (-u_xlat12.xy) + u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.x = u._angle * 0.0174532942;
    u_xlat1.x = sin(u_xlat12.x);
    u_xlat2.x = cos(u_xlat12.x);
    u_xlat3.x = sin((-u_xlat12.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat2.x = dot(u_xlat3.yx, u_xlat0.xy);
    u_xlat3.z = u_xlat1.x;
    u_xlat2.y = dot(u_xlat3.zy, u_xlat0.xy);
    u_xlat0.x = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u._twirl;
    u_xlat6.x = min(abs(u_xlat2.x), abs(u_xlat2.y));
    u_xlat12.x = max(abs(u_xlat2.x), abs(u_xlat2.y));
    u_xlat12.x = float(1.0) / u_xlat12.x;
    u_xlat6.x = u_xlat12.x * u_xlat6.x;
    u_xlat12.x = u_xlat6.x * u_xlat6.x;
    u_xlat18 = u_xlat12.x * 0.0208350997 + -0.0851330012;
    u_xlat18 = u_xlat12.x * u_xlat18 + 0.180141002;
    u_xlat18 = u_xlat12.x * u_xlat18 + -0.330299497;
    u_xlat12.x = u_xlat12.x * u_xlat18 + 0.999866009;
    u_xlat18 = u_xlat12.x * u_xlat6.x;
    u_xlatb1 = abs(u_xlat2.x)<abs(u_xlat2.y);
    u_xlat18 = u_xlat18 * -2.0 + 1.57079637;
    u_xlat18 = u_xlatb1 ? u_xlat18 : float(0.0);
    u_xlat6.x = u_xlat6.x * u_xlat12.x + u_xlat18;
    u_xlatb12 = u_xlat2.x<(-u_xlat2.x);
    u_xlat12.x = u_xlatb12 ? -3.14159274 : float(0.0);
    u_xlat6.x = u_xlat12.x + u_xlat6.x;
    u_xlat12.x = min(u_xlat2.x, u_xlat2.y);
    u_xlat18 = max(u_xlat2.x, u_xlat2.y);
    u_xlatb12 = u_xlat12.x<(-u_xlat12.x);
    u_xlatb18 = u_xlat18>=(-u_xlat18);
    u_xlatb12 = u_xlatb18 && u_xlatb12;
    u_xlat6.x = (u_xlatb12) ? (-u_xlat6.x) : u_xlat6.x;
    u_xlat6.x = u_xlat6.x + 3.14159274;
    u_xlat0.x = u_xlat0.x * 6.28318548 + u_xlat6.x;
    u_xlat0.x = u_xlat0.x * u._amount;
    u_xlat0.x = u_xlat0.x * 0.159154937;
    u_xlatb6 = u_xlat0.x>=(-u_xlat0.x);
    u_xlat0.x = fract(abs(u_xlat0.x));
    u_xlat0.x = (u_xlatb6) ? u_xlat0.x : (-u_xlat0.x);
    u_xlat0.x = u_xlat0.x + u_xlat0.x;
    u_xlatb6 = 1.0<abs(u_xlat0.x);
    u_xlat12.x = -abs(u_xlat0.x) + 2.0;
    u_xlat0.x = (u_xlatb6) ? u_xlat12.x : abs(u_xlat0.x);
    u_xlat0.x = u_xlat0.x + -0.5;
    u_xlat6.x = u._width + -0.5;
    u_xlat0.x = (-u_xlat6.x) + u_xlat0.x;
    u_xlat6.x = u._feather * -29.0 + 30.0;
    u_xlat0.x = u_xlat6.x * (-u_xlat0.x);
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat6.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat6.x;
    u_xlat6.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat6.xyz = u._color.xyz * u_xlat6.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat6.xyz = u_xlat6.xyz * u._color.xyz;
    u_xlat1.xyz = u_xlat6.xyz * u_xlat0.xxx;
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    u_xlat1.w = u_xlat0.x * u._color.w;
    u_xlat1.w = clamp(u_xlat1.w, 0.0, 1.0);
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat1.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
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
