// ---------------------------------------------------------------------------
// Web Homebkg (NV)
// origem : assets/effects/nv-nodevideo-web-homebkg.xml
// id     : nv.effect.nodevideo-web-homebkg
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_web_homebkgParams { int __vazio; };

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool u_xlatb2;
float2 u_xlat3;
float u_xlat4;
bool u_xlatb4;
float u_xlat5;
float u_xlat6;
float2 u_xlat7;
bool u_xlatb7;
float u_xlat8;
bool2 u_xlatb8;
float u_xlat9;
float u_xlat10;
bool u_xlatb10;
bool u_xlatb11;

fragment float4 fx_nv_nodevideo_web_homebkg(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_web_homebkgParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = in.acScreenNorm.yxy + float3(-0.200000003, 0.0, -0.200000003);
    u_xlat1.xy = _Time.yy * float2(0.200000003, 0.179999992);
    u_xlat9 = in.acScreenNorm.x * 2.0 + u_xlat1.y;
    u_xlat7.x = float(0.0);
    u_xlat10 = float(1.0);
    while(true){
        u_xlatb2 = 4.0<u_xlat10;
        if(u_xlatb2){break;}
        u_xlat2.x = u_xlat9 * u_xlat10;
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat2.x = u_xlat2.x / u_xlat10;
        u_xlat7.x = u_xlat7.x + u_xlat2.x;
        u_xlat10 = u_xlat10 * 1.70000005;
    }
    u_xlat0.w = u_xlat7.x * 0.400000006;
    u_xlat10 = in.acScreenNorm.x * 1.20000005 + u_xlat1.x;
    u_xlat10 = u_xlat10 + 16.2999992;
    u_xlat2.x = float(0.0);
    u_xlat5 = float(1.0);
    while(true){
        u_xlatb8.x = 4.0<u_xlat5;
        if(u_xlatb8.x){break;}
        u_xlat8 = u_xlat10 * u_xlat5;
        u_xlat8 = sin(u_xlat8);
        u_xlat8 = u_xlat8 / u_xlat5;
        u_xlat2.x = u_xlat8 + u_xlat2.x;
        u_xlat5 = u_xlat5 * 1.70000005;
    }
    u_xlat10 = u_xlat2.x * 0.400000006;
    u_xlat5 = u_xlat7.x * 0.400000006 + (-u_xlat10);
    u_xlat5 = abs(u_xlat5) * 10.0 + 0.400000006;
    u_xlat5 = float(1.0) / u_xlat5;
    u_xlatb8.xy = lessThan(u_xlat0.wxwx, float4(u_xlat10)).xy;
    u_xlatb8.x = u_xlatb8.y && u_xlatb8.x;
    u_xlatb11 = u_xlat10<u_xlat0.w;
    u_xlatb10 = u_xlat10<u_xlat0.x;
    u_xlatb10 = u_xlatb10 && u_xlatb11;
    u_xlatb10 = u_xlatb10 || u_xlatb8.x;
    u_xlat9 = u_xlat2.x * 0.400000006 + (-u_xlat0.w);
    u_xlat7.x = (-u_xlat7.x) * 0.400000006 + u_xlat0.x;
    u_xlat9 = float(1.0) / u_xlat9;
    u_xlat9 = u_xlat9 * u_xlat7.x;
    u_xlat9 = clamp(u_xlat9, 0.0, 1.0);
    u_xlat7.x = u_xlat9 * -2.0 + 3.0;
    u_xlat9 = u_xlat9 * u_xlat9;
    u_xlat9 = u_xlat9 * u_xlat7.x;
    u_xlat9 = u_xlatb10 ? u_xlat9 : float(0.0);
    u_xlat9 = u_xlat9 * u_xlat9;
    u_xlat0.x = (-u_xlat2.x) * 0.400000006 + u_xlat0.x;
    u_xlat7.xy = abs(u_xlat0.xx) * float2(499.999969, 333.333344);
    u_xlat7.xy = min(u_xlat7.xy, float2(1.0, 1.0));
    u_xlat2.xz = u_xlat7.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat7.xy = u_xlat7.xy * u_xlat7.xy;
    u_xlat0.x = u_xlat7.x * u_xlat2.x;
    u_xlat0.x = u_xlat9 * u_xlat9 + (-u_xlat0.x);
    u_xlat9 = (-u_xlat2.z) * u_xlat7.y + 1.0;
    u_xlat0.x = u_xlat0.x + 1.0;
    u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
    u_xlat0.x = u_xlat9 + u_xlat0.x;
    u_xlat0.x = u_xlat5 * u_xlat0.x;
    u_xlat2 = u_xlat0.yzyz * float4(1.20000005, 1.0, 0.800000012, 1.0) + float4(11.1999998, -0.0, 32.3209991, 0.0);
    u_xlat3.xy = u_xlat2.xz * float2(2.0, 2.0) + u_xlat1.yy;
    u_xlat9 = 0.0;
    u_xlat4 = 1.0;
    while(true){
        u_xlatb7 = 4.0<u_xlat4;
        if(u_xlatb7){break;}
        u_xlat7.x = u_xlat3.x * u_xlat4;
        u_xlat7.x = sin(u_xlat7.x);
        u_xlat7.x = u_xlat7.x / u_xlat4;
        u_xlat9 = u_xlat9 + u_xlat7.x;
        u_xlat4 = u_xlat4 * 1.70000005;
    }
    u_xlat3.x = u_xlat9 * 0.400000006;
    u_xlat1.xy = u_xlat2.xz * float2(1.20000005, 1.20000005) + u_xlat1.xx;
    u_xlat1.xy = u_xlat1.xy + float2(16.2999992, 16.2999992);
    u_xlat7.x = float(0.0);
    u_xlat10 = float(1.0);
    while(true){
        u_xlatb2 = 4.0<u_xlat10;
        if(u_xlatb2){break;}
        u_xlat2.x = u_xlat10 * u_xlat1.x;
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat2.x = u_xlat2.x / u_xlat10;
        u_xlat7.x = u_xlat7.x + u_xlat2.x;
        u_xlat10 = u_xlat10 * 1.70000005;
    }
    u_xlat1.x = u_xlat7.x * 0.400000006;
    u_xlat10 = u_xlat9 * 0.400000006 + (-u_xlat1.x);
    u_xlat10 = abs(u_xlat10) * 10.0 + 0.400000006;
    u_xlat10 = float(1.0) / u_xlat10;
    u_xlatb2 = u_xlat3.x<u_xlat1.x;
    u_xlatb8.x = u_xlat2.y<u_xlat1.x;
    u_xlatb2 = u_xlatb8.x && u_xlatb2;
    u_xlatb8.x = u_xlat1.x<u_xlat3.x;
    u_xlatb1 = u_xlat1.x<u_xlat2.y;
    u_xlatb1 = u_xlatb1 && u_xlatb8.x;
    u_xlatb1 = u_xlatb1 || u_xlatb2;
    u_xlat3.x = u_xlat7.x * 0.400000006 + (-u_xlat3.x);
    u_xlat9 = (-u_xlat9) * 0.400000006 + u_xlat2.y;
    u_xlat3.x = float(1.0) / u_xlat3.x;
    u_xlat3.x = u_xlat3.x * u_xlat9;
    u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
    u_xlat9 = u_xlat3.x * -2.0 + 3.0;
    u_xlat3.x = u_xlat3.x * u_xlat3.x;
    u_xlat3.x = u_xlat3.x * u_xlat9;
    u_xlat3.x = u_xlatb1 ? u_xlat3.x : float(0.0);
    u_xlat3.x = u_xlat3.x * u_xlat3.x;
    u_xlat9 = (-u_xlat7.x) * 0.400000006 + u_xlat2.y;
    u_xlat1.xz = abs(float2(u_xlat9)) * float2(499.999969, 333.333344);
    u_xlat1.xz = min(u_xlat1.xz, float2(1.0, 1.0));
    u_xlat2.xy = u_xlat1.xz * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat1.xz = u_xlat1.xz * u_xlat1.xz;
    u_xlat9 = u_xlat1.x * u_xlat2.x;
    u_xlat3.x = u_xlat3.x * u_xlat3.x + (-u_xlat9);
    u_xlat9 = (-u_xlat2.y) * u_xlat1.z + 1.0;
    u_xlat3.x = u_xlat3.x + 1.0;
    u_xlat3.x = clamp(u_xlat3.x, 0.0, 1.0);
    u_xlat3.x = u_xlat9 + u_xlat3.x;
    u_xlat3.x = u_xlat10 * u_xlat3.x;
    u_xlat9 = 0.0;
    u_xlat1.x = 1.0;
    while(true){
        u_xlatb7 = 4.0<u_xlat1.x;
        if(u_xlatb7){break;}
        u_xlat7.x = u_xlat3.y * u_xlat1.x;
        u_xlat7.x = sin(u_xlat7.x);
        u_xlat7.x = u_xlat7.x / u_xlat1.x;
        u_xlat9 = u_xlat9 + u_xlat7.x;
        u_xlat1.x = u_xlat1.x * 1.70000005;
    }
    u_xlat6 = u_xlat9 * 0.400000006;
    u_xlat1.x = float(0.0);
    u_xlat7.x = float(1.0);
    while(true){
        u_xlatb10 = 4.0<u_xlat7.x;
        if(u_xlatb10){break;}
        u_xlat10 = u_xlat7.x * u_xlat1.y;
        u_xlat10 = sin(u_xlat10);
        u_xlat10 = u_xlat10 / u_xlat7.x;
        u_xlat1.x = u_xlat10 + u_xlat1.x;
        u_xlat7.x = u_xlat7.x * 1.70000005;
    }
    u_xlat4 = u_xlat1.x * 0.400000006;
    u_xlat7.x = u_xlat9 * 0.400000006 + (-u_xlat4);
    u_xlat7.x = abs(u_xlat7.x) * 10.0 + 0.400000006;
    u_xlat7.x = float(1.0) / u_xlat7.x;
    u_xlatb10 = u_xlat6<u_xlat4;
    u_xlatb2 = u_xlat2.w<u_xlat4;
    u_xlatb10 = u_xlatb10 && u_xlatb2;
    u_xlatb2 = u_xlat4<u_xlat6;
    u_xlatb4 = u_xlat4<u_xlat2.w;
    u_xlatb4 = u_xlatb4 && u_xlatb2;
    u_xlatb4 = u_xlatb4 || u_xlatb10;
    u_xlat6 = u_xlat1.x * 0.400000006 + (-u_xlat6);
    u_xlat9 = (-u_xlat9) * 0.400000006 + u_xlat2.w;
    u_xlat6 = float(1.0) / u_xlat6;
    u_xlat6 = u_xlat6 * u_xlat9;
    u_xlat6 = clamp(u_xlat6, 0.0, 1.0);
    u_xlat9 = u_xlat6 * -2.0 + 3.0;
    u_xlat6 = u_xlat6 * u_xlat6;
    u_xlat6 = u_xlat6 * u_xlat9;
    u_xlat6 = u_xlatb4 ? u_xlat6 : float(0.0);
    u_xlat6 = u_xlat6 * u_xlat6;
    u_xlat9 = (-u_xlat1.x) * 0.400000006 + u_xlat2.w;
    u_xlat1.xy = abs(float2(u_xlat9)) * float2(499.999969, 333.333344);
    u_xlat1.xy = min(u_xlat1.xy, float2(1.0, 1.0));
    u_xlat2.xy = u_xlat1.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
    u_xlat1.xy = u_xlat1.xy * u_xlat1.xy;
    u_xlat9 = u_xlat1.x * u_xlat2.x;
    u_xlat6 = u_xlat6 * u_xlat6 + (-u_xlat9);
    u_xlat9 = (-u_xlat2.y) * u_xlat1.y + 1.0;
    u_xlat6 = u_xlat6 + 1.0;
    u_xlat6 = clamp(u_xlat6, 0.0, 1.0);
    u_xlat6 = u_xlat9 + u_xlat6;
    u_xlat6 = u_xlat7.x * u_xlat6;
    u_xlat1 = u_xlat3.xxxx * float4(1.3499999, 0.600000024, 1.3499999, 1.5);
    u_xlat1 = u_xlat0.xxxx * float4(0.600000024, 1.3499999, 1.3499999, 1.5) + u_xlat1;
    u_xlat0 = float4(u_xlat6) * float4(1.3499999, 1.3499999, 0.600000024, 1.5) + u_xlat1;
    u_xlat0 = log2(u_xlat0);
    u_xlat0 = u_xlat0 * float4(1.29999995, 1.29999995, 1.29999995, 1.29999995);
    u_xlat0 = exp2(u_xlat0);
    u_xlat0 = u_xlat0 * float4(0.909090877, 0.909090877, 0.909090877, 0.909090877);
    u_xlat0 = min(u_xlat0, float4(1.0, 1.0, 1.0, 1.0));
    u_xlat1 = u_xlat0 * float4(-2.0, -2.0, -2.0, -2.0) + float4(3.0, 3.0, 3.0, 3.0);
    u_xlat0 = u_xlat0 * u_xlat0;
    __nv_out = u_xlat0 * u_xlat1;
    return __nv_out;
    return __nv_out;
}
