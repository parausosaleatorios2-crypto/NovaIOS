// ---------------------------------------------------------------------------
// Rendercommand Color Grading (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-color-grading.xml
// id     : nv.effect.nodevideo-rendercommand-color-grading
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_color_gradingParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _Lut3D_Params;
    float _PostExposure;
    float _lut_space;
    float _blend;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat20;

fragment float4 fx_nv_nodevideo_rendercommand_color_grading(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_color_gradingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Lut3D [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = log2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat1.yzw = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    u_xlat2.xyz = u_xlat0.xyz * float3(5.55555582, 5.55555582, 5.55555582) + float3(0.0479959995, 0.0479959995, 0.0479959995);
    u_xlat2.xyz = log2(u_xlat2.xyz);
    u_xlat2.yzw = u_xlat2.xyz * float3(0.0734997839, 0.0734997839, 0.0734997839) + float3(0.386036009, 0.386036009, 0.386036009);
    u_xlat2.yzw = clamp(u_xlat2.yzw, 0.0, 1.0);
    u_xlat2.x = u_xlat0.w * u._PostExposure;
    u_xlat1.x = u_xlat0.w;
    u_xlat1 = (int(u._lut_space) != 0) ? u_xlat1.yzwx : u_xlat2.yzwx;
    u_xlat2.xyz = u_xlat1.xyz * u._Lut3D_Params.yyy;
    u_xlat20 = u._Lut3D_Params.x * 0.5;
    u_xlat2.xyz = u_xlat2.xyz * u._Lut3D_Params.xxx + float3(u_xlat20);
    u_xlat2.xyz = Lut3D.sample(__nv_smp, u_xlat2.xyz).xyz;
    u_xlat3.xyz = u_xlat2.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u_xlat2.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.xyz = u_xlat2.xyz * u_xlat3.xyz;
    u_xlat1.xyz = (int(u._lut_space) != 0) ? u_xlat3.xyz : u_xlat2.xyz;
    u_xlat1 = (-u_xlat0) + u_xlat1;
    u_xlat1 = float4(u._blend) * u_xlat1 + u_xlat0;
    if(u._use_inner_mask != 0) {
        u_xlatb2.xy = equal(int4(u._show_inner_mask, u._b_clip_mask, u._show_inner_mask, u._show_inner_mask), int4(1, 1, 0, 0)).xy;
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
