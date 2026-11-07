// ---------------------------------------------------------------------------
// Effect Noise Grain Denoise (NV)
// origem : assets/effects/nv-nodevideo-effect-noise-grain-denoise.xml
// id     : nv.effect.nodevideo-effect-noise-grain-denoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_noise_grain_denoiseParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _threshold;
    float _radius;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float4 u_xlat7;
float2 u_xlat9;
float u_xlat10;
float u_xlat18;
bool u_xlatb18;
float u_xlat20;
bool u_xlatb20;
float u_xlat25;
float u_xlat26;
float u_xlat28;

fragment float4 fx_nv_nodevideo_effect_noise_grain_denoise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_noise_grain_denoiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u._radius + u._radius;
    u_xlat1.x = rint(u_xlat1.x);
    u_xlat9.xy = float2(u._radius, u._threshold) * float2(u._radius, u._threshold);
    u_xlat9.xy = float2(0.5, 0.5) / u_xlat9.xy;
    u_xlat25 = u_xlat9.x * 0.318309873;
    u_xlat2 = 0.398942292 / u._threshold;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat10 = 0.0;
    u_xlat4.x = (-u_xlat1.x);
    while(true){
        u_xlatb18 = u_xlat1.x<u_xlat4.x;
        if(u_xlatb18){break;}
        u_xlat18 = u_xlat4.x * u_xlat4.x;
        u_xlat18 = u_xlat1.x * u_xlat1.x + (-u_xlat18);
        u_xlat18 = sqrt(u_xlat18);
        u_xlat5 = u_xlat3;
        u_xlat26 = u_xlat10;
        u_xlat4.y = (-u_xlat18);
        while(true){
            u_xlatb20 = u_xlat18<u_xlat4.y;
            if(u_xlatb20){break;}
            u_xlat20 = dot(u_xlat4.xy, u_xlat4.xy);
            u_xlat20 = u_xlat9.x * (-u_xlat20);
            u_xlat20 = u_xlat20 * 1.44269502;
            u_xlat20 = exp2(u_xlat20);
            u_xlat20 = u_xlat25 * u_xlat20;
            u_xlat6.xy = u_xlat4.xy * _SourceTex_TexelSize.xy + in.acScreenNorm.xy;
            u_xlat6 = inputImg.sample(__nv_smp, u_xlat6.xy);
            u_xlat7 = (-u_xlat0) + u_xlat6;
            u_xlat28 = dot(u_xlat7, u_xlat7);
            u_xlat28 = u_xlat9.y * (-u_xlat28);
            u_xlat28 = u_xlat28 * 1.44269502;
            u_xlat28 = exp2(u_xlat28);
            u_xlat28 = u_xlat2 * u_xlat28;
            u_xlat7.x = u_xlat20 * u_xlat28;
            u_xlat26 = u_xlat28 * u_xlat20 + u_xlat26;
            u_xlat5 = u_xlat7.xxxx * u_xlat6 + u_xlat5;
            u_xlat4.y = u_xlat4.y + 1.0;
        }
        u_xlat3 = u_xlat5;
        u_xlat10 = u_xlat26;
        u_xlat4.x = u_xlat4.x + 1.0;
    }
    u_xlat1 = u_xlat3 / float4(u_xlat10);
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
