// ---------------------------------------------------------------------------
// Fill Audiovisualization Bar (NV)
// origem : assets/effects/nv-nodevideo-fill-audiovisualization-bar.xml
// id     : nv.effect.nodevideo-fill-audiovisualization-bar
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_audiovisualization_barParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _scale;
    float _invert;
    float _band_count;
    float _offset;
    float4 _color1;
    float4 _color2;
    float4 _color3;
    float4 _color4;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
uint u_xlatu6;
float2 u_xlat12;
float u_xlat18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_fill_audiovisualization_bar(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_audiovisualization_barParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = in.acScreenNorm.y * 2.0 + -1.0;
    u_xlat0.x = u_xlat0.x + (-u._offset);
    u_xlat6.x = float(u._band_count);
    u_xlat12.x = u_xlat6.x * in.acScreenNorm.x;
    u_xlat18 = floor(u_xlat12.x);
    u_xlat12.x = fract(u_xlat12.x);
    u_xlat6.x = u_xlat6.x * 0.0322580636;
    u_xlat6.x = u_xlat18 / u_xlat6.x;
    u_xlat6.x = max(u_xlat6.x, 0.0);
    u_xlat6.x = min(u_xlat6.x, 30.0);
    u_xlatu6 = uint(u_xlat6.x);
    u_xlat18 = 3.0 * _bands[int(u_xlatu6)];
    u_xlat18 = clamp(u_xlat18, 0.0, 1.0);
    u_xlat1.xyz = (-u._color1.xyz) + u._color2.xyz;
    u_xlat1.xyz = float3(u_xlat18) * u_xlat1.xyz + u._color1.xyz;
    u_xlat2.xy = float2(-0.333333343, -0.666666687) + float2(_bands[int(u_xlatu6)]);
    u_xlat2.xy = u_xlat2.xy * float2(3.0, 3.0);
    u_xlat2.xy = clamp(u_xlat2.xy, 0.0, 1.0);
    u_xlat3.xyz = (-u_xlat1.xyz) + u._color3.xyz;
    u_xlat1.xyz = u_xlat2.xxx * u_xlat3.xyz + u_xlat1.xyz;
    u_xlat2.xzw = (-u_xlat1.xyz) + u._color4.xyz;
    u_xlat1.xyz = u_xlat2.yyy * u_xlat2.xzw + u_xlat1.xyz;
    u_xlat2 = (int(u._invert) != 0) ? float4(-1.0, -0.00999999978, -100.0, 100.0) : float4(1.0, 0.00999999978, 100.0, -100.0);
    u_xlat6.xz = float2(u._scale.x, u._scale.y) * float2(_bands[int(u_xlatu6)]);
    u_xlat6.xz = u_xlat2.xx * u_xlat6.xz;
    u_xlat6.x = (-u_xlat6.x) * 1.5 + u_xlat0.x;
    u_xlat6.x = u_xlat2.z * u_xlat6.x;
    u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
    u_xlat19 = u_xlat6.x * -2.0 + 3.0;
    u_xlat6.x = u_xlat6.x * u_xlat6.x;
    u_xlat3.w = (-u_xlat19) * u_xlat6.x + 1.0;
    u_xlat3.xyz = u_xlat1.xyz * u_xlat3.www;
    u_xlat6.x = u_xlat6.z * 1.5 + u_xlat0.x;
    u_xlat6.x = u_xlat2.w * u_xlat6.x;
    u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
    u_xlat18 = u_xlat6.x * -2.0 + 3.0;
    u_xlat6.x = u_xlat6.x * u_xlat6.x;
    u_xlat4.w = (-u_xlat18) * u_xlat6.x + 1.0;
    u_xlat6.xz = (int(u._invert) != 0) ? float2(-0.5, -50.0) : float2(0.5, 50.0);
    u_xlat6.x = u_xlat6.x + u_xlat0.x;
    u_xlat6.x = u_xlat2.x * u_xlat6.x;
    u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
    u_xlat19 = u_xlat6.x * -2.0 + 3.0;
    u_xlat6.x = u_xlat6.x * u_xlat6.x;
    u_xlat6.x = u_xlat6.x * u_xlat19;
    u_xlat1.xyz = u_xlat6.xxx * u_xlat1.xyz;
    u_xlat4.xyz = u_xlat1.xyz * u_xlat4.www;
    u_xlat0.x = u_xlat0.x + u_xlat2.y;
    u_xlat0.x = u_xlat6.z * u_xlat0.x;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat6.x = u_xlat0.x * -2.0 + 3.0;
    u_xlat0.x = u_xlat0.x * u_xlat0.x;
    u_xlat0.x = u_xlat0.x * u_xlat6.x;
    u_xlat1 = u_xlat3 + (-u_xlat4);
    u_xlat1 = u_xlat0.xxxx * u_xlat1 + u_xlat4;
    u_xlat0.xy = u_xlat12.xx + float2(-0.125, -0.875);
    u_xlat0.xy = u_xlat0.xy * float2(4.0, -4.0);
    u_xlat0.xy = clamp(u_xlat0.xy, 0.0, 1.0);
    u_xlat12.xy = u_xlat0.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat0.xy = u_xlat0.xy * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * u_xlat12.xy;
    u_xlat1 = u_xlat0.xxxx * u_xlat1;
    u_xlat0 = u_xlat0.yyyy * u_xlat1;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb2.x = u._blend_mode==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat1.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat0.xyz;
    u_xlat0 = (u._blend_mode != 0) ? u_xlat2 : u_xlat3;
    if(u._use_inner_mask != 0) {
        u_xlatb2.xy = equal(int4(u._show_inner_mask, u._b_clip_mask, u._show_inner_mask, u._show_inner_mask), int4(1, 1, 0, 0)).xy;
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
