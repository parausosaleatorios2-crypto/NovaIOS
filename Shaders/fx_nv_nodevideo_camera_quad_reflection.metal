// ---------------------------------------------------------------------------
// Camera Quad Reflection (NV)
// origem : assets/effects/nv-nodevideo-camera-quad-reflection.xml
// id     : nv.effect.nodevideo-camera-quad-reflection
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_camera_quad_reflectionParams {
    float _opacity;
    float _alpha_clip;
    float _reflection;
    float _panoramic_upside_down;
    float _reflection_mode;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
bool u_xlatb0;
float4 u_xlat1;
float3 u_xlat2;
bool u_xlatb2;
float u_xlat3;
bool u_xlatb3;
float u_xlat4;
float u_xlat6;
bool u_xlatb6;
float u_xlat7;
bool2 u_xlatb7;
float u_xlat9;

fragment float4 fx_nv_nodevideo_camera_quad_reflection(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_camera_quad_reflectionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> quad_tex [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = dot(in.vs_TEXCOORD2.xyz, in.vs_TEXCOORD2.xyz);
    u_xlat0.x = rsqrt(u_xlat0.x);
    u_xlat0.xyz = u_xlat0.xxx * in.vs_TEXCOORD2.yzx;
    u_xlat9 = -abs(u_xlat0.x) + 1.0;
    u_xlat9 = sqrt(u_xlat9);
    u_xlat1.x = abs(u_xlat0.x) * -0.0187292993 + 0.0742610022;
    u_xlat1.x = u_xlat1.x * abs(u_xlat0.x) + -0.212114394;
    u_xlat1.x = u_xlat1.x * abs(u_xlat0.x) + 1.57072878;
    u_xlat4 = u_xlat9 * u_xlat1.x;
    u_xlat4 = u_xlat4 * -2.0 + 3.14159274;
    u_xlatb7.xy = lessThan(u_xlat0.xzxz, (-u_xlat0.xzxz)).xy;
    u_xlat0.x = u_xlatb7.x ? u_xlat4 : float(0.0);
    u_xlat1.y = u_xlat1.x * u_xlat9 + u_xlat0.x;
    u_xlat0.x = min(abs(u_xlat0.z), abs(u_xlat0.y));
    u_xlat9 = max(abs(u_xlat0.z), abs(u_xlat0.y));
    u_xlat9 = float(1.0) / u_xlat9;
    u_xlat0.x = u_xlat9 * u_xlat0.x;
    u_xlat9 = u_xlat0.x * u_xlat0.x;
    u_xlat7 = u_xlat9 * 0.0208350997 + -0.0851330012;
    u_xlat7 = u_xlat9 * u_xlat7 + 0.180141002;
    u_xlat7 = u_xlat9 * u_xlat7 + -0.330299497;
    u_xlat9 = u_xlat9 * u_xlat7 + 0.999866009;
    u_xlat7 = u_xlat9 * u_xlat0.x;
    u_xlatb2 = abs(u_xlat0.z)<abs(u_xlat0.y);
    u_xlat7 = u_xlat7 * -2.0 + 1.57079637;
    u_xlat7 = u_xlatb2 ? u_xlat7 : float(0.0);
    u_xlat0.x = u_xlat0.x * u_xlat9 + u_xlat7;
    u_xlat9 = u_xlatb7.y ? -3.14159274 : float(0.0);
    u_xlat0.x = u_xlat9 + u_xlat0.x;
    u_xlat9 = min(u_xlat0.z, u_xlat0.y);
    u_xlat3 = max(u_xlat0.z, u_xlat0.y);
    u_xlatb6 = u_xlat9<(-u_xlat9);
    u_xlatb3 = u_xlat3>=(-u_xlat3);
    u_xlatb3 = u_xlatb3 && u_xlatb6;
    u_xlat1.x = (u_xlatb3) ? (-u_xlat0.x) : u_xlat0.x;
    u_xlat0.xy = (-u_xlat1.xy) * float2(0.159154937, 0.318309873) + float2(0.5, 1.0);
    u_xlatb6 = 1.0<u_xlat0.x;
    if(u_xlatb6){
        __nv_out = float4(0.0, 0.0, 0.0, 1.0);
        return __nv_out;
    }
    u_xlatb6 = u_xlat0.x>=(-u_xlat0.x);
    u_xlat0.x = fract(abs(u_xlat0.x));
    u_xlat1.x = (u_xlatb6) ? u_xlat0.x : (-u_xlat0.x);
    u_xlatb0 = 0<u._panoramic_upside_down;
    u_xlat6 = (-u_xlat0.y) + 1.0;
    u_xlat1.y = (u_xlatb0) ? u_xlat6 : u_xlat0.y;
    u_xlat0.xyz = inputImg.sample(__nv_smp, u_xlat1.xy).xyz;
    u_xlat1 = quad_tex.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat2.xyz = u_xlat0.xyz * u_xlat1.xyz;
    u_xlat2.xyz = u_xlat2.xyz * float3(u._reflection);
    u_xlat0.xyz = u_xlat0.xyz * u_xlat0.xyz;
    u_xlat0.xyz = u_xlat0.xyz * float3(u._reflection);
    u_xlat0.xyz = u_xlat0.xyz * float3(0.5, 0.5, 0.5) + u_xlat1.xyz;
    __nv_out.xyz = (int(u._reflection_mode) != 0) ? u_xlat0.xyz : u_xlat2.xyz;
    u_xlat0.x = u_xlat1.w * u._opacity;
    u_xlat3 = u_xlat1.w * u._opacity + (-u._alpha_clip);
    u_xlatb3 = u_xlat3<0.0;
    if(u_xlatb3){discard_fragment();}
    __nv_out.w = u_xlat0.x;
    return __nv_out;
    return __nv_out;
}
