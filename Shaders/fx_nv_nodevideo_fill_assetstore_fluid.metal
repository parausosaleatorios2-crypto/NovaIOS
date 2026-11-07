// ---------------------------------------------------------------------------
// Fill Assetstore Fluid (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-fluid.xml
// id     : nv.effect.nodevideo-fill-assetstore-fluid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_fluidParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _color;
    float2 _scale;
    float _contrast;
    float _distortion;
    float2 _offset;
    float _angle;
    float _speed;
    float _iteration;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat14;
float2 u_xlat16;
float u_xlat18;
bool u_xlatb18;
float u_xlat20;
float u_xlat21;
bool u_xlatb21;

fragment float4 fx_nv_nodevideo_fill_assetstore_fluid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_fluidParams&  u    [[buffer(1)]],
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
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat18 = _resolution.x / _resolution.y;
    u_xlat2.x = u_xlat18 * in.acScreenNorm.x;
    u_xlat2.y = in.acScreenNorm.y;
    u_xlat2.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat18 = u._angle * 0.0174532924;
    u_xlat3.x = sin(u_xlat18);
    u_xlat4.x = cos(u_xlat18);
    u_xlat5.x = sin((-u_xlat18));
    u_xlat5.y = u_xlat4.x;
    u_xlat4.x = dot(u_xlat5.yx, u_xlat2.xy);
    u_xlat5.z = u_xlat3.x;
    u_xlat4.y = dot(u_xlat5.zy, u_xlat2.xy);
    u_xlat2.xy = u_xlat4.xy * u._scale.xy + u._offset.xy;
    u_xlat2.xy = u_xlat2.xy + float2(0.5, 0.5);
    u_xlat18 = u._iteration * 10.0;
    u_xlat14 = _cur_time * u._speed + 1.0;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat4.x = float(0.0);
    u_xlat4.y = float(0.0);
    u_xlat20 = 7.0;
    while(true){
        u_xlatb21 = u_xlat20>=u_xlat18;
        if(u_xlatb21){break;}
        u_xlat16.xy = float2(u_xlat20) * u_xlat2.xy + float2(u_xlat14);
        u_xlat16.xy = u_xlat4.yx * float2(float2(u._distortion, u._distortion)) + u_xlat16.xy;
        u_xlat16.xy = cos(u_xlat16.xy);
        u_xlat4.xy = u_xlat16.xy + u_xlat4.xy;
        u_xlat21 = dot(u_xlat4.xy, u_xlat4.xy);
        u_xlat21 = sqrt(u_xlat21);
        u_xlat20 = u_xlat20 * 1.33333337;
        u_xlat21 = u_xlat21 / u_xlat20;
        u_xlat3.xyz = float3(u_xlat21) + u_xlat3.xyz;
    }
    u_xlat2.xyz = u_xlat3.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = u_xlat3.xyz * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat2.xyz * u_xlat3.xyz;
    u_xlat2.xyz = log2(u_xlat2.xyz);
    u_xlat2.xyz = u_xlat2.xyz * float3(float3(u._contrast, u._contrast, u._contrast));
    u_xlat2.xyz = exp2(u_xlat2.xyz);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat2.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(5.77078009, 5.77078009, 5.77078009);
    u_xlat2.xyz = exp2(u_xlat0.xyz);
    u_xlat0.xyz = exp2((-u_xlat0.xyz));
    u_xlat3.xyz = (-u_xlat0.xyz) + u_xlat2.xyz;
    u_xlat0.xyz = u_xlat0.xyz + u_xlat2.xyz;
    u_xlat0.xyz = float3(1.0, 1.0, 1.0) / u_xlat0.xyz;
    u_xlat2.xyz = u_xlat0.xyz * u_xlat3.xyz;
    u_xlatb18 = int(u._blend_mode)==1;
    u_xlat2.w = 1.0;
    u_xlat4 = u_xlat1 * u_xlat2;
    u_xlat3.xyz = u_xlat3.xyz * u_xlat0.xyz + u_xlat1.xyz;
    u_xlat3.w = u_xlat1.w;
    u_xlat0 = (bool(u_xlatb18)) ? u_xlat4 : u_xlat3;
    u_xlat3.xyz = u_xlat2.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat0 : u_xlat3;
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
