// ---------------------------------------------------------------------------
// Rgb Displacement (NV)
// origem : assets/effects/nv-nodevideo-assetstore-rgb-displacement.xml
// id     : nv.effect.nodevideo-assetstore-rgb-displacement
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_assetstore_rgb_displacementParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _channel;
    float _evolution;
    float _phase;
    float _scale;
    float _saturation;
    float _blend;
    float4 _color1;
    float4 _color2;
    float4 _color3;
};

// --- funcoes auxiliares do efeito
float4 ImmCB_0[4];

float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float4 u_xlat2;
bool3 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float u_xlat8;
float2 u_xlat9;
float u_xlat19;
int u_xlati19;
float u_xlat20;

fragment float4 fx_nv_nodevideo_assetstore_rgb_displacement(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_assetstore_rgb_displacementParams&  u    [[buffer(1)]],
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
    u_xlatb1 = u_xlat0.y>=u_xlat0.z;
    u_xlat1.x = u_xlatb1 ? 1.0 : float(0.0);
    u_xlat2.xy = u_xlat0.zy;
    u_xlat2.z = float(-1.0);
    u_xlat2.w = float(0.666666687);
    u_xlat3.xy = u_xlat0.yz + (-u_xlat2.xy);
    u_xlat3.z = float(1.0);
    u_xlat3.w = float(-1.0);
    u_xlat1 = u_xlat1.xxxx * u_xlat3 + u_xlat2;
    u_xlatb2.x = u_xlat0.x>=u_xlat1.x;
    u_xlat2.x = u_xlatb2.x ? 1.0 : float(0.0);
    u_xlat3.xyz = u_xlat1.xyw;
    u_xlat3.w = u_xlat0.x;
    u_xlat1.xyw = u_xlat3.wyx;
    u_xlat1 = (-u_xlat3) + u_xlat1;
    u_xlat1 = u_xlat2.xxxx * u_xlat1.yzxw + u_xlat3.yzxw;
    u_xlat2.x = min(u_xlat1.x, u_xlat1.w);
    u_xlat2.x = u_xlat1.z + (-u_xlat2.x);
    u_xlat19 = (-u_xlat1.x) + u_xlat1.w;
    u_xlat8 = u_xlat2.x * 6.0 + 9.99999975e-05;
    u_xlat19 = u_xlat19 / u_xlat8;
    u_xlat19 = u_xlat19 + u_xlat1.y;
    u_xlat1.x = abs(u_xlat19);
    u_xlat19 = u_xlat1.z + 9.99999975e-05;
    u_xlat1.y = u_xlat2.x / u_xlat19;
    u_xlati19 = int(u._channel);
    u_xlat1.x = dot(u_xlat1.xyz, ImmCB_0[u_xlati19].xyz);
    u_xlat1.x = log2(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * u._scale;
    u_xlat1.x = exp2(u_xlat1.x);
    u_xlat1.x = u_xlat1.x * u._phase + u._evolution;
    u_xlat1.xyz = u_xlat1.xxx + float3(10.0, 9.66666698, 9.33333302);
    u_xlatb2.xyz = greaterThanEqual(u_xlat1.xyzx, (-u_xlat1.xyzx)).xyz;
    u_xlat1.xyz = fract(abs(u_xlat1.xyz));
    {
        float4 hlslcc_movcTemp = u_xlat1;
        hlslcc_movcTemp.x = (u_xlatb2.x) ? u_xlat1.x : (-u_xlat1.x);
        hlslcc_movcTemp.y = (u_xlatb2.y) ? u_xlat1.y : (-u_xlat1.y);
        hlslcc_movcTemp.z = (u_xlatb2.z) ? u_xlat1.z : (-u_xlat1.z);
        u_xlat1 = hlslcc_movcTemp;
    }
    u_xlat1.xyz = u_xlat1.xyz + float3(-0.5, -0.5, -0.5);
    u_xlat1.xyz = abs(u_xlat1.xyz) * float3(4.0, 4.0, 4.0) + float3(-0.333299994, -0.333299994, -0.333299994);
    u_xlat1.xyz = clamp(u_xlat1.xyz, 0.0, 1.0);
    u_xlat2 = u_xlat1.yyyy * u._color2;
    u_xlat2 = u_xlat1.xxxx * u._color1 + u_xlat2;
    u_xlat1 = u_xlat1.zzzz * u._color3 + u_xlat2;
    u_xlat2.x = dot(float3(0.298999995, 0.587000012, 0.114), u_xlat1.xyz);
    u_xlat9.x = dot(float3(-0.147129998, -0.288859993, 0.43599999), u_xlat1.xyz);
    u_xlat9.y = dot(float3(0.61500001, -0.514989972, -0.10001), u_xlat1.xyz);
    u_xlat20 = u._saturation + 1.0;
    u_xlat2.yz = float2(u_xlat20) * u_xlat9.xy;
    u_xlat1.x = dot(float2(1.0, 1.13982999), u_xlat2.xz);
    u_xlat1.y = dot(float3(1.0, -0.394650012, -0.580600023), u_xlat2.xyz);
    u_xlat1.z = dot(float2(1.0, 2.03210998), u_xlat2.xy);
    u_xlat1 = u_xlat1 * u_xlat0.wwww + (-u_xlat0);
    u_xlat1 = float4(float4(u._blend, u._blend, u._blend, u._blend)) * u_xlat1 + u_xlat0;
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
