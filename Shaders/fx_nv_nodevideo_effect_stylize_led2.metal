// ---------------------------------------------------------------------------
// Effect Stylize Led2 (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-led2.xml
// id     : nv.effect.nodevideo-effect-stylize-led2
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_led2Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _size;
    float _scale;
    float _brightness;
    float _blend;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat12;
float2 u_xlat13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_effect_stylize_led2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_led2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = float2(float2(u._scale, u._scale)) * float2(10.0, 5.0);
    u_xlat12.x = u._size + -0.5;
    u_xlat12.x = u_xlat12.x * -10.0;
    u_xlat18 = 3.1415925 / u_xlat0.x;
    u_xlat12.x = u_xlat12.x / u_xlat0.x;
    u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * _resolution.xy;
    u_xlat13.xy = float2(u_xlat18) * u_xlat1.xy;
    u_xlat13.xy = sin(u_xlat13.xy);
    u_xlat12.xy = (-u_xlat12.xx) + abs(u_xlat13.xy);
    u_xlat1.xy = u_xlat1.xy / u_xlat0.xx;
    u_xlat1.xy = floor(u_xlat1.xy);
    u_xlat0.xy = u_xlat1.xy * u_xlat0.xx + u_xlat0.yy;
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat1 = u_xlat12.xxxx * u_xlat1;
    u_xlat0 = u_xlat12.yyyy * u_xlat1;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = u_xlat0 * float4(float4(u._brightness, u._brightness, u._brightness, u._brightness)) + (-u_xlat1);
    u_xlat0 = float4(float4(u._blend, u._blend, u._blend, u._blend)) * u_xlat0 + u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
