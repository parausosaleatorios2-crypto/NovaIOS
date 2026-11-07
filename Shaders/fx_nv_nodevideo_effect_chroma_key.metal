// ---------------------------------------------------------------------------
// Effect Chroma Key (NV)
// origem : assets/effects/nv-nodevideo-effect-chroma-key.xml
// id     : nv.effect.nodevideo-effect-chroma-key
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_chroma_keyParams {
    float4 _green_color;
    float _red_intensity;
    float _blue_intensity;
    float _green_intensity;
    float4 _blue_color;
    float4 _red_color;
    float _key_mode;
    float _invert;
    float _alpha_clip;
};

// --- funcoes auxiliares do efeito
float u_xlat0;
bool3 u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
float4 u_xlat3;
float3 u_xlat4;
float u_xlat8;

fragment float4 fx_nv_nodevideo_effect_chroma_key(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_chroma_keyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = dot(u._blue_color.xy, float2(u._red_intensity, u._green_intensity));
    u_xlat0 = (-u_xlat0) + u._blue_color.z;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat4.xyz = u_xlat1.xzy * float3(u._red_intensity, u._blue_intensity, u._green_intensity);
    u_xlat4.xyz = u_xlat4.yzz + u_xlat4.xxy;
    u_xlat4.xyz = (-u_xlat4.xyz) + u_xlat1.yzx;
    u_xlat0 = u_xlat4.y / u_xlat0;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat0 = (-u_xlat0) + 1.0;
    u_xlat8 = (-u_xlat0) * u_xlat1.w + 1.0;
    u_xlat2.w = u_xlat1.w * u_xlat0;
    u_xlat2.xyz = (-u._blue_color.xyz) * float3(u_xlat8) + u_xlat1.xyz;
    u_xlat2.xyz = clamp(u_xlat2.xyz, 0.0, 1.0);
    u_xlat0 = dot(u_xlat2.xy, float2(0.5, 0.5));
    u_xlat2.z = min(u_xlat0, u_xlat2.z);
    u_xlat0 = dot(u._red_color.zy, float2(u._blue_intensity, u._green_intensity));
    u_xlat0 = (-u_xlat0) + u._red_color.x;
    u_xlat0 = u_xlat4.z / u_xlat0;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat0 = (-u_xlat0) + 1.0;
    u_xlat8 = (-u_xlat0) * u_xlat1.w + 1.0;
    u_xlat3.w = u_xlat1.w * u_xlat0;
    u_xlat3.xyz = (-u._red_color.xyz) * float3(u_xlat8) + u_xlat1.xyz;
    u_xlat3.xyz = clamp(u_xlat3.xyz, 0.0, 1.0);
    u_xlat0 = dot(u_xlat3.zy, float2(0.5, 0.5));
    u_xlat3.x = min(u_xlat0, u_xlat3.x);
    u_xlatb0.xz = equal(int4(int(u._key_mode), int(u._key_mode), int(u._invert), int(u._key_mode)), int4(1, 0, 1, 0)).xz;
    u_xlat2 = (u_xlatb0.x) ? u_xlat2 : u_xlat3;
    u_xlat0 = dot(u._green_color.xz, float2(u._red_intensity, u._blue_intensity));
    u_xlat0 = (-u_xlat0) + u._green_color.y;
    u_xlat0 = u_xlat4.x / u_xlat0;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat0 = (-u_xlat0) + 1.0;
    u_xlat4.x = (-u_xlat0) * u_xlat1.w + 1.0;
    u_xlat3.w = u_xlat1.w * u_xlat0;
    u_xlat3.xyz = (-u._green_color.xyz) * u_xlat4.xxx + u_xlat1.xyz;
    u_xlat3.xyz = clamp(u_xlat3.xyz, 0.0, 1.0);
    u_xlat0 = dot(u_xlat3.xz, float2(0.5, 0.5));
    u_xlat3.y = min(u_xlat0, u_xlat3.y);
    u_xlat1 = (int(u._key_mode) != 0) ? u_xlat2 : u_xlat3;
    u_xlatb0.x = u_xlat1.w<u._alpha_clip;
    u_xlat1.w = (u_xlatb0.x) ? 0.0 : u_xlat1.w;
    u_xlat2 = (-u_xlat1) + float4(1.0, 1.0, 1.0, 1.0);
    __nv_out = (u_xlatb0.z) ? u_xlat2 : u_xlat1;
    return __nv_out;
    return __nv_out;
}
