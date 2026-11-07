// ---------------------------------------------------------------------------
// Effect Layer Mask (NV)
// origem : assets/effects/nv-nodevideo-effect-layer-mask.xml
// id     : nv.effect.nodevideo-effect-layer-mask
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_layer_maskParams {
    float _channel;
    float _invert;
    float _show_mask;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
bool4 u_xlatb2;
float u_xlat3;
bool u_xlatb3;
float u_xlat6;
float u_xlat9;

fragment float4 fx_nv_nodevideo_effect_layer_mask(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_layer_maskParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> source [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = source.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlat1.x = dot(u_xlat0.xyz, float3(0.300000012, 0.589999974, 0.109999999));
    u_xlatb2 = equal(int4(int(u._channel), int(u._channel), int(u._channel), int(u._invert)), int4(1, 2, 3, 1));
    u_xlat9 = (u_xlatb2.z) ? u_xlat0.w : u_xlat1.x;
    u_xlat6 = (u_xlatb2.y) ? u_xlat0.z : u_xlat9;
    u_xlat3 = (u_xlatb2.x) ? u_xlat0.y : u_xlat6;
    u_xlat0.x = (int(u._channel) != 0) ? u_xlat3 : u_xlat0.x;
    u_xlat3 = (-u_xlat0.x) + 1.0;
    u_xlat0.x = (u_xlatb2.w) ? u_xlat3 : u_xlat0.x;
    u_xlat1 = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    u_xlatb3 = int(u._show_mask)==1;
    u_xlat1 = (bool(u_xlatb3)) ? float4(1.0, 0.0, 1.0, 1.0) : u_xlat1;
    u_xlat0.x = u_xlat0.x * u_xlat1.w;
    __nv_out.xyz = u_xlat0.xxx * u_xlat1.xyz;
    __nv_out.w = u_xlat0.x;
    return __nv_out;
    return __nv_out;
}
