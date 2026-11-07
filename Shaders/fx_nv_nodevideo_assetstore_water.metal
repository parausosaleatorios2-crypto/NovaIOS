// ---------------------------------------------------------------------------
// Water (NV)
// origem : assets/effects/nv-nodevideo-assetstore-water.xml
// id     : nv.effect.nodevideo-assetstore-water
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_waterParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amplitude;
    float _speed;
    float _frequency;
    float _amp_mult;
    float _octaves;
    float _direction;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
bool u_xlatb6;
float u_xlat8;
float u_xlat9;
float u_xlat12;
bool u_xlatb12;
float2 u_xlat13;
bool2 u_xlatb13;
float2 u_xlat14;
float2 u_xlat15;
float u_xlat18;
float u_xlat19;
float u_xlat21;

fragment float4 fx_nv_nodevideo_assetstore_water(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_waterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat0.xy = u_xlat0.xy / _resolution.yy;
    u_xlat12 = _cur_time * u._speed;
    u_xlat18 = u._direction + 90.0;
    u_xlat18 = u_xlat18 * 0.0174532942;
    u_xlat1.x = sin((-u_xlat18));
    u_xlat18 = cos(u_xlat18);
    u_xlat1.x = u_xlat12 * u_xlat1.x;
    u_xlat1.y = u_xlat12 * u_xlat18;
    u_xlat0.xy = u_xlat0.xy + u_xlat1.xy;
    u_xlat12 = log2(abs(u._frequency));
    u_xlat1.xy = u_xlat0.xy;
    u_xlat18 = 0.0;
    u_xlat13.x = float(0.0);
    u_xlat13.y = float(0.0);
    while(true){
        u_xlatb2.x = u_xlat13.y>=u._octaves;
        if(u_xlatb2.x){break;}
        u_xlat2.xy = floor(u_xlat1.xy);
        u_xlat14.xy = fract(u_xlat1.xy);
        u_xlat3.xy = u_xlat14.xy * u_xlat14.xy;
        u_xlat14.xy = (-u_xlat14.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
        u_xlat14.xy = u_xlat14.xy * u_xlat3.xy;
        u_xlat3.x = dot(u_xlat2.xy, float2(17.1000004, 311.700012));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 4358.54541;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 2.0 + -1.0;
        u_xlat4 = u_xlat2.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat9 = dot(u_xlat4.xy, float2(17.1000004, 311.700012));
        u_xlat9 = sin(u_xlat9);
        u_xlat9 = u_xlat9 * 4358.54541;
        u_xlat9 = fract(u_xlat9);
        u_xlat9 = u_xlat9 * 2.0 + -1.0;
        u_xlat9 = (-u_xlat3.x) + u_xlat9;
        u_xlat3.x = u_xlat14.x * u_xlat9 + u_xlat3.x;
        u_xlat9 = dot(u_xlat4.zw, float2(17.1000004, 311.700012));
        u_xlat9 = sin(u_xlat9);
        u_xlat9 = u_xlat9 * 4358.54541;
        u_xlat9 = fract(u_xlat9);
        u_xlat9 = u_xlat9 * 2.0 + -1.0;
        u_xlat2.xy = u_xlat2.xy + float2(1.0, 1.0);
        u_xlat2.x = dot(u_xlat2.xy, float2(17.1000004, 311.700012));
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat2.x = u_xlat2.x * 4358.54541;
        u_xlat2.x = fract(u_xlat2.x);
        u_xlat2.x = u_xlat2.x * 2.0 + -1.0;
        u_xlat2.x = (-u_xlat9) + u_xlat2.x;
        u_xlat2.x = u_xlat14.x * u_xlat2.x + u_xlat9;
        u_xlat2.x = (-u_xlat3.x) + u_xlat2.x;
        u_xlat2.x = u_xlat14.y * u_xlat2.x + u_xlat3.x;
        u_xlat14.xy = float2(float2(_cur_time, _cur_time)) * float2(float2(u._speed, u._speed)) + u_xlat1.xy;
        u_xlat14.xy = u_xlat14.xy + float2(0.330000013, 0.330000013);
        u_xlat3.xy = floor(u_xlat14.xy);
        u_xlat14.xy = fract(u_xlat14.xy);
        u_xlat15.xy = u_xlat14.xy * u_xlat14.xy;
        u_xlat14.xy = (-u_xlat14.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
        u_xlat14.xy = u_xlat14.xy * u_xlat15.xy;
        u_xlat15.x = dot(u_xlat3.xy, float2(17.1000004, 311.700012));
        u_xlat15.x = sin(u_xlat15.x);
        u_xlat15.x = u_xlat15.x * 4358.54541;
        u_xlat15.x = fract(u_xlat15.x);
        u_xlat15.x = u_xlat15.x * 2.0 + -1.0;
        u_xlat4 = u_xlat3.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat21 = dot(u_xlat4.xy, float2(17.1000004, 311.700012));
        u_xlat21 = sin(u_xlat21);
        u_xlat21 = u_xlat21 * 4358.54541;
        u_xlat21 = fract(u_xlat21);
        u_xlat21 = u_xlat21 * 2.0 + -1.0;
        u_xlat21 = (-u_xlat15.x) + u_xlat21;
        u_xlat15.x = u_xlat14.x * u_xlat21 + u_xlat15.x;
        u_xlat21 = dot(u_xlat4.zw, float2(17.1000004, 311.700012));
        u_xlat21 = sin(u_xlat21);
        u_xlat21 = u_xlat21 * 4358.54541;
        u_xlat21 = fract(u_xlat21);
        u_xlat21 = u_xlat21 * 2.0 + -1.0;
        u_xlat3.xy = u_xlat3.xy + float2(1.0, 1.0);
        u_xlat3.x = dot(u_xlat3.xy, float2(17.1000004, 311.700012));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 4358.54541;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 2.0 + -1.0;
        u_xlat3.x = (-u_xlat21) + u_xlat3.x;
        u_xlat14.x = u_xlat14.x * u_xlat3.x + u_xlat21;
        u_xlat14.x = (-u_xlat15.x) + u_xlat14.x;
        u_xlat2.y = u_xlat14.y * u_xlat14.x + u_xlat15.x;
        u_xlat2.xy = u_xlat1.xy + u_xlat2.xy;
        u_xlat14.xy = floor(u_xlat2.xy);
        u_xlat2.xy = fract(u_xlat2.xy);
        u_xlat3.xy = u_xlat2.xy * u_xlat2.xy;
        u_xlat2.xy = (-u_xlat2.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
        u_xlat2.xy = u_xlat2.xy * u_xlat3.xy;
        u_xlat3.x = dot(u_xlat14.xy, float2(17.1000004, 311.700012));
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 4358.54541;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat3.x = u_xlat3.x * 2.0 + -1.0;
        u_xlat4 = u_xlat14.xyxy + float4(1.0, 0.0, 0.0, 1.0);
        u_xlat9 = dot(u_xlat4.xy, float2(17.1000004, 311.700012));
        u_xlat9 = sin(u_xlat9);
        u_xlat9 = u_xlat9 * 4358.54541;
        u_xlat9 = fract(u_xlat9);
        u_xlat9 = u_xlat9 * 2.0 + -1.0;
        u_xlat9 = (-u_xlat3.x) + u_xlat9;
        u_xlat3.x = u_xlat2.x * u_xlat9 + u_xlat3.x;
        u_xlat9 = dot(u_xlat4.zw, float2(17.1000004, 311.700012));
        u_xlat9 = sin(u_xlat9);
        u_xlat9 = u_xlat9 * 4358.54541;
        u_xlat9 = fract(u_xlat9);
        u_xlat9 = u_xlat9 * 2.0 + -1.0;
        u_xlat14.xy = u_xlat14.xy + float2(1.0, 1.0);
        u_xlat14.x = dot(u_xlat14.xy, float2(17.1000004, 311.700012));
        u_xlat14.x = sin(u_xlat14.x);
        u_xlat14.x = u_xlat14.x * 4358.54541;
        u_xlat14.x = fract(u_xlat14.x);
        u_xlat14.x = u_xlat14.x * 2.0 + -1.0;
        u_xlat14.x = (-u_xlat9) + u_xlat14.x;
        u_xlat2.x = u_xlat2.x * u_xlat14.x + u_xlat9;
        u_xlat2.x = (-u_xlat3.x) + u_xlat2.x;
        u_xlat2.x = u_xlat2.y * u_xlat2.x + u_xlat3.x;
        u_xlat8 = u_xlat13.y * (-u._amp_mult);
        u_xlat8 = u_xlat12 * u_xlat8;
        u_xlat8 = exp2(u_xlat8);
        u_xlat18 = u_xlat2.x * u_xlat8 + u_xlat18;
        u_xlat1.xy = u_xlat1.xy * float2(float2(u._frequency, u._frequency));
        u_xlat13.xy = u_xlat13.xy + float2(1.0, 1.0);
    }
    u_xlat0.x = fract(u._octaves);
    u_xlatb6 = u_xlat0.x!=0.0;
    u_xlat2.xy = floor(u_xlat1.xy);
    u_xlat1.xy = fract(u_xlat1.xy);
    u_xlat14.xy = u_xlat1.xy * u_xlat1.xy;
    u_xlat1.xy = (-u_xlat1.xy) * float2(2.0, 2.0) + float2(3.0, 3.0);
    u_xlat1.xy = u_xlat1.xy * u_xlat14.xy;
    u_xlat19 = dot(u_xlat2.xy, float2(17.1000004, 311.700012));
    u_xlat19 = sin(u_xlat19);
    u_xlat19 = u_xlat19 * 4358.54541;
    u_xlat19 = fract(u_xlat19);
    u_xlat19 = u_xlat19 * 2.0 + -1.0;
    u_xlat3 = u_xlat2.xyxy + float4(1.0, 0.0, 0.0, 1.0);
    u_xlat14.x = dot(u_xlat3.xy, float2(17.1000004, 311.700012));
    u_xlat14.x = sin(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * 4358.54541;
    u_xlat14.x = fract(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * 2.0 + -1.0;
    u_xlat14.x = (-u_xlat19) + u_xlat14.x;
    u_xlat19 = u_xlat1.x * u_xlat14.x + u_xlat19;
    u_xlat14.x = dot(u_xlat3.zw, float2(17.1000004, 311.700012));
    u_xlat14.x = sin(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * 4358.54541;
    u_xlat14.x = fract(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * 2.0 + -1.0;
    u_xlat2.xy = u_xlat2.xy + float2(1.0, 1.0);
    u_xlat2.x = dot(u_xlat2.xy, float2(17.1000004, 311.700012));
    u_xlat2.x = sin(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 4358.54541;
    u_xlat2.x = fract(u_xlat2.x);
    u_xlat2.x = u_xlat2.x * 2.0 + -1.0;
    u_xlat2.x = (-u_xlat14.x) + u_xlat2.x;
    u_xlat1.x = u_xlat1.x * u_xlat2.x + u_xlat14.x;
    u_xlat1.x = (-u_xlat19) + u_xlat1.x;
    u_xlat1.x = u_xlat1.y * u_xlat1.x + u_xlat19;
    u_xlat0.x = u_xlat0.x * u_xlat1.x;
    u_xlat1.x = u_xlat13.x * (-u._amp_mult);
    u_xlat12 = u_xlat12 * u_xlat1.x;
    u_xlat12 = exp2(u_xlat12);
    u_xlat0.x = u_xlat0.x * u_xlat12 + u_xlat18;
    u_xlat0.x = (u_xlatb6) ? u_xlat0.x : u_xlat18;
    u_xlat0.x = u_xlat0.x * u._amplitude;
    u_xlat0.xy = u_xlat0.xx * float2(0.0400000028, 0.0400000028) + in.acScreenNorm.xy;
    u_xlatb12 = int(u._keep_edge)==1;
    u_xlat1.xy = u_xlat0.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(1.00999999, 1.00999999) + float2(0.5, 0.5);
    u_xlatb13.xy = lessThan(u_xlat1.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat1.xyxx).xy;
    u_xlat14.xy = fract(u_xlat1.xy);
    u_xlat14.xy = (-u_xlat14.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat14.x : u_xlat1.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat14.y : u_xlat1.y;
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb13.x) ? (-u_xlat1.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb13.y) ? (-u_xlat1.y) : u_xlat2.y;
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1.xy = u_xlat1.xy + float2(-0.5, -0.5);
    u_xlat1.xy = u_xlat1.xy * float2(0.990099013, 0.990099013) + float2(0.5, 0.5);
    u_xlat0.xy = (bool(u_xlatb12)) ? u_xlat1.xy : u_xlat0.xy;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
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
