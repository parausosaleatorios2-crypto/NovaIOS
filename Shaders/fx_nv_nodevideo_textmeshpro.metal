// ---------------------------------------------------------------------------
// Textmeshpro (NV)
// origem : assets/effects/nv-nodevideo-textmeshpro.xml
// id     : nv.effect.nodevideo-textmeshpro
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_textmeshproParams {
    float _FaceUVSpeedX;
    float _FaceUVSpeedY;
    float4 _FaceColor;
    float _OutlineSoftness;
    float _OutlineUVSpeedX;
    float _OutlineUVSpeedY;
    float4 _OutlineColor;
    float _OutlineWidth;
    float _ScaleRatioA;
    float _fill_texture;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat16_0;
float4 u_xlat1;
float4 u_xlat16_1;
float4 u_xlat2;
bool u_xlatb2;
float u_xlat3;
float4 u_xlat4;
float u_xlat16_5;
float3 u_xlat16_6;
float3 u_xlat7;
bool u_xlatb7;
float2 u_xlat10;
float u_xlat16_12;
float u_xlat16_19;

fragment float4 fx_nv_nodevideo_textmeshpro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_textmeshproParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> FaceTex [[texture(1)]],
    texture2d<float> OutlineTex [[texture(2)]],
    texture2d<float> source_rt [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = inputImg.sample(__nv_smp, in.acScreenNorm.xy).w;
    u_xlat7.x = u_xlat0.x + (-in.vs_TEXCOORD1.x);
    u_xlatb7 = u_xlat7.x<0.0;
    if(u_xlatb7){discard_fragment();}
    u_xlat0.x = (-u_xlat0.x) + in.vs_TEXCOORD1.z;
    u_xlat7.x = u._OutlineWidth * u._ScaleRatioA;
    u_xlat7.y = u._OutlineSoftness * u._ScaleRatioA;
    u_xlat7.xz = u_xlat7.xy * in.vs_TEXCOORD1.yy;
    u_xlat16_1.xyz = in.vs_COLOR0.xyz * u._FaceColor.xyz;
    u_xlat2.xy = float2(u._FaceUVSpeedX, u._FaceUVSpeedY) * _Time.yy + in.vs_TEXCOORD5.xy;
    u_xlat2 = FaceTex.sample(__nv_smp, u_xlat2.xy);
    u_xlat2.xyz = u_xlat16_1.xyz * u_xlat2.xyz;
    u_xlat3 = u_xlat2.w * u._FaceColor.w;
    u_xlat10.xy = float2(u._OutlineUVSpeedX, u._OutlineUVSpeedY) * _Time.yy + in.vs_TEXCOORD5.zw;
    u_xlat1 = OutlineTex.sample(__nv_smp, u_xlat10.xy);
    u_xlat4 = u_xlat1 * u._OutlineColor;
    u_xlat16_5 = u_xlat7.x * 0.5;
    u_xlat16_12 = u_xlat0.x * in.vs_TEXCOORD1.y + (-u_xlat16_5);
    u_xlat16_12 = u_xlat7.z * 0.5 + u_xlat16_12;
    u_xlat16_19 = u_xlat7.y * in.vs_TEXCOORD1.y + 1.0;
    u_xlat16_12 = u_xlat16_12 / u_xlat16_19;
    u_xlat16_12 = clamp(u_xlat16_12, 0.0, 1.0);
    u_xlat16_12 = (-u_xlat16_12) + 1.0;
    u_xlat16_5 = u_xlat0.x * in.vs_TEXCOORD1.y + u_xlat16_5;
    u_xlat16_5 = clamp(u_xlat16_5, 0.0, 1.0);
    u_xlat16_19 = min(u_xlat7.x, 1.0);
    u_xlat16_19 = sqrt(u_xlat16_19);
    u_xlat16_5 = u_xlat16_19 * u_xlat16_5;
    u_xlat16_6.xyz = u_xlat2.xyz * float3(u_xlat3);
    u_xlat16_0.xyz = u_xlat4.xyz * u_xlat4.www + (-u_xlat16_6.xyz);
    u_xlat16_0.w = u._OutlineColor.w * u_xlat1.w + (-u_xlat3);
    u_xlat16_0 = u_xlat16_0 * float4(u_xlat16_5);
    u_xlat16_1.xyz = u_xlat2.xyz * float3(u_xlat3) + u_xlat16_0.xyz;
    u_xlat16_1.w = u._FaceColor.w * u_xlat2.w + u_xlat16_0.w;
    u_xlat16_0 = float4(u_xlat16_12) * u_xlat16_1;
    u_xlatb2 = 0<u._fill_texture;
    if(u_xlatb2){
        u_xlat1 = source_rt.sample(__nv_smp, in.vs_TEXCOORD2.xy);
        u_xlat0 = u_xlat16_0 * u_xlat1;
        u_xlat16_0 = u_xlat0;
    }
    __nv_out = u_xlat16_0 * in.vs_COLOR0.wwww;
    return __nv_out;
    return __nv_out;
}
