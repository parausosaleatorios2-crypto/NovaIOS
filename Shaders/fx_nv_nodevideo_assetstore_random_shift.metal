// ---------------------------------------------------------------------------
// Random Shift (NV)
// origem : assets/effects/nv-nodevideo-assetstore-random-shift.xml
// id     : nv.effect.nodevideo-assetstore-random-shift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_random_shiftParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _scale;
    float _strength;
    float _rgb_shift;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat12;
float u_xlat13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_assetstore_random_shift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_random_shiftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12 = u._scale * 0.100000001;
    u_xlat18 = float(1.0) / u_xlat12;
    u_xlat1.xy = u_xlat0.xy * float2(u_xlat18) + float2(0.5, 0.5);
    u_xlat1.xy = floor(u_xlat1.xy);
    u_xlat1.xy = float2(u_xlat12) * u_xlat1.xy;
    u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat18 = u_xlat2.y + u_xlat2.x;
    u_xlat18 = u_xlat2.z + u_xlat18;
    u_xlat18 = (-u_xlat18) * 0.333333343 + 1.0;
    u_xlat18 = log2(u_xlat18);
    u_xlat18 = u_xlat18 * u._scale;
    u_xlat18 = exp2(u_xlat18);
    u_xlat12 = u_xlat18 * u_xlat12;
    u_xlat13 = float(1.0) / u_xlat12;
    u_xlat0.xy = u_xlat0.xy * float2(u_xlat13) + float2(0.5, 0.5);
    u_xlat0.xy = floor(u_xlat0.xy);
    u_xlat0.xy = (-u_xlat0.xy) * float2(u_xlat12) + u_xlat1.xy;
    u_xlat1.xy = float2(u_xlat18) * u_xlat0.xy;
    u_xlat1.xy = u_xlat1.xy * float2(float2(u._strength, u._strength)) + in.acScreenNorm.xy;
    u_xlat1.xw = inputImg.sample(__nv_smp, u_xlat1.xy).xw;
    u_xlat12 = u_xlat18 + u._rgb_shift;
    u_xlat2.xy = float2(u_xlat12) * u_xlat0.xy;
    u_xlat2.xy = u_xlat2.xy * float2(float2(u._strength, u._strength)) + in.acScreenNorm.xy;
    u_xlat1.y = inputImg.sample(__nv_smp, u_xlat2.xy).y;
    u_xlat12 = u_xlat12 + u._rgb_shift;
    u_xlat0.xy = float2(u_xlat12) * u_xlat0.xy;
    u_xlat0.xy = u_xlat0.xy * float2(float2(u._strength, u._strength)) + in.acScreenNorm.xy;
    u_xlat1.z = inputImg.sample(__nv_smp, u_xlat0.xy).z;
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
