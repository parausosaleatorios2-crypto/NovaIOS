// ---------------------------------------------------------------------------
// Water Reflection (NV)
// origem : assets/effects/nv-nodevideo-assetstore-water-reflection.xml
// id     : nv.effect.nodevideo-assetstore-water-reflection
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_water_reflectionParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _complexity;
    float _speed;
    float _phase;
    float _strength;
    float _scale;
    float _light_intensity;
    float2 _light_pos;
    float _random_speed;
    float _scattering;
    float _horizontal_line;
    float _feather;
    float _spread;
    float _perspective;
    float4 _color;
    float _enable_light;
    float _fade;
    float _direction;
    float _mirror;
    float4 _light_color;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
bool u_xlatb0;
float u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool u_xlatb5;
float4 u_xlat6;
float u_xlat7;
bool u_xlatb7;
bool u_xlatb8;
float2 u_xlat10;
bool2 u_xlatb10;
float3 u_xlat11;
bool2 u_xlatb11;
float u_xlat12;
float u_xlat13;
float u_xlat14;
float u_xlat15;
float u_xlat16;
bool u_xlatb16;
float2 u_xlat17;
float u_xlat18;
float u_xlat19;
float2 u_xlat20;
float u_xlat21;
float u_xlat22;
float u_xlat23;
bool u_xlatb23;
float u_xlat24;
bool u_xlatb24;
float u_xlat25;
float u_xlat26;
float u_xlat27;

