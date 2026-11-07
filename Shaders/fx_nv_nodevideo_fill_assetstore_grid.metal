// ---------------------------------------------------------------------------
// Fill Assetstore Grid (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-grid.xml
// id     : nv.effect.nodevideo-fill-assetstore-grid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_gridParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _cells1;
    float _cells2;
    float _intensity1;
    float _intensity2;
    float _show_axes;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat13;
bool2 u_xlatb13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_fill_assetstore_grid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_gridParams&  u    [[buffer(1)]],
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
    u_xlat1.xy = float2(1.0, 1.0) / _SourceTex_TexelSize.xy;
    u_xlat13.xy = u_xlat1.xy * float2(0.5, 0.5);
    u_xlat13.xy = ceil(u_xlat13.xy);
    u_xlat1.xy = in.acScreenNorm.xy * u_xlat1.xy + (-u_xlat13.xy);
    u_xlat2 = float4(1.0, 1.0, 1.0, 1.0) / float4(u._cells1, u._cells2, u._cells1, u._cells2);
    u_xlat2 = (-u_xlat2) + float4(1.0, 1.0, 1.0, 1.0);
    u_xlat3 = u_xlat1.xxyy / float4(u._cells1, u._cells2, u._cells1, u._cells2);
    u_xlat3 = fract(u_xlat3);
    u_xlatb2 = greaterThanEqual(u_xlat3, u_xlat2);
    u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
    u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
    u_xlat2.z = u_xlatb2.z ? float(1.0) : 0.0;
    u_xlat2.w = u_xlatb2.w ? float(1.0) : 0.0;
;
    u_xlat13.xy = u_xlat2.xy * float2(u._intensity1, u._intensity2);
    u_xlat18 = u_xlat13.y + u_xlat13.x;
    u_xlat18 = u_xlat2.z * u._intensity1 + u_xlat18;
    u_xlat2.w = u_xlat2.w * u._intensity2 + u_xlat18;
    u_xlat3.xyz = u_xlat0.xyz * u_xlat2.www;
    u_xlatb13.xy = equal(int4(int(u._show_axes), int(u._blend_mode), int(u._show_axes), int(u._blend_mode)), int4(1, 1, 1, 1)).xy;
    u_xlat1.xy = abs(u_xlat1.xy) + float2(-1.0, -1.0);
    u_xlatb1.xy = greaterThanEqual(float4(0.0, 0.0, 0.0, 0.0), u_xlat1.xyxx).xy;
    u_xlat1.x = u_xlatb1.x ? float(1.0) : 0.0;
    u_xlat1.y = u_xlatb1.y ? float(1.0) : 0.0;
;
    u_xlat0.xyz = (-u_xlat2.www) * u_xlat0.xyz + float3(0.963999987, 0.446999997, 0.442999989);
    u_xlat0.xyz = u_xlat1.xxx * u_xlat0.xyz + u_xlat3.xyz;
    u_xlat4.xyz = (-u_xlat0.xyz) + float3(0.340999991, 0.800000012, 0.560000002);
    u_xlat0.xyz = u_xlat1.yyy * u_xlat4.xyz + u_xlat0.xyz;
    u_xlat2.xyz = (u_xlatb13.x) ? u_xlat0.xyz : u_xlat3.xyz;
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat3 = u_xlat0 * u_xlat2;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat2.xyz;
    u_xlat4.w = u_xlat0.w;
    u_xlat1 = (u_xlatb13.y) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat2.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat1 : u_xlat3;
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
