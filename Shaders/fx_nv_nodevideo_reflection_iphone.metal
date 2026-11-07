// ---------------------------------------------------------------------------
// Reflection Iphone (NV)
// origem : assets/effects/nv-nodevideo-reflection-iphone.xml
// id     : nv.effect.nodevideo-reflection-iphone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_reflection_iphoneParams {
    float _reflection;
    float4 _Color;
    float _panoramic_upside_down;
    float _material;
    float _reflection_mode;
    float3 _light_direction;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
bool u_xlatb0;
float3 u_xlat1;
bool u_xlatb1;
float3 u_xlat2;
float3 u_xlat16_3;
float u_xlat5;
bool u_xlatb5;
bool2 u_xlatb6;
float u_xlat12;
bool u_xlatb12;
float u_xlat13;
bool u_xlatb14;

fragment float4 fx_nv_nodevideo_reflection_iphone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_reflection_iphoneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> panoramic_texture [[texture(1)]],
    texture2d<float> mat_cap [[texture(2)]],
    texture2d<float> MainTex [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = u._material==1;
    if(u_xlatb0){
        u_xlat0.xyz = in.vs_TEXCOORD2.xyz + u._light_direction.xyz;
        u_xlat0.xyz = inputImg.sample(__nv_smp, u_xlat0.xyz).xyz;
    } else {
        u_xlatb12 = u._material==2;
        if(u_xlatb12){
            u_xlat1.xyz = in.vs_TEXCOORD2.yzx + u._light_direction.yzx;
            u_xlat12 = dot(u_xlat1.xyz, u_xlat1.xyz);
            u_xlat12 = rsqrt(u_xlat12);
            u_xlat1.xyz = float3(u_xlat12) * u_xlat1.xyz;
            u_xlat12 = -abs(u_xlat1.x) + 1.0;
            u_xlat12 = sqrt(u_xlat12);
            u_xlat13 = abs(u_xlat1.x) * -0.0187292993 + 0.0742610022;
            u_xlat13 = u_xlat13 * abs(u_xlat1.x) + -0.212114394;
            u_xlat13 = u_xlat13 * abs(u_xlat1.x) + 1.57072878;
            u_xlat2.x = u_xlat12 * u_xlat13;
            u_xlat2.x = u_xlat2.x * -2.0 + 3.14159274;
            u_xlatb6.xy = lessThan(u_xlat1.xzxx, (-u_xlat1.xzxx)).xy;
            u_xlat1.x = u_xlatb6.x ? u_xlat2.x : float(0.0);
            u_xlat2.y = u_xlat13 * u_xlat12 + u_xlat1.x;
            u_xlat12 = min(abs(u_xlat1.z), abs(u_xlat1.y));
            u_xlat1.x = max(abs(u_xlat1.z), abs(u_xlat1.y));
            u_xlat1.x = float(1.0) / u_xlat1.x;
            u_xlat12 = u_xlat12 * u_xlat1.x;
            u_xlat1.x = u_xlat12 * u_xlat12;
            u_xlat13 = u_xlat1.x * 0.0208350997 + -0.0851330012;
            u_xlat13 = u_xlat1.x * u_xlat13 + 0.180141002;
            u_xlat13 = u_xlat1.x * u_xlat13 + -0.330299497;
            u_xlat1.x = u_xlat1.x * u_xlat13 + 0.999866009;
            u_xlat13 = u_xlat12 * u_xlat1.x;
            u_xlatb14 = abs(u_xlat1.z)<abs(u_xlat1.y);
            u_xlat13 = u_xlat13 * -2.0 + 1.57079637;
            u_xlat13 = u_xlatb14 ? u_xlat13 : float(0.0);
            u_xlat12 = u_xlat12 * u_xlat1.x + u_xlat13;
            u_xlat1.x = u_xlatb6.y ? -3.14159274 : float(0.0);
            u_xlat12 = u_xlat12 + u_xlat1.x;
            u_xlat1.x = min(u_xlat1.z, u_xlat1.y);
            u_xlat5 = max(u_xlat1.z, u_xlat1.y);
            u_xlatb1 = u_xlat1.x<(-u_xlat1.x);
            u_xlatb5 = u_xlat5>=(-u_xlat5);
            u_xlatb1 = u_xlatb5 && u_xlatb1;
            u_xlat2.x = (u_xlatb1) ? (-u_xlat12) : u_xlat12;
            u_xlat1.xy = (-u_xlat2.xy) * float2(0.159154937, 0.318309873) + float2(0.5, 1.0);
            u_xlatb12 = 1.0<u_xlat1.x;
            if(u_xlatb12){
                __nv_out = float4(0.0, 0.0, 0.0, 1.0);
                return __nv_out;
            }
            u_xlatb12 = u_xlat1.x>=(-u_xlat1.x);
            u_xlat1.x = fract(abs(u_xlat1.x));
            u_xlat2.x = (u_xlatb12) ? u_xlat1.x : (-u_xlat1.x);
            u_xlatb12 = 0<u._panoramic_upside_down;
            u_xlat1.x = (-u_xlat1.y) + 1.0;
            u_xlat2.y = (u_xlatb12) ? u_xlat1.x : u_xlat1.y;
            u_xlat0.xyz = panoramic_texture.sample(__nv_smp, u_xlat2.xy).xyz;
        } else {
            u_xlatb12 = u._material==3;
            if(u_xlatb12){
                u_xlat1.xyz = mat_cap.sample(__nv_smp, in.vs_TEXCOORD1.xy).xyz;
                u_xlat16_3.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
                u_xlat1.xyz = log2(u_xlat16_3.xyz);
                u_xlat1.xyz = u_xlat1.xyz * float3(0.416666657, 0.416666657, 0.416666657);
                u_xlat1.xyz = exp2(u_xlat1.xyz);
                u_xlat1.xyz = u_xlat1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
                u_xlat0.xyz = max(u_xlat1.xyz, float3(0.0, 0.0, 0.0));
            } else {
                u_xlat0.x = float(0.0);
                u_xlat0.y = float(0.0);
                u_xlat0.z = float(0.0);
            }
        }
    }
    u_xlat1.xyz = u._Color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat1.xyz = u._Color.xyz * u_xlat1.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat2.xyz = MainTex.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat1.xyz = u._Color.xyz * u_xlat1.xyz + u_xlat2.xyz;
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(u._reflection);
    u_xlat2.xyz = u_xlat2.xyz + u_xlat2.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(u._reflection) + u_xlat1.xyz;
    __nv_out.xyz = (int(u._reflection_mode) != 0) ? u_xlat0.xyz : u_xlat2.xyz;
    __nv_out.w = u._Color.w;
    return __nv_out;
    return __nv_out;
}
