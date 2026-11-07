// ---------------------------------------------------------------------------
// Effect Blur Cross Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-cross-blur.xml
// id     : nv.effect.nodevideo-effect-blur-cross-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_cross_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _samples;
    float2 _radius;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
int u_xlati0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat6;
int u_xlati12;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_effect_blur_cross_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_cross_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlati0 = int(u._samples) + int(0xFFFFFFFFu);
    u_xlat0.x = float(u_xlati0);
    u_xlat1 = float4(u._radius.x, u._radius.x, u._radius.y, u._radius.y) * float4(1.0, 0.0, 0.0, 1.0);
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    u_xlat6 = float(0.0);
    for(int u_xlati_loop_1 = int(0) ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat18 = float(u_xlati_loop_1);
        u_xlat18 = u_xlat18 / u_xlat0.x;
        u_xlat18 = u_xlat18 + -0.5;
        u_xlat3.x = -abs(u_xlat18) * 2.0 + 1.0;
        u_xlat6 = u_xlat3.x * 2.0 + u_xlat6;
        u_xlat4 = u_xlat1 * float4(u_xlat18) + in.acScreenNorm.xyxy;
        u_xlat5 = inputImg.sample(__nv_smp, u_xlat4.xy);
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat4.zw);
        u_xlat5 = u_xlat5 * u_xlat5;
        u_xlat4 = u_xlat4 * u_xlat4;
        u_xlat5 = u_xlat5 * u_xlat3.xxxx + u_xlat2;
        u_xlat2 = u_xlat4 * u_xlat3.xxxx + u_xlat5;
    }
    u_xlat0 = u_xlat2 / float4(u_xlat6);
    u_xlat0 = sqrt(u_xlat0);
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
