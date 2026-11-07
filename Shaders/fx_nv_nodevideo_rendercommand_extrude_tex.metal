// ---------------------------------------------------------------------------
// Rendercommand Extrude Tex (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-extrude-tex.xml
// id     : nv.effect.nodevideo-rendercommand-extrude-tex
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_extrude_texParams {
    float _edge;
    float4 _edge_color;
    float _is_text;
    float4 _text_color;
    float4 _tint;
    float _material;
    float _reflection;
    float _panoramic_upside_down;
    float _reflection_mode;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float3 u_xlat16_1;
int u_xlati2;
float4 u_xlat3;
bool2 u_xlatb4;
float3 u_xlat7;
bool u_xlatb7;
float u_xlat8;
float u_xlat12;
bool u_xlatb12;
float u_xlat13;
float u_xlat17;
bool u_xlatb17;
float u_xlat18;

fragment float4 fx_nv_nodevideo_rendercommand_extrude_tex(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_extrude_texParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> cube [[texture(1)]],
    texture2d<float> panoramic_texture [[texture(2)]],
    texture2d<float> source_tex [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if(u._material == 0) {
        u_xlat0.xyz = inputImg.sample(__nv_smp, in.vs_TEXCOORD1.xy).xyz;
        u_xlat16_1.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat0.xyz = log2(u_xlat16_1.xyz);
        u_xlat0.xyz = u_xlat0.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat0.xyz = exp2(u_xlat0.xyz);
        u_xlat0.xyz = u_xlat0.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat0.w = 1.0;
        u_xlati2 = 0;
    } else {
        u_xlatb7 = u._material==1;
        if(u_xlatb7){
            u_xlat0 = cube.sample(__nv_smp, in.vs_TEXCOORD2.xyz);
        } else {
            u_xlat7.x = dot(in.vs_TEXCOORD2.xyz, in.vs_TEXCOORD2.xyz);
            u_xlat7.x = rsqrt(u_xlat7.x);
            u_xlat7.xyz = u_xlat7.xxx * in.vs_TEXCOORD2.yzx;
            u_xlat3.x = -abs(u_xlat7.x) + 1.0;
            u_xlat3.x = sqrt(u_xlat3.x);
            u_xlat8 = abs(u_xlat7.x) * -0.0187292993 + 0.0742610022;
            u_xlat8 = u_xlat8 * abs(u_xlat7.x) + -0.212114394;
            u_xlat8 = u_xlat8 * abs(u_xlat7.x) + 1.57072878;
            u_xlat13 = u_xlat3.x * u_xlat8;
            u_xlat13 = u_xlat13 * -2.0 + 3.14159274;
            u_xlatb4.xy = lessThan(u_xlat7.xzxx, (-u_xlat7.xzxx)).xy;
            u_xlat7.x = u_xlatb4.x ? u_xlat13 : float(0.0);
            u_xlat3.y = u_xlat8 * u_xlat3.x + u_xlat7.x;
            u_xlat7.x = min(abs(u_xlat7.z), abs(u_xlat7.y));
            u_xlat13 = max(abs(u_xlat7.z), abs(u_xlat7.y));
            u_xlat13 = float(1.0) / u_xlat13;
            u_xlat7.x = u_xlat7.x * u_xlat13;
            u_xlat13 = u_xlat7.x * u_xlat7.x;
            u_xlat18 = u_xlat13 * 0.0208350997 + -0.0851330012;
            u_xlat18 = u_xlat13 * u_xlat18 + 0.180141002;
            u_xlat18 = u_xlat13 * u_xlat18 + -0.330299497;
            u_xlat13 = u_xlat13 * u_xlat18 + 0.999866009;
            u_xlat18 = u_xlat7.x * u_xlat13;
            u_xlatb4.x = abs(u_xlat7.z)<abs(u_xlat7.y);
            u_xlat18 = u_xlat18 * -2.0 + 1.57079637;
            u_xlat18 = u_xlatb4.x ? u_xlat18 : float(0.0);
            u_xlat7.x = u_xlat7.x * u_xlat13 + u_xlat18;
            u_xlat13 = u_xlatb4.y ? -3.14159274 : float(0.0);
            u_xlat7.x = u_xlat7.x + u_xlat13;
            u_xlat13 = min(u_xlat7.z, u_xlat7.y);
            u_xlat12 = max(u_xlat7.z, u_xlat7.y);
            u_xlatb17 = u_xlat13<(-u_xlat13);
            u_xlatb12 = u_xlat12>=(-u_xlat12);
            u_xlatb12 = u_xlatb12 && u_xlatb17;
            u_xlat3.x = (u_xlatb12) ? (-u_xlat7.x) : u_xlat7.x;
            u_xlat7.xy = (-u_xlat3.xy) * float2(0.159154937, 0.318309873) + float2(0.5, 1.0);
            u_xlatb17 = 1.0<u_xlat7.x;
            if(u_xlatb17){
                __nv_out = float4(0.0, 0.0, 0.0, 1.0);
                return __nv_out;
            }
            u_xlatb17 = u_xlat7.x>=(-u_xlat7.x);
            u_xlat7.x = fract(abs(u_xlat7.x));
            u_xlat3.x = (u_xlatb17) ? u_xlat7.x : (-u_xlat7.x);
            u_xlatb7 = 0<u._panoramic_upside_down;
            u_xlat17 = (-u_xlat7.y) + 1.0;
            u_xlat3.y = (u_xlatb7) ? u_xlat17 : u_xlat7.y;
            u_xlat0 = panoramic_texture.sample(__nv_smp, u_xlat3.xy);
        }
        u_xlati2 = u._reflection_mode;
    }
    u_xlatb7 = u._edge!=0;
    u_xlatb12 = 0.5<in.vs_COLOR0.w;
    u_xlatb7 = u_xlatb12 && u_xlatb7;
    if(u_xlatb7){
        u_xlat7.xyz = u._edge_color.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
        u_xlat7.xyz = u._edge_color.xyz * u_xlat7.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
        u_xlat1.xyz = u_xlat7.xyz * u._edge_color.xyz;
        u_xlat1.w = 1.0;
        u_xlat3 = u_xlat0 * u_xlat1;
        u_xlat3 = u_xlat3 * float4(float4(u._reflection, u._reflection, u._reflection, u._reflection));
        u_xlat7.xyz = u_xlat0.xyz * u_xlat0.xyz;
        u_xlat1.xyz = u_xlat7.xyz * float3(float3(u._reflection, u._reflection, u._reflection)) + u_xlat1.xyz;
        u_xlat1.w = 1.0;
        __nv_out = (int(u_xlati2) != 0) ? u_xlat1 : u_xlat3;
        return __nv_out;
    }
    u_xlatb7 = u._is_text==1;
    if(u_xlatb7){
        if(u_xlati2 == 0) {
            u_xlat1 = u._text_color * u._tint;
            u_xlat1 = u_xlat0 * u_xlat1;
            __nv_out = u_xlat1 * float4(float4(u._reflection, u._reflection, u._reflection, u._reflection));
            return __nv_out;
        } else {
            u_xlat7.xyz = u_xlat0.xyz * u_xlat0.xyz;
            u_xlat7.xyz = u_xlat7.xyz * u._tint.xyz;
            __nv_out.xyz = u_xlat7.xyz * float3(float3(u._reflection, u._reflection, u._reflection)) + u._text_color.xyz;
            __nv_out.w = u._text_color.w;
            return __nv_out;
        }
    }
    u_xlat7.xyz = source_tex.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    if(u_xlati2 == 0) {
        u_xlat3.xyz = u_xlat7.xyz * u._tint.xyz;
        u_xlat3.xyz = u_xlat0.xyz * u_xlat3.xyz;
        __nv_out.xyz = u_xlat3.xyz * float3(float3(u._reflection, u._reflection, u._reflection));
        __nv_out.w = 1.0;
        return __nv_out;
    } else {
        u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
        u_xlat0.xyz = u_xlat0.xyz * u._tint.xyz;
        __nv_out.xyz = u_xlat0.xyz * float3(float3(u._reflection, u._reflection, u._reflection)) + u_xlat7.xyz;
        __nv_out.w = 1.0;
        return __nv_out;
    }
    return __nv_out;
    return __nv_out;
}