fragment float4 fx_nv_nodevideo_assetstore_water_reflection(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_water_reflectionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = float4(1.0, 1.0, 1.0, 1.0) / _resolution.xyyx;
    u_xlat1 = u._scale * 10.0;
    u_xlatb8 = u._horizontal_line<in.acScreenNorm.y;
    if(u_xlatb8){
        u_xlat2.x = in.acScreenNorm.y;
        u_xlat15 = float(0.0);
        u_xlat22 = float(0.0);
        u_xlat16 = u._speed;
    } else {
        u_xlat23 = u._light_intensity * 0.5;
        u_xlat3.x = (-in.acScreenNorm.y) + u._horizontal_line;
        u_xlat10.x = log2(u_xlat3.x);
        u_xlat10.x = u_xlat10.x * u._fade;
        u_xlat10.x = exp2(u_xlat10.x);
        u_xlat22 = u_xlat23 * u_xlat10.x;
        u_xlat23 = (-u_xlat3.x) + 1.0;
        u_xlat10.x = log2(u_xlat23);
        u_xlat10.x = u_xlat10.x * u._spread;
        u_xlat10.x = exp2(u_xlat10.x);
        u_xlat10.x = u_xlat10.x * u._strength;
        u_xlat17.xy = float2(u_xlat23) * float2(1.20000005, 0.833333313);
        u_xlat17.xy = log2(u_xlat17.xy);
        u_xlat17.xy = u_xlat17.xy * float2(u._spread);
        u_xlat17.xy = exp2(u_xlat17.xy);
        u_xlat16 = u_xlat17.x * u._speed;
        u_xlat23 = in.acScreenNorm.x + -0.5;
        u_xlat23 = -abs(u_xlat23) * 2.0 + 1.0;
        u_xlat23 = log2(u_xlat23);
        u_xlat23 = u_xlat23 * u._spread;
        u_xlat23 = exp2(u_xlat23);
        u_xlat15 = u_xlat23 * u_xlat10.x;
        u_xlat1 = u_xlat1 * u_xlat17.y;
        u_xlatb23 = 0<int(u._mirror);
        u_xlat3.x = u_xlat3.x + u._horizontal_line;
        u_xlat2.x = (u_xlatb23) ? u_xlat3.x : in.acScreenNorm.y;
    }
    u_xlat23 = u._direction * 0.0174532942;
    u_xlat3.x = sin((-u_xlat23));
    u_xlat23 = cos(u_xlat23);
    u_xlat10.x = (-u_xlat16) * u_xlat3.x;
    u_xlat10.y = (-u_xlat16) * u_xlat23;
    u_xlat4 = (-u_xlat0.wzzw) + in.acScreenNorm.xyxy;
    u_xlat4 = float4(u_xlat1) * u_xlat4;
    u_xlat16 = dot(u_xlat10.xy, u_xlat10.xy);
    u_xlat23 = sqrt(u_xlat16);
    u_xlat3.x = float(int(u._complexity));
    u_xlatb24 = 9.99999975e-06<u_xlat23;
    u_xlat5.xy = u_xlat10.xy / float2(u_xlat23);
    u_xlat5.xy = bool(u_xlatb24) ? u_xlat5.xy : float2(0.0, 0.0);
    u_xlat24 = u_xlat3.x + -1.0;
    u_xlat24 = max(u_xlat24, 1.0);
    u_xlat4.x = dot((-u_xlat5.xy), u_xlat4.xy);
    u_xlat19 = float(0.0);
    u_xlat26 = float(0.0);
    while(true){
        u_xlatb11.x = u_xlat26>=u_xlat3.x;
        if(u_xlatb11.x){break;}
        u_xlat6.xy = float2(u_xlat26) * float2(1.1375035, 0.137844697);
        u_xlat11.x = exp2(u_xlat6.x);
        u_xlat11.x = float(1.0) / u_xlat11.x;
        u_xlat6.x = exp2(u_xlat26);
        u_xlat6.x = 314.159271 / u_xlat6.x;
        u_xlat13 = fract(u_xlat6.y);
        u_xlat20.x = u_xlat13 + 19.1900005;
        u_xlat20.x = dot(float3(u_xlat13), u_xlat20.xxx);
        u_xlat13 = u_xlat20.x + u_xlat13;
        u_xlat20.x = u_xlat13 + u_xlat13;
        u_xlat13 = u_xlat13 * u_xlat20.x;
        u_xlat13 = fract(u_xlat13);
        u_xlat20.x = u_xlat13 * 0.100000001 + 0.75;
        u_xlat6.x = u_xlat20.x * u_xlat6.x;
        u_xlat20.x = u_xlat26 / u_xlat24;
        u_xlat20.x = u_xlat20.x * -1.5 + 2.0;
        u_xlat20.x = u_xlat20.x + u_xlat20.x;
        u_xlat27 = u_xlat13 + 0.5;
        u_xlat20.x = u_xlat27 * u_xlat20.x;
        u_xlat20.x = u_xlat23 * u_xlat20.x;
        u_xlat6.x = 6.28318548 / u_xlat6.x;
        u_xlat13 = u_xlat13 * u._random_speed;
        u_xlat13 = u_xlat13 * 6.28318548;
        u_xlat13 = u_xlat20.x * u_xlat6.x + u_xlat13;
        u_xlat13 = u_xlat13 * _cur_time;
        u_xlat6.x = u_xlat4.x * u_xlat6.x + u_xlat13;
        u_xlat6.x = sin(u_xlat6.x);
        u_xlat19 = u_xlat11.x * u_xlat6.x + u_xlat19;
        u_xlat26 = u_xlat26 + 1.0;
    }
    u_xlat6 = u_xlat0 + in.acScreenNorm.xyxy;
    u_xlat6 = float4(u_xlat1) * u_xlat6;
    u_xlat0.x = dot((-u_xlat5.xy), u_xlat6.xy);
    u_xlat7 = float(0.0);
    u_xlat14 = float(0.0);
    while(true){
        u_xlatb1.x = u_xlat14>=u_xlat3.x;
        if(u_xlatb1.x){break;}
        u_xlat6.xy = float2(u_xlat14) * float2(1.1375035, 0.137844697);
        u_xlat1 = exp2(u_xlat6.x);
        u_xlat1 = float(1.0) / u_xlat1;
        u_xlat11.x = exp2(u_xlat14);
        u_xlat11.x = 314.159271 / u_xlat11.x;
        u_xlat26 = fract(u_xlat6.y);
        u_xlat6.x = u_xlat26 + 19.1900005;
        u_xlat6.x = dot(float3(u_xlat26), u_xlat6.xxx);
        u_xlat26 = u_xlat26 + u_xlat6.x;
        u_xlat6.x = u_xlat26 + u_xlat26;
        u_xlat26 = u_xlat26 * u_xlat6.x;
        u_xlat26 = fract(u_xlat26);
        u_xlat6.x = u_xlat26 * 0.100000001 + 0.75;
        u_xlat11.x = u_xlat11.x * u_xlat6.x;
        u_xlat6.x = u_xlat14 / u_xlat24;
        u_xlat6.x = u_xlat6.x * -1.5 + 2.0;
        u_xlat6.x = u_xlat6.x + u_xlat6.x;
        u_xlat13 = u_xlat26 + 0.5;
        u_xlat6.x = u_xlat13 * u_xlat6.x;
        u_xlat6.x = u_xlat23 * u_xlat6.x;
        u_xlat11.x = 6.28318548 / u_xlat11.x;
        u_xlat26 = u_xlat26 * u._random_speed;
        u_xlat26 = u_xlat26 * 6.28318548;
        u_xlat26 = u_xlat6.x * u_xlat11.x + u_xlat26;
        u_xlat26 = u_xlat26 * _cur_time;
        u_xlat11.x = u_xlat0.x * u_xlat11.x + u_xlat26;
        u_xlat11.x = sin(u_xlat11.x);
        u_xlat7 = u_xlat1 * u_xlat11.x + u_xlat7;
        u_xlat14 = u_xlat14 + 1.0;
    }
    u_xlat14 = dot((-u_xlat5.xy), u_xlat4.zw);
    u_xlat11.x = float(0.0);
    u_xlat18 = float(0.0);
    while(true){
        u_xlatb1.x = u_xlat18>=u_xlat3.x;
        if(u_xlatb1.x){break;}
        u_xlat6.xy = float2(u_xlat18) * float2(1.1375035, 0.137844697);
        u_xlat1 = exp2(u_xlat6.x);
        u_xlat1 = float(1.0) / u_xlat1;
        u_xlat25 = exp2(u_xlat18);
        u_xlat25 = 314.159271 / u_xlat25;
        u_xlat26 = fract(u_xlat6.y);
        u_xlat6.x = u_xlat26 + 19.1900005;
        u_xlat6.x = dot(float3(u_xlat26), u_xlat6.xxx);
        u_xlat26 = u_xlat26 + u_xlat6.x;
        u_xlat6.x = u_xlat26 + u_xlat26;
        u_xlat26 = u_xlat26 * u_xlat6.x;
        u_xlat26 = fract(u_xlat26);
        u_xlat6.x = u_xlat26 * 0.100000001 + 0.75;
        u_xlat25 = u_xlat25 * u_xlat6.x;
        u_xlat6.x = u_xlat18 / u_xlat24;
        u_xlat6.x = u_xlat6.x * -1.5 + 2.0;
        u_xlat6.x = u_xlat6.x + u_xlat6.x;
        u_xlat13 = u_xlat26 + 0.5;
        u_xlat6.x = u_xlat13 * u_xlat6.x;
        u_xlat6.x = u_xlat23 * u_xlat6.x;
        u_xlat25 = 6.28318548 / u_xlat25;
        u_xlat26 = u_xlat26 * u._random_speed;
        u_xlat26 = u_xlat26 * 6.28318548;
        u_xlat26 = u_xlat6.x * u_xlat25 + u_xlat26;
        u_xlat26 = u_xlat26 * _cur_time;
        u_xlat25 = u_xlat14 * u_xlat25 + u_xlat26;
        u_xlat25 = sin(u_xlat25);
        u_xlat11.x = u_xlat1 * u_xlat25 + u_xlat11.x;
        u_xlat18 = u_xlat18 + 1.0;
    }
    u_xlat1 = dot((-u_xlat5.xy), u_xlat6.zw);
    u_xlat18 = float(0.0);
    u_xlat25 = float(0.0);
    while(true){
        u_xlatb5 = u_xlat25>=u_xlat3.x;
        if(u_xlatb5){break;}
        u_xlat5.xy = float2(u_xlat25) * float2(1.1375035, 0.137844697);
        u_xlat5.x = exp2(u_xlat5.x);
        u_xlat5.x = float(1.0) / u_xlat5.x;
        u_xlat26 = exp2(u_xlat25);
        u_xlat26 = 314.159271 / u_xlat26;
        u_xlat12 = fract(u_xlat5.y);
        u_xlat6.x = u_xlat12 + 19.1900005;
        u_xlat6.x = dot(float3(u_xlat12), u_xlat6.xxx);
        u_xlat12 = u_xlat12 + u_xlat6.x;
        u_xlat6.x = u_xlat12 + u_xlat12;
        u_xlat12 = u_xlat12 * u_xlat6.x;
        u_xlat12 = fract(u_xlat12);
        u_xlat6.x = u_xlat12 * 0.100000001 + 0.75;
        u_xlat26 = u_xlat26 * u_xlat6.x;
        u_xlat6.x = u_xlat25 / u_xlat24;
        u_xlat6.x = u_xlat6.x * -1.5 + 2.0;
        u_xlat6.x = u_xlat6.x + u_xlat6.x;
        u_xlat13 = u_xlat12 + 0.5;
        u_xlat6.x = u_xlat13 * u_xlat6.x;
        u_xlat6.x = u_xlat23 * u_xlat6.x;
        u_xlat26 = 6.28318548 / u_xlat26;
        u_xlat12 = u_xlat12 * u._random_speed;
        u_xlat12 = u_xlat12 * 6.28318548;
        u_xlat12 = u_xlat6.x * u_xlat26 + u_xlat12;
        u_xlat12 = u_xlat12 * _cur_time;
        u_xlat12 = u_xlat1 * u_xlat26 + u_xlat12;
        u_xlat12 = sin(u_xlat12);
        u_xlat18 = u_xlat5.x * u_xlat12 + u_xlat18;
        u_xlat25 = u_xlat25 + 1.0;
    }
    u_xlat5.y = (-u_xlat19) + u_xlat7;
    u_xlat5.w = 0.5;
    u_xlat5.x = u._phase;
    u_xlat7 = dot(u_xlat5.xyw, u_xlat5.xyw);
    u_xlat7 = rsqrt(u_xlat7);
    u_xlat6.xyz = float3(u_xlat7) * u_xlat5.wxy;
    u_xlat5.z = (-u_xlat11.x) + u_xlat18;
    u_xlat7 = dot(u_xlat5.xzw, u_xlat5.xzw);
    u_xlat7 = rsqrt(u_xlat7);
    u_xlat5.y = u_xlat6.z;
    u_xlat11.xyz = float3(u_xlat7) * u_xlat5.xyz;
    u_xlat6.w = 0.5;
    u_xlat5.xy = u_xlat11.yz * u_xlat6.wx;
    u_xlat11.xy = u_xlat6.yz * u_xlat11.zx + (-u_xlat5.xy);
    u_xlat5.xy = float2(u_xlat15) * u_xlat11.xy;
    u_xlat7 = rsqrt(u_xlat16);
    u_xlat10.xy = float2(u_xlat7) * u_xlat10.xy;
    u_xlat5.z = u_xlat5.y * 10.0;
    u_xlat2.y = in.acScreenNorm.x;
    u_xlat2.xy = u_xlat5.xz * u_xlat10.xy + u_xlat2.yx;
    u_xlat2.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat2.xy = u_xlat2.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb10.xy = lessThan(u_xlat2.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb11.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat2.xyxx).xy;
    u_xlat5.xy = fract(u_xlat2.xy);
    u_xlat5.xy = (-u_xlat5.xy) + float2(1.0, 1.0);
    u_xlat11.x = (u_xlatb11.x) ? u_xlat5.x : u_xlat2.x;
    u_xlat11.y = (u_xlatb11.y) ? u_xlat5.y : u_xlat2.y;
    {
        float4 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb10.x) ? (-u_xlat2.x) : u_xlat11.x;
        hlslcc_movcTemp.y = (u_xlatb10.y) ? (-u_xlat2.y) : u_xlat11.y;
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.xy = u_xlat2.xy + float2(-0.5, -0.5);
    u_xlat2.yz = u_xlat2.xy * float2(0.990099013, 0.990099013);
    u_xlatb7 = u._horizontal_line>=in.acScreenNorm.y;
    u_xlat15 = (-in.acScreenNorm.y) + u._horizontal_line;
    u_xlat10.x = u_xlat15 * u._perspective + 1.0;
    u_xlat2.x = u_xlat2.y / u_xlat10.x;
    u_xlat5 = u_xlat2.yzxz + float4(0.5, 0.5, 0.5, 0.5);
    u_xlat2.xy = (bool(u_xlatb7)) ? u_xlat5.zw : u_xlat5.xy;
    u_xlatb7 = 0<int(u._enable_light);
    if(u_xlatb7){
        u_xlat7 = u._scattering * 0.100000001;
        u_xlat7 = -9.99999975e-05 / u_xlat7;
        u_xlat16 = u._light_pos.xxxy.w + u._horizontal_line;
        u_xlat5.y = u_xlat16 + -0.5;
        u_xlat10.x = float(0.0);
        u_xlat17.x = float(0.0);
        while(true){
            u_xlatb16 = u_xlat17.x>=u_xlat3.x;
            if(u_xlatb16){break;}
            u_xlat11.xy = u_xlat17.xx * float2(1.1375035, 0.137844697);
            u_xlat16 = exp2(u_xlat11.x);
            u_xlat16 = float(1.0) / u_xlat16;
            u_xlat11.x = exp2(u_xlat17.x);
            u_xlat11.x = 314.159271 / u_xlat11.x;
            u_xlat18 = fract(u_xlat11.y);
            u_xlat25 = u_xlat18 + 19.1900005;
            u_xlat25 = dot(float3(u_xlat18), float3(u_xlat25));
            u_xlat18 = u_xlat25 + u_xlat18;
            u_xlat25 = u_xlat18 + u_xlat18;
            u_xlat18 = u_xlat18 * u_xlat25;
            u_xlat18 = fract(u_xlat18);
            u_xlat25 = u_xlat18 * 0.100000001 + 0.75;
            u_xlat11.x = u_xlat25 * u_xlat11.x;
            u_xlat25 = u_xlat17.x / u_xlat24;
            u_xlat25 = u_xlat25 * -1.5 + 2.0;
            u_xlat25 = u_xlat25 + u_xlat25;
            u_xlat26 = u_xlat18 + 0.5;
            u_xlat25 = u_xlat25 * u_xlat26;
            u_xlat25 = u_xlat23 * u_xlat25;
            u_xlat11.x = 6.28318548 / u_xlat11.x;
            u_xlat18 = u_xlat18 * u._random_speed;
            u_xlat18 = u_xlat18 * 6.28318548;
            u_xlat18 = u_xlat25 * u_xlat11.x + u_xlat18;
            u_xlat18 = u_xlat18 * _cur_time;
            u_xlat11.x = u_xlat0.x * u_xlat11.x + u_xlat18;
            u_xlat11.x = sin(u_xlat11.x);
            u_xlat10.x = u_xlat16 * u_xlat11.x + u_xlat10.x;
            u_xlat17.x = u_xlat17.x + 1.0;
        }
        u_xlat11.x = float(0.0);
        u_xlat18 = float(0.0);
        while(true){
            u_xlatb0 = u_xlat18>=u_xlat3.x;
            if(u_xlatb0){break;}
            u_xlat6.xy = float2(u_xlat18) * float2(1.1375035, 0.137844697);
            u_xlat0.x = exp2(u_xlat6.x);
            u_xlat0.x = float(1.0) / u_xlat0.x;
            u_xlat16 = exp2(u_xlat18);
            u_xlat16 = 314.159271 / u_xlat16;
            u_xlat17.x = fract(u_xlat6.y);
            u_xlat25 = u_xlat17.x + 19.1900005;
            u_xlat25 = dot(u_xlat17.xxx, float3(u_xlat25));
            u_xlat17.x = u_xlat17.x + u_xlat25;
            u_xlat25 = u_xlat17.x + u_xlat17.x;
            u_xlat17.x = u_xlat17.x * u_xlat25;
            u_xlat17.x = fract(u_xlat17.x);
            u_xlat25 = u_xlat17.x * 0.100000001 + 0.75;
            u_xlat16 = u_xlat16 * u_xlat25;
            u_xlat25 = u_xlat18 / u_xlat24;
            u_xlat25 = u_xlat25 * -1.5 + 2.0;
            u_xlat25 = u_xlat25 + u_xlat25;
            u_xlat26 = u_xlat17.x + 0.5;
            u_xlat25 = u_xlat25 * u_xlat26;
            u_xlat25 = u_xlat23 * u_xlat25;
            u_xlat16 = 6.28318548 / u_xlat16;
            u_xlat17.x = u_xlat17.x * u._random_speed;
            u_xlat17.x = u_xlat17.x * 6.28318548;
            u_xlat17.x = u_xlat25 * u_xlat16 + u_xlat17.x;
            u_xlat17.x = u_xlat17.x * _cur_time;
            u_xlat16 = u_xlat4.x * u_xlat16 + u_xlat17.x;
            u_xlat16 = sin(u_xlat16);
            u_xlat11.x = u_xlat0.x * u_xlat16 + u_xlat11.x;
            u_xlat18 = u_xlat18 + 1.0;
        }
        u_xlat4.x = u_xlat10.x + (-u_xlat11.x);
        u_xlat10.x = float(0.0);
        u_xlat17.x = float(0.0);
        while(true){
            u_xlatb0 = u_xlat17.x>=u_xlat3.x;
            if(u_xlatb0){break;}
            u_xlat6.xy = u_xlat17.xx * float2(1.1375035, 0.137844697);
            u_xlat0.x = exp2(u_xlat6.x);
            u_xlat0.x = float(1.0) / u_xlat0.x;
            u_xlat16 = exp2(u_xlat17.x);
            u_xlat16 = 314.159271 / u_xlat16;
            u_xlat25 = fract(u_xlat6.y);
            u_xlat26 = u_xlat25 + 19.1900005;
            u_xlat26 = dot(float3(u_xlat25), float3(u_xlat26));
            u_xlat25 = u_xlat25 + u_xlat26;
            u_xlat26 = u_xlat25 + u_xlat25;
            u_xlat25 = u_xlat25 * u_xlat26;
            u_xlat25 = fract(u_xlat25);
            u_xlat26 = u_xlat25 * 0.100000001 + 0.75;
            u_xlat16 = u_xlat16 * u_xlat26;
            u_xlat26 = u_xlat17.x / u_xlat24;
            u_xlat26 = u_xlat26 * -1.5 + 2.0;
            u_xlat26 = u_xlat26 + u_xlat26;
            u_xlat6.x = u_xlat25 + 0.5;
            u_xlat26 = u_xlat26 * u_xlat6.x;
            u_xlat26 = u_xlat23 * u_xlat26;
            u_xlat16 = 6.28318548 / u_xlat16;
            u_xlat25 = u_xlat25 * u._random_speed;
            u_xlat25 = u_xlat25 * 6.28318548;
            u_xlat25 = u_xlat26 * u_xlat16 + u_xlat25;
            u_xlat25 = u_xlat25 * _cur_time;
            u_xlat16 = u_xlat1 * u_xlat16 + u_xlat25;
            u_xlat16 = sin(u_xlat16);
            u_xlat10.x = u_xlat0.x * u_xlat16 + u_xlat10.x;
            u_xlat17.x = u_xlat17.x + 1.0;
        }
        u_xlat6.x = float(0.0);
        u_xlat13 = float(0.0);
        while(true){
            u_xlatb0 = u_xlat13>=u_xlat3.x;
            if(u_xlatb0){break;}
            u_xlat20.xy = float2(u_xlat13) * float2(1.1375035, 0.137844697);
            u_xlat0.x = exp2(u_xlat20.x);
            u_xlat0.x = float(1.0) / u_xlat0.x;
            u_xlat1 = exp2(u_xlat13);
            u_xlat1 = 314.159271 / u_xlat1;
            u_xlat16 = fract(u_xlat20.y);
            u_xlat17.x = u_xlat16 + 19.1900005;
            u_xlat17.x = dot(float3(u_xlat16), u_xlat17.xxx);
            u_xlat16 = u_xlat16 + u_xlat17.x;
            u_xlat17.x = u_xlat16 + u_xlat16;
            u_xlat16 = u_xlat16 * u_xlat17.x;
            u_xlat16 = fract(u_xlat16);
            u_xlat17.x = u_xlat16 * 0.100000001 + 0.75;
            u_xlat1 = u_xlat1 * u_xlat17.x;
            u_xlat17.x = u_xlat13 / u_xlat24;
            u_xlat17.x = u_xlat17.x * -1.5 + 2.0;
            u_xlat17.x = u_xlat17.x + u_xlat17.x;
            u_xlat25 = u_xlat16 + 0.5;
            u_xlat17.x = u_xlat17.x * u_xlat25;
            u_xlat17.x = u_xlat23 * u_xlat17.x;
            u_xlat1 = 6.28318548 / u_xlat1;
            u_xlat16 = u_xlat16 * u._random_speed;
            u_xlat16 = u_xlat16 * 6.28318548;
            u_xlat16 = u_xlat17.x * u_xlat1 + u_xlat16;
            u_xlat16 = u_xlat16 * _cur_time;
            u_xlat1 = u_xlat14 * u_xlat1 + u_xlat16;
            u_xlat1 = sin(u_xlat1);
            u_xlat6.x = u_xlat0.x * u_xlat1 + u_xlat6.x;
            u_xlat13 = u_xlat13 + 1.0;
        }
        u_xlat4.y = u_xlat10.x + (-u_xlat6.x);
        u_xlat4.z = u_xlat7 / u_xlat0.w;
        u_xlat0.x = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat0.x = rsqrt(u_xlat0.x);
        u_xlat0.xyz = u_xlat0.xxx * u_xlat4.xyz;
        u_xlat21 = u_xlat22 * 0.100000001;
        u_xlat5.x = u._light_pos.xxxy.z;
        u_xlat5.z = 0.800000012;
        u_xlat1 = dot(u_xlat5.xyz, u_xlat5.xyz);
        u_xlat1 = rsqrt(u_xlat1);
        u_xlat3.xyz = float3(u_xlat1) * u_xlat5.xyz;
        u_xlat1 = dot(u_xlat3.xyz, u_xlat0.xyz);
        u_xlat1 = u_xlat1 + u_xlat1;
        u_xlat0.xyz = u_xlat0.xyz * (-float3(u_xlat1)) + u_xlat3.xyz;
        u_xlat3.xy = in.acScreenNorm.xy;
        u_xlat3.z = -1.0;
        u_xlat1 = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat1 = rsqrt(u_xlat1);
        u_xlat0.xyz = (-u_xlat3.xyz) * float3(u_xlat1) + u_xlat0.xyz;
        u_xlat0.x = dot(u_xlat0.xyz, u_xlat0.xyz);
        u_xlat0.x = sqrt(u_xlat0.x);
        u_xlat0.x = u_xlat21 / u_xlat0.x;
        u_xlat0 = u_xlat0.xxxx * u._light_color;
    } else {
        u_xlat0.x = float(0.0);
        u_xlat0.y = float(0.0);
        u_xlat0.z = float(0.0);
        u_xlat0.w = float(0.0);
    }
    u_xlat2 = inputImg.sample(__nv_smp, u_xlat2.xy);
    u_xlat0 = u_xlat0 + u_xlat2;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1 = u._feather * 0.100000001;
    u_xlat1 = float(1.0) / u_xlat1;
    u_xlat1 = u_xlat1 * u_xlat15;
    u_xlat1 = clamp(u_xlat1, 0.0, 1.0);
    u_xlat15 = u_xlat1 * -2.0 + 3.0;
    u_xlat1 = u_xlat1 * u_xlat1;
    u_xlat1 = u_xlat1 * u_xlat15;
    u_xlat3.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u._color.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat3.xyz = u_xlat3.xyz * u._color.xyz;
    u_xlat3.xyz = u_xlat0.xyz * u_xlat3.xyz;
    u_xlat3.w = u_xlat0.w * u._color.w;
    u_xlat0 = (-u_xlat2) + u_xlat3;
    u_xlat0 = float4(u_xlat1) * u_xlat0 + u_xlat2;
    u_xlat0 = (bool(u_xlatb8)) ? u_xlat2 : u_xlat0;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat2 = u_xlat2 * u_xlat5;
        u_xlat2 = u_xlat3 * u_xlat4 + u_xlat2;
        u_xlat1 = u_xlat4.x * u_xlat2.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1 : u_xlat2.w;
        __nv_out.xyz = u_xlat2.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
