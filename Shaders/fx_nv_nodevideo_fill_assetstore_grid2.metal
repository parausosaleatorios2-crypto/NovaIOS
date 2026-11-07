// ---------------------------------------------------------------------------
// Fill Assetstore Grid2 (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-grid2.xml
// id     : nv.effect.nodevideo-fill-assetstore-grid2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_grid2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _position;
    float _spacing;
    float _width;
    float _smoothing;
    float4 _color;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
float2 u_xlat14;
bool2 u_xlatb14;
float2 u_xlat15;
float u_xlat19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_fill_assetstore_grid2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_grid2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._color.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u._color.xyz;
    u_xlat19 = in.acScreenNorm.x;
    u_xlat19 = u_xlat19 + -0.5;
    u_xlat2.x = _resolution.x / _resolution.y;
    u_xlat2.x = u_xlat19 * u_xlat2.x;
    u_xlat2.y = (-in.acScreenNorm.y) + 0.5;
    u_xlat2.xy = u_xlat2.xy + (-u._position.xy);
    u_xlat2.xy = abs(u_xlat2.xy) / float2(float2(u._spacing, u._spacing));
    u_xlatb14.xy = greaterThanEqual(u_xlat2.xyxy, (-u_xlat2.xyxy)).xy;
    u_xlat2.xy = fract(abs(u_xlat2.xy));
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb14.x) ? u_xlat2.x : (-u_xlat2.x);
        hlslcc_movcTemp.y = (u_xlatb14.y) ? u_xlat2.y : (-u_xlat2.y);
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.xy = u_xlat2.xy * float2(float2(u._spacing, u._spacing));
    u_xlat2.xy = u_xlat2.xy / float2(float2(u._spacing, u._spacing));
    u_xlat2.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat2.xy = -abs(u_xlat2.xy) * float2(2.0, 2.0) + float2(1.0, 1.0);
    u_xlat19 = u._width / u._spacing;
    u_xlat19 = clamp(u_xlat19, 0.0, 1.0);
    u_xlat14.x = u_xlat19 * u._smoothing;
    u_xlat20 = u_xlat19 * 0.5;
    u_xlat20 = max(u_xlat20, u_xlat14.x);
    u_xlat3.xy = float2(float2(u._width, u._width)) + float2(-0.0120000001, -0.00600000005);
    u_xlat3.xy = u_xlat3.xy * float2(-499.999908, -999.999817);
    u_xlat3.xy = clamp(u_xlat3.xy, 0.0, 1.0);
    u_xlat15.xy = u_xlat3.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat3.xy = u_xlat3.xy * u_xlat3.xy;
    u_xlat3.xy = u_xlat3.xy * u_xlat15.xy;
    u_xlat20 = (-u_xlat19) * u._smoothing + u_xlat20;
    u_xlat14.x = u_xlat3.x * u_xlat20 + u_xlat14.x;
    u_xlat20 = max(u_xlat19, u_xlat14.x);
    u_xlat20 = (-u_xlat14.x) + u_xlat20;
    u_xlat14.x = u_xlat3.y * u_xlat20 + u_xlat14.x;
    u_xlat19 = (-u_xlat19) + 1.0;
    u_xlat20 = (-u_xlat14.x) + u_xlat19;
    u_xlat19 = u_xlat14.x + u_xlat19;
    u_xlat19 = (-u_xlat20) + u_xlat19;
    u_xlat2.xy = (-float2(u_xlat20)) + u_xlat2.xy;
    u_xlat19 = float(1.0) / u_xlat19;
    u_xlat2.xy = float2(u_xlat19) * u_xlat2.xy;
    u_xlat2.xy = clamp(u_xlat2.xy, 0.0, 1.0);
    u_xlat14.xy = u_xlat2.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat2.xy = u_xlat2.xy * u_xlat2.xy;
    u_xlat2.xy = u_xlat2.xy * u_xlat14.xy;
    u_xlat19 = max(u_xlat2.y, u_xlat2.x);
    u_xlat2.xyz = float3(u_xlat19) * u_xlat1.xyz;
    u_xlat2.w = u_xlat19 * u._color.w;
    u_xlatb1 = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat2;
    u_xlat7 = (-u_xlat2.w) * u_xlat0.w + 1.0;
    u_xlat4 = u_xlat0 * float4(u_xlat7);
    u_xlat4 = u_xlat2 * u_xlat3.wwww + u_xlat4;
    u_xlat1 = (bool(u_xlatb1)) ? u_xlat3 : u_xlat4;
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
