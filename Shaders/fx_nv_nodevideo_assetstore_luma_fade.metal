// ---------------------------------------------------------------------------
// Luma Fade (NV)
// origem : assets/effects/nv-nodevideo-assetstore-luma-fade.xml
// id     : nv.effect.nodevideo-assetstore-luma-fade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_luma_fadeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _intensity;
    float _interpolation;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;

fragment float4 fx_nv_nodevideo_assetstore_luma_fade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_luma_fadeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = float4(float4(u._interpolation, u._interpolation, u._interpolation, u._interpolation)) * (-u_xlat0) + u_xlat0;
    u_xlat1.x = dot(u_xlat1, u_xlat1);
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat1.x = log2(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * u._intensity;
    u_xlat1.x = exp2(u_xlat1.x);
    u_xlat1.x = min(u_xlat1.x, 1.0);
    u_xlat1 = u_xlat0 * u_xlat1.xxxx;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2 = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2 : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
