// ---------------------------------------------------------------------------
// Effect Blur Spin Blur (NV)
// origem : assets/effects/nv-nodevideo-effect-blur-spin-blur.xml
// id     : nv.effect.nodevideo-effect-blur-spin-blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_blur_spin_blurParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _angle;
    float _samples;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
int u_xlati3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float u_xlat7;
float2 u_xlat10;
bool u_xlatb10;
float u_xlat21;

fragment float4 fx_nv_nodevideo_effect_blur_spin_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_blur_spin_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + (-u._center.xy);
    u_xlat21 = _resolution.y / _resolution.x;
    u_xlat0.z = u_xlat21 * u_xlat0.y;
    u_xlat7 = u._angle * 0.0174532998;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat21 = float(int(u._samples));
    u_xlat2 = u_xlat1;
    for(int u_xlati_loop_1 = 1 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat10.x = float(u_xlati_loop_1);
        u_xlat10.x = u_xlat7 * u_xlat10.x;
        u_xlat10.x = u_xlat10.x / u_xlat21;
        u_xlat10.x = (-u._angle) * 0.00872664992 + u_xlat10.x;
        u_xlat4.x = sin(u_xlat10.x);
        u_xlat5.x = cos(u_xlat10.x);
        u_xlat6.x = (-u_xlat4.x);
        u_xlat6.y = u_xlat5.x;
        u_xlat5.x = dot(u_xlat6.yx, u_xlat0.xz);
        u_xlat6.z = u_xlat4.x;
        u_xlat10.x = dot(u_xlat6.zy, u_xlat0.xz);
        u_xlat10.x = u_xlat10.x * _resolution.x;
        u_xlat5.y = u_xlat10.x / _resolution.y;
        u_xlat10.xy = u_xlat5.xy + u._center.xy;
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat10.xy);
        u_xlat2 = u_xlat2 + u_xlat4;
    }
    u_xlat0 = u_xlat2 / float4(u_xlat21);
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
