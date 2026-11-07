// ---------------------------------------------------------------------------
// Rendercommand Custom Model (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-custom-model.xml
// id     : nv.effect.nodevideo-rendercommand-custom-model
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_custom_modelParams {
    float4 _color;
    float4 _tint;
    float _material;
    float _reflection;
    float _panoramic_upside_down;
    float _reflection_mode;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
float3 u_xlat16_1;
float3 u_xlat2;
bool u_xlatb2;
float3 u_xlat3;
bool u_xlatb4;
float u_xlat7;
bool u_xlatb7;
float u_xlat8;
float u_xlat12;
bool u_xlatb12;
float u_xlat13;
bool2 u_xlatb13;
int u_xlati15;
float u_xlat17;

fragment float4 fx_nv_nodevideo_rendercommand_custom_model(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_custom_modelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> cube [[texture(1)]],
    texture2d<float> panoramic_texture [[texture(2)]],
    texture2d<float> model_tex [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlatb0 = u._material==1;
    if(u_xlatb0){
        u_xlat0.xyz = inputImg.sample(__nv_smp, in.vs_TEXCOORD1.xy).xyz;
        u_xlat16_1.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat0.xyz = log2(u_xlat16_1.xyz);
        u_xlat0.xyz = u_xlat0.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat0.xyz = exp2(u_xlat0.xyz);
        u_xlat0.xyz = u_xlat0.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat0.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlati15 = 0;
    } else {
        u_xlatb2 = u._material==2;
        if(u_xlatb2){
            u_xlat0.xyz = cube.sample(__nv_smp, in.vs_TEXCOORD2.xyz).xyz;
        } else {
            u_xlatb2 = u._material==3;
            if(u_xlatb2){
                u_xlat2.x = dot(in.vs_TEXCOORD2.xyz, in.vs_TEXCOORD2.xyz);
                u_xlat2.x = rsqrt(u_xlat2.x);
                u_xlat2.xyz = u_xlat2.xxx * in.vs_TEXCOORD2.yzx;
                u_xlat17 = -abs(u_xlat2.x) + 1.0;
                u_xlat17 = sqrt(u_xlat17);
                u_xlat3.x = abs(u_xlat2.x) * -0.0187292993 + 0.0742610022;
                u_xlat3.x = u_xlat3.x * abs(u_xlat2.x) + -0.212114394;
                u_xlat3.x = u_xlat3.x * abs(u_xlat2.x) + 1.57072878;
                u_xlat8 = u_xlat17 * u_xlat3.x;
                u_xlat8 = u_xlat8 * -2.0 + 3.14159274;
                u_xlatb13.xy = lessThan(u_xlat2.xzxz, (-u_xlat2.xzxz)).xy;
                u_xlat2.x = u_xlatb13.x ? u_xlat8 : float(0.0);
                u_xlat3.y = u_xlat3.x * u_xlat17 + u_xlat2.x;
                u_xlat2.x = min(abs(u_xlat2.z), abs(u_xlat2.y));
                u_xlat17 = max(abs(u_xlat2.z), abs(u_xlat2.y));
                u_xlat17 = float(1.0) / u_xlat17;
                u_xlat2.x = u_xlat17 * u_xlat2.x;
                u_xlat17 = u_xlat2.x * u_xlat2.x;
                u_xlat13 = u_xlat17 * 0.0208350997 + -0.0851330012;
                u_xlat13 = u_xlat17 * u_xlat13 + 0.180141002;
                u_xlat13 = u_xlat17 * u_xlat13 + -0.330299497;
                u_xlat17 = u_xlat17 * u_xlat13 + 0.999866009;
                u_xlat13 = u_xlat17 * u_xlat2.x;
                u_xlatb4 = abs(u_xlat2.z)<abs(u_xlat2.y);
                u_xlat13 = u_xlat13 * -2.0 + 1.57079637;
                u_xlat13 = u_xlatb4 ? u_xlat13 : float(0.0);
                u_xlat2.x = u_xlat2.x * u_xlat17 + u_xlat13;
                u_xlat17 = u_xlatb13.y ? -3.14159274 : float(0.0);
                u_xlat2.x = u_xlat17 + u_xlat2.x;
                u_xlat17 = min(u_xlat2.z, u_xlat2.y);
                u_xlat7 = max(u_xlat2.z, u_xlat2.y);
                u_xlatb12 = u_xlat17<(-u_xlat17);
                u_xlatb7 = u_xlat7>=(-u_xlat7);
                u_xlatb7 = u_xlatb7 && u_xlatb12;
                u_xlat3.x = (u_xlatb7) ? (-u_xlat2.x) : u_xlat2.x;
                u_xlat2.xy = (-u_xlat3.xy) * float2(0.159154937, 0.318309873) + float2(0.5, 1.0);
                u_xlatb12 = 1.0<u_xlat2.x;
                if(u_xlatb12){
                    __nv_out = float4(0.0, 0.0, 0.0, 1.0);
                    return __nv_out;
                }
                u_xlatb12 = u_xlat2.x>=(-u_xlat2.x);
                u_xlat2.x = fract(abs(u_xlat2.x));
                u_xlat3.x = (u_xlatb12) ? u_xlat2.x : (-u_xlat2.x);
                u_xlatb2 = 0<u._panoramic_upside_down;
                u_xlat12 = (-u_xlat2.y) + 1.0;
                u_xlat3.y = (u_xlatb2) ? u_xlat12 : u_xlat2.y;
                u_xlat0.xyz = panoramic_texture.sample(__nv_smp, u_xlat3.xy).xyz;
            } else {
                u_xlat0.x = float(0.0);
                u_xlat0.y = float(0.0);
                u_xlat0.z = float(0.0);
            }
        }
        u_xlati15 = u._reflection_mode;
    }
    u_xlat1 = model_tex.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.xyz = u._color.xyz * u._tint.xyz;
    u_xlat3.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat3.xyz = u_xlat2.xyz * u_xlat3.xyz;
    u_xlat3.xyz = u_xlat3.xyz * float3(float3(u._reflection, u._reflection, u._reflection));
    u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat0.xyz = u_xlat2.xyz * u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(float3(u._reflection, u._reflection, u._reflection)) + u_xlat1.xyz;
    __nv_out.xyz = (int(u_xlati15) != 0) ? u_xlat0.xyz : u_xlat3.xyz;
    __nv_out.w = u_xlat1.w;
    return __nv_out;
    return __nv_out;
}
