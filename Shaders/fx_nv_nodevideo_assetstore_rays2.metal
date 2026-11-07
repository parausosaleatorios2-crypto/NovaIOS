// ---------------------------------------------------------------------------
// Rays2 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-rays2.xml
// id     : nv.effect.nodevideo-assetstore-rays2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_rays2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _samples;
    float _brightness;
    float _dispersion;
    float _amount;
    float _threshold;
    float4 _color1;
    float4 _color2;
    float4 _color3;
    float _length;
    float _colorize;
    float _color_offset;
    float _source_opacity;
    float _ray_opacity;
    float _base_on;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
float4 u_xlat6;
int u_xlati7;
float4 u_xlat8;
float4 u_xlat9;
float4 u_xlat10;
bool2 u_xlatb10;
float4 u_xlat11;
bool u_xlatb11;
float4 u_xlat12;
float2 u_xlat16;
float u_xlat17;
float u_xlat20;
float3 u_xlat24;
bool2 u_xlatb24;
float u_xlat26;
float u_xlat33;
bool u_xlatb33;
float u_xlat36;
float u_xlat39;
int u_xlati39;
int u_xlati42;
float u_xlat46;
bool u_xlatb46;

fragment float4 fx_nv_nodevideo_assetstore_rays2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_rays2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = (-in.acScreenNorm.xy) + u._center.xy;
    u_xlat26 = float(int(u._samples));
    u_xlat0.xy = u_xlat0.xy / float2(u_xlat26);
    u_xlat1 = (-u._color1) + u._color2;
    u_xlat2 = (-u._color2) + u._color3;
    u_xlati39 = int(u._samples) + int(0xFFFFFFFFu);
    u_xlat39 = float(u_xlati39);
    u_xlat3.x = max(u._length, 0.00999999978);
    u_xlat3.x = float(1.0) / u_xlat3.x;
    u_xlat4.z = float(-1.0);
    u_xlat4.w = float(0.666666687);
    u_xlat5.z = float(1.0);
    u_xlat5.w = float(-1.0);
    u_xlat6.x = float(0.0);
    u_xlat6.y = float(0.0);
    u_xlat6.z = float(0.0);
    u_xlat6.w = float(0.0);
    u_xlat16.xy = in.acScreenNorm.xy;
    u_xlati42 = int(u._colorize);
    u_xlati7 = int(u._base_on);
    u_xlat20 = 0.0;
    while(true){
        u_xlatb33 = u_xlat20>=u_xlat26;
        if(u_xlatb33){break;}
        u_xlat8 = inputImg.sample(__nv_smp, u_xlat16.xy);
        u_xlat33 = u_xlat20 / u_xlat26;
        u_xlat46 = log2(u_xlat33);
        u_xlat46 = u_xlat46 * u._color_offset;
        u_xlat46 = exp2(u_xlat46);
        u_xlat9 = float4(u_xlat46) * u_xlat1 + u._color1;
        u_xlatb10.xy = equal(int4(u_xlati42), int4(1, 2, 0, 0)).xy;
        u_xlatb46 = u_xlat33<0.5;
        u_xlat36 = u_xlat33 + u_xlat33;
        u_xlat36 = log2(u_xlat36);
        u_xlat36 = u_xlat36 * u._color_offset;
        u_xlat36 = exp2(u_xlat36);
        u_xlat11 = float4(u_xlat36) * u_xlat1 + u._color1;
        u_xlat36 = u_xlat33 + -0.5;
        u_xlat36 = u_xlat36 + u_xlat36;
        u_xlat36 = log2(u_xlat36);
        u_xlat36 = u_xlat36 * u._color_offset;
        u_xlat36 = exp2(u_xlat36);
        u_xlat12 = float4(u_xlat36) * u_xlat2 + u._color2;
        u_xlat11 = (bool(u_xlatb46)) ? u_xlat11 : u_xlat12;
        u_xlat11 = (u_xlatb10.y) ? u_xlat11 : u._color1;
        u_xlat9 = (u_xlatb10.x) ? u_xlat9 : u_xlat11;
        u_xlat10.xyz = u_xlat9.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat10.xyz = u_xlat9.xyz * u_xlat10.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat9.xyz = u_xlat9.xyz * u_xlat10.xyz;
        u_xlatb46 = u_xlat8.y>=u_xlat8.z;
        u_xlat46 = u_xlatb46 ? 1.0 : float(0.0);
        u_xlat10.xy = (-u_xlat8.zy) + u_xlat8.yz;
        u_xlat10.xy = float2(u_xlat46) * u_xlat10.xy + u_xlat8.zy;
        u_xlatb11 = u_xlat8.x>=u_xlat10.x;
        u_xlat11.x = u_xlatb11 ? 1.0 : float(0.0);
        u_xlat10.w = u_xlat8.x;
        u_xlat24.xyz = (-u_xlat10.xyw) + u_xlat10.wyx;
        u_xlat11.xyz = u_xlat11.xxx * u_xlat24.xyz + u_xlat10.xyw;
        u_xlat24.x = min(u_xlat11.y, u_xlat11.z);
        u_xlat24.x = (-u_xlat24.x) + u_xlat11.x;
        u_xlat11.x = u_xlat11.x + 1.00000001e-10;
        u_xlat11.x = u_xlat24.x / u_xlat11.x;
        u_xlatb24.xy = equal(int4(u_xlati7), int4(2, 1, 0, 0)).xy;
        u_xlat4.xy = u_xlat8.zy;
        u_xlat5.xy = (-u_xlat4.xy) + u_xlat8.yz;
        u_xlat12 = float4(u_xlat46) * u_xlat5 + u_xlat4;
        u_xlatb4 = u_xlat8.x>=u_xlat12.x;
        u_xlat4.x = u_xlatb4 ? 1.0 : float(0.0);
        u_xlat10.xyz = u_xlat12.xyw;
        u_xlat12.xyw = u_xlat10.wyx;
        u_xlat12 = (-u_xlat10) + u_xlat12;
        u_xlat10 = u_xlat4.xxxx * u_xlat12 + u_xlat10;
        u_xlat4.x = min(u_xlat10.y, u_xlat10.w);
        u_xlat4.x = (-u_xlat4.x) + u_xlat10.x;
        u_xlat17 = (-u_xlat10.y) + u_xlat10.w;
        u_xlat4.x = u_xlat4.x * 6.0 + 1.00000001e-10;
        u_xlat4.x = u_xlat17 / u_xlat4.x;
        u_xlat4.x = u_xlat4.x + u_xlat10.z;
        u_xlat17 = dot(u_xlat8.xyz, float3(0.300000012, 0.589999974, 0.109999999));
        u_xlat4.x = (u_xlatb24.y) ? abs(u_xlat4.x) : u_xlat17;
        u_xlat4.x = (u_xlatb24.x) ? u_xlat11.x : u_xlat4.x;
        u_xlatb4 = u._threshold<u_xlat4.x;
        u_xlat17 = u_xlat20 / u_xlat39;
        u_xlat10.z = u_xlat17 * 3.0 + -1.5;
        u_xlat10.y = -abs(u_xlat10.z) + 1.0;
        u_xlat10.x = (-u_xlat10.z);
        u_xlat10.xyz = u_xlat10.xyz;
        u_xlat10.xyz = clamp(u_xlat10.xyz, 0.0, 1.0);
        u_xlat10.xyz = u_xlat8.xyz * u_xlat10.xyz;
        u_xlat10.xyz = u_xlat10.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat8.xyz);
        u_xlat8.xyz = float3(u._dispersion) * u_xlat10.xyz + u_xlat8.xyz;
        u_xlat8 = u_xlat8 * u_xlat9;
        u_xlat8 = u_xlat8 * float4(float4(u._brightness, u._brightness, u._brightness, u._brightness));
        u_xlat17 = (-u_xlat33) + 1.0;
        u_xlat17 = log2(u_xlat17);
        u_xlat17 = u_xlat3.x * u_xlat17;
        u_xlat17 = exp2(u_xlat17);
        u_xlat8 = u_xlat8 * float4(u_xlat17) + u_xlat6;
        u_xlat6 = (bool(u_xlatb4)) ? u_xlat8 : u_xlat6;
        u_xlat16.xy = u_xlat0.xy * float2(float2(u._amount, u._amount)) + u_xlat16.xy;
        u_xlat20 = u_xlat20 + 1.0;
    }
    u_xlat0 = u_xlat6 / float4(u_xlat26);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.w = u_xlat1.w * u._source_opacity;
    u_xlat0.w = u_xlat0.w * u._ray_opacity;
    u_xlat2.xyz = u_xlat1.xyz;
    u_xlat2 = (-u_xlat2) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat0 = (-u_xlat0) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat0 = (-u_xlat2) * u_xlat0 + float4(1.0, 1.0, 1.0, 1.0);
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
