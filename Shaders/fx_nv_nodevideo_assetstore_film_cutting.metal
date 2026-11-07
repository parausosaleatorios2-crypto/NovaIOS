// ---------------------------------------------------------------------------
// Film Cutting (NV)
// origem : assets/effects/nv-nodevideo-assetstore-film-cutting.xml
// id     : nv.effect.nodevideo-assetstore-film-cutting
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_film_cuttingParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _luminosity;
    float _vignetting;
    float _speed;
    float _invert;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
float u_xlat18;

fragment float4 fx_nv_nodevideo_assetstore_film_cutting(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_film_cuttingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = _cur_time * 15.0;
    u_xlat0.x = trunc(u_xlat0.x);
    u_xlat6 = dot(u_xlat0.xx, float2(12.9898005, 78.2330017));
    u_xlat6 = sin(u_xlat6);
    u_xlat0.y = u_xlat6 * 43758.5469;
    u_xlat0.x = u_xlat0.x + 23.0;
    u_xlat0.x = dot(u_xlat0.xx, float2(12.9898005, 78.2330017));
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 43758.5469;
    u_xlat1.xy = fract(u_xlat0.yx);
    u_xlat0.xyw = u_xlat1.xyy * float3(-0.00800000038, 0.00400000019, 0.00999999978) + in.acScreenNorm.xyy;
    u_xlat1.xyz = inputImg.sample(__nv_smp, u_xlat0.xy).xyz;
    u_xlat2.xyz = u_xlat1.xyz * float3(-2.0, -2.0, -2.0) + float3(1.0, 1.0, 1.0);
    u_xlat1.xyz = float3(float3(u._invert, u._invert, u._invert)) * u_xlat2.xyz + u_xlat1.xyz;
    u_xlat0.z = _cur_time * u._speed + in.acScreenNorm.x;
    u_xlat0.xyz = texture0.sample(__nv_smp, u_xlat0.zw).xyz;
    u_xlat18 = in.acScreenNorm.x * 16.0;
    u_xlat2.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
    u_xlat18 = u_xlat18 * u_xlat2.x;
    u_xlat18 = u_xlat18 * in.acScreenNorm.y;
    u_xlat18 = u_xlat2.y * u_xlat18;
    u_xlat18 = log2(abs(u_xlat18));
    u_xlat18 = u_xlat18 * 0.400000006;
    u_xlat18 = exp2(u_xlat18);
    u_xlat18 = u_xlat18 + (-u._vignetting);
    u_xlat18 = u_xlat18 + 1.0;
    u_xlat1.xyz = float3(u_xlat18) * u_xlat1.xyz;
    u_xlat18 = dot(float3(0.212599993, 0.715200007, 0.0722000003), u_xlat1.xyz);
    u_xlat0.xyz = u_xlat0.xyz * float3(2.0, 2.0, 2.0) + float3(u_xlat18);
    u_xlat18 = (-u._luminosity) + 2.0;
    u_xlat0.xyz = (-float3(u_xlat18)) + u_xlat0.xyz;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat0.w = u_xlat1.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat1 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat18 = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat18 : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = u_xlat1.w;
    }
    return __nv_out;
    return __nv_out;
}
