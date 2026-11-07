// ---------------------------------------------------------------------------
// Glitch Line (NV)
// origem : assets/effects/nv-nodevideo-assetstore-glitch-line.xml
// id     : nv.effect.nodevideo-assetstore-glitch-line
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_glitch_lineParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _amount;
    float _speed;
    float _width;
    float _offset;
    float _rgb_shift;
    float _direction;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
float3 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
float4 u_xlat3;
bool3 u_xlatb3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float2 u_xlat12;
int u_xlati12;
bool u_xlatb12;
float u_xlat18;
int u_xlati18;

fragment float4 fx_nv_nodevideo_assetstore_glitch_line(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_glitch_lineParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(int(u._direction) == 0) {
        u_xlat0.x = _cur_time * u._speed;
        u_xlat6.x = u_xlat0.x * 4.0;
        u_xlat6.y = in.acScreenNorm.y * 8.0;
        u_xlat6.xy = floor(u_xlat6.xy);
        u_xlat6.x = u_xlat6.x * 25.0;
        u_xlat6.x = u_xlat6.y * 0.125 + u_xlat6.x;
        u_xlat6.x = dot(u_xlat6.xx, float2(12.9898005, 78.2330017));
        u_xlat6.x = sin(u_xlat6.x);
        u_xlat6.x = u_xlat6.x * 43758.5469;
        u_xlat6.x = fract(u_xlat6.x);
        u_xlat6.x = u_xlat6.x * 24.0;
        u_xlat0.x = u_xlat6.x * u_xlat0.x;
        u_xlat0.x = floor(u_xlat0.x);
        u_xlat0.x = u_xlat0.x / u_xlat6.x;
        u_xlat6.x = u._width * -9.98999977 + 10.0;
        u_xlat0.x = u_xlat0.x * 6.0 + in.acScreenNorm.y;
        u_xlat6.x = u_xlat6.x * 8.0;
        u_xlat12.x = u_xlat6.x * u_xlat0.x;
        u_xlat12.x = floor(u_xlat12.x);
        u_xlat6.x = u_xlat12.x / u_xlat6.x;
        u_xlat6.x = dot(u_xlat6.xx, float2(12.9898005, 78.2330017));
        u_xlat0.y = sin(u_xlat6.x);
        u_xlat0.xy = u_xlat0.xy * float2(7.0, 43758.5469);
        u_xlat0.x = floor(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 0.142857149;
        u_xlat0.x = dot(u_xlat0.xx, float2(12.9898005, 78.2330017));
        u_xlat0.x = sin(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 43758.5469;
        u_xlat0.xy = fract(u_xlat0.xy);
        u_xlat0.x = u_xlat0.x * 0.5;
        u_xlat0.x = u_xlat0.y * 0.5 + u_xlat0.x;
        u_xlat0.x = u_xlat0.x * 2.0 + -1.0;
        u_xlat6.x = (-u._amount) + 1.0;
        u_xlati12 = int((0.0<u_xlat0.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati18 = int((u_xlat0.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati12 = (-u_xlati12) + u_xlati18;
        u_xlat12.x = float(u_xlati12);
        u_xlat0.x = (-u_xlat6.x) + abs(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 2.5;
        u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
        u_xlat0.x = u_xlat0.x * u_xlat12.x;
        u_xlat6.x = u_xlat0.x * u._offset;
        u_xlat1.xy = u_xlat6.xx * float2(0.100000001, 0.324999988);
        u_xlat1.z = 0.0;
        u_xlat12.xy = u_xlat1.xz + in.acScreenNorm.xy;
        u_xlat12.xy = clamp(u_xlat12.xy, 0.0, 1.0);
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
        u_xlatb12 = u_xlat2.y>=u_xlat2.z;
        u_xlat12.x = u_xlatb12 ? 1.0 : float(0.0);
        u_xlat3.xy = u_xlat2.zy;
        u_xlat3.z = float(-1.0);
        u_xlat3.w = float(0.666666687);
        u_xlat4.xy = u_xlat2.yz + (-u_xlat3.xy);
        u_xlat4.z = float(1.0);
        u_xlat4.w = float(-1.0);
        u_xlat3 = u_xlat12.xxxx * u_xlat4 + u_xlat3;
        u_xlatb12 = u_xlat2.x>=u_xlat3.x;
        u_xlat12.x = u_xlatb12 ? 1.0 : float(0.0);
        u_xlat4.xyz = u_xlat3.xyw;
        u_xlat4.w = u_xlat2.x;
        u_xlat3.xyw = u_xlat4.wyx;
        u_xlat3 = (-u_xlat4) + u_xlat3;
        u_xlat3 = u_xlat12.xxxx * u_xlat3 + u_xlat4;
        u_xlat12.x = min(u_xlat3.y, u_xlat3.w);
        u_xlat12.x = (-u_xlat12.x) + u_xlat3.x;
        u_xlat18 = (-u_xlat3.y) + u_xlat3.w;
        u_xlat1.x = u_xlat12.x * 6.0 + 1.00000001e-10;
        u_xlat18 = u_xlat18 / u_xlat1.x;
        u_xlat18 = u_xlat18 + u_xlat3.z;
        u_xlat1.x = u_xlat3.x + 1.00000001e-10;
        u_xlat12.x = u_xlat12.x / u_xlat1.x;
        u_xlat6.x = abs(u_xlat6.x) * 3.0;
        u_xlat1.x = (-u._offset) * u_xlat0.x + 0.5;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat6.x = (-u_xlat6.x) * u_xlat1.x + 1.0;
        u_xlat6.x = abs(u_xlat18) / u_xlat6.x;
        u_xlat0.x = u._offset * u_xlat0.x + -0.5;
        u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
        u_xlat0.x = u_xlat1.y * u_xlat0.x + u_xlat3.x;
        u_xlat1.xyz = u_xlat6.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
        u_xlat1.xyz = u_xlat1.xyz * float3(0.166666672, 0.166666672, 0.166666672);
        u_xlatb3.xyz = greaterThanEqual(u_xlat1.xyzx, (-u_xlat1.xyzx)).xyz;
        u_xlat1.xyz = fract(abs(u_xlat1.xyz));
        {
            float3 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat1.x : (-u_xlat1.x);
            hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat1.y : (-u_xlat1.y);
            hlslcc_movcTemp.z = (u_xlatb3.z) ? u_xlat1.z : (-u_xlat1.z);
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat1.xyz = u_xlat1.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
        u_xlat1.xyz = abs(u_xlat1.xyz) + float3(-1.0, -1.0, -1.0);
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat1.xyz = u_xlat1.xyz + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = u_xlat12.xxx * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
        u_xlat0.xyz = u_xlat0.xxx * u_xlat6.xyz + (-u_xlat2.xyz);
        u_xlat2.xyz = float3(u._rgb_shift) * u_xlat0.xyz + u_xlat2.xyz;
    } else {
        u_xlat0.x = _cur_time * u._speed;
        u_xlat6.x = u_xlat0.x * 4.0;
        u_xlat6.y = in.acScreenNorm.x * 8.0;
        u_xlat6.xy = floor(u_xlat6.xy);
        u_xlat6.x = u_xlat6.x * 25.0;
        u_xlat6.x = u_xlat6.y * 0.125 + u_xlat6.x;
        u_xlat6.x = dot(u_xlat6.xx, float2(12.9898005, 78.2330017));
        u_xlat6.x = sin(u_xlat6.x);
        u_xlat6.x = u_xlat6.x * 43758.5469;
        u_xlat6.x = fract(u_xlat6.x);
        u_xlat6.x = u_xlat6.x * 24.0;
        u_xlat0.x = u_xlat6.x * u_xlat0.x;
        u_xlat0.x = floor(u_xlat0.x);
        u_xlat0.x = u_xlat0.x / u_xlat6.x;
        u_xlat0.x = u_xlat0.x * 6.0 + in.acScreenNorm.x;
        u_xlat6.x = u._width * 8.0;
        u_xlat12.x = u_xlat6.x * u_xlat0.x;
        u_xlat12.x = floor(u_xlat12.x);
        u_xlat6.x = u_xlat12.x / u_xlat6.x;
        u_xlat6.x = dot(u_xlat6.xx, float2(12.9898005, 78.2330017));
        u_xlat0.y = sin(u_xlat6.x);
        u_xlat0.xy = u_xlat0.xy * float2(7.0, 43758.5469);
        u_xlat0.x = floor(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 0.142857149;
        u_xlat0.x = dot(u_xlat0.xx, float2(12.9898005, 78.2330017));
        u_xlat0.x = sin(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 43758.5469;
        u_xlat0.xy = fract(u_xlat0.xy);
        u_xlat0.x = u_xlat0.x * 0.5;
        u_xlat0.x = u_xlat0.y * 0.5 + u_xlat0.x;
        u_xlat0.x = u_xlat0.x * 2.0 + -1.0;
        u_xlat6.x = (-u._amount) + 1.0;
        u_xlati12 = int((0.0<u_xlat0.x) ? 0xFFFFFFFFu : uint(0));
        u_xlati18 = int((u_xlat0.x<0.0) ? 0xFFFFFFFFu : uint(0));
        u_xlati12 = (-u_xlati12) + u_xlati18;
        u_xlat12.x = float(u_xlati12);
        u_xlat0.x = (-u_xlat6.x) + abs(u_xlat0.x);
        u_xlat0.x = u_xlat0.x * 2.5;
        u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
        u_xlat0.x = u_xlat0.x * u_xlat12.x;
        u_xlat6.x = u_xlat0.x * u._offset;
        u_xlat1.xy = u_xlat6.xx * float2(0.100000001, 0.324999988);
        u_xlat1.z = 0.0;
        u_xlat12.xy = u_xlat1.zx + in.acScreenNorm.xy;
        u_xlat12.xy = clamp(u_xlat12.xy, 0.0, 1.0);
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
        u_xlatb12 = u_xlat2.y>=u_xlat2.z;
        u_xlat12.x = u_xlatb12 ? 1.0 : float(0.0);
        u_xlat3.xy = u_xlat2.zy;
        u_xlat3.z = float(-1.0);
        u_xlat3.w = float(0.666666687);
        u_xlat4.xy = u_xlat2.yz + (-u_xlat3.xy);
        u_xlat4.z = float(1.0);
        u_xlat4.w = float(-1.0);
        u_xlat3 = u_xlat12.xxxx * u_xlat4 + u_xlat3;
        u_xlatb12 = u_xlat2.x>=u_xlat3.x;
        u_xlat12.x = u_xlatb12 ? 1.0 : float(0.0);
        u_xlat4.xyz = u_xlat3.xyw;
        u_xlat4.w = u_xlat2.x;
        u_xlat3.xyw = u_xlat4.wyx;
        u_xlat3 = (-u_xlat4) + u_xlat3;
        u_xlat3 = u_xlat12.xxxx * u_xlat3 + u_xlat4;
        u_xlat12.x = min(u_xlat3.y, u_xlat3.w);
        u_xlat12.x = (-u_xlat12.x) + u_xlat3.x;
        u_xlat18 = (-u_xlat3.y) + u_xlat3.w;
        u_xlat1.x = u_xlat12.x * 6.0 + 1.00000001e-10;
        u_xlat18 = u_xlat18 / u_xlat1.x;
        u_xlat18 = u_xlat18 + u_xlat3.z;
        u_xlat1.x = u_xlat3.x + 1.00000001e-10;
        u_xlat12.x = u_xlat12.x / u_xlat1.x;
        u_xlat6.x = abs(u_xlat6.x) * 3.0;
        u_xlat1.x = (-u._offset) * u_xlat0.x + 0.5;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat6.x = (-u_xlat6.x) * u_xlat1.x + 1.0;
        u_xlat6.x = abs(u_xlat18) / u_xlat6.x;
        u_xlat0.x = u._offset * u_xlat0.x + -0.5;
        u_xlat0.x = clamp(u_xlat0.x, 0.0, 1.0);
        u_xlat0.x = u_xlat1.y * u_xlat0.x + u_xlat3.x;
        u_xlat1.xyz = u_xlat6.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
        u_xlat1.xyz = u_xlat1.xyz * float3(0.166666672, 0.166666672, 0.166666672);
        u_xlatb3.xyz = greaterThanEqual(u_xlat1.xyzx, (-u_xlat1.xyzx)).xyz;
        u_xlat1.xyz = fract(abs(u_xlat1.xyz));
        {
            float3 hlslcc_movcTemp = u_xlat1;
            hlslcc_movcTemp.x = (u_xlatb3.x) ? u_xlat1.x : (-u_xlat1.x);
            hlslcc_movcTemp.y = (u_xlatb3.y) ? u_xlat1.y : (-u_xlat1.y);
            hlslcc_movcTemp.z = (u_xlatb3.z) ? u_xlat1.z : (-u_xlat1.z);
            u_xlat1 = hlslcc_movcTemp;
        }
        u_xlat1.xyz = u_xlat1.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
        u_xlat1.xyz = abs(u_xlat1.xyz) + float3(-1.0, -1.0, -1.0);
        u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
        u_xlat1.xyz = u_xlat1.xyz + float3(-1.0, -1.0, -1.0);
        u_xlat6.xyz = u_xlat12.xxx * u_xlat1.xyz + float3(1.0, 1.0, 1.0);
        u_xlat0.xyz = u_xlat0.xxx * u_xlat6.xyz + (-u_xlat2.xyz);
        u_xlat2.xyz = float3(u._rgb_shift) * u_xlat0.xyz + u_xlat2.xyz;
    }
    if(int(u._use_inner_mask) != 0) {
        u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat3 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat2;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat0 = u_xlat0 * u_xlat5;
        u_xlat0 = u_xlat3 * u_xlat4 + u_xlat0;
        u_xlat1.x = u_xlat4.x * u_xlat0.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat1.x : u_xlat0.w;
        __nv_out.xyz = u_xlat0.xyz;
    } else {
        __nv_out = u_xlat2;
    }
    return __nv_out;
    return __nv_out;
}
