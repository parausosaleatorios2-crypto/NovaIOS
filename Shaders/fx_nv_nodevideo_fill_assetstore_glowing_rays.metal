// ---------------------------------------------------------------------------
// Fill Assetstore Glowing Rays (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-glowing-rays.xml
// id     : nv.effect.nodevideo-fill-assetstore-glowing-rays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_glowing_raysParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float _speed;
    float _frequency;
    float _intensity;
    float _threshold;
    float _pattern;
    float _iteration;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
#define _SourceTex_TexelSize (1.0 / float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))))
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat8;
float u_xlat9;
bool u_xlatb9;
float2 u_xlat13;
bool2 u_xlatb13;
float u_xlat14;
float u_xlat18;
float u_xlat20;
bool u_xlatb20;

fragment float4 fx_nv_nodevideo_fill_assetstore_glowing_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_glowing_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u._color.xyz;
    u_xlat1.xyw = in.acScreenNorm.xyy + float3(-0.5, -0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy / _SourceTex_TexelSize.xy;
    u_xlat18 = _resolution.x / _resolution.y;
    u_xlat2.x = u_xlat18 * 0.5;
    u_xlat1.z = in.acScreenNorm.x * u_xlat18 + (-u_xlat2.x);
    u_xlat18 = dot(u_xlat1.zw, u_xlat1.zw);
    u_xlat2.x = rsqrt(u_xlat18);
    u_xlat13.xy = u_xlat1.zw * u_xlat2.xx;
    u_xlat2.x = float(int(u._iteration));
    u_xlat18 = u._intensity / u_xlat18;
    u_xlat8 = float(0.0);
    u_xlat14 = float(1.0);
    while(true){
        u_xlatb20 = u_xlat14>=u_xlat2.x;
        if(u_xlatb20){break;}
        u_xlat20 = u_xlat14 * _cur_time;
        u_xlat20 = u_xlat20 * u._frequency;
        u_xlat20 = u_xlat20 * 0.300000012;
        u_xlat20 = sin(u_xlat20);
        u_xlat20 = u_xlat20 * 0.5 + 0.5;
        u_xlat20 = u_xlat18 * u_xlat20;
        u_xlat3.x = u_xlat14 * 10.0;
        u_xlat3.x = _cur_time * u._speed + (-u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 0.25;
        u_xlat4.x = cos(u_xlat3.x);
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat4.y = u_xlat3.x;
        u_xlat3.x = dot(u_xlat4.xy, u_xlat13.xy);
        u_xlat3.x = abs(u_xlat3.x) * abs(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * u_xlat3.x;
        u_xlatb9 = u._threshold<u_xlat3.x;
        u_xlat9 = u_xlatb9 ? 1.0 : float(0.0);
        u_xlat3.x = u_xlat9 * u_xlat3.x;
        u_xlat20 = u_xlat20 * u_xlat3.x;
        u_xlat20 = u_xlat20 * 0.925000012;
        u_xlat20 = u_xlat20 / u_xlat14;
        u_xlat8 = u_xlat20 + u_xlat8;
        u_xlat14 = u_xlat14 + 1.0;
    }
    u_xlatb13.xy = equal(int4(int(u._pattern), int(u._blend_mode), int(u._pattern), int(u._blend_mode)), int4(1, 1, 1, 1)).xy;
    u_xlat18 = u_xlat1.x * u_xlat1.y;
    u_xlat18 = u_xlat18 * 0.666666687;
    u_xlatb1.x = u_xlat18>=(-u_xlat18);
    u_xlat18 = fract(abs(u_xlat18));
    u_xlat18 = (u_xlatb1.x) ? u_xlat18 : (-u_xlat18);
    u_xlat18 = u_xlat18 * 15.0;
    u_xlat18 = sin(u_xlat18);
    u_xlat18 = abs(u_xlat18) + 1.0;
    u_xlat18 = (u_xlatb13.x) ? u_xlat18 : 1.0;
    u_xlat18 = u_xlat8 * u_xlat18;
    u_xlat2.xyz = u_xlat0.xyz * float3(u_xlat18);
    u_xlat2.w = u_xlat18 * u._color.w;
    u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat4 = u_xlat2 * u_xlat3;
    u_xlat0.xyz = float3(u_xlat18) * u_xlat0.xyz + u_xlat3.xyz;
    u_xlat0.w = u_xlat3.w;
    u_xlat0 = (u_xlatb13.y) ? u_xlat4 : u_xlat0;
    u_xlat4.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat4;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat1.x = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
