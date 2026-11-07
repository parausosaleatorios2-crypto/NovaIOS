// ---------------------------------------------------------------------------
// Fire (NV)
// origem : assets/effects/nv-nodevideo-assetstore-fire.xml
// id     : nv.effect.nodevideo-assetstore-fire
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_fireParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _center;
    float _ring;
    float4 _color;
    float _blend;
    float _intensity;
    float _distort;
    float _speed;
    float2 _scale;
    float _invert;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
bool u_xlatb6;
float u_xlat7;
float3 u_xlat8;
bool u_xlatb8;
float u_xlat12;
bool u_xlatb12;
float2 u_xlat13;
float2 u_xlat14;
bool u_xlatb14;
float u_xlat15;
float u_xlat18;
bool u_xlatb18;
float u_xlat19;
float u_xlat21;
bool u_xlatb21;

fragment float4 fx_nv_nodevideo_assetstore_fire(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_fireParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.yz = in.acScreenNorm.xy + (-u._center.xy);
    u_xlat18 = _resolution.x / _resolution.y;
    u_xlat0.x = u_xlat18 * u_xlat0.y;
    u_xlat1 = u_xlat0.xzxz * u._scale.xyxy;
    u_xlat0.xy = u_xlat1.xy * float2(4.0, 4.0);
    u_xlat12 = _cur_time * u._speed;
    u_xlat2.xyz = float3(u_xlat12) * float3(1.60000002, 1.70000005, 0.720000029);
    u_xlat1.xy = u_xlat1.zw * float2(2.79999995, 2.79999995) + (-u_xlat2.xx);
    u_xlat2.xw = u_xlat1.xy;
    u_xlat12 = 2.0;
    u_xlat3.x = float(0.0);
    u_xlat15 = float(1.0);
    while(true){
        u_xlatb21 = u_xlat15>=6.0;
        if(u_xlatb21){break;}
        u_xlat4.xy = u_xlat2.xw * float2(0.00999999978, 0.00999999978);
        u_xlat21 = texture0.sample(__nv_smp, u_xlat4.xy).x;
        u_xlat21 = u_xlat21 + -0.5;
        u_xlat21 = u_xlat21 + u_xlat21;
        u_xlat21 = abs(u_xlat21) / u_xlat12;
        u_xlat3.x = u_xlat21 + u_xlat3.x;
        u_xlat12 = u_xlat12 + u_xlat12;
        u_xlat2.xw = u_xlat2.xw + u_xlat2.xw;
        u_xlat15 = u_xlat15 + 1.0;
    }
    u_xlat1.xy = u_xlat1.zw * float2(2.79999995, 2.79999995) + u_xlat2.yy;
    u_xlat13.xy = u_xlat1.xy;
    u_xlat12 = 2.0;
    u_xlat3.y = 0.0;
    u_xlat2.x = 1.0;
    while(true){
        u_xlatb8 = u_xlat2.x>=6.0;
        if(u_xlatb8){break;}
        u_xlat8.xz = u_xlat13.xy * float2(0.00999999978, 0.00999999978);
        u_xlat8.x = texture0.sample(__nv_smp, u_xlat8.xz).x;
        u_xlat8.x = u_xlat8.x + -0.5;
        u_xlat8.x = u_xlat8.x + u_xlat8.x;
        u_xlat8.x = abs(u_xlat8.x) / u_xlat12;
        u_xlat3.y = u_xlat8.x + u_xlat3.y;
        u_xlat12 = u_xlat12 + u_xlat12;
        u_xlat13.xy = u_xlat13.xy + u_xlat13.xy;
        u_xlat2.x = u_xlat2.x + 1.0;
    }
    u_xlat1.xy = u_xlat3.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(0.75999999, 0.75999999) + u_xlat0.xy;
    u_xlat3.x = cos(u_xlat2.z);
    u_xlat2.x = sin(u_xlat2.z);
    u_xlat4.x = (-u_xlat2.x);
    u_xlat4.y = u_xlat3.x;
    u_xlat12 = dot(u_xlat4.yx, u_xlat1.xy);
    u_xlat4.z = u_xlat2.x;
    u_xlat1.x = dot(u_xlat4.zy, u_xlat1.xy);
    u_xlat2.x = u_xlat12;
    u_xlat2.y = u_xlat1.x;
    u_xlat7 = float(2.0);
    u_xlat13.x = float(0.0);
    u_xlat19 = float(1.0);
    while(true){
        u_xlatb14 = u_xlat19>=6.0;
        if(u_xlatb14){break;}
        u_xlat14.xy = u_xlat2.xy * float2(0.00999999978, 0.00999999978);
        u_xlat14.x = texture0.sample(__nv_smp, u_xlat14.xy).x;
        u_xlat14.x = u_xlat14.x + -0.5;
        u_xlat14.x = u_xlat14.x + u_xlat14.x;
        u_xlat14.x = abs(u_xlat14.x) / u_xlat7;
        u_xlat13.x = u_xlat13.x + u_xlat14.x;
        u_xlat7 = u_xlat7 + u_xlat7;
        u_xlat2.xy = u_xlat2.xy + u_xlat2.xy;
        u_xlat19 = u_xlat19 + 1.0;
    }
    u_xlat12 = abs(u._ring);
    u_xlatb1.x = (-u._ring)>=u._ring;
    u_xlat12 = fract(u_xlat12);
    u_xlat12 = (u_xlatb1.x) ? u_xlat12 : (-u_xlat12);
    u_xlat12 = u_xlat12 * 4.53235626;
    u_xlat12 = exp2(u_xlat12);
    u_xlat0.xy = u_xlat0.xy / float2(u_xlat12);
    u_xlat0.x = dot(u_xlat0.xy, u_xlat0.xy);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = sqrt(u_xlat0.x);
    u_xlat0.x = log2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 0.441271186;
    u_xlatb6 = u_xlat0.x>=(-u_xlat0.x);
    u_xlat0.x = fract(abs(u_xlat0.x));
    u_xlat0.x = (u_xlatb6) ? u_xlat0.x : (-u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 6.28318548 + -3.1400001;
    u_xlat0.x = abs(u_xlat0.x) / u._intensity;
    u_xlat0.x = u_xlat0.x + 0.200000003;
    u_xlat0.x = (-u_xlat0.x) + 0.100000001;
    u_xlat0.x = log2(abs(u_xlat0.x));
    u_xlat0.x = u_xlat0.x * 0.899999976;
    u_xlat0.x = exp2(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * u_xlat13.x;
    u_xlat1.x = u_xlat18 * in.acScreenNorm.x;
    u_xlat2.x = u_xlat18 * u._center.x;
    u_xlat2.y = u._center.y;
    u_xlat1.y = in.acScreenNorm.y;
    u_xlat6.xy = u_xlat1.xy + (-u_xlat2.xy);
    u_xlat6.x = dot(u_xlat6.xy, u_xlat6.xy);
    u_xlat6.x = sqrt(u_xlat6.x);
    u_xlatb12 = 1.0<u_xlat6.x;
    u_xlat6.x = u_xlat6.x + -1.0;
    u_xlat6.x = (-u_xlat6.x) * 10.0 + 1.0;
    u_xlat6.x = max(u_xlat6.x, 0.0);
    u_xlat6.x = (u_xlatb12) ? u_xlat6.x : 1.0;
    u_xlat0.xzw = u._color.xyz / u_xlat0.xxx;
    u_xlat0.xyz = u_xlat6.xxx * u_xlat0.xzw;
    u_xlat0.xyz = u_xlat0.xyz * u._color.www;
    u_xlat1.xyw = u_xlat0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyw = u_xlat0.xyz * u_xlat1.xyw + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyw;
    u_xlat18 = u_xlat13.x * u._distort;
    u_xlat18 = u_xlat18 * 0.100000001;
    u_xlat13.x = (-u._blend) + 1.0;
    u_xlat3.xy = float2(u_xlat18) * u_xlat13.xx + in.acScreenNorm.xy;
    u_xlat4 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
    u_xlatb18 = int(u._invert)==1;
    u_xlat0.xyz = (-u_xlat0.xyz) * u_xlat1.xyw + float3(u._blend);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat3.xyz;
    u_xlat1.xyz = u_xlat13.xxx * u_xlat2.xyz;
    u_xlat1.xyz = u_xlat3.xyz * float3(u._blend) + u_xlat1.xyz;
    u_xlat0.xyz = (bool(u_xlatb18)) ? u_xlat0.xyz : u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat0.w = u_xlat4.w;
        u_xlat2 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat3 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat3) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat4 * u_xlat5;
        u_xlat2 = u_xlat2 * u_xlat3 + u_xlat5;
        u_xlat18 = u_xlat3.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat18 : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out.xyz = u_xlat0.xyz;
        __nv_out.w = u_xlat4.w;
    }
    return __nv_out;
    return __nv_out;
}
