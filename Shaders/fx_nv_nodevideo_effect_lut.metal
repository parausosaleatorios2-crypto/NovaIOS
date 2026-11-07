// ---------------------------------------------------------------------------
// Effect Lut (NV)
// origem : assets/effects/nv-nodevideo-effect-lut.xml
// id     : nv.effect.nodevideo-effect-lut
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_lutParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _blend;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
float u_xlat19;

fragment float4 fx_nv_nodevideo_effect_lut(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_lutParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> lut [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u_xlat0.z * 31.0;
    u_xlat7.xyz = u_xlat0.xyz * float3(0.0302734375, 0.96875, 31.0) + float3(0.00048828125, 0.015625, 0.0);
    u_xlat1.x = fract(u_xlat1.x);
    u_xlat19 = (-u_xlat1.x) + u_xlat7.z;
    u_xlat7.xy = float2(u_xlat19) * float2(0.03125, 0.0) + u_xlat7.xy;
    u_xlat2.xy = u_xlat7.xy + float2(0.03125, 0.0);
    u_xlat7.xyz = lut.sample(__nv_smp, u_xlat7.xy).xyz;
    u_xlat2.xyz = lut.sample(__nv_smp, u_xlat2.xy).xyz;
    u_xlat2.xyz = (-u_xlat7.xyz) + u_xlat2.xyz;
    u_xlat1.xyz = u_xlat1.xxx * u_xlat2.xyz + u_xlat7.xyz;
    u_xlat1.xyz = (-u_xlat0.xyz) + u_xlat1.xyz;
    u_xlat1.w = 0.0;
    u_xlat1 = float4(u._blend) * u_xlat1 + u_xlat0;
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
