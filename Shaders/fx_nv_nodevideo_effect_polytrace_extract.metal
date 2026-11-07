// ---------------------------------------------------------------------------
// Effect Polytrace Extract (NV)
// origem : assets/effects/nv-nodevideo-effect-polytrace-extract.xml
// id     : nv.effect.nodevideo-effect-polytrace-extract
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_polytrace_extractParams {
    float _threshold;
    float _channel;
    float _density;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool4 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float3 u_xlat5;
float3 u_xlat7;
bool u_xlatb7;
float3 u_xlat9;
float2 u_xlat13;
bool u_xlatb13;
float u_xlat18;
bool u_xlatb18;
float u_xlat19;

fragment float4 fx_nv_nodevideo_effect_polytrace_extract(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_polytrace_extractParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    if(int(u._channel) == 0) {
        u_xlat1.xy = float2(1.0, 1.0) / _resolution.xy;
        u_xlat1.z = (-u_xlat1.x);
        u_xlat2 = u_xlat1.zyxy + in.acScreenNorm.xyxy;
        u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
        u_xlat13.x = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat13.x = sqrt(u_xlat13.x);
        u_xlat3.xyz = (-u_xlat1.xyx);
        u_xlat3.w = 0.0;
        u_xlat3 = u_xlat3.zwxy + in.acScreenNorm.xyxy;
        u_xlat4.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
        u_xlat2.x = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat3.zw).xyz;
        u_xlat2.y = dot(u_xlat3.xyz, u_xlat3.xyz);
        u_xlat1.w = 0.0;
        u_xlat3 = u_xlat1.wyxw + in.acScreenNorm.xyxy;
        u_xlat4.xyz = inputImg.sample(__nv_smp, u_xlat3.xy).xyz;
        u_xlat3.x = dot(u_xlat4.xyz, u_xlat4.xyz);
        u_xlat3.x = sqrt(u_xlat3.x);
        u_xlat4 = u_xlat1.wyxy * float4(1.0, -1.0, 1.0, -1.0) + in.acScreenNorm.xyxy;
        u_xlat1.xyw = inputImg.sample(__nv_smp, u_xlat4.xy).xyz;
        u_xlat1.x = dot(u_xlat1.xyw, u_xlat1.xyw);
        u_xlat5.xyz = inputImg.sample(__nv_smp, u_xlat2.zw).xyz;
        u_xlat1.y = dot(u_xlat5.xyz, u_xlat5.xyz);
        u_xlat9.xyz = inputImg.sample(__nv_smp, u_xlat3.zw).xyz;
        u_xlat1.w = dot(u_xlat9.xyz, u_xlat9.xyz);
        u_xlat1.xyw = sqrt(u_xlat1.xyw);
        u_xlat9.xyz = inputImg.sample(__nv_smp, u_xlat4.zw).xyz;
        u_xlat2.z = dot(u_xlat9.xyz, u_xlat9.xyz);
        u_xlat2.xyz = sqrt(u_xlat2.xyz);
        u_xlat2.x = u_xlat2.x * 2.0 + u_xlat13.x;
        u_xlat2.x = u_xlat2.y + u_xlat2.x;
        u_xlat2.x = (-u_xlat1.y) + u_xlat2.x;
        u_xlat19 = (-u_xlat1.w) * 2.0 + u_xlat2.x;
        u_xlat19 = (-u_xlat2.z) + u_xlat19;
        u_xlat13.x = (-u_xlat3.x) * 2.0 + (-u_xlat13.x);
        u_xlat7.x = (-u_xlat1.y) + u_xlat13.x;
        u_xlat7.x = u_xlat2.y + u_xlat7.x;
        u_xlat1.x = u_xlat1.x * 2.0 + u_xlat7.x;
        u_xlat1.x = u_xlat2.z + u_xlat1.x;
        u_xlat1.x = u_xlat1.x * u_xlat1.x;
        u_xlat1.x = u_xlat19 * u_xlat19 + u_xlat1.x;
        u_xlat1.x = sqrt(u_xlat1.x);
        u_xlat7.x = (-u._density) + 1.0;
        u_xlat1.x = (-u_xlat7.x) + u_xlat1.x;
    } else {
        u_xlatb7 = int(u._channel)==1;
        if(u_xlatb7){
            u_xlat1.x = dot(u_xlat0.xyz, float3(0.300000012, 0.589999974, 0.109999999));
        } else {
            u_xlatb7 = int(u._channel)==2;
            if(u_xlatb7){
                u_xlatb7 = u_xlat0.y>=u_xlat0.z;
                u_xlat7.x = u_xlatb7 ? 1.0 : float(0.0);
                u_xlat2.xy = u_xlat0.zy;
                u_xlat2.z = float(-1.0);
                u_xlat2.w = float(0.666666687);
                u_xlat3.xy = u_xlat0.yz + (-u_xlat2.xy);
                u_xlat3.z = float(1.0);
                u_xlat3.w = float(-1.0);
                u_xlat2 = u_xlat7.xxxx * u_xlat3 + u_xlat2;
                u_xlatb7 = u_xlat0.x>=u_xlat2.x;
                u_xlat7.x = u_xlatb7 ? 1.0 : float(0.0);
                u_xlat3.xyz = u_xlat2.xyw;
                u_xlat3.w = u_xlat0.x;
                u_xlat2.xyw = u_xlat3.wyx;
                u_xlat2 = (-u_xlat3) + u_xlat2;
                u_xlat2 = u_xlat7.xxxx * u_xlat2 + u_xlat3;
                u_xlat7.x = min(u_xlat2.y, u_xlat2.w);
                u_xlat7.x = (-u_xlat7.x) + u_xlat2.x;
                u_xlat13.x = (-u_xlat2.y) + u_xlat2.w;
                u_xlat7.x = u_xlat7.x * 6.0 + 1.00000001e-10;
                u_xlat7.x = u_xlat13.x / u_xlat7.x;
                u_xlat1.x = u_xlat7.x + u_xlat2.z;
                u_xlat1.x = abs(u_xlat1.x);
            } else {
                u_xlatb7 = u_xlat0.y>=u_xlat0.z;
                u_xlat7.x = u_xlatb7 ? 1.0 : float(0.0);
                u_xlat13.xy = (-u_xlat0.zy) + u_xlat0.yz;
                u_xlat2.xy = u_xlat7.xx * u_xlat13.xy + u_xlat0.zy;
                u_xlatb7 = u_xlat0.x>=u_xlat2.x;
                u_xlat7.x = u_xlatb7 ? 1.0 : float(0.0);
                u_xlat2.z = u_xlat0.x;
                u_xlat3.xyz = (-u_xlat2.xyz) + u_xlat2.zyx;
                u_xlat7.xyz = u_xlat7.xxx * u_xlat3.xyz + u_xlat2.xyz;
                u_xlat13.x = min(u_xlat7.y, u_xlat7.z);
                u_xlat13.x = (-u_xlat13.x) + u_xlat7.x;
                u_xlat7.x = u_xlat7.x + 1.00000001e-10;
                u_xlat7.x = u_xlat13.x / u_xlat7.x;
                u_xlatb2 = equal(int4(int4(int(u._channel), int(u._channel), int(u._channel), int(u._channel))), int4(3, 4, 5, 6));
                u_xlatb13 = int(u._channel)==7;
                u_xlat18 = u_xlatb13 ? u_xlat0.w : float(0.0);
                u_xlat18 = (u_xlatb2.w) ? u_xlat0.z : u_xlat18;
                u_xlat18 = (u_xlatb2.z) ? u_xlat0.y : u_xlat18;
                u_xlat18 = (u_xlatb2.y) ? u_xlat0.x : u_xlat18;
                u_xlat1.x = (u_xlatb2.x) ? u_xlat7.x : u_xlat18;
            }
        }
    }
    u_xlatb18 = 0.0<u_xlat1.x;
    u_xlatb7 = u_xlat1.x<u._threshold;
    u_xlatb18 = u_xlatb18 && u_xlatb7;
    __nv_out.w = u_xlatb18 ? u_xlat1.x : float(0.0);
    __nv_out.xyz = u_xlat0.xyz;
    return __nv_out;
    return __nv_out;
}
