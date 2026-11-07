// ---------------------------------------------------------------------------
// Rendercommand Extrude Txt 3D (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-extrude-txt-3d.xml
// id     : nv.effect.nodevideo-rendercommand-extrude-txt-3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_extrude_txt_3dParams {
    float4 _color;
    float _reflection;
    float _material;
    float _has_texture;
    float2 _texture_offset;
    float2 _texture_scale;
    float _texture_rotation;
    float _panoramic_upside_down;
    float _reflection_mode;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float4 u_xlat1;
float3 u_xlat16_1;
float3 u_xlat2;
bool u_xlatb2;
float2 u_xlat3;
float2 u_xlat4;
bool u_xlatb4;
float3 u_xlat5;
float u_xlat8;
bool u_xlatb8;
float u_xlat9;
float u_xlat14;
bool u_xlatb14;
float u_xlat15;
bool2 u_xlatb15;
int u_xlati18;
float u_xlat20;

fragment float4 fx_nv_nodevideo_rendercommand_extrude_txt_3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_extrude_txt_3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> cube [[texture(1)]],
    texture2d<float> panoramic_texture [[texture(2)]],
    texture2d<float> text_texture [[texture(3)]])
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
        u_xlati18 = 0;
    } else {
        u_xlatb2 = u._material==1;
        if(u_xlatb2){
            u_xlat0.xyz = cube.sample(__nv_smp, in.vs_TEXCOORD2.xyz).xyz;
        } else {
            u_xlat2.x = dot(in.vs_TEXCOORD2.xyz, in.vs_TEXCOORD2.xyz);
            u_xlat2.x = rsqrt(u_xlat2.x);
            u_xlat2.xyz = u_xlat2.xxx * in.vs_TEXCOORD2.yzx;
            u_xlat20 = -abs(u_xlat2.x) + 1.0;
            u_xlat20 = sqrt(u_xlat20);
            u_xlat3.x = abs(u_xlat2.x) * -0.0187292993 + 0.0742610022;
            u_xlat3.x = u_xlat3.x * abs(u_xlat2.x) + -0.212114394;
            u_xlat3.x = u_xlat3.x * abs(u_xlat2.x) + 1.57072878;
            u_xlat9 = u_xlat20 * u_xlat3.x;
            u_xlat9 = u_xlat9 * -2.0 + 3.14159274;
            u_xlatb15.xy = lessThan(u_xlat2.xzxz, (-u_xlat2.xzxz)).xy;
            u_xlat2.x = u_xlatb15.x ? u_xlat9 : float(0.0);
            u_xlat3.y = u_xlat3.x * u_xlat20 + u_xlat2.x;
            u_xlat2.x = min(abs(u_xlat2.z), abs(u_xlat2.y));
            u_xlat20 = max(abs(u_xlat2.z), abs(u_xlat2.y));
            u_xlat20 = float(1.0) / u_xlat20;
            u_xlat2.x = u_xlat20 * u_xlat2.x;
            u_xlat20 = u_xlat2.x * u_xlat2.x;
            u_xlat15 = u_xlat20 * 0.0208350997 + -0.0851330012;
            u_xlat15 = u_xlat20 * u_xlat15 + 0.180141002;
            u_xlat15 = u_xlat20 * u_xlat15 + -0.330299497;
            u_xlat20 = u_xlat20 * u_xlat15 + 0.999866009;
            u_xlat15 = u_xlat20 * u_xlat2.x;
            u_xlatb4 = abs(u_xlat2.z)<abs(u_xlat2.y);
            u_xlat15 = u_xlat15 * -2.0 + 1.57079637;
            u_xlat15 = u_xlatb4 ? u_xlat15 : float(0.0);
            u_xlat2.x = u_xlat2.x * u_xlat20 + u_xlat15;
            u_xlat20 = u_xlatb15.y ? -3.14159274 : float(0.0);
            u_xlat2.x = u_xlat20 + u_xlat2.x;
            u_xlat20 = min(u_xlat2.z, u_xlat2.y);
            u_xlat8 = max(u_xlat2.z, u_xlat2.y);
            u_xlatb14 = u_xlat20<(-u_xlat20);
            u_xlatb8 = u_xlat8>=(-u_xlat8);
            u_xlatb8 = u_xlatb8 && u_xlatb14;
            u_xlat3.x = (u_xlatb8) ? (-u_xlat2.x) : u_xlat2.x;
            u_xlat2.xy = (-u_xlat3.xy) * float2(0.159154937, 0.318309873) + float2(0.5, 1.0);
            u_xlatb14 = 1.0<u_xlat2.x;
            if(u_xlatb14){
                __nv_out = float4(0.0, 0.0, 0.0, 1.0);
                return __nv_out;
            }
            u_xlatb14 = u_xlat2.x>=(-u_xlat2.x);
            u_xlat2.x = fract(abs(u_xlat2.x));
            u_xlat3.x = (u_xlatb14) ? u_xlat2.x : (-u_xlat2.x);
            u_xlatb2 = 0<u._panoramic_upside_down;
            u_xlat14 = (-u_xlat2.y) + 1.0;
            u_xlat3.y = (u_xlatb2) ? u_xlat14 : u_xlat2.y;
            u_xlat0.xyz = panoramic_texture.sample(__nv_smp, u_xlat3.xy).xyz;
        }
        u_xlati18 = u._reflection_mode;
    }
    u_xlatb2 = u._has_texture==1;
    if(u_xlatb2){
        u_xlat2.xy = in.acScreenNorm.xy + float2(-0.5, -0.5);
        u_xlat2.xy = u_xlat2.xy * float2(u._texture_scale.x, u._texture_scale.y);
        u_xlat14 = u._texture_rotation * 0.0174532924;
        u_xlat3.x = sin(u_xlat14);
        u_xlat4.x = cos(u_xlat14);
        u_xlat5.x = sin((-u_xlat14));
        u_xlat5.y = u_xlat4.x;
        u_xlat4.x = dot(u_xlat5.yx, u_xlat2.xy);
        u_xlat5.z = u_xlat3.x;
        u_xlat4.y = dot(u_xlat5.zy, u_xlat2.xy);
        u_xlat2.xy = u_xlat4.xy + u._texture_offset.xy;
        u_xlat2.xy = u_xlat2.xy + float2(0.5, 0.5);
        u_xlat1 = text_texture.sample(__nv_smp, u_xlat2.xy);
        u_xlat1 = u_xlat1 * u._color;
        __nv_out.w = u_xlat1.w;
    } else {
        u_xlat1.xyz = u._color.xyz;
        __nv_out.w = u._color.w;
    }
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(u._reflection);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(u._reflection);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.5, 0.5, 0.5) + u_xlat1.xyz;
    __nv_out.xyz = (int(u_xlati18) != 0) ? u_xlat0.xyz : u_xlat2.xyz;
    return __nv_out;
    return __nv_out;
}
