// ---------------------------------------------------------------------------
// Effect Distort Wave Warp (NV)
// origem : assets/effects/nv-nodevideo-effect-distort-wave-warp.xml
// id     : nv.effect.nodevideo-effect-distort-wave-warp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_distort_wave_warpParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _width;
    float _height;
    float _phase;
    float _direction;
    float _speed;
    float _type;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float3 u_xlat7;
float3 u_xlat8;
float2 u_xlat10;
bool2 u_xlatb10;
float u_xlat11;
float2 u_xlat18;
float2 u_xlat20;
float2 u_xlat21;
float u_xlat27;
bool u_xlatb27;
float u_xlat28;
bool u_xlatb28;

fragment float4 fx_nv_nodevideo_effect_distort_wave_warp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_distort_wave_warpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat1.xy = in.acScreenNorm.xy * float2(_viewport_ratio.x, _viewport_ratio.y) + float2(-0.5, -0.5);
    u_xlat1.z = _cur_time * u._speed + u_xlat1.y;
    u_xlat18.xy = float2(u._height, u._direction) * float2(0.100000001, 0.0174532942);
    u_xlat2.x = sin(u_xlat18.y);
    u_xlat3.x = cos(u_xlat18.y);
    u_xlat3.y = u_xlat2.x;
    u_xlat27 = dot(u_xlat3.yx, u_xlat1.xz);
    u_xlat27 = u_xlat27 + 0.5;
    u_xlat27 = u_xlat27 / _viewport_ratio.xxxy.w;
    u_xlatb1 = int(u._keep_edge)==1;
    if(int(u._type) == 0) {
        u_xlat10.x = u._width * 0.0500000007;
        u_xlat10.x = u_xlat27 / u_xlat10.x;
        u_xlat10.x = u_xlat10.x + u._phase;
        u_xlat10.x = sin(u_xlat10.x);
        u_xlat10.xy = u_xlat10.xx * u_xlat3.xy;
        u_xlat10.xy = u_xlat10.xy * u_xlat18.xx + u_xlat0.xy;
    } else {
        u_xlatb28 = int(u._type)==1;
        if(u_xlatb28){
            u_xlat28 = u._width * 0.0500000007;
            u_xlat28 = u_xlat27 / u_xlat28;
            u_xlat28 = floor(u_xlat28);
            u_xlat2.x = u._phase + 1.5;
            u_xlat28 = u_xlat28 * u_xlat2.x;
            u_xlat28 = fract(u_xlat28);
            u_xlat28 = (-u_xlat28) + 0.25;
            u_xlat2.xy = float2(u_xlat28) * u_xlat3.xy;
            u_xlat10.xy = u_xlat2.xy * u_xlat18.xx + u_xlat0.xy;
        } else {
            u_xlatb28 = int(u._type)==2;
            if(u_xlatb28){
                u_xlat28 = u._width * 0.0500000007;
                u_xlat28 = u_xlat27 / u_xlat28;
                u_xlat2.x = fract(u_xlat28);
                u_xlat11 = u._phase + 2.0;
                u_xlat2.x = u_xlat2.x * u_xlat11 + -1.0;
                u_xlat2.x = -abs(u_xlat2.x) + 0.5;
                u_xlat28 = floor(u_xlat28);
                u_xlat28 = u_xlat11 * u_xlat28;
                u_xlat28 = fract(u_xlat28);
                u_xlat28 = (-u_xlat28) + 0.5;
                u_xlat28 = u_xlat28 * u_xlat2.x;
                u_xlat2.xy = float2(u_xlat28) * u_xlat3.xy;
                u_xlat10.xy = u_xlat2.xy * u_xlat18.xx + u_xlat0.xy;
            } else {
                u_xlatb28 = int(u._type)==3;
                if(u_xlatb28){
                    u_xlat28 = u._width * 0.0500000007;
                    u_xlat28 = u_xlat27 / u_xlat28;
                    u_xlat2.x = u._phase + 1.5;
                    u_xlat28 = u_xlat28 * u_xlat2.x;
                    u_xlat28 = fract(u_xlat28);
                    u_xlat28 = (-u_xlat28) + 0.5;
                    u_xlat2.xy = float2(u_xlat28) * u_xlat3.xy;
                    u_xlat10.xy = u_xlat2.xy * u_xlat18.xx + u_xlat0.xy;
                } else {
                    u_xlatb28 = int(u._type)==4;
                    if(u_xlatb28){
                        u_xlat28 = u._width * 0.0500000007;
                        u_xlat2.x = u_xlat27 / u_xlat28;
                        u_xlat2.y = u._phase;
                        u_xlat28 = dot(u_xlat2.xy, float2(12.9898005, 78.2330017));
                        u_xlat28 = sin(u_xlat28);
                        u_xlat28 = u_xlat28 * 43758.5469;
                        u_xlat28 = fract(u_xlat28);
                        u_xlat28 = u_xlat28 + -0.5;
                        u_xlat2.xy = float2(u_xlat28) * u_xlat3.xy;
                        u_xlat10.xy = u_xlat2.xy * u_xlat18.xx + u_xlat0.xy;
                    } else {
                        u_xlatb28 = int(u._type)==5;
                        u_xlat2.x = u._width * 0.0500000007;
                        u_xlat2.x = u_xlat27 / u_xlat2.x;
                        u_xlat2.y = u._phase;
                        u_xlat27 = dot(u_xlat2.xy, float2(0.366025418, 0.366025418));
                        u_xlat20.xy = float2(u_xlat27) + u_xlat2.xy;
                        u_xlat20.xy = floor(u_xlat20.xy);
                        u_xlat2.xy = (-u_xlat20.xy) + u_xlat2.xy;
                        u_xlat27 = dot(u_xlat20.xy, float2(0.211324871, 0.211324871));
                        u_xlat2.xy = float2(u_xlat27) + u_xlat2.xy;
                        u_xlatb27 = u_xlat2.y<u_xlat2.x;
                        u_xlat4 = u_xlat2.xyxy + float4(0.211324871, 0.211324871, -0.577350259, -0.577350259);
                        u_xlat5 = (bool(u_xlatb27)) ? float4(0.0, 1.0, -1.0, -0.0) : float4(1.0, 0.0, -0.0, -1.0);
                        u_xlat4.xy = u_xlat4.xy + u_xlat5.zw;
                        u_xlat21.xy = u_xlat20.xy * float2(0.00346020772, 0.00346020772);
                        u_xlat21.xy = floor(u_xlat21.xy);
                        u_xlat20.xy = (-u_xlat21.xy) * float2(289.0, 289.0) + u_xlat20.xy;
                        u_xlat6.x = float(0.0);
                        u_xlat6.z = float(1.0);
                        u_xlat6.y = u_xlat5.x;
                        u_xlat6.xyz = u_xlat20.yyy + u_xlat6.xyz;
                        u_xlat7.xyz = u_xlat6.xyz * u_xlat6.xyz;
                        u_xlat6.xyz = u_xlat7.xyz * float3(34.0, 34.0, 34.0) + u_xlat6.xyz;
                        u_xlat7.xyz = u_xlat6.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
                        u_xlat7.xyz = floor(u_xlat7.xyz);
                        u_xlat6.xyz = (-u_xlat7.xyz) * float3(289.0, 289.0, 289.0) + u_xlat6.xyz;
                        u_xlat6.xyz = u_xlat20.xxx + u_xlat6.xyz;
                        u_xlat5.x = float(0.0);
                        u_xlat5.z = float(1.0);
                        u_xlat5.xyz = u_xlat5.xyz + u_xlat6.xyz;
                        u_xlat6.xyz = u_xlat5.xyz * u_xlat5.xyz;
                        u_xlat5.xyz = u_xlat6.xyz * float3(34.0, 34.0, 34.0) + u_xlat5.xyz;
                        u_xlat6.xyz = u_xlat5.xyz * float3(0.00346020772, 0.00346020772, 0.00346020772);
                        u_xlat6.xyz = floor(u_xlat6.xyz);
                        u_xlat5.xyz = (-u_xlat6.xyz) * float3(289.0, 289.0, 289.0) + u_xlat5.xyz;
                        u_xlat6.x = dot(u_xlat2.xy, u_xlat2.xy);
                        u_xlat6.y = dot(u_xlat4.xy, u_xlat4.xy);
                        u_xlat6.z = dot(u_xlat4.zw, u_xlat4.zw);
                        u_xlat6.xyz = (-u_xlat6.xyz) + float3(0.5, 0.5, 0.5);
                        u_xlat6.xyz = max(u_xlat6.xyz, float3(0.0, 0.0, 0.0));
                        u_xlat6.xyz = u_xlat6.xyz * u_xlat6.xyz;
                        u_xlat6.xyz = u_xlat6.xyz * u_xlat6.xyz;
                        u_xlat5.xyz = u_xlat5.xyz * float3(0.024390243, 0.024390243, 0.024390243);
                        u_xlat5.xyz = fract(u_xlat5.xyz);
                        u_xlat7.xyz = u_xlat5.xyz * float3(2.0, 2.0, 2.0) + float3(-1.0, -1.0, -1.0);
                        u_xlat8.xyz = abs(u_xlat7.xyz) + float3(-0.5, -0.5, -0.5);
                        u_xlat5.xyz = u_xlat5.xyz * float3(2.0, 2.0, 2.0) + float3(-0.5, -0.5, -0.5);
                        u_xlat5.xyz = floor(u_xlat5.xyz);
                        u_xlat5.xyz = (-u_xlat5.xyz) + u_xlat7.xyz;
                        u_xlat7.xyz = u_xlat8.xyz * u_xlat8.xyz;
                        u_xlat7.xyz = u_xlat5.xyz * u_xlat5.xyz + u_xlat7.xyz;
                        u_xlat7.xyz = (-u_xlat7.xyz) * float3(0.853734732, 0.853734732, 0.853734732) + float3(1.79284286, 1.79284286, 1.79284286);
                        u_xlat6.xyz = u_xlat6.xyz * u_xlat7.xyz;
                        u_xlat27 = u_xlat2.y * u_xlat8.x;
                        u_xlat2.x = u_xlat5.x * u_xlat2.x + u_xlat27;
                        u_xlat21.xy = u_xlat4.yw * u_xlat8.yz;
                        u_xlat2.yz = u_xlat5.yz * u_xlat4.xz + u_xlat21.xy;
                        u_xlat27 = dot(u_xlat6.xyz, u_xlat2.xyz);
                        u_xlat27 = u_xlat27 * 130.0;
                        u_xlat2.xy = float2(u_xlat27) * u_xlat3.xy;
                        u_xlat18.xy = u_xlat2.xy * u_xlat18.xx + u_xlat0.xy;
                        u_xlat10.xy = (bool(u_xlatb28)) ? u_xlat18.xy : u_xlat0.xy;
                    }
                }
            }
        }
    }
    u_xlat0.xy = u_xlat10.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlatb10.xy = lessThan(u_xlat0.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat0.xyxx).xy;
    u_xlatb27 = u_xlatb10.x || u_xlatb2.x;
    u_xlatb27 = u_xlatb10.y || u_xlatb27;
    u_xlatb27 = u_xlatb2.y || u_xlatb27;
    u_xlat0.z = (u_xlatb27) ? 0.0 : 1.0;
    u_xlat20.xy = fract(u_xlat0.xy);
    u_xlat20.xy = (-u_xlat20.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat20.x : u_xlat0.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat20.y : u_xlat0.y;
    {
        float3 hlslcc_movcTemp = u_xlat2;
        hlslcc_movcTemp.x = (u_xlatb10.x) ? (-u_xlat0.x) : u_xlat2.x;
        hlslcc_movcTemp.y = (u_xlatb10.y) ? (-u_xlat0.y) : u_xlat2.y;
        u_xlat2 = hlslcc_movcTemp;
    }
    u_xlat2.z = 1.0;
    u_xlat0.xyz = (bool(u_xlatb1)) ? u_xlat2.xyz : u_xlat0.xyz;
    u_xlat1 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat0 = u_xlat0.zzzz * u_xlat1;
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
