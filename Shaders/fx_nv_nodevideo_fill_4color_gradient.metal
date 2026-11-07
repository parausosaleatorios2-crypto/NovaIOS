// ---------------------------------------------------------------------------
// Fill 4Color Gradient (NV)
// origem : assets/effects/nv-nodevideo-fill-4color-gradient.xml
// id     : nv.effect.nodevideo-fill-4color-gradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_4color_gradientParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _point1;
    float4 _color1;
    float2 _point2;
    float4 _color2;
    float2 _point3;
    float4 _color3;
    float2 _point4;
    float4 _color4;
    float _blend;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool u_xlatb6;
float2 u_xlat12;
float u_xlat18;
bool u_xlatb18;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_fill_4color_gradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_4color_gradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.xy = (-u._point1.xy) * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat0.xy;
    u_xlat12.x = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat12.x = sqrt(u_xlat12.x);
    u_xlatb18 = u_xlat12.x==0.0;
    u_xlat12.x = log2(u_xlat12.x);
    u_xlat12.x = u_xlat12.x * u._blend;
    u_xlat12.x = exp2(u_xlat12.x);
    u_xlat12.x = float(1.0) / u_xlat12.x;
    u_xlat12.x = (u_xlatb18) ? 1.0 : u_xlat12.x;
    u_xlat1.xy = (-u._point2.xy) * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat0.xy;
    u_xlat18 = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat18 = sqrt(u_xlat18);
    u_xlatb1.x = u_xlat18==0.0;
    u_xlat18 = log2(u_xlat18);
    u_xlat18 = u_xlat18 * u._blend;
    u_xlat18 = exp2(u_xlat18);
    u_xlat18 = float(1.0) / u_xlat18;
    u_xlat18 = (u_xlatb1.x) ? 1.0 : u_xlat18;
    u_xlat1.xyz = float3(u_xlat18) * u._color2.xyz;
    u_xlat1.xyz = u_xlat12.xxx * u._color1.xyz + u_xlat1.xyz;
    u_xlat12.x = u_xlat18 + u_xlat12.x;
    u_xlat2.xy = (-u._point3.xy) * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat0.xy;
    u_xlat18 = dot(u_xlat2.xy, u_xlat2.xy);
    u_xlat18 = sqrt(u_xlat18);
    u_xlatb19 = u_xlat18==0.0;
    u_xlat18 = log2(u_xlat18);
    u_xlat18 = u_xlat18 * u._blend;
    u_xlat18 = exp2(u_xlat18);
    u_xlat18 = float(1.0) / u_xlat18;
    u_xlat18 = (u_xlatb19) ? 1.0 : u_xlat18;
    u_xlat1.xyz = float3(u_xlat18) * u._color3.xyz + u_xlat1.xyz;
    u_xlat12.x = u_xlat18 + u_xlat12.x;
    u_xlat0.xy = (-u._point4.xy) * float2(_viewport_ratio.x, _viewport_ratio.y) + u_xlat0.xy;
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlatb6 = u_xlat0.x==0.0;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u._blend;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = float(1.0) / u_xlat0.x;
    u_xlat0.x = (u_xlatb6) ? 1.0 : u_xlat0.x;
    u_xlat1.xyz = u_xlat0.xxx * u._color4.xyz + u_xlat1.xyz;
    u_xlat0.x = u_xlat0.x + u_xlat12.x;
    u_xlat0.xyz = u_xlat1.xyz / u_xlat0.xxx;
    u_xlat1.xyz = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb18 = int(u._blend_mode)==1;
    u_xlat2.w = 1.0;
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat1.xyz = u_xlat0.xyz * u_xlat1.xyz + u_xlat3.xyz;
    u_xlat1.w = u_xlat3.w;
    u_xlat0 = (bool(u_xlatb18)) ? u_xlat4 : u_xlat1;
    u_xlat1.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat1;
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
