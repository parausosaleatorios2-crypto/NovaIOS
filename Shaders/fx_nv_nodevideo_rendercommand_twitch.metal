// ---------------------------------------------------------------------------
// Rendercommand Twitch (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-twitch.xml
// id     : nv.effect.nodevideo-rendercommand-twitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_twitchParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _zoom;
    float _enable_motion_blur;
    float _samples;
    float _length;
    float _dispersion;
    float _enable_exposure;
    float _exposure_strength;
    float _enable_lumafade;
    float _lumafade_strength;
    float _lumafade_inensity;
    float4 _cur_shake;
    float4 _prev_shake;
    float _texture_wrap_mode;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _viewport_ratio eng.acProporcaoDoNode
float4 u_xlat0;
float4 u_xlat1;
bool2 u_xlatb1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
float u_xlat7;
int u_xlati7;
bool u_xlatb7;
float2 u_xlat10;
float2 u_xlat12;
float u_xlat13;
int u_xlati13;
bool2 u_xlatb13;
int u_xlati19;
bool u_xlatb22;

fragment float4 fx_nv_nodevideo_rendercommand_twitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_twitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> SourceTexMirror [[texture(1)]],
    texture2d<float> Mask [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
    u_xlat0.xy = u_xlat0.xy * float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.x = u._cur_shake.w * 6.28318548;
    u_xlat1.x = sin(u_xlat12.x);
    u_xlat2.x = cos(u_xlat12.x);
    u_xlat3.x = sin((-u_xlat12.x));
    u_xlat3.y = u_xlat2.x;
    u_xlat3.z = u_xlat1.x;
    u_xlat1.x = dot(u_xlat0.xy, u_xlat3.yz);
    u_xlat1.y = dot(u_xlat0.xy, u_xlat3.xy);
    u_xlat12.x = u._zoom + u._cur_shake.z;
    u_xlat12.xy = u_xlat12.xx * u_xlat1.xy;
    u_xlat12.xy = u_xlat12.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
    u_xlat12.xy = u_xlat12.xy + u._cur_shake.xy;
    u_xlat12.xy = u_xlat12.xy + float2(0.5, 0.5);
    u_xlatb1.xy = lessThan(u_xlat12.xyxx, float4(0.0, 0.0, 0.0, 0.0)).xy;
    u_xlatb13.xy = lessThan(float4(1.0, 1.0, 1.0, 1.0), u_xlat12.xyxy).xy;
    u_xlatb1.x = u_xlatb13.x || u_xlatb1.x;
    u_xlatb1.x = u_xlatb1.y || u_xlatb1.x;
    u_xlatb1.x = u_xlatb13.y || u_xlatb1.x;
    u_xlat1.x = (u_xlatb1.x) ? 0.0 : 1.0;
    u_xlat1.x = (int(u._texture_wrap_mode) != 0) ? 1.0 : u_xlat1.x;
    u_xlatb7 = int(u._texture_wrap_mode)==2;
    if(u_xlatb7){
        u_xlat2 = SourceTexMirror.sample(__nv_smp, u_xlat12.xy);
    } else {
        u_xlat2 = inputImg.sample(__nv_smp, u_xlat12.xy);
    }
    u_xlatb7 = 0<int(u._enable_motion_blur);
    if(u_xlatb7){
        u_xlat7 = u._prev_shake.w * 6.28318548;
        u_xlat3.x = sin(u_xlat7);
        u_xlat4.x = cos(u_xlat7);
        u_xlat5.x = sin((-u_xlat7));
        u_xlat5.y = u_xlat4.x;
        u_xlat5.z = u_xlat3.x;
        u_xlat3.x = dot(u_xlat0.xy, u_xlat5.yz);
        u_xlat3.y = dot(u_xlat0.xy, u_xlat5.xy);
        u_xlat0.x = u._zoom + u._prev_shake.z;
        u_xlat0.xy = u_xlat0.xx * u_xlat3.xy;
        u_xlat0.xy = u_xlat0.xy / float2(_viewport_ratio.x, _viewport_ratio.y);
        u_xlat0.xy = u_xlat0.xy + u._prev_shake.xy;
        u_xlat0.xy = u_xlat0.xy + float2(0.5, 0.5);
        u_xlat0.xy = (-u_xlat0.xy) + u_xlat12.xy;
        u_xlati7 = int(u._samples) + int(0xFFFFFFFFu);
        u_xlat7 = float(u_xlati7);
        u_xlat3 = u_xlat2;
        u_xlati13 = int(u._texture_wrap_mode);
        for(int u_xlati_loop_1 = 0 ; u_xlati_loop_1<int(u._samples) ; u_xlati_loop_1++)
        {
            u_xlat4.x = float(u_xlati_loop_1);
            u_xlat4.x = u_xlat4.x / u_xlat7;
            u_xlat10.xy = (-u_xlat0.xy) * u_xlat4.xx;
            u_xlat10.xy = (-u_xlat10.xy) * float2(float2(u._length, u._length)) + u_xlat12.xy;
            u_xlatb22 = u_xlati13==2;
            if(u_xlatb22){
                u_xlat5 = SourceTexMirror.sample(__nv_smp, u_xlat10.xy);
            } else {
                u_xlat5 = inputImg.sample(__nv_smp, u_xlat10.xy);
            }
            u_xlat4.z = u_xlat4.x * 3.0 + -1.5;
            u_xlat4.y = -abs(u_xlat4.z) + 1.0;
            u_xlat4.x = (-u_xlat4.z);
            u_xlat4.xyz = u_xlat4.xyz;
            u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
            u_xlat4.xyz = u_xlat4.xyz * u_xlat5.xyz;
            u_xlat4.xyz = u_xlat4.xyz * float3(3.0, 3.0, 3.0) + (-u_xlat5.xyz);
            u_xlat5.xyz = float3(u._dispersion) * u_xlat4.xyz + u_xlat5.xyz;
            u_xlat3 = u_xlat3 + u_xlat5;
        }
        u_xlat0.x = float(int(u._samples));
        u_xlat2 = u_xlat3 / u_xlat0.xxxx;
    }
    u_xlat0 = u_xlat1.xxxx * u_xlat2;
    u_xlatb1.xy = lessThan(int4(0, 0, 0, 0), int4(int(u._enable_lumafade), int(u._enable_exposure), int(u._enable_lumafade), int(u._enable_lumafade))).xy;
    u_xlat2 = float4(u._lumafade_strength) * (-u_xlat0) + u_xlat0;
    u_xlat13 = dot(u_xlat2, u_xlat2);
    u_xlat13 = sqrt(u_xlat13);
    u_xlat13 = log2(u_xlat13);
    u_xlat13 = u_xlat13 * u._lumafade_inensity;
    u_xlat13 = exp2(u_xlat13);
    u_xlat13 = min(u_xlat13, 1.0);
    u_xlat2 = u_xlat0 * float4(u_xlat13);
    u_xlat0 = (u_xlatb1.x) ? u_xlat2 : u_xlat0;
    u_xlat1.x = exp2(u._exposure_strength);
    u_xlat1.xzw = u_xlat0.xyz * u_xlat1.xxx;
    u_xlat0.xyz = (u_xlatb1.y) ? u_xlat1.xzw : u_xlat0.xyz;
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
