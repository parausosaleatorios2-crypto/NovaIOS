// ---------------------------------------------------------------------------
// Glitch Jump (NV)
// origem : assets/effects/nv-nodevideo-assetstore-glitch-jump.xml
// id     : nv.effect.nodevideo-assetstore-glitch-jump
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_glitch_jumpParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _speed;
    float _direction;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float4 u_xlat1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;

fragment float4 fx_nv_nodevideo_assetstore_glitch_jump(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_glitch_jumpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(int(u._direction) == 0) {
        u_xlat0.x = _cur_time * u._speed + in.acScreenNorm.x;
        u_xlat0.x = fract(u_xlat0.x);
        u_xlat0.x = u_xlat0.x + (-in.acScreenNorm.x);
        u_xlat0.x = u._amount * u_xlat0.x + in.acScreenNorm.x;
        u_xlat0.x = fract(u_xlat0.x);
        u_xlat0.y = fract(in.acScreenNorm.y);
        u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    } else {
        u_xlat1.x = _cur_time * u._speed + in.acScreenNorm.y;
        u_xlat1.x = fract(u_xlat1.x);
        u_xlat1.x = u_xlat1.x + (-in.acScreenNorm.y);
        u_xlat1.x = u._amount * u_xlat1.x + in.acScreenNorm.y;
        u_xlat2.x = fract(in.acScreenNorm.x);
        u_xlat2.y = fract(u_xlat1.x);
        u_xlat0 = inputImg.sample(__nv_smp, u_xlat2.xy);
    }
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
