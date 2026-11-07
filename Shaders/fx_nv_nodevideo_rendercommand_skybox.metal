// ---------------------------------------------------------------------------
// Rendercommand Skybox (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-skybox.xml
// id     : nv.effect.nodevideo-rendercommand-skybox
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_skyboxParams {
    float4 _MainTex_HDR;
    float4 _Tint;
    float _Exposure;
    float _panoramic_upside_down;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
bool u_xlatb0;
float3 u_xlat1;
bool u_xlatb2;
float3 u_xlat16_3;
float2 u_xlat4;
bool u_xlatb4;
float2 u_xlat5;
bool u_xlatb8;
bool2 u_xlatb9;
float u_xlat12;
bool u_xlatb12;

fragment float4 fx_nv_nodevideo_rendercommand_skybox(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_skyboxParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = dot(in.acScreenNorm.xyz, in.acScreenNorm.xyz);
    u_xlat0.x = rsqrt(u_xlat0.x);
    u_xlat0.xyz = u_xlat0.xxx * in.acScreenNorm.yzx;
    u_xlat12 = -abs(u_xlat0.x) + 1.0;
    u_xlat12 = sqrt(u_xlat12);
    u_xlat1.x = abs(u_xlat0.x) * -0.0187292993 + 0.0742610022;
    u_xlat1.x = u_xlat1.x * abs(u_xlat0.x) + -0.212114394;
    u_xlat1.x = u_xlat1.x * abs(u_xlat0.x) + 1.57072878;
    u_xlat5.x = u_xlat12 * u_xlat1.x;
    u_xlat5.x = u_xlat5.x * -2.0 + 3.14159274;
    u_xlatb9.xy = lessThan(u_xlat0.xzxz, (-u_xlat0.xzxz)).xy;
    u_xlat0.x = u_xlatb9.x ? u_xlat5.x : float(0.0);
    u_xlat5.y = u_xlat1.x * u_xlat12 + u_xlat0.x;
    u_xlat0.x = min(abs(u_xlat0.z), abs(u_xlat0.y));
    u_xlat12 = max(abs(u_xlat0.z), abs(u_xlat0.y));
    u_xlat12 = float(1.0) / u_xlat12;
    u_xlat0.x = u_xlat12 * u_xlat0.x;
    u_xlat12 = u_xlat0.x * u_xlat0.x;
    u_xlat1.x = u_xlat12 * 0.0208350997 + -0.0851330012;
    u_xlat1.x = u_xlat12 * u_xlat1.x + 0.180141002;
    u_xlat1.x = u_xlat12 * u_xlat1.x + -0.330299497;
    u_xlat12 = u_xlat12 * u_xlat1.x + 0.999866009;
    u_xlat1.x = u_xlat12 * u_xlat0.x;
    u_xlatb2 = abs(u_xlat0.z)<abs(u_xlat0.y);
    u_xlat1.x = u_xlat1.x * -2.0 + 1.57079637;
    u_xlat1.x = u_xlatb2 ? u_xlat1.x : float(0.0);
    u_xlat0.x = u_xlat0.x * u_xlat12 + u_xlat1.x;
    u_xlat12 = u_xlatb9.y ? -3.14159274 : float(0.0);
    u_xlat0.x = u_xlat12 + u_xlat0.x;
    u_xlat12 = min(u_xlat0.z, u_xlat0.y);
    u_xlat4.x = max(u_xlat0.z, u_xlat0.y);
    u_xlatb8 = u_xlat12<(-u_xlat12);
    u_xlatb4 = u_xlat4.x>=(-u_xlat4.x);
    u_xlatb4 = u_xlatb4 && u_xlatb8;
    u_xlat5.x = (u_xlatb4) ? (-u_xlat0.x) : u_xlat0.x;
    u_xlat4.x = 0.5;
    u_xlat4.y = in.vs_TEXCOORD2.y;
    u_xlat0.yz = (-u_xlat5.xy) * float2(0.159154937, 0.318309873) + u_xlat4.xy;
    u_xlatb12 = in.vs_TEXCOORD1.y<u_xlat0.y;
    if(u_xlatb12){
        __nv_out = float4(0.0, 0.0, 0.0, 1.0);
        return __nv_out;
    }
    u_xlat4.x = u_xlat0.y * in.vs_TEXCOORD1.x;
    u_xlatb12 = u_xlat4.x>=(-u_xlat4.x);
    u_xlat4.x = fract(abs(u_xlat4.x));
    u_xlat0.x = (u_xlatb12) ? u_xlat4.x : (-u_xlat4.x);
    u_xlat1.x = in.vs_TEXCOORD2.x;
    u_xlat1.y = 1.0;
    u_xlat0.xy = u_xlat0.xz + u_xlat1.xy;
    u_xlat1.xy = u_xlat0.xy * in.vs_TEXCOORD2.zw;
    u_xlatb0 = 0<u._panoramic_upside_down;
    u_xlat4.x = (-u_xlat0.y) * in.vs_TEXCOORD2.w + 1.0;
    u_xlat1.z = (u_xlatb0) ? u_xlat4.x : u_xlat1.y;
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat1.xz);
    u_xlat16_3.x = u_xlat0.w + -1.0;
    u_xlat16_3.x = u._MainTex_HDR.w * u_xlat16_3.x + 1.0;
    u_xlat16_3.x = log2(u_xlat16_3.x);
    u_xlat16_3.x = u_xlat16_3.x * u._MainTex_HDR.y;
    u_xlat16_3.x = exp2(u_xlat16_3.x);
    u_xlat16_3.x = u_xlat16_3.x * u._MainTex_HDR.x;
    u_xlat16_3.xyz = u_xlat0.xyz * u_xlat16_3.xxx;
    u_xlat16_3.xyz = u_xlat16_3.xyz * u._Tint.xyz;
    u_xlat16_3.xyz = u_xlat16_3.xyz * float3(u._Exposure);
    __nv_out.xyz = u_xlat16_3.xyz * float3(4.5947938, 4.5947938, 4.5947938);
    __nv_out.w = 1.0;
    return __nv_out;
    return __nv_out;
}
