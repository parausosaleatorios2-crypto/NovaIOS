// ---------------------------------------------------------------------------
// Fill Assetstore Checker (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-checker.xml
// id     : nv.effect.nodevideo-fill-assetstore-checker
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_checkerParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _position;
    float2 _scale;
    float4 _color;
    float _angle;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat7;
bool u_xlatb7;
float u_xlat8;
float u_xlat13;

fragment float4 fx_nv_nodevideo_fill_assetstore_checker(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_checkerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = in.acScreenNorm.x;
    u_xlat1.x = u_xlat1.x + -0.5;
    u_xlat7 = _resolution.x / _resolution.y;
    u_xlat1.x = u_xlat7 * u_xlat1.x;
    u_xlat1.y = (-in.acScreenNorm.y) + 0.5;
    u_xlat1.xy = u_xlat1.xy + (-u._position.xy);
    u_xlat13 = u._angle * 0.0174532998;
    u_xlat2.x = sin(u_xlat13);
    u_xlat3.x = cos(u_xlat13);
    u_xlat4.x = (-u_xlat3.x);
    u_xlat4.y = u_xlat2.x;
    u_xlat4.z = u_xlat3.x;
    u_xlat1.z = dot(u_xlat1.xy, u_xlat4.yz);
    u_xlat1.x = dot(u_xlat1.xy, u_xlat4.xy);
    u_xlat1.xy = u_xlat1.xz * float2(10.0, 10.0);
    u_xlat1.xy = u_xlat1.xy / float2(u._scale.x, u._scale.y);
    u_xlat1.xy = floor(u_xlat1.xy);
    u_xlat1.x = abs(u_xlat1.x) + abs(u_xlat1.y);
    u_xlat1.x = u_xlat1.x * 0.5;
    u_xlatb7 = u_xlat1.x>=(-u_xlat1.x);
    u_xlat1.x = fract(u_xlat1.x);
    u_xlat1.x = (u_xlatb7) ? u_xlat1.x : (-u_xlat1.x);
    u_xlatb1 = 0.25>=u_xlat1.x;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat1 = u_xlat1.xxxx * u._color;
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat8 = (-u_xlat1.w) * u_xlat0.w + 1.0;
    u_xlat4 = u_xlat0 * float4(u_xlat8);
    u_xlat4 = u_xlat1 * u_xlat3.wwww + u_xlat4;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat1.xyz;
    u_xlat1 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat3;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
