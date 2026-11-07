// ---------------------------------------------------------------------------
// Effect Channel Soften (NV)
// origem : assets/effects/nv-nodevideo-effect-channel-soften.xml
// id     : nv.effect.nodevideo-effect-channel-soften
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_channel_softenParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _radius;
    float _skin_mask;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 ImmCB_0[25];

float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat2;
int u_xlati2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat6;
float u_xlat9;
int2 u_xlati9;
bool u_xlatb9;
float u_xlat10;
bool u_xlatb16;
int2 u_xlati17;
float u_xlat22;
bool u_xlatb22;
float u_xlat23;
float u_xlat24;
bool u_xlatb25;

fragment float4 fx_nv_nodevideo_effect_channel_soften(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_channel_softenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

ImmCB_0[0] = float4(0.0194184929,0.0,0.0,0.0);
ImmCB_0[1] = float4(0.0217850935,0.0,0.0,0.0);
ImmCB_0[2] = float4(0.024196934,0.0,0.0,0.0);
ImmCB_0[3] = float4(0.0266083721,0.0,0.0,0.0);
ImmCB_0[4] = float4(0.0289689898,0.0,0.0,0.0);
ImmCB_0[5] = float4(0.0312252138,0.0,0.0,0.0);
ImmCB_0[6] = float4(0.0333222672,0.0,0.0,0.0);
ImmCB_0[7] = float4(0.0352063291,0.0,0.0,0.0);
ImmCB_0[8] = float4(0.0368268006,0.0,0.0,0.0);
ImmCB_0[9] = float4(0.038138561,0.0,0.0,0.0);
ImmCB_0[10] = float4(0.0391040444,0.0,0.0,0.0);
ImmCB_0[11] = float4(0.0396950282,0.0,0.0,0.0);
ImmCB_0[12] = float4(0.0398939997,0.0,0.0,0.0);
ImmCB_0[13] = float4(0.0396950282,0.0,0.0,0.0);
ImmCB_0[14] = float4(0.0391040444,0.0,0.0,0.0);
ImmCB_0[15] = float4(0.038138561,0.0,0.0,0.0);
ImmCB_0[16] = float4(0.0368268006,0.0,0.0,0.0);
ImmCB_0[17] = float4(0.0352063291,0.0,0.0,0.0);
ImmCB_0[18] = float4(0.0333222672,0.0,0.0,0.0);
ImmCB_0[19] = float4(0.0312252138,0.0,0.0,0.0);
ImmCB_0[20] = float4(0.0289689898,0.0,0.0,0.0);
ImmCB_0[21] = float4(0.0266083721,0.0,0.0,0.0);
ImmCB_0[22] = float4(0.024196934,0.0,0.0,0.0);
ImmCB_0[23] = float4(0.0217850935,0.0,0.0,0.0);
ImmCB_0[24] = float4(0.0194184929,0.0,0.0,0.0);
    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = float(0.0);
    u_xlat1.y = float(0.0);
    u_xlat1.z = float(0.0);
    u_xlat22 = float(0.0);
    u_xlati2 = int(0xFFFFFFF4u);
    while(true){
        u_xlatb9 = 12<u_xlati2;
        if(u_xlatb9){break;}
        u_xlati9.xy = int2(u_xlati2) + int2(12, 1);
        u_xlat3.x = float(u_xlati2);
        u_xlat4.xyz = u_xlat1.xyz;
        u_xlat23 = u_xlat22;
        u_xlati17.x = int(0xFFFFFFF4u);
        while(true){
            u_xlatb25 = 12<u_xlati17.x;
            if(u_xlatb25){break;}
            u_xlat3.y = float(u_xlati17.x);
            u_xlat5.xy = u_xlat3.xy * float2(float2(u._radius, u._radius));
            u_xlat5.xy = in.acScreenNorm.xy * _resolution.xy + u_xlat5.xy;
            u_xlat5.xy = u_xlat5.xy / _resolution.xy;
            u_xlat5.xyz = inputImg.sample(__nv_smp, u_xlat5.xy).xyz;
            u_xlat6.xyz = (-u_xlat0.xyz) + u_xlat5.xyz;
            u_xlat10 = dot(u_xlat6.xyz, u_xlat6.xyz);
            u_xlat10 = u_xlat10 * -72.1347427;
            u_xlat10 = exp2(u_xlat10);
            u_xlat10 = u_xlat10 * 1.0;
            u_xlati17.xy = u_xlati17.xx + int2(1, 12);
            u_xlat10 = u_xlat10 * ImmCB_0[u_xlati17.y].x;
            u_xlat24 = u_xlat10 * ImmCB_0[u_xlati9.x].x;
            u_xlat23 = u_xlat10 * ImmCB_0[u_xlati9.x].x + u_xlat23;
            u_xlat4.xyz = float3(u_xlat24) * u_xlat5.xyz + u_xlat4.xyz;
        }
        u_xlat1.xyz = u_xlat4.xyz;
        u_xlat22 = u_xlat23;
        u_xlati2 = u_xlati9.y;
    }
    u_xlat1.xyz = u_xlat1.xyz / float3(u_xlat22);
    u_xlatb22 = 0<int(u._skin_mask);
    u_xlat2.x = (-u_xlat1.x) * 37.7400017 + 128.0;
    u_xlat2.x = (-u_xlat1.y) * 74.2050018 + u_xlat2.x;
    u_xlat2.x = u_xlat1.z * 111.945 + u_xlat2.x;
    u_xlat9 = u_xlat1.x * 111.945 + 128.0;
    u_xlat9 = (-u_xlat1.y) * 93.840004 + u_xlat9;
    u_xlat9 = (-u_xlat1.z) * 18.1050014 + u_xlat9;
    u_xlatb16 = 100.0<u_xlat2.x;
    u_xlatb2.x = u_xlat2.x<118.0;
    u_xlatb2.x = u_xlatb2.x && u_xlatb16;
    u_xlatb16 = 121.0<u_xlat9;
    u_xlatb2.x = u_xlatb16 && u_xlatb2.x;
    u_xlatb9 = u_xlat9<161.0;
    u_xlatb2.x = u_xlatb9 && u_xlatb2.x;
    u_xlat2.xyz = (u_xlatb2.x) ? u_xlat1.xyz : u_xlat0.xyz;
    u_xlat1.xyz = (bool(u_xlatb22)) ? u_xlat2.xyz : u_xlat1.xyz;
    if(int(u._use_inner_mask) != 0) {
        u_xlatb2.xy = equal(int4(int(u._show_inner_mask), int(u._b_clip_mask), int(u._show_inner_mask), int(u._show_inner_mask)), int4(1, 1, 0, 0)).xy;
        u_xlat1.w = u_xlat0.w;
        u_xlat3 = (u_xlatb2.x) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
        u_xlat4 = Mask.sample(__nv_smp, in.acScreenNorm.xy);
        u_xlat5 = (-u_xlat4) + float4(1.0, 1.0, 1.0, 1.0);
        u_xlat5 = u_xlat0 * u_xlat5;
        u_xlat3 = u_xlat3 * u_xlat4 + u_xlat5;
        u_xlat0.x = u_xlat4.x * u_xlat3.w;
        __nv_out.w = (u_xlatb2.y) ? u_xlat0.x : u_xlat3.w;
        __nv_out.xyz = u_xlat3.xyz;
    } else {
        __nv_out.xyz = u_xlat1.xyz;
        __nv_out.w = u_xlat0.w;
    }
    return __nv_out;
    return __nv_out;
}
