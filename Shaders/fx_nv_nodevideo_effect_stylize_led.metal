// ---------------------------------------------------------------------------
// Effect Stylize Led (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-led.xml
// id     : nv.effect.nodevideo-effect-stylize-led
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_ledParams {
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
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
float2 u_xlat13;
float u_xlat18;

fragment float4 fx_nv_nodevideo_effect_stylize_led(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_ledParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = float3(u._scale, u._size, u._scale) * float3(10.0, 10.0, 5.0);
    u_xlat18 = 3.14159203 / u_xlat0.x;
    u_xlat6 = u_xlat0.y / u_xlat0.x;
    u_xlat1.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * _resolution.xy;
    u_xlat13.xy = float2(u_xlat18) * u_xlat1.xy;
    u_xlat13.xy = sin(u_xlat13.xy);
    u_xlat13.xy = (-float2(u_xlat6)) + abs(u_xlat13.xy);
    u_xlat1.xy = u_xlat1.xy / u_xlat0.xx;
    u_xlat1.xy = floor(u_xlat1.xy);
    u_xlat0.xz = u_xlat1.xy * u_xlat0.xx + u_xlat0.zz;
    u_xlat0.xz = u_xlat0.xz / _resolution.xy;
    u_xlat0.xz = u_xlat0.xz + float2(0.5, 0.5);
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat0.xz);
    u_xlat2 = u_xlat13.xxxx * u_xlat2;
    u_xlat1 = u_xlat13.yyyy * u_xlat2;
    u_xlat0.x = u._brightness / u_xlat6;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = u_xlat1 * u_xlat0.xxxx + (-u_xlat2);
    u_xlat0 = float4(float4(u._blend, u._blend, u._blend, u._blend)) * u_xlat0 + u_xlat2;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
