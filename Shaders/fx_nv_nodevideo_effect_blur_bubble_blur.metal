// ---------------------------------------------------------------------------
// Effect Blur Bubble Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-bubble-blur.xml
// id     : nv.effect.nodevideo-effect-blur-bubble-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_bubble_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _radius;
    float _inner_cutout;
    float _intensity;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
int u_xlati5;
float2 u_xlat6;
float4 u_xlat7;
float4 u_xlat8;
float4 u_xlat9;
float u_xlat13;
float u_xlat15;
float u_xlat20;
int u_xlati23;
int u_xlati25;
float2 u_xlat26;
float u_xlat30;
float u_xlat33;
bool u_xlatb33;
float u_xlat35;
bool u_xlatb35;
float u_xlat36;

fragment float4 fx_nv_nodevideo_effect_blur_bubble_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_bubble_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = float2(1.0, 1.0) / _resolution.xy;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2 = u_xlat1 * u_xlat1;
    u_xlat20 = u._radius * 0.100000001;
    u_xlat30 = _resolution.y / _resolution.x;
    u_xlat3.x = u._inner_cutout + u._inner_cutout;
    u_xlat4 = u_xlat2;
    u_xlat13 = float(1.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<60 ; u_xlati_loop_1++)
    {
        u_xlat33 = float(u_xlati_loop_1);
        u_xlat33 = u_xlat33 * 0.104719803;
        u_xlat5.x = cos(u_xlat33);
        u_xlat5.x = u_xlat20 * u_xlat5.x;
        u_xlat33 = sin((-u_xlat33));
        u_xlat6.y = u_xlat20 * u_xlat33;
        u_xlat6.x = u_xlat30 * u_xlat5.x;
        u_xlat5.xy = u_xlat6.xy / u_xlat0.xy;
        u_xlat33 = dot(u_xlat5.xy, u_xlat5.xy);
        u_xlat33 = sqrt(u_xlat33);
        u_xlat33 = max(u_xlat33, 1.00999999);
        u_xlat33 = min(u_xlat33, 100.010002);
        u_xlati5 = int(u_xlat33);
        u_xlat33 = trunc(u_xlat33);
        u_xlat7 = u_xlat4;
        u_xlat15 = u_xlat13;
        for(int u_xlati_loop_2 = 0 ; u_xlati_loop_2<u_xlati5 ; u_xlati_loop_2++)
        {
            u_xlat35 = float(u_xlati_loop_2);
            u_xlat35 = u_xlat35 / u_xlat33;
            u_xlat26.xy = (-u_xlat6.xy) * float2(u_xlat35) + in.acScreenNorm.xy;
            u_xlat8 = inputImg.sample(__nv_smp, u_xlat26.xy);
            u_xlat9 = u_xlat8 * u_xlat8;
            u_xlat26.x = u_xlat9.y + u_xlat9.x;
            u_xlat26.x = u_xlat8.z * u_xlat8.z + u_xlat26.x;
            u_xlat26.x = u_xlat26.x * 0.333333343;
            u_xlat35 = log2(u_xlat35);
            u_xlat35 = u_xlat3.x * u_xlat35;
            u_xlat35 = exp2(u_xlat35);
            u_xlat26.x = log2(u_xlat26.x);
            u_xlat26.x = u_xlat26.x * u._intensity;
            u_xlat26.x = exp2(u_xlat26.x);
            u_xlat36 = u_xlat35 * u_xlat26.x;
            u_xlat7 = u_xlat9 * float4(u_xlat36) + u_xlat7;
            u_xlat15 = u_xlat35 * u_xlat26.x + u_xlat15;
        }
        u_xlat4 = u_xlat7;
        u_xlat13 = u_xlat15;
    }
    u_xlat0 = u_xlat4 / float4(u_xlat13);
    u_xlat0 = sqrt(u_xlat0);
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2.x = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
