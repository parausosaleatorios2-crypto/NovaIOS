// ---------------------------------------------------------------------------
// Effect Distort Twirl (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-twirl.xml
// id     : nv.effect.nodevideo-effect-distort-twirl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_twirlParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _angle;
    float _radius;
    float2 _center;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
float u_xlat7;
bool u_xlatb7;
float u_xlat13;
bool u_xlatb13;
float u_xlat18;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_effect_distort_twirl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_twirlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._angle * 0.0174532942;
    u_xlat6.xy = in.acScreenNorm.xy + (-float2(u._center.x, u._center.y));
    u_xlat1.xy = u_xlat6.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat18 = dot(u_xlat1.xy, u_xlat1.xy);
    u_xlat18 = sqrt(u_xlat18);
    u_xlat1.x = min(abs(u_xlat6.x), abs(u_xlat6.y));
    u_xlat7 = max(abs(u_xlat6.x), abs(u_xlat6.y));
    u_xlat7 = float(1.0) / u_xlat7;
    u_xlat1.x = u_xlat7 * u_xlat1.x;
    u_xlat7 = u_xlat1.x * u_xlat1.x;
    u_xlat13 = u_xlat7 * 0.0208350997 + -0.0851330012;
    u_xlat13 = u_xlat7 * u_xlat13 + 0.180141002;
    u_xlat13 = u_xlat7 * u_xlat13 + -0.330299497;
    u_xlat7 = u_xlat7 * u_xlat13 + 0.999866009;
    u_xlat13 = u_xlat7 * u_xlat1.x;
    u_xlatb19 = abs(u_xlat6.x)<abs(u_xlat6.y);
    u_xlat13 = u_xlat13 * -2.0 + 1.57079637;
    u_xlat13 = u_xlatb19 ? u_xlat13 : float(0.0);
    u_xlat1.x = u_xlat1.x * u_xlat7 + u_xlat13;
    u_xlatb7 = u_xlat6.x<(-u_xlat6.x);
    u_xlat7 = u_xlatb7 ? -3.14159274 : float(0.0);
    u_xlat1.x = u_xlat7 + u_xlat1.x;
    u_xlat7 = min(u_xlat6.x, u_xlat6.y);
    u_xlat13 = max(u_xlat6.x, u_xlat6.y);
    u_xlatb7 = u_xlat7<(-u_xlat7);
    u_xlatb13 = u_xlat13>=(-u_xlat13);
    u_xlatb7 = u_xlatb13 && u_xlatb7;
    u_xlat1.x = (u_xlatb7) ? (-u_xlat1.x) : u_xlat1.x;
    u_xlat18 = u_xlat18 + (-u._radius);
    u_xlat7 = float(1.0) / (-u._radius);
    u_xlat18 = u_xlat18 * u_xlat7;
    u_xlat18 = clamp(u_xlat18, 0.0, 1.0);
    u_xlat7 = u_xlat18 * -2.0 + 3.0;
    u_xlat18 = u_xlat18 * u_xlat18;
    u_xlat18 = u_xlat18 * u_xlat7;
    u_xlat0.x = u_xlat0.x * u_xlat18 + u_xlat1.x;
    u_xlat6.x = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlat6.x = sqrt(u_xlat6.x);
    u_xlat1.x = cos(u_xlat0.x);
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat1.x = u_xlat6.x * u_xlat1.x;
    u_xlat1.y = u_xlat0.x * u_xlat6.x;
    u_xlat0.xy = u_xlat1.xy + float2(u._center.x, u._center.y);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
