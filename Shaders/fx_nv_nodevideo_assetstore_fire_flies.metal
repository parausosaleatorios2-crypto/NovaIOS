// ---------------------------------------------------------------------------
// Fire Flies (NV)
// origem : assets/effects/nv-nodevideo-assetstore-fire-flies.xml
// id     : nv.effect.nodevideo-assetstore-fire-flies
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_fire_fliesParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _glow;
    float _speed;
    float _size;
    float2 _scale;
    float2 _offset;
    float4 _color;
    float _amplitude;
    float _frequency;
    float _flash;
    float _seed;
    float _size_randomness;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool2 u_xlatb4;
float4 u_xlat5;
float u_xlat6;
float u_xlat7;
float u_xlat8;
float u_xlat12;
float u_xlat14;
float2 u_xlat15;
float u_xlat18;
float u_xlat19;
bool u_xlatb19;
float u_xlat20;
bool u_xlatb20;

fragment float4 fx_nv_nodevideo_assetstore_fire_flies(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_fire_fliesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * _resolution.xy;
    u_xlat12 = _resolution.y / _resolution.x;
    u_xlat0.xy = u_xlat0.xy * float2(2.0, 2.0) + (-_resolution.xy);
    u_xlat0.xy = u_xlat0.xy / _resolution.xy;
    u_xlat1.xy = u_xlat0.xy / float2(u._scale.x, u._scale.y);
    u_xlat0.xy = max(abs(u_xlat1.xy), float2(0.800000012, 0.800000012));
    u_xlat0.xy = min(u_xlat0.xy, float2(1.0, 1.0));
    u_xlat0.xy = u_xlat0.xy + float2(-0.800000012, -0.800000012);
    u_xlat0.xy = u_xlat0.xy * float2(5.0, 5.0);
    u_xlat0.x = max(u_xlat0.y, u_xlat0.x);
    u_xlat0.x = (-u_xlat0.x) + 1.0;
    u_xlat0.x = u_xlat0.x * u._size;
    u_xlat1.z = u_xlat12 * u_xlat1.y;
    u_xlat6 = u._amount * 10.0;
    u_xlat12 = u._seed + 43758.5469;
    u_xlat0.x = u_xlat0.x * 0.000500000024;
    u_xlat18 = _cur_time * u._frequency;
    u_xlat7 = float(1.0) / u._glow;
    u_xlat19 = float(int(u._flash));
    u_xlatb19 = 0.0<u_xlat19;
    u_xlat2 = (-u._size_randomness) + 1.0;
    u_xlat8 = float(0.0);
    u_xlat14 = float(0.0);
    while(true){
        u_xlatb20 = u_xlat14>=u_xlat6;
        if(u_xlatb20){break;}
        u_xlat20 = sin(u_xlat14);
        u_xlat20 = u_xlat12 * u_xlat20;
        u_xlat20 = fract(u_xlat20);
        u_xlat3.xy = float2(u_xlat14) * float2(1.29999995, 4.0);
        u_xlat3.xy = sin(u_xlat3.xy);
        u_xlat3.xy = float2(u_xlat12) * u_xlat3.xy;
        u_xlat3.xy = fract(u_xlat3.xy);
        u_xlat15.x = u_xlat20 * _cur_time;
        u_xlat15.x = u_xlat15.x * u._speed + u_xlat20;
        u_xlat15.x = cos(u_xlat15.x);
        u_xlat15.x = u_xlat15.x * u._amplitude;
        u_xlat20 = u_xlat20 * 13.0 + u_xlat15.x;
        u_xlat15.x = u_xlat14 * 0.100000001 + 5.0;
        u_xlat15.x = floor(u_xlat15.x);
        u_xlat15.xy = (-u._offset.xy) / u_xlat15.xx;
        u_xlat4.x = (-u_xlat15.x) * 2.0 + u_xlat20;
        u_xlat20 = u_xlat3.x * _cur_time;
        u_xlat20 = u_xlat20 * u._speed + u_xlat3.x;
        u_xlat20 = sin(u_xlat20);
        u_xlat20 = u_xlat20 * u._amplitude;
        u_xlat20 = u_xlat3.x * 13.0 + u_xlat20;
        u_xlat4.y = (-u_xlat15.y) * 2.0 + u_xlat20;
        u_xlat3.xz = u_xlat4.xy * float2(0.5, 0.5);
        u_xlatb4.xy = greaterThanEqual(u_xlat3.xzxx, (-u_xlat3.xzxx)).xy;
        u_xlat3.xz = fract(abs(u_xlat3.xz));
        {
            float4 hlslcc_movcTemp = u_xlat3;
            hlslcc_movcTemp.x = (u_xlatb4.x) ? u_xlat3.x : (-u_xlat3.x);
            hlslcc_movcTemp.z = (u_xlatb4.y) ? u_xlat3.z : (-u_xlat3.z);
            u_xlat3 = hlslcc_movcTemp;
        }
        u_xlat3.xz = u_xlat3.xz * float2(2.0, 2.0) + float2(-1.0, -1.0);
        u_xlat3.xz = u_xlat1.xz + (-u_xlat3.xz);
        u_xlat20 = dot(u_xlat3.xz, u_xlat3.xz);
        u_xlat20 = sqrt(u_xlat20);
        u_xlat20 = u_xlat0.x / u_xlat20;
        u_xlat3.x = u_xlat18 * 10.0 + u_xlat14;
        u_xlat3.x = sin(u_xlat3.x);
        u_xlat3.x = u_xlat3.x + 1.0;
        u_xlat20 = u_xlat20 * u_xlat3.x;
        u_xlat20 = log2(u_xlat20);
        u_xlat20 = u_xlat7 * u_xlat20;
        u_xlat20 = exp2(u_xlat20);
        u_xlat3.x = u_xlat14 + _cur_time;
        u_xlat3.x = u_xlat3.x * 0.103100002;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat15.x = u_xlat3.x + 33.3300018;
        u_xlat3.x = u_xlat15.x * u_xlat3.x;
        u_xlat15.x = u_xlat3.x + u_xlat3.x;
        u_xlat3.x = u_xlat15.x * u_xlat3.x;
        u_xlat3.x = fract(u_xlat3.x);
        u_xlat3.x = (u_xlatb19) ? u_xlat3.x : 1.0;
        u_xlat20 = u_xlat20 * u_xlat3.x;
        u_xlat3.x = max(u_xlat2, u_xlat3.y);
        u_xlat3.x = min(u_xlat3.x, 1.0);
        u_xlat8 = u_xlat20 * u_xlat3.x + u_xlat8;
        u_xlat14 = u_xlat14 + 1.0;
    }
    u_xlat0.xyz = u._color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = u._color.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat0.xyz = u_xlat0.xyz * u._color.xyz;
    u_xlat0.w = 1.0;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat0 = float4(u_xlat8) * u_xlat0 + u_xlat1;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat1 = u_xlat1 * u_xlat5;
        u_xlat1 = u_xlat3 * u_xlat4 + u_xlat1;
        u_xlat2 = u_xlat4.x * u_xlat1.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2 : u_xlat1.w;
        __nv_out.xyz = u_xlat1.xyz;
    } else {
        __nv_out = u_xlat0;
    }
    return __nv_out;
    return __nv_out;
}
