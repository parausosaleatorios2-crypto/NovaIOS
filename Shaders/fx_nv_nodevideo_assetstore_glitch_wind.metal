// ---------------------------------------------------------------------------
// Glitch Wind (NV)
// origem : assets/effects/nv-nodevideo-assetstore-glitch-wind.xml
// id     : nv.effect.nodevideo-assetstore-glitch-wind
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_glitch_windParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _strength;
    float _scale;
    float _samples;
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
float3 u_xlat6;
bool u_xlatb6;
float u_xlat12;
int u_xlati12;
bool u_xlatb12;
float u_xlat18;
bool u_xlatb18;

fragment float4 fx_nv_nodevideo_assetstore_glitch_wind(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_glitch_windParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = _cur_time * 0.03125;
    u_xlatb6 = u_xlat0.x>=(-u_xlat0.x);
    u_xlat0.x = fract(abs(u_xlat0.x));
    u_xlat0.x = (u_xlatb6) ? u_xlat0.x : (-u_xlat0.x);
    u_xlat6.x = u._strength;
    u_xlat6.x = clamp(u_xlat6.x, 0.0, 1.0);
    u_xlat1.yw = u_xlat0.xx * float2(32.0, 192.0);
    u_xlat12 = floor(u_xlat1.w);
    u_xlat12 = u_xlat12 * 0.166666672;
    u_xlat12 = dot(float2(u_xlat12), float2(12.9898005, 78.2330017));
    u_xlat12 = sin(u_xlat12);
    u_xlat12 = u_xlat12 * 43758.5469;
    u_xlat12 = fract(u_xlat12);
    u_xlat18 = (-u_xlat6.x) + 1.0;
    u_xlat18 = u_xlat18 * 0.699999988 + u_xlat12;
    u_xlat18 = min(u_xlat18, 1.0);
    u_xlat18 = u_xlat18 * 10.0;
    u_xlat2.xy = float2(u_xlat18) * in.acScreenNorm.xy;
    u_xlat2.xy = floor(u_xlat2.xy);
    u_xlat1.xz = u_xlat2.xy / float2(u_xlat18);
    u_xlat18 = dot(u_xlat1.xy, float2(12.9898005, 78.2330017));
    u_xlat18 = sin(u_xlat18);
    u_xlat18 = u_xlat18 * 43758.5469;
    u_xlat18 = fract(u_xlat18);
    u_xlat6.x = (-u_xlat6.x) * 0.5 + u_xlat18;
    u_xlat6.x = u_xlat6.x + 0.5;
    u_xlatb18 = u_xlat6.x<1.0;
    u_xlat6.x = (-u_xlat6.x) + 1.0;
    u_xlat6.x = u_xlat6.x * 40.0;
    u_xlat6.x = (u_xlatb18) ? u_xlat6.x : 4.76837158e-06;
    u_xlat6.x = u_xlat6.x / u._scale;
    u_xlat18 = u_xlat6.x * in.acScreenNorm.y;
    u_xlat18 = floor(u_xlat18);
    u_xlat1.x = u_xlat18 / u_xlat6.x;
    u_xlat6.x = dot(u_xlat1.xy, float2(12.9898005, 78.2330017));
    u_xlat6.x = sin(u_xlat6.x);
    u_xlat6.x = u_xlat6.x * 43758.5469;
    u_xlat18 = dot(u_xlat1.zy, float2(12.9898005, 78.2330017));
    u_xlat18 = sin(u_xlat18);
    u_xlat6.z = u_xlat18 * 43758.5469;
    u_xlat6.xz = fract(u_xlat6.xz);
    u_xlat18 = u_xlat6.z + 0.800000012;
    u_xlat18 = min(u_xlat18, 1.0);
    u_xlat18 = (-u_xlat18) + 0.899999976;
    u_xlat1.xy = u_xlat0.xx * float2(32.0, 32.0) + in.acScreenNorm.xy;
    u_xlat0.x = dot(u_xlat1.xy, float2(12.9898005, 78.2330017));
    u_xlat0.x = sin(u_xlat0.x);
    u_xlat0.x = u_xlat0.x * 43758.5469;
    u_xlat0.x = fract(u_xlat0.x);
    u_xlat6.x = u_xlat6.x * u._strength;
    u_xlat6.x = u_xlat6.x * 0.0500000007;
    u_xlatb12 = 0.5<u_xlat12;
    u_xlat12 = (u_xlatb12) ? 1.0 : -1.0;
    u_xlat6.x = u_xlat12 * u_xlat6.x;
    u_xlat0.x = u_xlat0.x * u_xlat6.x;
    u_xlat0.x = u_xlat0.x * 0.5 + u_xlat6.x;
    u_xlat6.x = u_xlat18 * u._strength;
    u_xlat1.y = u_xlat6.x * 0.100000001 + in.acScreenNorm.y;
    u_xlat6.x = float(int(u._samples));
    u_xlat6.x = float(1.0) / u_xlat6.x;
    u_xlat3.x = float(0.0);
    u_xlat3.y = float(0.0);
    u_xlat3.z = float(0.0);
    u_xlat1.x = in.acScreenNorm.x;
    u_xlat2.x = float(0.0);
    u_xlat2.y = float(0.0);
    u_xlat2.z = float(0.0);
    u_xlat2.w = float(0.0);
    for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
    {
        u_xlat18 = float(u_xlati_loop_1);
        u_xlat18 = u_xlat6.x * u_xlat18;
        u_xlat1.x = u_xlat0.x * u_xlat18 + u_xlat1.x;
        u_xlat1.x = clamp(u_xlat1.x, 0.0, 1.0);
        u_xlat4 = inputImg.sample(__nv_smp, u_xlat1.xy);
        u_xlat5.z = u_xlat18 * 3.0 + -1.5;
        u_xlat5.y = -abs(u_xlat5.z) + 1.0;
        u_xlat5.x = (-u_xlat5.z);
        u_xlat5.xyz = u_xlat5.xyz;
        u_xlat5.xyz = clamp(u_xlat5.xyz, 0.0, 1.0);
        u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
        u_xlat2 = u_xlat2 + u_xlat4;
        u_xlat3.xyz = u_xlat3.xyz + u_xlat5.xyz;
    }
    u_xlat1.xyz = u_xlat2.xyz / u_xlat3.xyz;
    u_xlat1.w = u_xlat6.x * u_xlat2.w;
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
