// ---------------------------------------------------------------------------
// Effect Channel Invert (NV)
// origem : assets/effects/nv-nodevideo-effect-channel-invert.xml
// id     : nv.effect.nodevideo-effect-channel-invert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_channel_invertParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _channel;
    float _blend_with_original;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
bool u_xlatb3;
float4 u_xlat4;
bool u_xlatb4;
float4 u_xlat5;
bool3 u_xlatb5;
float3 u_xlat9;
bool u_xlatb9;
float3 u_xlat10;
float u_xlat15;
float u_xlat19;
float u_xlat21;

fragment float4 fx_nv_nodevideo_effect_channel_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_channel_invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
    u_xlat1.xyz = log2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
    u_xlat1.xyz = exp2(u_xlat1.xyz);
    u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
    u_xlat1.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
    if(int(u._channel) == 0) {
        u_xlat1.xyz = (-u_xlat1.xyz) + float3(1.0, 1.0, 1.0);
        u_xlat2.w = u_xlat0.w;
    } else {
        u_xlatb3 = int(u._channel)==1;
        if(u_xlatb3){
            u_xlat1.xyz = u_xlat1.xyz * float3(-1.0, 1.0, 1.0) + float3(1.0, 0.0, 0.0);
            u_xlat2.w = u_xlat0.w;
        } else {
            u_xlatb3 = int(u._channel)==2;
            if(u_xlatb3){
                u_xlat1.xyz = u_xlat1.xyz * float3(1.0, -1.0, 1.0) + float3(0.0, 1.0, 0.0);
                u_xlat2.w = u_xlat0.w;
            } else {
                u_xlatb3 = int(u._channel)==3;
                if(u_xlatb3){
                    u_xlat1.w = (-u_xlat1.z) + 1.0;
                    u_xlat1.xyz = u_xlat1.xyw;
                    u_xlat2.w = u_xlat0.w;
                } else {
                    u_xlatb3 = int(u._channel)==4;
                    if(u_xlatb3){
                        u_xlat2.w = (-u_xlat0.w) + 1.0;
                    } else {
                        u_xlatb3 = int(u._channel)==5;
                        if(u_xlatb3){
                            u_xlatb3 = u_xlat1.y>=u_xlat1.z;
                            u_xlat3.x = u_xlatb3 ? 1.0 : float(0.0);
                            u_xlat4.xy = u_xlat1.zy;
                            u_xlat4.z = float(-1.0);
                            u_xlat4.w = float(0.666666687);
                            u_xlat5.xy = u_xlat1.yz + (-u_xlat4.xy);
                            u_xlat5.z = float(1.0);
                            u_xlat5.w = float(-1.0);
                            u_xlat3 = u_xlat3.xxxx * u_xlat5 + u_xlat4;
                            u_xlatb4 = u_xlat1.x>=u_xlat3.x;
                            u_xlat4.x = u_xlatb4 ? 1.0 : float(0.0);
                            u_xlat1.yzw = u_xlat3.xyw;
                            u_xlat3.xyw = u_xlat1.xzy;
                            u_xlat3 = (-u_xlat1.yzwx) + u_xlat3;
                            u_xlat3 = u_xlat4.xxxx * u_xlat3 + u_xlat1.yzwx;
                            u_xlat4.x = min(u_xlat3.y, u_xlat3.w);
                            u_xlat4.x = u_xlat3.x + (-u_xlat4.x);
                            u_xlat9.x = (-u_xlat3.y) + u_xlat3.w;
                            u_xlat21 = u_xlat4.x * 6.0 + 1.00000001e-10;
                            u_xlat9.x = u_xlat9.x / u_xlat21;
                            u_xlat9.x = u_xlat9.x + u_xlat3.z;
                            u_xlat15 = u_xlat3.x + 1.00000001e-10;
                            u_xlat15 = u_xlat4.x / u_xlat15;
                            u_xlat9.x = -abs(u_xlat9.x) + 1.0;
                            u_xlat4.xyz = u_xlat9.xxx * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
                            u_xlat4.xyz = u_xlat4.xyz * float3(0.166666672, 0.166666672, 0.166666672);
                            u_xlatb5.xyz = greaterThanEqual(u_xlat4.xyzx, (-u_xlat4.xyzx)).xyz;
                            u_xlat4.xyz = fract(abs(u_xlat4.xyz));
                            {
                                float4 hlslcc_movcTemp = u_xlat4;
                                hlslcc_movcTemp.x = (u_xlatb5.x) ? u_xlat4.x : (-u_xlat4.x);
                                hlslcc_movcTemp.y = (u_xlatb5.y) ? u_xlat4.y : (-u_xlat4.y);
                                hlslcc_movcTemp.z = (u_xlatb5.z) ? u_xlat4.z : (-u_xlat4.z);
                                u_xlat4 = hlslcc_movcTemp;
                            }
                            u_xlat4.xyz = u_xlat4.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
                            u_xlat4.xyz = abs(u_xlat4.xyz) + float3(-1.0, -1.0, -1.0);
                            u_xlat4.xyz = clamp(u_xlat4.xyz, 0.0, 1.0);
                            u_xlat4.xyz = u_xlat4.xyz + float3(-1.0, -1.0, -1.0);
                            u_xlat9.xyz = float3(u_xlat15) * u_xlat4.xyz + float3(1.0, 1.0, 1.0);
                            u_xlat1.xyz = u_xlat9.xyz * u_xlat3.xxx;
                        } else {
                            u_xlatb3 = int(u._channel)==6;
                            u_xlatb9 = u_xlat1.y>=u_xlat1.z;
                            u_xlat9.x = u_xlatb9 ? 1.0 : float(0.0);
                            u_xlat4.xy = u_xlat1.zy;
                            u_xlat4.z = float(-1.0);
                            u_xlat4.w = float(0.666666687);
                            u_xlat5.xy = u_xlat1.yz + (-u_xlat4.xy);
                            u_xlat5.z = float(1.0);
                            u_xlat5.w = float(-1.0);
                            u_xlat4 = u_xlat9.xxxx * u_xlat5 + u_xlat4;
                            u_xlatb9 = u_xlat1.x>=u_xlat4.x;
                            u_xlat9.x = u_xlatb9 ? 1.0 : float(0.0);
                            u_xlat1.yzw = u_xlat4.xyw;
                            u_xlat4.xyw = u_xlat1.xzy;
                            u_xlat4 = (-u_xlat1.yzwx) + u_xlat4;
                            u_xlat4 = u_xlat9.xxxx * u_xlat4 + u_xlat1.yzwx;
                            u_xlat19 = min(u_xlat4.y, u_xlat4.w);
                            u_xlat19 = (-u_xlat19) + u_xlat4.x;
                            u_xlat9.x = (-u_xlat4.y) + u_xlat4.w;
                            u_xlat15 = u_xlat19 * 6.0 + 1.00000001e-10;
                            u_xlat9.x = u_xlat9.x / u_xlat15;
                            u_xlat9.x = u_xlat9.x + u_xlat4.z;
                            u_xlat15 = u_xlat4.x + 1.00000001e-10;
                            u_xlat19 = u_xlat19 / u_xlat15;
                            u_xlat15 = (-u_xlat4.x) + 1.0;
                            u_xlat10.xyz = abs(u_xlat9.xxx) * float3(6.0, 6.0, 6.0) + float3(0.0, 4.0, 2.0);
                            u_xlat10.xyz = u_xlat10.xyz * float3(0.166666672, 0.166666672, 0.166666672);
                            u_xlatb5.xyz = greaterThanEqual(u_xlat10.xyzx, (-u_xlat10.xyzx)).xyz;
                            u_xlat10.xyz = fract(u_xlat10.xyz);
                            {
                                float3 hlslcc_movcTemp = u_xlat10;
                                hlslcc_movcTemp.x = (u_xlatb5.x) ? u_xlat10.x : (-u_xlat10.x);
                                hlslcc_movcTemp.y = (u_xlatb5.y) ? u_xlat10.y : (-u_xlat10.y);
                                hlslcc_movcTemp.z = (u_xlatb5.z) ? u_xlat10.z : (-u_xlat10.z);
                                u_xlat10 = hlslcc_movcTemp;
                            }
                            u_xlat10.xyz = u_xlat10.xyz * float3(6.0, 6.0, 6.0) + float3(-3.0, -3.0, -3.0);
                            u_xlat10.xyz = abs(u_xlat10.xyz) + float3(-1.0, -1.0, -1.0);
                            u_xlat10.xyz = clamp(u_xlat10.xyz, 0.0, 1.0);
                            u_xlat10.xyz = u_xlat10.xyz + float3(-1.0, -1.0, -1.0);
                            u_xlat5.xyz = float3(u_xlat19) * u_xlat10.xyz + float3(1.0, 1.0, 1.0);
                            u_xlat9.xyz = float3(u_xlat15) * u_xlat5.xyz;
                            u_xlat19 = (-u_xlat19) + 1.0;
                            u_xlat10.xyz = float3(u_xlat19) * u_xlat10.xyz + float3(1.0, 1.0, 1.0);
                            u_xlat4.xyz = u_xlat10.xyz * u_xlat4.xxx;
                            u_xlat1.xyz = (bool(u_xlatb3)) ? u_xlat9.xyz : u_xlat4.xyz;
                        }
                        u_xlat2.w = u_xlat0.w;
                    }
                }
            }
        }
    }
    u_xlat3.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat3.xyz = u_xlat1.xyz * u_xlat3.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = u_xlat1.xyz * u_xlat3.xyz;
    u_xlat1.x = (-u._blend_with_original) + 1.0;
    u_xlat1 = u_xlat1.xxxx * u_xlat2;
    u_xlat1 = u_xlat0 * float4(float4(u._blend_with_original, u._blend_with_original, u._blend_with_original, u._blend_with_original)) + u_xlat1;
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
