// ---------------------------------------------------------------------------
// Glitch Wave (NV)
// origem : assets/effects/nv-nodevideo-assetstore-glitch-wave.xml
// id     : nv.effect.nodevideo-assetstore-glitch-wave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_glitch_waveParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float2 _strength;
    float _scale;
    float _speed;
    float _rgb_shift;
    float _type;
    float _direction;
    float _keep_edge;
};

// --- funcoes auxiliares do efeito
// tempo do Node ligado ao motor (tools/nodevideo/ligar_tempo.py)
#define _cur_time eng.acTime
float4 u_xlat0;
bool u_xlatb0;
float2 u_xlat1;
bool2 u_xlatb1;
float2 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float4 u_xlat6;
float2 u_xlat7;
float2 u_xlat15;
bool2 u_xlatb15;
float2 u_xlat16;
bool2 u_xlatb16;
bool u_xlatb21;

fragment float4 fx_nv_nodevideo_assetstore_glitch_wave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_glitch_waveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> texture0 [[texture(1)]],
    texture2d<float> texture1 [[texture(2)]],
    texture2d<float> texture2 [[texture(3)]],
    texture2d<float> texture3 [[texture(4)]],
    texture2d<float> Mask [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = int(u._keep_edge)==1;
    if(int(u._direction) == 0) {
        u_xlat1.x = in.acScreenNorm.y / u._scale;
        u_xlat1.y = _cur_time * u._speed;
        if(int(u._type) == 0) {
            u_xlat7.xy = texture0.sample(__nv_smp, u_xlat1.xy).xy;
        } else {
            u_xlatb21 = int(u._type)==1;
            if(u_xlatb21){
                u_xlat7.xy = texture1.sample(__nv_smp, u_xlat1.xy).xy;
            } else {
                u_xlatb21 = int(u._type)==2;
                if(u_xlatb21){
                    u_xlat7.xy = texture2.sample(__nv_smp, u_xlat1.xy).xy;
                } else {
                    u_xlat7.xy = texture3.sample(__nv_smp, u_xlat1.xy).xy;
                }
            }
        }
        u_xlat7.xy = u_xlat7.xy + float2(-0.5, -0.5);
    } else {
        u_xlat1.x = _cur_time * u._speed;
        u_xlat1.y = in.acScreenNorm.x / u._scale;
        if(int(u._type) == 0) {
            u_xlat15.xy = texture0.sample(__nv_smp, u_xlat1.xy).xy;
        } else {
            u_xlatb21 = int(u._type)==1;
            if(u_xlatb21){
                u_xlat15.xy = texture1.sample(__nv_smp, u_xlat1.xy).xy;
            } else {
                u_xlatb21 = int(u._type)==2;
                if(u_xlatb21){
                    u_xlat15.xy = texture2.sample(__nv_smp, u_xlat1.xy).xy;
                } else {
                    u_xlat15.xy = texture3.sample(__nv_smp, u_xlat1.xy).xy;
                }
            }
        }
        u_xlat7.xy = u_xlat15.xy + float2(-0.5, -0.5);
    }
    u_xlat7.xy = u_xlat7.xy * u._strength.xy;
    u_xlat1.xy = u_xlat7.xy * float2(0.200000003, 0.200000003);
    u_xlat7.xy = u_xlat7.xy * float2(0.200000003, 0.200000003) + in.acScreenNorm.xy;
    u_xlatb15.xy = lessThan(u_xlat7.xyxy, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb2.xy = lessThan(float4(1.0, 1.0, 0.0, 0.0), u_xlat7.xyxx).xy;
    u_xlat16.xy = fract(u_xlat7.xy);
    u_xlat16.xy = (-u_xlat16.xy) + float2(1.0, 1.0);
    u_xlat2.x = (u_xlatb2.x) ? u_xlat16.x : u_xlat7.x;
    u_xlat2.y = (u_xlatb2.y) ? u_xlat16.y : u_xlat7.y;
    u_xlat15.x = (u_xlatb15.x) ? (-u_xlat7.x) : u_xlat2.x;
    u_xlat15.y = (u_xlatb15.y) ? (-u_xlat7.y) : u_xlat2.y;
    u_xlat15.xy = (bool(u_xlatb0)) ? u_xlat15.xy : u_xlat7.xy;
    u_xlat15.xy = inputImg.sample(__nv_smp, u_xlat15.xy).xw;
    u_xlat7.xy = u_xlat1.xy * float2(u._rgb_shift) + u_xlat7.xy;
    u_xlatb2.xy = lessThan(u_xlat7.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb16.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat7.xyxy).xy;
    u_xlat3.xy = fract(u_xlat7.xy);
    u_xlat3.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
    u_xlat16.x = (u_xlatb16.x) ? u_xlat3.x : u_xlat7.x;
    u_xlat16.y = (u_xlatb16.y) ? u_xlat3.y : u_xlat7.y;
    u_xlat2.x = (u_xlatb2.x) ? (-u_xlat7.x) : u_xlat16.x;
    u_xlat2.y = (u_xlatb2.y) ? (-u_xlat7.y) : u_xlat16.y;
    u_xlat2.xy = (bool(u_xlatb0)) ? u_xlat2.xy : u_xlat7.xy;
    u_xlat2.xy = inputImg.sample(__nv_smp, u_xlat2.xy).yw;
    u_xlat7.xy = u_xlat1.xy * float2(u._rgb_shift) + u_xlat7.xy;
    u_xlatb1.xy = lessThan(u_xlat7.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb16.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat7.xyxy).xy;
    u_xlat3.xy = fract(u_xlat7.xy);
    u_xlat3.xy = (-u_xlat3.xy) + float2(1.0, 1.0);
    u_xlat16.x = (u_xlatb16.x) ? u_xlat3.x : u_xlat7.x;
    u_xlat16.y = (u_xlatb16.y) ? u_xlat3.y : u_xlat7.y;
    u_xlat1.x = (u_xlatb1.x) ? (-u_xlat7.x) : u_xlat16.x;
    u_xlat1.y = (u_xlatb1.y) ? (-u_xlat7.y) : u_xlat16.y;
    u_xlat0.xy = (bool(u_xlatb0)) ? u_xlat1.xy : u_xlat7.xy;
    u_xlat0.zw = inputImg.sample(__nv_smp, u_xlat0.xy).zw;
    u_xlat1.x = max(u_xlat0.w, u_xlat2.y);
    u_xlat0.w = max(u_xlat1.x, u_xlat15.y);
    if(int(u._use_inner_mask) != 0) {
        u_xlat3 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlatb1.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat0.x = u_xlat15.x;
        u_xlat0.y = u_xlat2.x;
        u_xlat4 = (u_xlatb1.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat0;
        u_xlat5 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat6 = (-u_xlat5) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat3 = u_xlat3 * u_xlat6;
        u_xlat3 = u_xlat4 * u_xlat5 + u_xlat3;
        u_xlat0.x = u_xlat5.x * u_xlat3.w;
        __nv_out.w = (u_xlatb1.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.x = u_xlat15.x;
        __nv_out.y = u_xlat2.x;
        __nv_out.zw = u_xlat0.zw;
    }
    return __nv_out;
    return __nv_out;
}
