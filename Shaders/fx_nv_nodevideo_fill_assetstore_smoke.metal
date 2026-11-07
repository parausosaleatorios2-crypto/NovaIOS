// ---------------------------------------------------------------------------
// Fill Assetstore Smoke (NV)
// origem : assets/effects/nv-nodevideo-fill-assetstore-smoke.xml
// id     : nv.effect.nodevideo-fill-assetstore-smoke
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_fill_assetstore_smokeParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float4 _background_color;
    float4 _smoke_color;
    float _intensity;
    float _complexity;
    float _speed;
    float _invert;
    float _blend_mode;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float2 u_xlat6;
float2 u_xlat7;
float u_xlat8;
float u_xlat9;
float2 u_xlat10;
float2 u_xlat11;
float2 u_xlat13;
float2 u_xlat14;
bool u_xlatb14;
float2 u_xlat15;
bool u_xlatb15;
float2 u_xlat16;
float u_xlat18;
float u_xlat19;
float u_xlat20;
float u_xlat21;

fragment float4 fx_nv_nodevideo_fill_assetstore_smoke(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_fill_assetstore_smokeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = int(u._invert)==1;
    if(u_xlatb0){
        u_xlat0.x = _cur_time * u._speed;
        u_xlat1.x = u_xlat0.x * 0.400000006;
        u_xlat0.x = u_xlat0.x + u_xlat0.x;
        u_xlat0.x = sin(u_xlat0.x);
        u_xlat13.x = u_xlat0.x * 0.100000001;
        u_xlat0.x = u._intensity + 1.0;
        u_xlat1.y = float(0.0);
        u_xlat13.y = float(0.0);
        u_xlat6.xy = u_xlat1.xy + in.acScreenNorm.xy;
        u_xlat1.xy = (-u_xlat13.xy) + in.acScreenNorm.xy;
        u_xlat13.xy = u_xlat1.xy;
        u_xlat18 = 0.5;
        u_xlat2.x = float(0.0);
        u_xlat8 = float(0.0);
        while(true){
            u_xlatb14 = u_xlat8>=u._complexity;
            if(u_xlatb14){break;}
            u_xlat3.xy = floor(u_xlat13.xy);
            u_xlat14.xy = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat4.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.x = fract(u_xlat4.x);
            u_xlat3.zw = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat9 = dot(u_xlat3.zy, float2(12.9898005, 78.2330017));
            u_xlat9 = cos(u_xlat9);
            u_xlat3.y = u_xlat9 * 43758.5469;
            u_xlat3.x = dot(u_xlat3.xw, float2(12.9898005, 78.2330017));
            u_xlat3.x = cos(u_xlat3.x);
            u_xlat3.x = u_xlat3.x * 43758.5469;
            u_xlat3.xy = fract(u_xlat3.xy);
            u_xlat14.x = dot(u_xlat14.xy, float2(12.9898005, 78.2330017));
            u_xlat14.x = cos(u_xlat14.x);
            u_xlat14.x = u_xlat14.x * 43758.5469;
            u_xlat14.x = fract(u_xlat14.x);
            u_xlat15.xy = fract(u_xlat13.xy);
            u_xlat10.xy = u_xlat15.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat15.xy = u_xlat15.xy * u_xlat15.xy;
            u_xlat15.xy = u_xlat15.xy * u_xlat10.xy;
            u_xlat20 = (-u_xlat4.x) + u_xlat3.y;
            u_xlat20 = u_xlat15.x * u_xlat20 + u_xlat4.x;
            u_xlat14.x = (-u_xlat3.x) + u_xlat14.x;
            u_xlat14.x = u_xlat15.x * u_xlat14.x + u_xlat3.x;
            u_xlat14.x = (-u_xlat20) + u_xlat14.x;
            u_xlat14.x = u_xlat15.y * u_xlat14.x + u_xlat20;
            u_xlat2.x = u_xlat18 * u_xlat14.x + u_xlat2.x;
            u_xlat18 = u_xlat18 * 0.5;
            u_xlat13.xy = u_xlat13.xy + u_xlat13.xy;
            u_xlat8 = u_xlat8 + 1.0;
        }
        u_xlat1.xy = u_xlat2.xx * float2(2.0, 2.0) + in.acScreenNorm.xy;
        u_xlat13.xy = u_xlat1.xy;
        u_xlat18 = 0.5;
        u_xlat2.x = float(0.0);
        u_xlat8 = float(0.0);
        while(true){
            u_xlatb14 = u_xlat8>=u._complexity;
            if(u_xlatb14){break;}
            u_xlat3.xy = floor(u_xlat13.xy);
            u_xlat14.xy = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat4.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.x = fract(u_xlat4.x);
            u_xlat3.zw = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat9 = dot(u_xlat3.zy, float2(12.9898005, 78.2330017));
            u_xlat9 = cos(u_xlat9);
            u_xlat3.y = u_xlat9 * 43758.5469;
            u_xlat3.x = dot(u_xlat3.xw, float2(12.9898005, 78.2330017));
            u_xlat3.x = cos(u_xlat3.x);
            u_xlat3.x = u_xlat3.x * 43758.5469;
            u_xlat3.xy = fract(u_xlat3.xy);
            u_xlat14.x = dot(u_xlat14.xy, float2(12.9898005, 78.2330017));
            u_xlat14.x = cos(u_xlat14.x);
            u_xlat14.x = u_xlat14.x * 43758.5469;
            u_xlat14.x = fract(u_xlat14.x);
            u_xlat15.xy = fract(u_xlat13.xy);
            u_xlat10.xy = u_xlat15.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat15.xy = u_xlat15.xy * u_xlat15.xy;
            u_xlat15.xy = u_xlat15.xy * u_xlat10.xy;
            u_xlat20 = (-u_xlat4.x) + u_xlat3.y;
            u_xlat20 = u_xlat15.x * u_xlat20 + u_xlat4.x;
            u_xlat14.x = (-u_xlat3.x) + u_xlat14.x;
            u_xlat14.x = u_xlat15.x * u_xlat14.x + u_xlat3.x;
            u_xlat14.x = (-u_xlat20) + u_xlat14.x;
            u_xlat14.x = u_xlat15.y * u_xlat14.x + u_xlat20;
            u_xlat2.x = u_xlat18 * u_xlat14.x + u_xlat2.x;
            u_xlat18 = u_xlat18 * 0.5;
            u_xlat13.xy = u_xlat13.xy + u_xlat13.xy;
            u_xlat8 = u_xlat8 + 1.0;
        }
        u_xlat1.xy = u_xlat2.xx + in.acScreenNorm.xy;
        u_xlat13.xy = u_xlat1.xy;
        u_xlat18 = 0.5;
        u_xlat2.x = float(0.0);
        u_xlat8 = float(0.0);
        while(true){
            u_xlatb14 = u_xlat8>=u._complexity;
            if(u_xlatb14){break;}
            u_xlat3.xy = floor(u_xlat13.xy);
            u_xlat14.xy = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat4.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.x = fract(u_xlat4.x);
            u_xlat3.zw = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat9 = dot(u_xlat3.zy, float2(12.9898005, 78.2330017));
            u_xlat9 = cos(u_xlat9);
            u_xlat3.y = u_xlat9 * 43758.5469;
            u_xlat3.x = dot(u_xlat3.xw, float2(12.9898005, 78.2330017));
            u_xlat3.x = cos(u_xlat3.x);
            u_xlat3.x = u_xlat3.x * 43758.5469;
            u_xlat3.xy = fract(u_xlat3.xy);
            u_xlat14.x = dot(u_xlat14.xy, float2(12.9898005, 78.2330017));
            u_xlat14.x = cos(u_xlat14.x);
            u_xlat14.x = u_xlat14.x * 43758.5469;
            u_xlat14.x = fract(u_xlat14.x);
            u_xlat15.xy = fract(u_xlat13.xy);
            u_xlat10.xy = u_xlat15.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat15.xy = u_xlat15.xy * u_xlat15.xy;
            u_xlat15.xy = u_xlat15.xy * u_xlat10.xy;
            u_xlat20 = (-u_xlat4.x) + u_xlat3.y;
            u_xlat20 = u_xlat15.x * u_xlat20 + u_xlat4.x;
            u_xlat14.x = (-u_xlat3.x) + u_xlat14.x;
            u_xlat14.x = u_xlat15.x * u_xlat14.x + u_xlat3.x;
            u_xlat14.x = (-u_xlat20) + u_xlat14.x;
            u_xlat14.x = u_xlat15.y * u_xlat14.x + u_xlat20;
            u_xlat2.x = u_xlat18 * u_xlat14.x + u_xlat2.x;
            u_xlat18 = u_xlat18 * 0.5;
            u_xlat13.xy = u_xlat13.xy + u_xlat13.xy;
            u_xlat8 = u_xlat8 + 1.0;
        }
        u_xlat6.xy = u_xlat6.xy + u_xlat2.xx;
        u_xlat1.xy = u_xlat6.xy;
        u_xlat18 = 0.5;
        u_xlat13.x = float(0.0);
        u_xlat19 = float(0.0);
        while(true){
            u_xlatb2.x = u_xlat19>=u._complexity;
            if(u_xlatb2.x){break;}
            u_xlat2.xy = floor(u_xlat1.xy);
            u_xlat3.xy = u_xlat2.xy + float2(1.0, 1.0);
            u_xlat15.x = dot(u_xlat2.xy, float2(12.9898005, 78.2330017));
            u_xlat15.x = cos(u_xlat15.x);
            u_xlat15.x = u_xlat15.x * 43758.5469;
            u_xlat15.x = fract(u_xlat15.x);
            u_xlat2.zw = u_xlat2.xy + float2(1.0, 1.0);
            u_xlat8 = dot(u_xlat2.zy, float2(12.9898005, 78.2330017));
            u_xlat8 = cos(u_xlat8);
            u_xlat2.y = u_xlat8 * 43758.5469;
            u_xlat2.x = dot(u_xlat2.xw, float2(12.9898005, 78.2330017));
            u_xlat2.x = cos(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 43758.5469;
            u_xlat14.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
            u_xlat14.x = cos(u_xlat14.x);
            u_xlat2.z = u_xlat14.x * 43758.5469;
            u_xlat2.xyz = fract(u_xlat2.xyz);
            u_xlat3.xy = fract(u_xlat1.xy);
            u_xlat4.xy = u_xlat3.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat3.xy = u_xlat3.xy * u_xlat3.xy;
            u_xlat3.xy = u_xlat3.xy * u_xlat4.xy;
            u_xlat8 = (-u_xlat15.x) + u_xlat2.y;
            u_xlat8 = u_xlat3.x * u_xlat8 + u_xlat15.x;
            u_xlat14.x = (-u_xlat2.x) + u_xlat2.z;
            u_xlat2.x = u_xlat3.x * u_xlat14.x + u_xlat2.x;
            u_xlat2.x = (-u_xlat8) + u_xlat2.x;
            u_xlat2.x = u_xlat3.y * u_xlat2.x + u_xlat8;
            u_xlat13.x = u_xlat18 * u_xlat2.x + u_xlat13.x;
            u_xlat18 = u_xlat18 * 0.5;
            u_xlat1.xy = u_xlat1.xy + u_xlat1.xy;
            u_xlat19 = u_xlat19 + 1.0;
        }
        u_xlat0.x = u_xlat0.x * u_xlat13.x;
        u_xlat1 = u._background_color + (-u._smoke_color);
        u_xlat0 = u_xlat0.xxxx * u_xlat1 + u._smoke_color;
    } else {
        u_xlat1.x = _cur_time * u._speed;
        u_xlat2.x = u_xlat1.x * 0.400000006;
        u_xlat1.x = u_xlat1.x + u_xlat1.x;
        u_xlat1.x = sin(u_xlat1.x);
        u_xlat14.x = u_xlat1.x * 0.100000001;
        u_xlat1.x = u._intensity + 1.0;
        u_xlat2.y = float(0.0);
        u_xlat14.y = float(0.0);
        u_xlat7.xy = u_xlat2.xy + in.acScreenNorm.xy;
        u_xlat2.xy = (-u_xlat14.xy) + in.acScreenNorm.xy;
        u_xlat14.xy = u_xlat2.xy;
        u_xlat19 = 0.5;
        u_xlat3.x = float(0.0);
        u_xlat9 = float(0.0);
        while(true){
            u_xlatb15 = u_xlat9>=u._complexity;
            if(u_xlatb15){break;}
            u_xlat4.xy = floor(u_xlat14.xy);
            u_xlat15.xy = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat5.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat5.x = cos(u_xlat5.x);
            u_xlat5.x = u_xlat5.x * 43758.5469;
            u_xlat5.x = fract(u_xlat5.x);
            u_xlat4.zw = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat10.x = dot(u_xlat4.zy, float2(12.9898005, 78.2330017));
            u_xlat10.x = cos(u_xlat10.x);
            u_xlat4.y = u_xlat10.x * 43758.5469;
            u_xlat4.x = dot(u_xlat4.xw, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.xy = fract(u_xlat4.xy);
            u_xlat15.x = dot(u_xlat15.xy, float2(12.9898005, 78.2330017));
            u_xlat15.x = cos(u_xlat15.x);
            u_xlat15.x = u_xlat15.x * 43758.5469;
            u_xlat15.x = fract(u_xlat15.x);
            u_xlat16.xy = fract(u_xlat14.xy);
            u_xlat11.xy = u_xlat16.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat16.xy = u_xlat16.xy * u_xlat16.xy;
            u_xlat16.xy = u_xlat16.xy * u_xlat11.xy;
            u_xlat21 = (-u_xlat5.x) + u_xlat4.y;
            u_xlat21 = u_xlat16.x * u_xlat21 + u_xlat5.x;
            u_xlat15.x = (-u_xlat4.x) + u_xlat15.x;
            u_xlat15.x = u_xlat16.x * u_xlat15.x + u_xlat4.x;
            u_xlat15.x = (-u_xlat21) + u_xlat15.x;
            u_xlat15.x = u_xlat16.y * u_xlat15.x + u_xlat21;
            u_xlat3.x = u_xlat19 * u_xlat15.x + u_xlat3.x;
            u_xlat19 = u_xlat19 * 0.5;
            u_xlat14.xy = u_xlat14.xy + u_xlat14.xy;
            u_xlat9 = u_xlat9 + 1.0;
        }
        u_xlat2.xy = u_xlat3.xx * float2(2.0, 2.0) + in.acScreenNorm.xy;
        u_xlat14.xy = u_xlat2.xy;
        u_xlat19 = 0.5;
        u_xlat3.x = float(0.0);
        u_xlat9 = float(0.0);
        while(true){
            u_xlatb15 = u_xlat9>=u._complexity;
            if(u_xlatb15){break;}
            u_xlat4.xy = floor(u_xlat14.xy);
            u_xlat15.xy = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat5.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat5.x = cos(u_xlat5.x);
            u_xlat5.x = u_xlat5.x * 43758.5469;
            u_xlat5.x = fract(u_xlat5.x);
            u_xlat4.zw = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat10.x = dot(u_xlat4.zy, float2(12.9898005, 78.2330017));
            u_xlat10.x = cos(u_xlat10.x);
            u_xlat4.y = u_xlat10.x * 43758.5469;
            u_xlat4.x = dot(u_xlat4.xw, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.xy = fract(u_xlat4.xy);
            u_xlat15.x = dot(u_xlat15.xy, float2(12.9898005, 78.2330017));
            u_xlat15.x = cos(u_xlat15.x);
            u_xlat15.x = u_xlat15.x * 43758.5469;
            u_xlat15.x = fract(u_xlat15.x);
            u_xlat16.xy = fract(u_xlat14.xy);
            u_xlat11.xy = u_xlat16.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat16.xy = u_xlat16.xy * u_xlat16.xy;
            u_xlat16.xy = u_xlat16.xy * u_xlat11.xy;
            u_xlat21 = (-u_xlat5.x) + u_xlat4.y;
            u_xlat21 = u_xlat16.x * u_xlat21 + u_xlat5.x;
            u_xlat15.x = (-u_xlat4.x) + u_xlat15.x;
            u_xlat15.x = u_xlat16.x * u_xlat15.x + u_xlat4.x;
            u_xlat15.x = (-u_xlat21) + u_xlat15.x;
            u_xlat15.x = u_xlat16.y * u_xlat15.x + u_xlat21;
            u_xlat3.x = u_xlat19 * u_xlat15.x + u_xlat3.x;
            u_xlat19 = u_xlat19 * 0.5;
            u_xlat14.xy = u_xlat14.xy + u_xlat14.xy;
            u_xlat9 = u_xlat9 + 1.0;
        }
        u_xlat2.xy = u_xlat3.xx + in.acScreenNorm.xy;
        u_xlat14.xy = u_xlat2.xy;
        u_xlat19 = 0.5;
        u_xlat3.x = float(0.0);
        u_xlat9 = float(0.0);
        while(true){
            u_xlatb15 = u_xlat9>=u._complexity;
            if(u_xlatb15){break;}
            u_xlat4.xy = floor(u_xlat14.xy);
            u_xlat15.xy = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat5.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat5.x = cos(u_xlat5.x);
            u_xlat5.x = u_xlat5.x * 43758.5469;
            u_xlat5.x = fract(u_xlat5.x);
            u_xlat4.zw = u_xlat4.xy + float2(1.0, 1.0);
            u_xlat10.x = dot(u_xlat4.zy, float2(12.9898005, 78.2330017));
            u_xlat10.x = cos(u_xlat10.x);
            u_xlat4.y = u_xlat10.x * 43758.5469;
            u_xlat4.x = dot(u_xlat4.xw, float2(12.9898005, 78.2330017));
            u_xlat4.x = cos(u_xlat4.x);
            u_xlat4.x = u_xlat4.x * 43758.5469;
            u_xlat4.xy = fract(u_xlat4.xy);
            u_xlat15.x = dot(u_xlat15.xy, float2(12.9898005, 78.2330017));
            u_xlat15.x = cos(u_xlat15.x);
            u_xlat15.x = u_xlat15.x * 43758.5469;
            u_xlat15.x = fract(u_xlat15.x);
            u_xlat16.xy = fract(u_xlat14.xy);
            u_xlat11.xy = u_xlat16.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat16.xy = u_xlat16.xy * u_xlat16.xy;
            u_xlat16.xy = u_xlat16.xy * u_xlat11.xy;
            u_xlat21 = (-u_xlat5.x) + u_xlat4.y;
            u_xlat21 = u_xlat16.x * u_xlat21 + u_xlat5.x;
            u_xlat15.x = (-u_xlat4.x) + u_xlat15.x;
            u_xlat15.x = u_xlat16.x * u_xlat15.x + u_xlat4.x;
            u_xlat15.x = (-u_xlat21) + u_xlat15.x;
            u_xlat15.x = u_xlat16.y * u_xlat15.x + u_xlat21;
            u_xlat3.x = u_xlat19 * u_xlat15.x + u_xlat3.x;
            u_xlat19 = u_xlat19 * 0.5;
            u_xlat14.xy = u_xlat14.xy + u_xlat14.xy;
            u_xlat9 = u_xlat9 + 1.0;
        }
        u_xlat7.xy = u_xlat7.xy + u_xlat3.xx;
        u_xlat2.xy = u_xlat7.xy;
        u_xlat19 = 0.5;
        u_xlat14.x = float(0.0);
        u_xlat20 = float(0.0);
        while(true){
            u_xlatb3 = u_xlat20>=u._complexity;
            if(u_xlatb3){break;}
            u_xlat3.xy = floor(u_xlat2.xy);
            u_xlat4.xy = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat16.x = dot(u_xlat3.xy, float2(12.9898005, 78.2330017));
            u_xlat16.x = cos(u_xlat16.x);
            u_xlat16.x = u_xlat16.x * 43758.5469;
            u_xlat16.x = fract(u_xlat16.x);
            u_xlat3.zw = u_xlat3.xy + float2(1.0, 1.0);
            u_xlat9 = dot(u_xlat3.zy, float2(12.9898005, 78.2330017));
            u_xlat9 = cos(u_xlat9);
            u_xlat3.y = u_xlat9 * 43758.5469;
            u_xlat3.x = dot(u_xlat3.xw, float2(12.9898005, 78.2330017));
            u_xlat3.x = cos(u_xlat3.x);
            u_xlat3.x = u_xlat3.x * 43758.5469;
            u_xlat15.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat15.x = cos(u_xlat15.x);
            u_xlat3.z = u_xlat15.x * 43758.5469;
            u_xlat3.xyz = fract(u_xlat3.xyz);
            u_xlat4.xy = fract(u_xlat2.xy);
            u_xlat5.xy = u_xlat4.xy * float2(-2.0, -2.0) + float2(3.0, 3.0);
            u_xlat4.xy = u_xlat4.xy * u_xlat4.xy;
            u_xlat4.xy = u_xlat4.xy * u_xlat5.xy;
            u_xlat9 = (-u_xlat16.x) + u_xlat3.y;
            u_xlat9 = u_xlat4.x * u_xlat9 + u_xlat16.x;
            u_xlat15.x = (-u_xlat3.x) + u_xlat3.z;
            u_xlat3.x = u_xlat4.x * u_xlat15.x + u_xlat3.x;
            u_xlat3.x = (-u_xlat9) + u_xlat3.x;
            u_xlat3.x = u_xlat4.y * u_xlat3.x + u_xlat9;
            u_xlat14.x = u_xlat19 * u_xlat3.x + u_xlat14.x;
            u_xlat19 = u_xlat19 * 0.5;
            u_xlat2.xy = u_xlat2.xy + u_xlat2.xy;
            u_xlat20 = u_xlat20 + 1.0;
        }
        u_xlat1.x = u_xlat1.x * u_xlat14.x;
        u_xlat2 = (-u._background_color) + u._smoke_color;
        u_xlat0 = u_xlat1.xxxx * u_xlat2 + u._background_color;
    }
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb2.x = int(u._blend_mode)==1;
    u_xlat3 = u_xlat0 * u_xlat1;
    u_xlat4.xyz = u_xlat0.xyz + u_xlat1.xyz;
    u_xlat4.w = u_xlat1.w;
    u_xlat2 = (u_xlatb2.x) ? u_xlat3 : u_xlat4;
    u_xlat3.xyz = u_xlat0.xyz;
    u_xlat0 = (int(u._blend_mode) != 0) ? u_xlat2 : u_xlat3;
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
