// ---------------------------------------------------------------------------
// Manga (NV)
// origem : assets/effects/nv-nodevideo-assetstore-manga.xml
// id     : nv.effect.nodevideo-assetstore-manga
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_mangaParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _intensity;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float3 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool u_xlatb7;
float u_xlat8;
float u_xlat13;
float u_xlat14;
float u_xlat19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_assetstore_manga(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_mangaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u._intensity * 0.125 + -0.200000018;
    u_xlat1.x = u_xlat0.x + (-u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 3.33333349;
    u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
    u_xlat7 = u_xlat1.x * -2.0 + 3.0;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat13 = u_xlat1.x * u_xlat7;
    u_xlat19 = 2136.28125 / u._intensity;
    u_xlat19 = u_xlat19 * 1.66666663;
    u_xlat2.xy = in.acScreenNorm.xy * float2(0.707106411, 0.707106411);
    u_xlat2.x = u_xlat2.y + u_xlat2.x;
    u_xlat2.x = u_xlat19 * u_xlat2.x;
    u_xlat2.x = cos(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 0.25 + 0.5;
    u_xlat8 = in.acScreenNorm.x * 0.707106411 + (-u_xlat2.y);
    u_xlat19 = u_xlat19 * u_xlat8;
    u_xlat19 = cos(u_xlat19);
    u_xlat19 = u_xlat19 * 0.25 + u_xlat2.x;
    u_xlatb2.x = 0.300000012<u_xlat13;
    u_xlat1.x = u_xlat7 * u_xlat1.x + u_xlat19;
    u_xlat1.x = (u_xlatb2.x) ? u_xlat1.x : u_xlat13;
    u_xlat2 = in.acScreenNorm.xyxy + float4(-0.00390625, -0.00390625, 0.00390625, -0.00390625);
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat7 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat13 = dot(u_xlat2, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat2 = in.acScreenNorm.xyxy + float4(-0.00390625, 0.0, -0.00390625, 0.00390625);
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat2.x = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat2.zw);
    u_xlat8 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = in.acScreenNorm.xyxy + float4(0.0, 0.00390625, 0.00390625, 0.00390625);
    u_xlat4 = inputImg.sample(__nv_smp, u_xlat3.xy);
    u_xlat14 = dot(u_xlat4, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3 = inputImg.sample(__nv_smp, u_xlat3.zw);
    u_xlat20 = dot(u_xlat3, float4(0.300000012, 0.589999974, 0.109999999, 0.25));
    u_xlat3.x = u_xlat13 + u_xlat20;
    u_xlat3.x = u_xlat2.x * 2.0 + u_xlat3.x;
    u_xlat3.x = (-u_xlat7) + u_xlat3.x;
    u_xlat2.x = (-u_xlat2.x) * 2.0 + u_xlat3.x;
    u_xlat2.x = (-u_xlat8) + u_xlat2.x;
    u_xlat8 = u_xlat14 * 2.0 + u_xlat8;
    u_xlat8 = u_xlat20 + u_xlat8;
    u_xlat8 = (-u_xlat7) + u_xlat8;
    u_xlat7 = (-u_xlat7) * 2.0 + u_xlat8;
    u_xlat7 = (-u_xlat13) + u_xlat7;
    u_xlat7 = u_xlat7 * u_xlat7;
    u_xlat7 = u_xlat2.x * u_xlat2.x + u_xlat7;
    u_xlatb7 = 0.0399999991<u_xlat7;
    u_xlat7 = u_xlatb7 ? -1.0 : float(0.0);
    u_xlat1.x = u_xlat7 * u_xlat19 + u_xlat1.x;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1.y = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1.xxxy;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        u_xlat1.z = u_xlat0.w;
        __nv_out = u_xlat1.xxxz;
    }
    return __nv_out;
    return __nv_out;
}
