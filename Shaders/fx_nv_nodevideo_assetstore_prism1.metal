// ---------------------------------------------------------------------------
// Prism1 (NV)
// origem : assets/effects/nv-nodevideo-assetstore-prism1.xml
// id     : nv.effect.nodevideo-assetstore-prism1
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_prism1Params {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amplitude;
    float _speed;
    float _direction;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat12;
float2 u_xlat13;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_assetstore_prism1(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_prism1Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._direction + 90.0;
    u_xlat0.x = u_xlat0.x * 0.0174532942;
    u_xlat1.x = sin((-u_xlat0.x));
    u_xlat1.y = cos(u_xlat0.x);
    u_xlat0.x = _cur_time * u._speed;
    u_xlat0.xy = in.acScreenNorm.xy * float2(20.0, 20.0) + u_xlat0.xx;
    u_xlat0.xy = sin(u_xlat0.xy);
    u_xlat12.xy = u_xlat0.xy * u_xlat0.xy;
    u_xlat0.xy = u_xlat12.xy * u_xlat0.xy;
    u_xlat2.w = 1.0;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat3.w = float(0.0);
    u_xlat12.x = 0.0;
    while(true){
        u_xlatb18 = u_xlat12.x>=1.0;
        if(u_xlatb18){break;}
        u_xlat18 = (-u_xlat12.x) + 1.0;
        u_xlat18 = u_xlat12.x * u_xlat18;
        u_xlat18 = log2(u_xlat18);
        u_xlat18 = u_xlat18 * 1.5;
        u_xlat18 = exp2(u_xlat18);
        u_xlat4.y = u_xlat18 * 6.80000019;
        u_xlat13.xy = u_xlat12.xx * u_xlat1.xy;
        u_xlat13.xy = u_xlat13.xy * float2(u._amplitude);
        u_xlat13.xy = u_xlat0.xy * u_xlat13.xy;
        u_xlat13.xy = u_xlat13.xy * float2(0.100000001, 0.100000001) + in.acScreenNorm.xy;
        u_xlat4.xz = u_xlat12.xx * float2(1.0, -1.0) + float2(0.0, 1.0);
        u_xlat2.xyz = u_xlat4.xyz * u_xlat4.xyz;
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat13.xy);
        u_xlat3 = u_xlat2 * u_xlat4 + u_xlat3;
        u_xlat12.x = u_xlat12.x + 0.00999999978;
    }
    u_xlat0 = u_xlat3 * float4(0.029555222, 0.0302767847, 0.0295551848, 0.00990098994);
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
