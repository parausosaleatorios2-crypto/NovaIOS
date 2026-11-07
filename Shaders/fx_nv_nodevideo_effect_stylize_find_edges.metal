// ---------------------------------------------------------------------------
// Effect Stylize Find Edges (NV)
// origem : assets/effects/nv-nodevideo-effect-stylize-find-edges.xml
// id     : nv.effect.nodevideo-effect-stylize-find-edges
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_stylize_find_edgesParams {
    float _use_inner_mask;
    float _b_clip_mask;
    float _show_inner_mask;
    float _invert;
    float _blend_with_original;
    float _threshold;
};

// --- funcoes auxiliares do efeito
// globais do Node ligados ao motor (tools/nodevideo/ligar_globais.py)
#define _resolution eng.acTamanhoDaTela
float4 u_xlat0;
float4 u_xlat1;
float4 u_xlat2;
bool2 u_xlatb2;
float4 u_xlat3;
float4 u_xlat4;
float4 u_xlat5;
float3 u_xlat7;
float3 u_xlat9;
float u_xlat13;
float u_xlat19;

fragment float4 fx_nv_nodevideo_effect_stylize_find_edges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_stylize_find_edgesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> Mask [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.xy = float2(1.0, 1.0) / _resolution.xy;
    u_xlat1.z = (-u_xlat1.x);
    u_xlat2 = u_xlat1.zyxy + in.acScreenNorm.xyxy;
    u_xlat3.xyz = inputImg.sample(__nv_smp, u_xlat2.xy).xyz;
    u_xlat13 = dot(u_xlat3.xyz, u_xlat3.xyz);
    u_xlat13 = sqrt(u_xlat13);
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
    u_xlat2.x = u_xlat2.x * 2.0 + u_xlat13;
    u_xlat2.x = u_xlat2.y + u_xlat2.x;
    u_xlat2.x = (-u_xlat1.y) + u_xlat2.x;
    u_xlat19 = (-u_xlat1.w) * 2.0 + u_xlat2.x;
    u_xlat19 = (-u_xlat2.z) + u_xlat19;
    u_xlat13 = (-u_xlat3.x) * 2.0 + (-u_xlat13);
    u_xlat7.x = (-u_xlat1.y) + u_xlat13;
    u_xlat7.x = u_xlat2.y + u_xlat7.x;
    u_xlat1.x = u_xlat1.x * 2.0 + u_xlat7.x;
    u_xlat1.x = u_xlat2.z + u_xlat1.x;
    u_xlat1.x = u_xlat1.x * u_xlat1.x;
    u_xlat1.x = u_xlat19 * u_xlat19 + u_xlat1.x;
    u_xlat1.x = sqrt(u_xlat1.x);
    u_xlat1.x = u_xlat1.x + (-u._threshold);
    u_xlat7.xyz = u_xlat0.xyz * u_xlat1.xxx;
    u_xlatb2.x = int(u._invert)==1;
    u_xlat1.x = (-u_xlat1.x) + 1.0;
    u_xlat1.xyz = (u_xlatb2.x) ? u_xlat1.xxx : u_xlat7.xyz;
    u_xlat19 = (-u._blend_with_original) + 1.0;
    u_xlat1.xyz = u_xlat1.xyz * float3(u_xlat19);
    u_xlat1.xyz = u_xlat0.xyz * float3(float3(u._blend_with_original, u._blend_with_original, u._blend_with_original)) + u_xlat1.xyz;
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
