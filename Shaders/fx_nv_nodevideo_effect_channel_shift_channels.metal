// ---------------------------------------------------------------------------
// Effect Channel Shift Channels (NV)
// origem : assets/effects/nv-nodevideo-effect-channel-shift-channels.xml
// id     : nv.effect.nodevideo-effect-channel-shift-channels
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_channel_shift_channelsParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _r_source;
    float _g_source;
    float _b_source;
    float _a_source;
};

// --- funcoes auxiliares do efeito
float4 ImmCB_0[4];

float4 u_xlat0;
float4 u_xlat1;
int u_xlati1;
float4 u_xlat2;
int u_xlati2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
bool3 u_xlatb4;
float4 u_xlat5;
bool2 u_xlatb5;
float u_xlat7;
float u_xlat8;
float u_xlat9;
float u_xlat10;
bool3 u_xlatb10;
float u_xlat13;
bool u_xlatb13;
float2 u_xlat14;
bool u_xlatb14;
float u_xlat15;
bool u_xlatb15;
float u_xlat16;
float u_xlat19;
float u_xlat20;
float u_xlat21;
float u_xlat22;

fragment float4 fx_nv_nodevideo_effect_channel_shift_channels(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_channel_shift_channelsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

ImmCB_0[0] = float4(1.0,0.0,0.0,0.0);
ImmCB_0[1] = float4(0.0,1.0,0.0,0.0);
ImmCB_0[2] = float4(0.0,0.0,1.0,0.0);
ImmCB_0[3] = float4(0.0,0.0,0.0,1.0);
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = log2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat1.xyz = max(u_xlat1.zyx, float3(0.0, 0.0, 0.0));
    u_xlatb2 = greaterThanEqual(int4(3, 3, 3, 3), int4(int(u._r_source), int(u._g_source), int(u._b_source), int(u._a_source)));
    if(u_xlatb2.x){
        u_xlat1.w = u_xlat0.w;
        u_xlati2 = int(u._r_source);
        u_xlat3.w = dot(u_xlat1.zyxw, ImmCB_0[u_xlati2]);
    } else {
        u_xlatb2.x = int(u._r_source)==4;
        if(u_xlatb2.x){
            u_xlat3.w = dot(u_xlat1.zyx, float3(0.300000012, 0.589999974, 0.109999999));
        } else {
            u_xlatb2.x = int(u._r_source)==5;
            if(u_xlatb2.x){
                u_xlatb2.x = u_xlat1.y>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat4.xy = u_xlat1.xy;
                u_xlat4.z = float(-1.0);
                u_xlat4.w = float(0.666666687);
                u_xlat5.xy = u_xlat1.yx + (-u_xlat4.xy);
                u_xlat5.z = float(1.0);
                u_xlat5.w = float(-1.0);
                u_xlat4 = u_xlat2.xxxx * u_xlat5 + u_xlat4;
                u_xlatb2.x = u_xlat1.z>=u_xlat4.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat5.xyz = u_xlat4.xyw;
                u_xlat5.w = u_xlat1.z;
                u_xlat4.xyw = u_xlat5.wyx;
                u_xlat4 = (-u_xlat5) + u_xlat4;
                u_xlat4 = u_xlat2.xxxx * u_xlat4 + u_xlat5;
                u_xlat2.x = min(u_xlat4.y, u_xlat4.w);
                u_xlat2.x = (-u_xlat2.x) + u_xlat4.x;
                u_xlat4.x = (-u_xlat4.y) + u_xlat4.w;
                u_xlat2.x = u_xlat2.x * 6.0 + 1.00000001e-10;
                u_xlat2.x = u_xlat4.x / u_xlat2.x;
                u_xlat21 = u_xlat2.x + u_xlat4.z;
                u_xlat3.w = abs(u_xlat21);
            } else {
                u_xlatb2.x = u_xlat1.y>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat4.xyz = (-u_xlat1.xxy) + u_xlat1.yyx;
                u_xlat4.xyz = u_xlat2.xxx * u_xlat4.xyz + u_xlat1.xxy;
                u_xlatb5.xy = greaterThanEqual(u_xlat1.zzzz, u_xlat4.xyxx).xy;
                u_xlat5.x = u_xlatb5.x ? float(1.0) : 0.0;
                u_xlat5.y = u_xlatb5.y ? float(1.0) : 0.0;
;
                u_xlat4.w = u_xlat1.z;
                u_xlat2.x = u_xlat1.z + (-u_xlat4.x);
                u_xlat2.x = u_xlat5.x * u_xlat2.x + u_xlat4.x;
                u_xlat5.xzw = (-u_xlat4.yzw) + u_xlat4.wzy;
                u_xlat4.xyz = u_xlat5.yyy * u_xlat5.xzw + u_xlat4.yzw;
                u_xlat10 = min(u_xlat4.y, u_xlat4.z);
                u_xlat10 = (-u_xlat10) + u_xlat4.x;
                u_xlat4.x = u_xlat4.x + 1.00000001e-10;
                u_xlat4.x = u_xlat10 / u_xlat4.x;
                u_xlatb10.xyz = equal(int4(int(u._r_source)), int4(6, 7, 8, 8)).xyz;
                u_xlat22 = u_xlatb10.z ? 1.0 : float(0.0);
                u_xlat4.x = (u_xlatb10.y) ? u_xlat4.x : u_xlat22;
                u_xlat3.w = (u_xlatb10.x) ? u_xlat2.x : u_xlat4.x;
            }
        }
    }
    if(u_xlatb2.y){
        u_xlat3.xy = u_xlat1.yx;
        u_xlat3.z = u_xlat0.w;
        u_xlati2 = int(u._g_source);
        u_xlat3.x = dot(u_xlat3.wxyz, ImmCB_0[u_xlati2]);
    } else {
        u_xlatb2.x = int(u._g_source)==4;
        if(u_xlatb2.x){
            u_xlat2.x = u_xlat1.y * 0.589999974;
            u_xlat2.x = u_xlat3.w * 0.300000012 + u_xlat2.x;
            u_xlat3.x = u_xlat1.x * 0.109999999 + u_xlat2.x;
        } else {
            u_xlatb2.x = int(u._g_source)==5;
            if(u_xlatb2.x){
                u_xlatb2.x = u_xlat1.y>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat1.z = float(-1.0);
                u_xlat1.w = float(0.666666687);
                u_xlat4.xy = (-u_xlat1.xy) + u_xlat1.yx;
                u_xlat4.z = float(1.0);
                u_xlat4.w = float(-1.0);
                u_xlat4 = u_xlat2.xxxx * u_xlat4 + u_xlat1;
                u_xlatb2.x = u_xlat3.w>=u_xlat4.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat3.xyz = u_xlat4.xyw;
                u_xlat4.xyw = u_xlat3.wyx;
                u_xlat4 = (-u_xlat3) + u_xlat4;
                u_xlat4 = u_xlat2.xxxx * u_xlat4 + u_xlat3;
                u_xlat2.x = min(u_xlat4.y, u_xlat4.w);
                u_xlat2.x = (-u_xlat2.x) + u_xlat4.x;
                u_xlat8 = (-u_xlat4.y) + u_xlat4.w;
                u_xlat2.x = u_xlat2.x * 6.0 + 1.00000001e-10;
                u_xlat2.x = u_xlat8 / u_xlat2.x;
                u_xlat3.x = u_xlat2.x + u_xlat4.z;
                u_xlat3.x = abs(u_xlat3.x);
            } else {
                u_xlatb2.x = u_xlat1.y>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat4.xyz = (-u_xlat1.xxy) + u_xlat1.yyx;
                u_xlat3.xyz = u_xlat2.xxx * u_xlat4.xyz + u_xlat1.xxy;
                u_xlatb2.xy = greaterThanEqual(u_xlat3.wwww, u_xlat3.xyxx).xy;
                u_xlat2.x = u_xlatb2.x ? float(1.0) : 0.0;
                u_xlat2.y = u_xlatb2.y ? float(1.0) : 0.0;
;
                u_xlat4.x = (-u_xlat3.x) + u_xlat3.w;
                u_xlat2.x = u_xlat2.x * u_xlat4.x + u_xlat3.x;
                u_xlat4.xyz = (-u_xlat3.yzw) + u_xlat3.wzy;
                u_xlat4.xyz = u_xlat2.yyy * u_xlat4.xyz + u_xlat3.yzw;
                u_xlat8 = min(u_xlat4.y, u_xlat4.z);
                u_xlat8 = (-u_xlat8) + u_xlat4.x;
                u_xlat4.x = u_xlat4.x + 1.00000001e-10;
                u_xlat8 = u_xlat8 / u_xlat4.x;
                u_xlatb4.xyz = equal(int4(int4(int(u._g_source), int(u._g_source), int(u._g_source), int(u._g_source))), int4(6, 7, 8, 0)).xyz;
                u_xlat16 = u_xlatb4.z ? 1.0 : float(0.0);
                u_xlat8 = (u_xlatb4.y) ? u_xlat8 : u_xlat16;
                u_xlat3.x = (u_xlatb4.x) ? u_xlat2.x : u_xlat8;
            }
        }
    }
    if(u_xlatb2.z){
        u_xlat3.y = u_xlat1.x;
        u_xlat3.z = u_xlat0.w;
        u_xlati2 = int(u._b_source);
        u_xlat3.y = dot(u_xlat3.wxyz, ImmCB_0[u_xlati2]);
    } else {
        u_xlatb2.x = int(u._b_source)==4;
        if(u_xlatb2.x){
            u_xlat2.x = u_xlat3.x * 0.589999974;
            u_xlat2.x = u_xlat3.w * 0.300000012 + u_xlat2.x;
            u_xlat3.y = u_xlat1.x * 0.109999999 + u_xlat2.x;
        } else {
            u_xlatb2.x = int(u._b_source)==5;
            if(u_xlatb2.x){
                u_xlatb2.x = u_xlat3.x>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat1.z = u_xlat3.x;
                u_xlat1.y = float(-1.0);
                u_xlat1.w = float(0.666666687);
                u_xlat4.x = (-u_xlat1.x) + u_xlat3.x;
                u_xlat4.y = (-u_xlat1.z) + u_xlat1.x;
                u_xlat4.z = float(1.0);
                u_xlat4.w = float(-1.0);
                u_xlat4 = u_xlat2.xxxx * u_xlat4 + u_xlat1.xzyw;
                u_xlatb13 = u_xlat3.w>=u_xlat4.x;
                u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                u_xlat5.xyz = u_xlat4.xyw;
                u_xlat5.w = u_xlat3.w;
                u_xlat4.xyw = u_xlat5.wyx;
                u_xlat4 = (-u_xlat5) + u_xlat4;
                u_xlat4 = float4(u_xlat13) * u_xlat4 + u_xlat5;
                u_xlat13 = min(u_xlat4.y, u_xlat4.w);
                u_xlat13 = (-u_xlat13) + u_xlat4.x;
                u_xlat19 = (-u_xlat4.y) + u_xlat4.w;
                u_xlat13 = u_xlat13 * 6.0 + 1.00000001e-10;
                u_xlat13 = u_xlat19 / u_xlat13;
                u_xlat9 = u_xlat13 + u_xlat4.z;
                u_xlat3.y = abs(u_xlat9);
            } else {
                u_xlatb13 = u_xlat3.x>=u_xlat1.x;
                u_xlat13 = u_xlatb13 ? 1.0 : float(0.0);
                u_xlat1.y = u_xlat3.x;
                u_xlat19 = (-u_xlat1.x) + u_xlat3.x;
                u_xlat19 = u_xlat13 * u_xlat19 + u_xlat1.x;
                u_xlatb2.x = u_xlat3.w>=u_xlat19;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat8 = (-u_xlat19) + u_xlat3.w;
                u_xlat19 = u_xlat2.x * u_xlat8 + u_xlat19;
                u_xlat2.xy = (-u_xlat1.xy) + u_xlat1.yx;
                u_xlat1.xy = float2(u_xlat13) * u_xlat2.xy + u_xlat1.xy;
                u_xlatb2.x = u_xlat3.w>=u_xlat1.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat1.z = u_xlat3.w;
                u_xlat4.xyz = (-u_xlat1.xyz) + u_xlat1.zyx;
                u_xlat1.xyz = u_xlat2.xxx * u_xlat4.xyz + u_xlat1.xyz;
                u_xlat7 = min(u_xlat1.y, u_xlat1.z);
                u_xlat7 = (-u_xlat7) + u_xlat1.x;
                u_xlat1.x = u_xlat1.x + 1.00000001e-10;
                u_xlat1.x = u_xlat7 / u_xlat1.x;
                u_xlatb2.xyz = equal(int4(int4(int(u._b_source), int(u._b_source), int(u._b_source), int(u._b_source))), int4(6, 7, 8, 0)).xyz;
                u_xlat7 = u_xlatb2.z ? 1.0 : float(0.0);
                u_xlat1.x = (u_xlatb2.y) ? u_xlat1.x : u_xlat7;
                u_xlat3.y = (u_xlatb2.x) ? u_xlat19 : u_xlat1.x;
            }
        }
    }
    if(u_xlatb2.w){
        u_xlat3.z = u_xlat0.w;
        u_xlati1 = int(u._a_source);
        u_xlat1.w = dot(u_xlat3.wxyz, ImmCB_0[u_xlati1]);
    } else {
        u_xlatb2.x = int(u._a_source)==4;
        if(u_xlatb2.x){
            u_xlat2.x = u_xlat3.x * 0.589999974;
            u_xlat2.x = u_xlat3.w * 0.300000012 + u_xlat2.x;
            u_xlat1.w = u_xlat3.y * 0.109999999 + u_xlat2.x;
        } else {
            u_xlatb2.x = int(u._a_source)==5;
            if(u_xlatb2.x){
                u_xlatb2.x = u_xlat3.x>=u_xlat3.y;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat4.xy = u_xlat3.yx;
                u_xlat4.z = float(-1.0);
                u_xlat4.w = float(0.666666687);
                u_xlat5.xy = u_xlat3.xy + (-u_xlat4.xy);
                u_xlat5.z = float(1.0);
                u_xlat5.w = float(-1.0);
                u_xlat2 = u_xlat2.xxxx * u_xlat5 + u_xlat4;
                u_xlatb15 = u_xlat3.w>=u_xlat2.x;
                u_xlat15 = u_xlatb15 ? 1.0 : float(0.0);
                u_xlat4.xyz = u_xlat2.xyw;
                u_xlat4.w = u_xlat3.w;
                u_xlat2.xyw = u_xlat4.wyx;
                u_xlat2 = (-u_xlat4) + u_xlat2;
                u_xlat2 = float4(u_xlat15) * u_xlat2 + u_xlat4;
                u_xlat15 = min(u_xlat2.y, u_xlat2.w);
                u_xlat2.x = u_xlat2.x + (-u_xlat15);
                u_xlat8 = (-u_xlat2.y) + u_xlat2.w;
                u_xlat2.x = u_xlat2.x * 6.0 + 1.00000001e-10;
                u_xlat2.x = u_xlat8 / u_xlat2.x;
                u_xlat19 = u_xlat2.x + u_xlat2.z;
                u_xlat1.w = abs(u_xlat19);
            } else {
                u_xlatb2.x = u_xlat3.x>=u_xlat3.y;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat8 = (-u_xlat3.y) + u_xlat3.x;
                u_xlat8 = u_xlat2.x * u_xlat8 + u_xlat3.y;
                u_xlatb14 = u_xlat3.w>=u_xlat8;
                u_xlat14.x = u_xlatb14 ? 1.0 : float(0.0);
                u_xlat20 = (-u_xlat8) + u_xlat3.w;
                u_xlat8 = u_xlat14.x * u_xlat20 + u_xlat8;
                u_xlat14.xy = (-u_xlat3.yx) + u_xlat3.xy;
                u_xlat4.xy = u_xlat2.xx * u_xlat14.xy + u_xlat3.yx;
                u_xlatb2.x = u_xlat3.w>=u_xlat4.x;
                u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
                u_xlat4.z = u_xlat3.w;
                u_xlat5.xyz = (-u_xlat4.xyz) + u_xlat4.zyx;
                u_xlat2.xzw = u_xlat2.xxx * u_xlat5.xyz + u_xlat4.xyz;
                u_xlat14.x = min(u_xlat2.z, u_xlat2.w);
                u_xlat14.x = (-u_xlat14.x) + u_xlat2.x;
                u_xlat2.x = u_xlat2.x + 1.00000001e-10;
                u_xlat2.x = u_xlat14.x / u_xlat2.x;
                u_xlatb4.xyz = equal(int4(int4(int(u._a_source), int(u._a_source), int(u._a_source), int(u._a_source))), int4(6, 7, 8, 0)).xyz;
                u_xlat14.x = u_xlatb4.z ? 1.0 : float(0.0);
                u_xlat2.x = (u_xlatb4.y) ? u_xlat2.x : u_xlat14.x;
                u_xlat1.w = (u_xlatb4.x) ? u_xlat8 : u_xlat2.x;
            }
        }
    }
    u_xlat2.xyz = u_xlat3.wxy * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = u_xlat3.wxy * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat2.xyz * u_xlat3.wxy;
    if(int(u._use_inner_mask) != 0) {
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
