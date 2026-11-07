// ---------------------------------------------------------------------------
// Sdf (NV)
// origem : assets/effects/nv-nodevideo-assetstore-sdf.xml
// id     : nv.effect.nodevideo-assetstore-sdf
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_sdfParams { int __vazio; };

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
float2 u_xlat3;
bool u_xlatb3;
float3 u_xlat4;
float u_xlat5;
float2 u_xlat6;
float u_xlat10;
float u_xlat11;
float2 u_xlat12;
bool u_xlatb12;
float u_xlat13;
float2 u_xlat14;
float u_xlat15;
float u_xlat16;
float u_xlat17;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_assetstore_sdf(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_sdfParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = inputImg.sample(__nv_smp, in.acScreenNorm.xy).x;
    u_xlat0.xy = u_xlat0.xx * float2(2.0, 2.0) + float2(-1.0, -1.00600004);
    u_xlat0.x = 0.0149999997 / u_xlat0.x;
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 1.29999995;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat5 = u_xlat0.y * -333.333344;
    u_xlat5 = clamp(u_xlat5, 0.0, 1.0);
    u_xlat10 = u_xlat5 * -2.0 + 3.0;
    u_xlat5 = u_xlat5 * u_xlat5;
    u_xlat5 = u_xlat5 * u_xlat10;
    u_xlat0.xzw = u_xlat0.xxx * float3(1.0, 0.0500000007, 0.300000012);
    u_xlat0.xyz = float3(u_xlat5) * float3(10.0, 10.0, 10.0) + u_xlat0.xzw;
    u_xlat1.xz = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat15 = _resolution.x / _resolution.y;
    u_xlat1.y = u_xlat15 * u_xlat1.x;
    u_xlat1.xw = u_xlat1.yz * float2(4.0, 4.0);
    u_xlat2.xyz = float3(float3(_cur_time, _cur_time, _cur_time)) * float3(1.60000002, 1.70000005, 0.720000029);
    u_xlat2.xw = u_xlat1.yz * float2(2.79999995, 2.79999995) + (-u_xlat2.xx);
    u_xlat3.xy = u_xlat2.xw;
    u_xlat15 = 2.0;
    u_xlat4.x = 0.0;
    u_xlat13 = 1.0;
    while(true){
        u_xlatb18 = u_xlat13>=6.0;
        if(u_xlatb18){break;}
        u_xlat14.xy = u_xlat3.xy * float2(0.00999999978, 0.00999999978);
        u_xlat18 = texture0.sample(__nv_smp, u_xlat14.xy).x;
        u_xlat18 = u_xlat18 + -0.5;
        u_xlat18 = u_xlat18 + u_xlat18;
        u_xlat18 = abs(u_xlat18) / u_xlat15;
        u_xlat4.x = u_xlat18 + u_xlat4.x;
        u_xlat15 = u_xlat15 + u_xlat15;
        u_xlat3.xy = u_xlat3.xy + u_xlat3.xy;
        u_xlat13 = u_xlat13 + 1.0;
    }
    u_xlat6.xy = u_xlat1.yz * float2(2.79999995, 2.79999995) + u_xlat2.yy;
    u_xlat2.xy = u_xlat6.xy;
    u_xlat15 = 2.0;
    u_xlat4.y = 0.0;
    u_xlat17 = 1.0;
    while(true){
        u_xlatb3 = u_xlat17>=6.0;
        if(u_xlatb3){break;}
        u_xlat3.xy = u_xlat2.xy * float2(0.00999999978, 0.00999999978);
        u_xlat3.x = texture0.sample(__nv_smp, u_xlat3.xy).x;
        u_xlat3.x = u_xlat3.x + -0.5;
        u_xlat3.x = u_xlat3.x + u_xlat3.x;
        u_xlat3.x = abs(u_xlat3.x) / u_xlat15;
        u_xlat4.y = u_xlat3.x + u_xlat4.y;
        u_xlat15 = u_xlat15 + u_xlat15;
        u_xlat2.xy = u_xlat2.xy + u_xlat2.xy;
        u_xlat17 = u_xlat17 + 1.0;
    }
    u_xlat6.xy = u_xlat4.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat6.xy * float2(0.75999999, 0.75999999) + u_xlat1.xw;
    u_xlat3.x = cos(u_xlat2.z);
    u_xlat2.x = sin(u_xlat2.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat4.y = u_xlat3.x;
    u_xlat15 = dot(u_xlat4.yx, u_xlat1.xy);
    u_xlat4.z = u_xlat2.x;
    u_xlat1.x = dot(u_xlat4.zy, u_xlat1.xy);
    u_xlat2.x = u_xlat15;
    u_xlat2.y = u_xlat1.x;
    u_xlat6.x = float(2.0);
    u_xlat11 = float(0.0);
    u_xlat16 = float(1.0);
    while(true){
        u_xlatb12 = u_xlat16>=6.0;
        if(u_xlatb12){break;}
        u_xlat12.xy = u_xlat2.xy * float2(0.00999999978, 0.00999999978);
        u_xlat12.x = texture0.sample(__nv_smp, u_xlat12.xy).x;
        u_xlat12.x = u_xlat12.x + -0.5;
        u_xlat12.x = u_xlat12.x + u_xlat12.x;
        u_xlat12.x = abs(u_xlat12.x) / u_xlat6.x;
        u_xlat11 = u_xlat11 + u_xlat12.x;
        u_xlat6.x = u_xlat6.x + u_xlat6.x;
        u_xlat2.xy = u_xlat2.xy + u_xlat2.xy;
        u_xlat16 = u_xlat16 + 1.0;
    }
    u_xlat0.xyz = u_xlat0.xyz * float3(u_xlat11);
    u_xlat0.xyz = log2(u_xlat0.xyz);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.899999976, 0.899999976, 0.899999976);
    u_xlat0.xyz = exp2(u_xlat0.xyz);
    __nv_out.xyz = u_xlat0.xyz * float3(u_xlat11);
    __nv_out.w = 1.0;
    return __nv_out;
    return __nv_out;
}
