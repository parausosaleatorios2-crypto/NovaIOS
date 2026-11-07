// ---------------------------------------------------------------------------
// Effect Distort Scale Wipe (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-scale-wipe.xml
// id     : nv.effect.nodevideo-effect-distort-scale-wipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_scale_wipeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _angle;
    float _strength;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat12;
bool2 u_xlatb12;
float u_xlat13;
float u_xlat19;
bool u_xlatb19;

fragment float4 fx_nv_nodevideo_effect_distort_scale_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_scale_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u._center.xy + float2(-0.5, -0.5);
    u_xlat1.x = u._angle * 0.0174532942;
    u_xlat1.y = cos(u_xlat1.x);
    u_xlat1.x = sin((-u_xlat1.x));
    u_xlat2 = u_xlat1.yyxx * float4(-0.5, 0.5, -0.5, 0.5);
    u_xlat1 = u_xlat12.xyxy * float4(_viewport_ratio.x, _viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.y) + u_xlat2.xzyw;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat1.xy);
    u_xlat12.xy = (-u_xlat1.xy) + u_xlat1.zw;
    u_xlat13 = dot(u_xlat0.xy, u_xlat12.xy);
    u_xlat19 = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat13 = u_xlat13 / u_xlat19;
    u_xlat0.xy = (-float2(u_xlat13)) * u_xlat12.xy + u_xlat0.xy;
    u_xlat19 = u_xlat0.x * u_xlat12.y;
    u_xlat19 = u_xlat12.x * u_xlat0.y + (-u_xlat19);
    u_xlatb19 = 0.0<u_xlat19;
    u_xlat2.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat2.x = sqrt(u_xlat2.x);
    u_xlat2.x = (-u_xlat2.x) * u._strength;
    u_xlat2.x = u_xlat2.x * 28.8539009;
    u_xlat2.x = exp2(u_xlat2.x);
    u_xlat19 = (u_xlatb19) ? u_xlat2.x : 1.0;
    u_xlat12.xy = float2(u_xlat13) * u_xlat12.xy + u_xlat1.xy;
    u_xlat0.xy = u_xlat0.xy * float2(u_xlat19) + u_xlat12.xy;
    u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
    u_xlatb12.xy = lessThan(u_xlat0.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb1.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlatb12.x = u_xlatb12.x || u_xlatb1.x;
    u_xlatb12.x = u_xlatb12.y || u_xlatb12.x;
    u_xlatb12.x = u_xlatb1.y || u_xlatb12.x;
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0.x = (u_xlatb12.x) ? 0.0 : 1.0;
    u_xlat0 = u_xlat0.xxxx * u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
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
