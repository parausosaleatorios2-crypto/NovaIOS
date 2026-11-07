// ---------------------------------------------------------------------------
// Effect Stylize Emboss (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-emboss.xml
// id     : nv.effect.nodevideo-effect-stylize-emboss
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_embossParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _direction;
    float _relief;
    float _contrast;
    float _bw;
    float _invert;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool u_xlatb1;
float3 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
bool u_xlatb7;

fragment float4 fx_nv_nodevideo_effect_stylize_emboss(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_embossParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = u._relief * 0.00100000005;
    u_xlatb7 = int(u._invert)==1;
    if(u_xlatb7){
        u_xlat7.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat7.xyz = log2(u_xlat7.xyz);
        u_xlat7.xyz = u_xlat7.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat7.xyz = exp2(u_xlat7.xyz);
        u_xlat7.xyz = u_xlat7.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat7.xyz = max(u_xlat7.xyz, float3(0.0, 0.0, 0.0));
        u_xlat2.x = u._direction * 0.0174532924;
        u_xlat3.x = cos(u_xlat2.x);
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat3.y = u_xlat2.x;
        u_xlat2.xy = u_xlat3.xy * u_xlat1.xx + in.acScreenNorm.xy;
        u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
        u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat2.xyz = log2(u_xlat2.xyz);
        u_xlat2.xyz = u_xlat2.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat2.xyz = exp2(u_xlat2.xyz);
        u_xlat2.xyz = u_xlat2.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat7.xyz = u_xlat7.xyz + (-u_xlat2.xyz);
        u_xlat7.xyz = u_xlat7.xyz * float3(float3(u._contrast, u._contrast, u._contrast)) + float3(0.5, 0.5, 0.5);
    } else {
        u_xlat2.x = u._direction * 0.0174532924;
        u_xlat3.x = cos(u_xlat2.x);
        u_xlat2.x = sin(u_xlat2.x);
        u_xlat3.y = u_xlat2.x;
        u_xlat2.xy = u_xlat3.xy * u_xlat1.xx + in.acScreenNorm.xy;
        u_xlat2.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
        u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat2.xyz = log2(u_xlat2.xyz);
        u_xlat2.xyz = u_xlat2.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat2.xyz = exp2(u_xlat2.xyz);
        u_xlat2.xyz = u_xlat2.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat2.xyz = max(u_xlat2.xyz, float3(0.0, 0.0, 0.0));
        u_xlat3.xyz = max(u_xlat0.xyz, float3(0.0, 0.0, 0.0));
        u_xlat3.xyz = log2(u_xlat3.xyz);
        u_xlat3.xyz = u_xlat3.xyz * float3(0.416666657, 0.416666657, 0.416666657);
        u_xlat3.xyz = exp2(u_xlat3.xyz);
        u_xlat3.xyz = u_xlat3.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
        u_xlat3.xyz = max(u_xlat3.xyz, float3(0.0, 0.0, 0.0));
        u_xlat2.xyz = u_xlat2.xyz + (-u_xlat3.xyz);
        u_xlat7.xyz = u_xlat2.xyz * float3(float3(u._contrast, u._contrast, u._contrast)) + float3(0.5, 0.5, 0.5);
    }
    u_xlatb1 = int(u._bw)==1;
    u_xlat2.x = u_xlat7.y + u_xlat7.x;
    u_xlat2.x = u_xlat7.z + u_xlat2.x;
    u_xlat2.x = u_xlat2.x * 0.333333343;
    u_xlat1.xyz = (bool(u_xlatb1)) ? u_xlat2.xxx : u_xlat7.xyz;
    u_xlat2.xyz = u_xlat1.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat2.xyz = u_xlat1.xyz * u_xlat2.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    u_xlat1.xyz = u_xlat1.xyz * u_xlat2.xyz;
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
