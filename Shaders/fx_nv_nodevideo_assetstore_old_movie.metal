// ---------------------------------------------------------------------------
// Old Movie (NV)
// origem : assets/effects/nv-nodevideo-assetstore-old-movie.xml
// id     : nv.effect.nodevideo-assetstore-old-movie
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_old_movieParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _black_white;
    float _lines_flicker;
    float _blotches;
    float _grain;
    float _flicker;
    float _frequency;
    float _brightness;
    float _vignetting;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
bool4 u_xlatb5;
float4 u_xlat6;
float3 u_xlat7;
float2 u_xlat9;
int u_xlati9;
bool u_xlatb9;
float u_xlat11;
bool u_xlatb11;
float2 u_xlat14;
float u_xlat16;
bool u_xlatb16;
float2 u_xlat18;
bool u_xlatb18;
float u_xlat21;
int u_xlati21;
bool u_xlatb21;
float u_xlat24;
bool u_xlatb24;
float u_xlat25;
bool u_xlatb25;

fragment float4 fx_nv_nodevideo_assetstore_old_movie(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_old_movieParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = _cur_time * u._frequency;
    u_xlat0.x = trunc(u_xlat0.x);
    u_xlat0.y = 1.0;
    u_xlat1.x = dot(u_xlat0.xy, float2(12.9898005, 78.2330017));
    u_xlat1.x = sin(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * 43758.5469;
    u_xlat1.x = fract(u_xlat1.x);
    u_xlat0.zw = u_xlat0.xx + float2(23.0, 0.5);
    u_xlat14.x = dot(u_xlat0.zy, float2(12.9898005, 78.2330017));
    u_xlat14.x = sin(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * 43758.5469;
    u_xlat1.y = fract(u_xlat14.x);
    u_xlat1.xy = u_xlat1.xy * float2(0.00200000009, 0.00200000009) + in.acScreenNorm.xy;
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat1.xy);
    u_xlatb2 = equal(int4(int(u._black_white), int(u._lines_flicker), int(u._blotches), int(u._grain)), int4(1, 1, 1, 1));
    u_xlat14.x = dot(float3(0.212599993, 0.715200007, 0.0722000003), u_xlat1.xyz);
    u_xlat14.x = u_xlat14.x * 0.699999988;
    u_xlat3.xyz = (u_xlatb2.x) ? u_xlat14.xxx : u_xlat1.xyz;
    u_xlat4.xy = (-in.acScreenNorm.xy) + float2(1.0, 1.0);
    u_xlat14.x = u_xlat4.x * in.acScreenNorm.x;
    u_xlat14.x = u_xlat14.x * in.acScreenNorm.y;
    u_xlat14.x = u_xlat4.y * u_xlat14.x;
    u_xlatb2.x = int(u._flicker)==1;
    u_xlat21 = dot(u_xlat0.wy, float2(12.9898005, 78.2330017));
    u_xlat14.y = sin(u_xlat21);
    u_xlat14.xy = u_xlat14.xy * float2(16.0, 43758.5469);
    u_xlat4.x = fract(u_xlat14.y);
    u_xlat18.xy = u_xlat0.xy + float2(8.0, 0.0);
    u_xlat21 = dot(u_xlat18.xy, float2(12.9898005, 78.2330017));
    u_xlat21 = sin(u_xlat21);
    u_xlat21 = u_xlat21 * 43758.5469;
    u_xlat4.y = fract(u_xlat21);
    u_xlat4.xz = (u_xlatb2.x) ? u_xlat4.xy : float2(1.0, 1.0);
    u_xlat21 = u_xlat4.x * 0.300000012 + 0.699999988;
    u_xlat2.x = u_xlat4.z * u._brightness;
    u_xlat21 = u_xlat14.x * u_xlat21 + u_xlat2.x;
    u_xlat21 = u_xlat21 + 1.0;
    u_xlat14.x = log2(abs(u_xlat14.x));
    u_xlat14.x = u_xlat14.x * u._vignetting;
    u_xlat14.x = exp2(u_xlat14.x);
    u_xlat14.x = u_xlat14.x * u_xlat21;
    if(u_xlatb2.y){
        u_xlat4.xzw = u_xlat0.xxy + float3(6.0, 7.0, 0.0);
        u_xlat21 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
        u_xlat21 = sin(u_xlat21);
        u_xlat21 = u_xlat21 * 43758.5469;
        u_xlat21 = fract(u_xlat21);
        u_xlat21 = u_xlat21 * 8.0;
        u_xlati21 = int(u_xlat21);
        u_xlat5.y = 1.0;
        u_xlat2.x = u_xlat14.x;
        for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<32 ; u_xlati_loop_1++)
        {
            u_xlatb24 = u_xlati_loop_1<u_xlati21;
            if(u_xlatb24){
                u_xlat24 = float(u_xlati_loop_1);
                u_xlat5.x = u_xlat24 * 17.0 + u_xlat4.x;
                u_xlat24 = dot(u_xlat5.xy, float2(12.9898005, 78.2330017));
                u_xlat24 = sin(u_xlat24);
                u_xlat24 = u_xlat24 * 43758.5469;
                u_xlat24 = fract(u_xlat24);
                u_xlat24 = u_xlat24 * in.acScreenNorm.y;
                u_xlat5.zw = u_xlat5.xx + float2(1.0, 2.0);
                u_xlat18.x = dot(u_xlat5.zy, float2(12.9898005, 78.2330017));
                u_xlat18.x = sin(u_xlat18.x);
                u_xlat18.x = u_xlat18.x * 43758.5469;
                u_xlat25 = dot(u_xlat5.wy, float2(12.9898005, 78.2330017));
                u_xlat25 = sin(u_xlat25);
                u_xlat18.y = u_xlat25 * 43758.5469;
                u_xlat18.xy = fract(u_xlat18.xy);
                u_xlat25 = u_xlat18.y + -0.5;
                u_xlat5.xz = u_xlat5.xy + float2(3.0, 0.0);
                u_xlat5.x = dot(u_xlat5.xz, float2(12.9898005, 78.2330017));
                u_xlat5.x = sin(u_xlat5.x);
                u_xlat5.x = u_xlat5.x * 43758.5469;
                u_xlat5.x = fract(u_xlat5.x);
                u_xlatb5.x = 0.200000003<u_xlat5.x;
                u_xlat24 = u_xlat24 * 0.00999999978;
                u_xlat24 = u_xlat18.x * in.acScreenNorm.x + u_xlat24;
                u_xlat24 = u_xlat25 + u_xlat24;
                u_xlat24 = log2(abs(u_xlat24));
                u_xlat24 = u_xlat24 * 0.125;
                u_xlat24 = exp2(u_xlat24);
                u_xlat18.x = (-u_xlat24) + 2.0;
                u_xlat24 = (u_xlatb5.x) ? u_xlat24 : u_xlat18.x;
                u_xlat24 = u_xlat24 * 0.5 + 0.5;
                u_xlat2.x = u_xlat2.x * u_xlat24;
            }
        }
        u_xlat14.x = u_xlat2.x;
    }
    if(u_xlatb2.z){
        u_xlat2.xy = u_xlat0.xy + float2(18.0, 0.0);
        u_xlat21 = dot(u_xlat2.xy, float2(12.9898005, 78.2330017));
        u_xlat21 = sin(u_xlat21);
        u_xlat21 = u_xlat21 * 43758.5469;
        u_xlat21 = fract(u_xlat21);
        u_xlat21 = u_xlat21 * 8.0 + -2.0;
        u_xlat21 = max(u_xlat21, 0.0);
        u_xlati21 = int(u_xlat21);
        u_xlatb5 = lessThan(int4(0, 1, 2, 3), int4(u_xlati21));
        if(u_xlatb5.x){
            u_xlat6 = u_xlat0.xyxy + float4(6.0, 0.0, 7.0, 0.0);
            u_xlat2.x = dot(u_xlat6.xy, float2(12.9898005, 78.2330017));
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 43758.5469;
            u_xlat16 = dot(u_xlat6.zw, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat2.z = u_xlat16 * 43758.5469;
            u_xlat2.xy = fract(u_xlat2.xz);
            u_xlat2.z = u_xlat4.y * 0.00999999978;
            u_xlat4.xz = u_xlat2.xy + (-in.acScreenNorm.xy);
            u_xlat4.xz = u_xlat4.xz * float2(_viewport_ratio.x, _viewport_ratio.y);
            u_xlat9.x = min(abs(u_xlat4.x), abs(u_xlat4.z));
            u_xlat24 = max(abs(u_xlat4.x), abs(u_xlat4.z));
            u_xlat24 = float(1.0) / u_xlat24;
            u_xlat9.x = u_xlat9.x * u_xlat24;
            u_xlat24 = u_xlat9.x * u_xlat9.x;
            u_xlat25 = u_xlat24 * 0.0208350997 + -0.0851330012;
            u_xlat25 = u_xlat24 * u_xlat25 + 0.180141002;
            u_xlat25 = u_xlat24 * u_xlat25 + -0.330299497;
            u_xlat24 = u_xlat24 * u_xlat25 + 0.999866009;
            u_xlat25 = u_xlat9.x * u_xlat24;
            u_xlatb5.x = abs(u_xlat4.x)<abs(u_xlat4.z);
            u_xlat25 = u_xlat25 * -2.0 + 1.57079637;
            u_xlat25 = u_xlatb5.x ? u_xlat25 : float(0.0);
            u_xlat9.x = u_xlat9.x * u_xlat24 + u_xlat25;
            u_xlatb24 = u_xlat4.x<(-u_xlat4.x);
            u_xlat24 = u_xlatb24 ? -3.14159274 : float(0.0);
            u_xlat9.x = u_xlat9.x + u_xlat24;
            u_xlat24 = min(u_xlat4.x, u_xlat4.z);
            u_xlat25 = max(u_xlat4.x, u_xlat4.z);
            u_xlatb24 = u_xlat24<(-u_xlat24);
            u_xlatb25 = u_xlat25>=(-u_xlat25);
            u_xlatb24 = u_xlatb24 && u_xlatb25;
            u_xlat2.y = (u_xlatb24) ? (-u_xlat9.x) : u_xlat9.x;
            u_xlat2.xz = u_xlat2.yz * u_xlat2.xz;
            u_xlat2.x = u_xlat2.x * 6.28310013;
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 0.100000001 + 1.0;
            u_xlat9.x = u_xlat2.x * u_xlat2.z;
            u_xlat24 = dot(u_xlat4.xz, u_xlat4.xz);
            u_xlatb9 = u_xlat24<u_xlat9.x;
            u_xlat2.x = (-u_xlat2.z) * u_xlat2.x + u_xlat24;
            u_xlat2.x = log2(abs(u_xlat2.x));
            u_xlat2.x = u_xlat2.x * 0.0625;
            u_xlat2.x = exp2(u_xlat2.x);
            u_xlat2.x = (u_xlatb9) ? 0.200000003 : u_xlat2.x;
            u_xlat9.x = (-u_xlat4.y) * 0.5 + 1.0;
            u_xlat9.x = u_xlat9.x * 0.200000003 + 0.300000012;
            u_xlat16 = (-u_xlat9.x) + 1.0;
            u_xlat2.x = u_xlat2.x * u_xlat16 + u_xlat9.x;
            u_xlat14.x = u_xlat14.x * u_xlat2.x;
        }
        if(u_xlatb5.y){
            u_xlat4 = u_xlat0.xyxy + float4(25.0, 0.0, 26.0, 0.0);
            u_xlat2.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 43758.5469;
            u_xlat16 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat2.z = u_xlat16 * 43758.5469;
            u_xlat2.xy = fract(u_xlat2.xz);
            u_xlat4.xy = u_xlat0.xy + float2(27.0, 0.0);
            u_xlat16 = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat16 = u_xlat16 * 43758.5469;
            u_xlat16 = fract(u_xlat16);
            u_xlat24 = u_xlat16 * 0.00999999978;
            u_xlat4.xy = u_xlat2.xy + (-in.acScreenNorm.xy);
            u_xlat4.xy = u_xlat4.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
            u_xlat9.x = min(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = max(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = float(1.0) / u_xlat18.x;
            u_xlat9.x = u_xlat9.x * u_xlat18.x;
            u_xlat18.x = u_xlat9.x * u_xlat9.x;
            u_xlat25 = u_xlat18.x * 0.0208350997 + -0.0851330012;
            u_xlat25 = u_xlat18.x * u_xlat25 + 0.180141002;
            u_xlat25 = u_xlat18.x * u_xlat25 + -0.330299497;
            u_xlat18.x = u_xlat18.x * u_xlat25 + 0.999866009;
            u_xlat25 = u_xlat9.x * u_xlat18.x;
            u_xlatb5.x = abs(u_xlat4.x)<abs(u_xlat4.y);
            u_xlat25 = u_xlat25 * -2.0 + 1.57079637;
            u_xlat25 = u_xlatb5.x ? u_xlat25 : float(0.0);
            u_xlat9.x = u_xlat9.x * u_xlat18.x + u_xlat25;
            u_xlatb18 = u_xlat4.x<(-u_xlat4.x);
            u_xlat18.x = u_xlatb18 ? -3.14159274 : float(0.0);
            u_xlat9.x = u_xlat9.x + u_xlat18.x;
            u_xlat18.x = min(u_xlat4.x, u_xlat4.y);
            u_xlat25 = max(u_xlat4.x, u_xlat4.y);
            u_xlatb18 = u_xlat18.x<(-u_xlat18.x);
            u_xlatb25 = u_xlat25>=(-u_xlat25);
            u_xlatb18 = u_xlatb25 && u_xlatb18;
            u_xlat9.x = (u_xlatb18) ? (-u_xlat9.x) : u_xlat9.x;
            u_xlat24 = u_xlat24 * u_xlat24;
            u_xlat2.x = u_xlat9.x * u_xlat2.x;
            u_xlat2.x = u_xlat2.x * 6.28310013;
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 0.100000001 + 1.0;
            u_xlat9.x = u_xlat2.x * u_xlat24;
            u_xlat4.x = dot(u_xlat4.xy, u_xlat4.xy);
            u_xlatb9 = u_xlat4.x<u_xlat9.x;
            u_xlat2.x = (-u_xlat24) * u_xlat2.x + u_xlat4.x;
            u_xlat2.x = log2(abs(u_xlat2.x));
            u_xlat2.x = u_xlat2.x * 0.0625;
            u_xlat2.x = exp2(u_xlat2.x);
            u_xlat2.x = (u_xlatb9) ? 0.200000003 : u_xlat2.x;
            u_xlat9.x = (-u_xlat16) * 0.5 + 1.0;
            u_xlat9.x = u_xlat9.x * 0.200000003 + 0.300000012;
            u_xlat16 = (-u_xlat9.x) + 1.0;
            u_xlat2.x = u_xlat2.x * u_xlat16 + u_xlat9.x;
            u_xlat14.x = u_xlat14.x * u_xlat2.x;
        }
        if(u_xlatb5.z){
            u_xlat4 = u_xlat0.xyxy + float4(44.0, 0.0, 45.0, 0.0);
            u_xlat2.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 43758.5469;
            u_xlat16 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat2.z = u_xlat16 * 43758.5469;
            u_xlat2.xy = fract(u_xlat2.xz);
            u_xlat4.xy = u_xlat0.xy + float2(46.0, 0.0);
            u_xlat16 = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat16 = u_xlat16 * 43758.5469;
            u_xlat16 = fract(u_xlat16);
            u_xlat24 = u_xlat16 * 0.00999999978;
            u_xlat4.xy = u_xlat2.xy + (-in.acScreenNorm.xy);
            u_xlat4.xy = u_xlat4.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
            u_xlat9.x = min(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = max(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = float(1.0) / u_xlat18.x;
            u_xlat9.x = u_xlat9.x * u_xlat18.x;
            u_xlat18.x = u_xlat9.x * u_xlat9.x;
            u_xlat25 = u_xlat18.x * 0.0208350997 + -0.0851330012;
            u_xlat25 = u_xlat18.x * u_xlat25 + 0.180141002;
            u_xlat25 = u_xlat18.x * u_xlat25 + -0.330299497;
            u_xlat18.x = u_xlat18.x * u_xlat25 + 0.999866009;
            u_xlat25 = u_xlat9.x * u_xlat18.x;
            u_xlatb5.x = abs(u_xlat4.x)<abs(u_xlat4.y);
            u_xlat25 = u_xlat25 * -2.0 + 1.57079637;
            u_xlat25 = u_xlatb5.x ? u_xlat25 : float(0.0);
            u_xlat9.x = u_xlat9.x * u_xlat18.x + u_xlat25;
            u_xlatb18 = u_xlat4.x<(-u_xlat4.x);
            u_xlat18.x = u_xlatb18 ? -3.14159274 : float(0.0);
            u_xlat9.x = u_xlat9.x + u_xlat18.x;
            u_xlat18.x = min(u_xlat4.x, u_xlat4.y);
            u_xlat25 = max(u_xlat4.x, u_xlat4.y);
            u_xlatb18 = u_xlat18.x<(-u_xlat18.x);
            u_xlatb25 = u_xlat25>=(-u_xlat25);
            u_xlatb18 = u_xlatb25 && u_xlatb18;
            u_xlat9.x = (u_xlatb18) ? (-u_xlat9.x) : u_xlat9.x;
            u_xlat24 = u_xlat24 * u_xlat24;
            u_xlat2.x = u_xlat9.x * u_xlat2.x;
            u_xlat2.x = u_xlat2.x * 6.28310013;
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 0.100000001 + 1.0;
            u_xlat9.x = u_xlat2.x * u_xlat24;
            u_xlat4.x = dot(u_xlat4.xy, u_xlat4.xy);
            u_xlatb9 = u_xlat4.x<u_xlat9.x;
            u_xlat2.x = (-u_xlat24) * u_xlat2.x + u_xlat4.x;
            u_xlat2.x = log2(abs(u_xlat2.x));
            u_xlat2.x = u_xlat2.x * 0.0625;
            u_xlat2.x = exp2(u_xlat2.x);
            u_xlat2.x = (u_xlatb9) ? 0.200000003 : u_xlat2.x;
            u_xlat9.x = (-u_xlat16) * 0.5 + 1.0;
            u_xlat9.x = u_xlat9.x * 0.200000003 + 0.300000012;
            u_xlat16 = (-u_xlat9.x) + 1.0;
            u_xlat2.x = u_xlat2.x * u_xlat16 + u_xlat9.x;
            u_xlat14.x = u_xlat14.x * u_xlat2.x;
        }
        if(u_xlatb5.w){
            u_xlat4 = u_xlat0.xyxy + float4(63.0, 0.0, 64.0, 0.0);
            u_xlat2.x = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 43758.5469;
            u_xlat16 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat2.z = u_xlat16 * 43758.5469;
            u_xlat2.xy = fract(u_xlat2.xz);
            u_xlat4.xy = u_xlat0.xy + float2(65.0, 0.0);
            u_xlat16 = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat16 = sin(u_xlat16);
            u_xlat16 = u_xlat16 * 43758.5469;
            u_xlat16 = fract(u_xlat16);
            u_xlat24 = u_xlat16 * 0.00999999978;
            u_xlat4.xy = u_xlat2.xy + (-in.acScreenNorm.xy);
            u_xlat4.xy = u_xlat4.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
            u_xlat9.x = min(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = max(abs(u_xlat4.x), abs(u_xlat4.y));
            u_xlat18.x = float(1.0) / u_xlat18.x;
            u_xlat9.x = u_xlat9.x * u_xlat18.x;
            u_xlat18.x = u_xlat9.x * u_xlat9.x;
            u_xlat25 = u_xlat18.x * 0.0208350997 + -0.0851330012;
            u_xlat25 = u_xlat18.x * u_xlat25 + 0.180141002;
            u_xlat25 = u_xlat18.x * u_xlat25 + -0.330299497;
            u_xlat18.x = u_xlat18.x * u_xlat25 + 0.999866009;
            u_xlat25 = u_xlat9.x * u_xlat18.x;
            u_xlatb5.x = abs(u_xlat4.x)<abs(u_xlat4.y);
            u_xlat25 = u_xlat25 * -2.0 + 1.57079637;
            u_xlat25 = u_xlatb5.x ? u_xlat25 : float(0.0);
            u_xlat9.x = u_xlat9.x * u_xlat18.x + u_xlat25;
            u_xlatb18 = u_xlat4.x<(-u_xlat4.x);
            u_xlat18.x = u_xlatb18 ? -3.14159274 : float(0.0);
            u_xlat9.x = u_xlat9.x + u_xlat18.x;
            u_xlat18.x = min(u_xlat4.x, u_xlat4.y);
            u_xlat25 = max(u_xlat4.x, u_xlat4.y);
            u_xlatb18 = u_xlat18.x<(-u_xlat18.x);
            u_xlatb25 = u_xlat25>=(-u_xlat25);
            u_xlatb18 = u_xlatb25 && u_xlatb18;
            u_xlat9.x = (u_xlatb18) ? (-u_xlat9.x) : u_xlat9.x;
            u_xlat24 = u_xlat24 * u_xlat24;
            u_xlat2.x = u_xlat9.x * u_xlat2.x;
            u_xlat2.x = u_xlat2.x * 6.28310013;
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 0.100000001 + 1.0;
            u_xlat9.x = u_xlat2.x * u_xlat24;
            u_xlat4.x = dot(u_xlat4.xy, u_xlat4.xy);
            u_xlatb9 = u_xlat4.x<u_xlat9.x;
            u_xlat2.x = (-u_xlat24) * u_xlat2.x + u_xlat4.x;
            u_xlat2.x = log2(abs(u_xlat2.x));
            u_xlat2.x = u_xlat2.x * 0.0625;
            u_xlat2.x = exp2(u_xlat2.x);
            u_xlat2.x = (u_xlatb9) ? 0.200000003 : u_xlat2.x;
            u_xlat9.x = (-u_xlat16) * 0.5 + 1.0;
            u_xlat9.x = u_xlat9.x * 0.200000003 + 0.300000012;
            u_xlat16 = (-u_xlat9.x) + 1.0;
            u_xlat2.x = u_xlat2.x * u_xlat16 + u_xlat9.x;
            u_xlat14.x = u_xlat14.x * u_xlat2.x;
        }
        u_xlatb21 = 4<u_xlati21;
        if(u_xlatb21){
            u_xlat4 = u_xlat0.xyxy + float4(82.0, 0.0, 83.0, 0.0);
            u_xlat21 = dot(u_xlat4.xy, float2(12.9898005, 78.2330017));
            u_xlat21 = sin(u_xlat21);
            u_xlat21 = u_xlat21 * 43758.5469;
            u_xlat2.x = fract(u_xlat21);
            u_xlat21 = dot(u_xlat4.zw, float2(12.9898005, 78.2330017));
            u_xlat21 = sin(u_xlat21);
            u_xlat21 = u_xlat21 * 43758.5469;
            u_xlat2.y = fract(u_xlat21);
            u_xlat7.xz = u_xlat0.xy + float2(84.0, 0.0);
            u_xlat7.x = dot(u_xlat7.xz, float2(12.9898005, 78.2330017));
            u_xlat7.x = sin(u_xlat7.x);
            u_xlat7.x = u_xlat7.x * 43758.5469;
            u_xlat7.x = fract(u_xlat7.x);
            u_xlat21 = u_xlat7.x * 0.00999999978;
            u_xlat9.xy = u_xlat2.xy + (-in.acScreenNorm.xy);
            u_xlat9.xy = u_xlat9.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
            u_xlat24 = min(abs(u_xlat9.x), abs(u_xlat9.y));
            u_xlat4.x = max(abs(u_xlat9.x), abs(u_xlat9.y));
            u_xlat4.x = float(1.0) / u_xlat4.x;
            u_xlat24 = u_xlat24 * u_xlat4.x;
            u_xlat4.x = u_xlat24 * u_xlat24;
            u_xlat11 = u_xlat4.x * 0.0208350997 + -0.0851330012;
            u_xlat11 = u_xlat4.x * u_xlat11 + 0.180141002;
            u_xlat11 = u_xlat4.x * u_xlat11 + -0.330299497;
            u_xlat4.x = u_xlat4.x * u_xlat11 + 0.999866009;
            u_xlat11 = u_xlat24 * u_xlat4.x;
            u_xlatb18 = abs(u_xlat9.x)<abs(u_xlat9.y);
            u_xlat11 = u_xlat11 * -2.0 + 1.57079637;
            u_xlat11 = u_xlatb18 ? u_xlat11 : float(0.0);
            u_xlat24 = u_xlat24 * u_xlat4.x + u_xlat11;
            u_xlatb4 = u_xlat9.x<(-u_xlat9.x);
            u_xlat4.x = u_xlatb4 ? -3.14159274 : float(0.0);
            u_xlat24 = u_xlat24 + u_xlat4.x;
            u_xlat4.x = min(u_xlat9.x, u_xlat9.y);
            u_xlat11 = max(u_xlat9.x, u_xlat9.y);
            u_xlatb4 = u_xlat4.x<(-u_xlat4.x);
            u_xlatb11 = u_xlat11>=(-u_xlat11);
            u_xlatb4 = u_xlatb11 && u_xlatb4;
            u_xlat24 = (u_xlatb4) ? (-u_xlat24) : u_xlat24;
            u_xlat21 = u_xlat21 * u_xlat21;
            u_xlat2.x = u_xlat2.x * u_xlat24;
            u_xlat2.x = u_xlat2.x * 6.28310013;
            u_xlat2.x = sin(u_xlat2.x);
            u_xlat2.x = u_xlat2.x * 0.100000001 + 1.0;
            u_xlat24 = u_xlat21 * u_xlat2.x;
            u_xlat9.x = dot(u_xlat9.xy, u_xlat9.xy);
            u_xlatb16 = u_xlat9.x<u_xlat24;
            u_xlat21 = (-u_xlat21) * u_xlat2.x + u_xlat9.x;
            u_xlat21 = log2(abs(u_xlat21));
            u_xlat21 = u_xlat21 * 0.0625;
            u_xlat21 = exp2(u_xlat21);
            u_xlat21 = (u_xlatb16) ? 0.200000003 : u_xlat21;
            u_xlat7.x = (-u_xlat7.x) * 0.5 + 1.0;
            u_xlat7.x = u_xlat7.x * 0.200000003 + 0.300000012;
            u_xlat2.x = (-u_xlat7.x) + 1.0;
            u_xlat7.x = u_xlat21 * u_xlat2.x + u_xlat7.x;
            u_xlat14.x = u_xlat7.x * u_xlat14.x;
        }
    }
    u_xlat2.xyz = u_xlat14.xxx * u_xlat3.xyz;
    u_xlat0.xy = u_xlat0.xx * float2(0.00999999978, 0.00999999978) + in.acScreenNorm.xy;
    u_xlat0.x = dot(u_xlat0.xy, float2(12.9898005, 78.2330017));
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 43758.5469;
    u_xlat0.x = fract(u_xlat0.x);
    u_xlat0.x = u_xlat0.x + -0.200000003;
    u_xlat0.x = u_xlat0.x * 0.300000012 + 1.0;
    u_xlat0.xyw = u_xlat0.xxx * u_xlat2.xyz;
    u_xlat0.xyw = (u_xlatb2.w) ? u_xlat0.xyw : u_xlat2.xyz;
    u_xlat1.xyz = u_xlat14.xxx * u_xlat0.xyw;
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat2.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat2.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat1;
    }
    return __nv_out;
    return __nv_out;
}
