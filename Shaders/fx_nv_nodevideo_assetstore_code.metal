// ---------------------------------------------------------------------------
// Code (NV)
// origem : assets/effects/nv-nodevideo-assetstore-code.xml
// id     : nv.effect.nodevideo-assetstore-code
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_codeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _scale;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat7;
float2 u_xlat13;
float4 TempArray0[12];

fragment float4 fx_nv_nodevideo_assetstore_code(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_codeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    TempArray0[0].x = 9.52882956e-44;
    TempArray0[1].x = 1.14906474e-43;
    TempArray0[2].x = 8.82818033e-44;
    TempArray0[3].x = 9.6689594e-44;
    TempArray0[4].x = 0.0;
    TempArray0[5].x = 1.40129846e-45;
    TempArray0[6].x = 7.56701171e-44;
    TempArray0[7].x = 5.18480432e-44;
    TempArray0[8].x = 7.14662217e-44;
    TempArray0[9].x = 2.94272678e-44;
    TempArray0[10].x = as_type<float>(int(0xFFFFFFE5u));
    TempArray0[11].x = 5.04467447e-44;
    u_xlat1.xy = _resolution.xy * float2(u._scale);
    u_xlat13.xy = u_xlat1.xy * in.acScreenNorm.xy;
    u_xlat13.xy = u_xlat13.xy * float2(0.125, 0.0625);
    u_xlat2.xy = ceil(u_xlat13.xy);
    u_xlat2.xy = u_xlat2.xy * float2(8.0, 16.0);
    u_xlat1.xy = u_xlat2.xy / u_xlat1.xy;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat1.x = dot(u_xlat2.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlat1.x = u_xlat1.x * 12.0;
    u_xlati1 = int(u_xlat1.x);
    u_xlat1.x = TempArray0[u_xlati1].x;
    u_xlati1 = as_type<int>(u_xlat1.x) + 140;
    u_xlatb2.xy = greaterThanEqual(u_xlat13.xyxx, (-u_xlat13.xyxx)).xy;
    u_xlat7.xy = fract(abs(u_xlat13.xy));
    {
        float2 hlslcc_movcTemp = u_xlat7;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat7.x : (-u_xlat7.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat7.y : (-u_xlat7.y);
        u_xlat7 = hlslcc_movcTemp;
    }
    u_xlat7.xy = u_xlat7.xy * float2(8.0, 16.0) + float2(4.0, 0.0);
    u_xlat1.x = float(u_xlati1);
    u_xlat1.xw = u_xlat1.xx * float2(0.0625, 0.00390625);
    u_xlat1.xy = u_xlat7.xy * float2(0.00390625, 0.00390625) + u_xlat1.xw;
    u_xlat1.x = texture0.sample(__nv_smp, u_xlat1.xy).x;
    u_xlat1.y = u_xlat0.w;
    u_xlat1 = u_xlat1.xxxy * u._color;
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
