// ---------------------------------------------------------------------------
// Textmeshprossd (NV)
// origem : assets/effects/nv-nodevideo-textmeshprossd.xml
// id     : nv.effect.nodevideo-textmeshprossd
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_textmeshprossdParams {
    float _FaceDilate;
    float _WeightNormal;
    float _WeightBold;
    float _ScaleRatioA;
    float _VertexOffsetX;
    float _VertexOffsetY;
    float4 _FaceTex_ST;
    float4 _OutlineTex_ST;
    float _UIVertexColorAlwaysGammaSpace;
    float _FaceUVSpeedX;
    float _FaceUVSpeedY;
    float4 _FaceColor;
    float _OutlineSoftness;
    float _OutlineUVSpeedX;
    float _OutlineUVSpeedY;
    float4 _OutlineColor;
    float _OutlineWidth;
    float _TextureHeight;
    float _GradientScale;
    float _Sharpness;
    float _fill_texture;
};

// --- funcoes auxiliares do efeito
out float4 vs_COLOR0;
out float2 acScreenNorm;
out float vs_TEXCOORD1;
out float4 vs_TEXCOORD2;
float3 vs_TEXCOORD3;
out float4 vs_TEXCOORD5;
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool3 u_xlatb2;
float4 u_xlat3;
float3 u_xlat16_4;
float3 u_xlat16_5;
float u_xlat18;
bool u_xlatb18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_textmeshprossd(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_textmeshprossdParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> FaceTex [[texture(1)]],
    texture2d<float> OutlineTex [[texture(2)]],
    texture2d<float> source_rt [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in_POSITION0.xy + float2(u._VertexOffsetX, u._VertexOffsetY);
    u_xlat1 = u_xlat0.yyyy * hlslcc_mtx4x4unity_ObjectToWorld[1];
    u_xlat1 = hlslcc_mtx4x4unity_ObjectToWorld[0] * u_xlat0.xxxx + u_xlat1;
    u_xlat1 = hlslcc_mtx4x4unity_ObjectToWorld[2] * in_POSITION0.zzzz + u_xlat1;
    u_xlat2 = u_xlat1 + hlslcc_mtx4x4unity_ObjectToWorld[3];
    u_xlat1.xyz = hlslcc_mtx4x4unity_ObjectToWorld[3].xyz * in_POSITION0.www + u_xlat1.xyz;
    u_xlat1.xyz = (-u_xlat1.xyz) + _WorldSpaceCameraPos.xyz;
    u_xlat3 = u_xlat2.yyyy * hlslcc_mtx4x4unity_MatrixVP[1];
    u_xlat3 = hlslcc_mtx4x4unity_MatrixVP[0] * u_xlat2.xxxx + u_xlat3;
    u_xlat3 = hlslcc_mtx4x4unity_MatrixVP[2] * u_xlat2.zzzz + u_xlat3;
    gl_Position = hlslcc_mtx4x4unity_MatrixVP[3] * u_xlat2.wwww + u_xlat3;
    u_xlat16_4.xyz = in_COLOR0.xyz * float3(0.265884995, 0.265884995, 0.265884995) + float3(0.736584008, 0.736584008, 0.736584008);
    u_xlat16_4.xyz = in_COLOR0.xyz * u_xlat16_4.xyz + float3(-0.00980184041, -0.00980184041, -0.00980184041);
    u_xlat16_4.xyz = in_COLOR0.xyz * u_xlat16_4.xyz + float3(0.00319697009, 0.00319697009, 0.00319697009);
    u_xlat16_5.xyz = in_COLOR0.xyz * float3(0.0849710032, 0.0849710032, 0.0849710032) + float3(-0.000163029006, -0.000163029006, -0.000163029006);
    u_xlatb2.xyz = lessThan(in_COLOR0.xyzx, float4(0.0725490004, 0.0725490004, 0.0725490004, 0.0)).xyz;
    {
        float3 hlslcc_movcTemp = u_xlat16_4;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat16_5.x : u_xlat16_4.x;
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat16_5.y : u_xlat16_4.y;
        hlslcc_movcTemp.z = (u_xlatb2.z) ? u_xlat16_5.z : u_xlat16_4.z;
        u_xlat16_4 = hlslcc_movcTemp;
    }
    vs_COLOR0.xyz = (int(u._UIVertexColorAlwaysGammaSpace) != 0) ? u_xlat16_4.xyz : in_COLOR0.xyz;
    vs_COLOR0.w = in_COLOR0.w;
    u_xlatb18 = 0.0>=in_TEXCOORD0.w;
    u_xlat18 = u_xlatb18 ? 1.0 : float(0.0);
    u_xlat19 = (-u._WeightNormal) + u._WeightBold;
    u_xlat18 = u_xlat18 * u_xlat19 + u._WeightNormal;
    u_xlat18 = u_xlat18 * 0.25 + u._FaceDilate;
    u_xlat18 = u_xlat18 * u._ScaleRatioA;
    vs_TEXCOORD1 = u_xlat18 * 0.5;
    acScreenNorm.xy = in_TEXCOORD0.xy;
    u_xlat0.z = in_POSITION0.w;
    u_xlat0.y = u_xlat0.y * _ProjectionParams.x;
    u_xlat0.xzw = u_xlat0.xzy * float3(0.5, 0.5, 0.5);
    vs_TEXCOORD2.xy = u_xlat0.zz + u_xlat0.xw;
    vs_TEXCOORD2.zw = in_POSITION0.zw;
    u_xlat0.xyz = u_xlat1.yyy * hlslcc_mtx4x4_EnvMatrix[1].xyz;
    u_xlat0.xyz = hlslcc_mtx4x4_EnvMatrix[0].xyz * u_xlat1.xxx + u_xlat0.xyz;
    vs_TEXCOORD3.xyz = hlslcc_mtx4x4_EnvMatrix[2].xyz * u_xlat1.zzz + u_xlat0.xyz;
    vs_TEXCOORD5.xy = in_TEXCOORD1.xy * u._FaceTex_ST.xy + u._FaceTex_ST.zw;
    vs_TEXCOORD5.zw = in_TEXCOORD1.xy * u._OutlineTex_ST.xy + u._OutlineTex_ST.zw;
    return __nv_out;
    return __nv_out;
}
