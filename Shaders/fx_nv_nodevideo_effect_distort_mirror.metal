// ---------------------------------------------------------------------------
// Effect Distort Mirror (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-mirror.xml
// id     : nv.effect.nodevideo-effect-distort-mirror
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_mirrorParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _reflection_center;
    float _reflection_angle;
    float _invert;
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
float2 u_xlat13;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_effect_distort_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_mirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat12.xy = u._reflection_center.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat13.xy = float2(float2(u._reflection_angle, u._reflection_angle)) * float2(0.0174532942, 360.0);
    u_xlat2.x = cos(u_xlat13.x);
    u_xlat13.x = sin((-u_xlat13.x));
    u_xlat2.xy = u_xlat2.xx * float2(-0.5, 0.5);
    u_xlat2.zw = u_xlat13.xx * float2(-0.5, 0.5);
    u_xlat2 = u_xlat12.xyxy * float4(_viewport_ratio.x, _viewport_ratio.y, _viewport_ratio.x, _viewport_ratio.y) + u_xlat2.xzyw;
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + (-u_xlat2.xy);
    u_xlat12.xy = (-u_xlat2.xy) + u_xlat2.zw;
    u_xlat13.x = dot(u_xlat0.xy, u_xlat12.xy);
    u_xlat2.x = dot(u_xlat12.xy, u_xlat12.xy);
    u_xlat13.x = u_xlat13.x / u_xlat2.x;
    u_xlat0.xy = (-u_xlat13.xx) * u_xlat12.xy + u_xlat0.xy;
    u_xlatb12.x = u_xlat13.y>=(-u_xlat13.y);
    u_xlat12.xy = (u_xlatb12.x) ? float2(360.0, 0.00277777785) : float2(-360.0, -0.00277777785);
    u_xlat18 = u_xlat12.y * u._reflection_angle;
    u_xlat18 = fract(u_xlat18);
    u_xlat12.x = u_xlat18 * u_xlat12.x;
    u_xlatb18 = 90.0<abs(u_xlat12.x);
    u_xlatb12.x = abs(u_xlat12.x)<270.0;
    u_xlatb12.x = u_xlatb12.x && u_xlatb18;
    u_xlat13.xy = (int(u._invert) != 0) ? float2(-1.0, 1.0) : float2(1.0, -1.0);
    u_xlat12.x = (u_xlatb12.x) ? u_xlat13.y : u_xlat13.x;
    u_xlatb18 = abs(u_xlat0.y)<9.99999975e-05;
    u_xlat13.xy = u_xlat12.xx * (-u_xlat0.yx);
    u_xlat12.x = (u_xlatb18) ? u_xlat13.y : u_xlat13.x;
    u_xlat12.x = u_xlat12.x * 100000.0;
    u_xlat12.x = clamp(u_xlat12.x, 0.0, 1.0);
    u_xlat0.xy = u_xlat0.xy * u_xlat12.xx;
    u_xlat0.xy = (-u_xlat0.xy) * float2(2.0, 2.0) + u_xlat1.xy;
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
