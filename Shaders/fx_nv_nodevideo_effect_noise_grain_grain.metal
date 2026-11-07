// ---------------------------------------------------------------------------
// Effect Noise Grain Grain (NV)
// origem : assets/effects/nv-nodevideo-effect-noise-grain-grain.xml
// id     : nv.effect.nodevideo-effect-noise-grain-grain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_noise_grain_grainParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _blend_mode;
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
float3 u_xlat7;
bool u_xlatb7;
bool2 u_xlatb13;

fragment float4 fx_nv_nodevideo_effect_noise_grain_grain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_noise_grain_grainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xy = in.acScreenNorm.xy + float2(4.0, 4.0);
    u_xlat1.x = u_xlat1.y * u_xlat1.x;
    u_xlat7.x = _cur_time * 10.0 + 100.0;
    u_xlat1.x = u_xlat7.x * u_xlat1.x;
    u_xlat1.xy = u_xlat1.xx * float2(0.0769230798, 0.008130081);
    u_xlatb13.xy = greaterThanEqual(u_xlat1.xyxy, (-u_xlat1.xyxy)).xy;
    u_xlat1.xy = fract(abs(u_xlat1.xy));
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? u_xlat1.x : (-u_xlat1.x);
        hlslcc_movcTemp.y = (u_xlatb13.y) ? u_xlat1.y : (-u_xlat1.y);
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1.xy = u_xlat1.xy * float2(13.0, 123.0) + float2(1.0, 1.0);
    u_xlat1.x = u_xlat1.y * u_xlat1.x;
    u_xlat1.x = u_xlat1.x * 100.0;
    u_xlatb7 = u_xlat1.x>=(-u_xlat1.x);
    u_xlat1.x = fract(abs(u_xlat1.x));
    u_xlat1.x = (u_xlatb7) ? u_xlat1.x : (-u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 0.00999999978 + -0.00499999989;
    u_xlat7.x = (-u_xlat1.x) * u._amount + 1.0;
    u_xlat7.xyz = u_xlat0.xyz * u_xlat7.xxx;
    u_xlat2.xyz = u_xlat1.xxx * float3(u._amount) + u_xlat0.xyz;
    u_xlat1.xyz = (int(u._blend_mode) != 0) ? u_xlat2.xyz : u_xlat7.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1.w = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat1.xyz;
        __nv_out.w = u_xlat0.w;
    }
    return __nv_out;
    return __nv_out;
}
