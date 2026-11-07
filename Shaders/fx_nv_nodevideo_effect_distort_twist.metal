// ---------------------------------------------------------------------------
// Effect Distort Twist (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-twist.xml
// id     : nv.effect.nodevideo-effect-distort-twist
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_twistParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _strength;
    float _evolution;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool u_xlatb12;
float2 u_xlat13;
bool2 u_xlatb13;

fragment float4 fx_nv_nodevideo_effect_distort_twist(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_twistParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.yx * float2(6.28000021, 6.28000021) + float2(float2(u._evolution, u._evolution));
    u_xlat0.xy = sin(u_xlat0.xy);
    u_xlat0.xy = u_xlat0.xy * u._strength.xy;
    u_xlat0.xy = u_xlat0.xy * float2(0.100000001, 0.100000001) + in.acScreenNorm.xy;
    u_xlatb12 = int(u._keep_edge)==1;
    u_xlatb1.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb13.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat0.xyxy).xy;
    u_xlat2.xy = fract(u_xlat0.xy);
    u_xlat2.xy = (-u_xlat2.xy) + float2(1.0, 1.0);
    u_xlat13.x = (u_xlatb13.x) ? u_xlat2.x : u_xlat0.x;
    u_xlat13.y = (u_xlatb13.y) ? u_xlat2.y : u_xlat0.y;
    u_xlat1.x = (u_xlatb1.x) ? (-u_xlat0.x) : u_xlat13.x;
    u_xlat1.y = (u_xlatb1.y) ? (-u_xlat0.y) : u_xlat13.y;
    u_xlat0.xy = (bool(u_xlatb12)) ? u_xlat1.xy : u_xlat0.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
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
