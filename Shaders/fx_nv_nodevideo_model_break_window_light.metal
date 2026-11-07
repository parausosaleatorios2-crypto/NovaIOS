// ---------------------------------------------------------------------------
// Model Break Window Light (NV)
// origem : assets/effects/nv-nodevideo-model-break-window-light.xml
// id     : nv.effect.nodevideo-model-break-window-light
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_break_window_lightParams {
    float4 _WorldSpaceLightPos0;
    float4 _LightColor0;
    float4 _SpecColor;
    float _Shininess;
    float4 _reflection_color;
    float _intensity;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float4 u_xlat1;
float3 u_xlat16_1;
float3 u_xlat16_2;
float3 u_xlat3;
float3 u_xlat16_6;
float u_xlat12;
float u_xlat16_13;

fragment float4 fx_nv_nodevideo_model_break_window_light(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_break_window_lightParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Cube [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = (-in.vs_TEXCOORD3.xyz) + _WorldSpaceCameraPos.xyz;
    u_xlat12 = dot(u_xlat0.xyz, u_xlat0.xyz);
    u_xlat12 = rsqrt(u_xlat12);
    u_xlat16_1.xyz = u_xlat0.xyz * float3(u_xlat12) + u._WorldSpaceLightPos0.xyz;
    u_xlat16_13 = dot(u_xlat16_1.xyz, u_xlat16_1.xyz);
    u_xlat16_13 = rsqrt(u_xlat16_13);
    u_xlat16_1.xyz = float3(u_xlat16_13) * u_xlat16_1.xyz;
    u_xlat16_1.x = dot(in.vs_TEXCOORD2.xyz, u_xlat16_1.xyz);
    u_xlat16_1.x = max(u_xlat16_1.x, 0.0);
    u_xlat0.x = log2(u_xlat16_1.x);
    u_xlat16_1.x = u._Shininess * 128.0;
    u_xlat0.x = u_xlat0.x * u_xlat16_1.x;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0.x = u_xlat0.x * u_xlat1.w;
    u_xlat16_2.xyz = u._LightColor0.xyz * u._SpecColor.xyz;
    u_xlat0.xyz = u_xlat0.xxx * u_xlat16_2.xyz;
    u_xlat16_2.x = dot(in.vs_TEXCOORD2.xyz, u._WorldSpaceLightPos0.xyz);
    u_xlat16_2.x = max(u_xlat16_2.x, 0.0);
    u_xlat3.xyz = u_xlat1.xyz * in.vs_COLOR0.xyz;
    u_xlat12 = u_xlat1.w * u._intensity;
    __nv_out.w = u_xlat12;
    u_xlat16_6.xyz = u_xlat3.xyz * u._LightColor0.xyz;
    u_xlat0.xyz = u_xlat16_6.xyz * u_xlat16_2.xxx + u_xlat0.xyz;
    u_xlat16_2.xyz = u_xlat3.xyz * in.vs_TEXCOORD4.xyz + u_xlat0.xyz;
    u_xlat0.xyz = Cube.sample(__nv_smp, in.vs_TEXCOORD1.xyz).xyz;
    __nv_out.xyz = u_xlat0.xyz * u._reflection_color.xyz + u_xlat16_2.xyz;
    return __nv_out;
    return __nv_out;
}
