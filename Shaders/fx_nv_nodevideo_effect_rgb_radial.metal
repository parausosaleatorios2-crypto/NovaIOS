// ---------------------------------------------------------------------------
// Effect Rgb Radial (NV)
// origem : assets/effects/nv-nodevideo-effect-rgb-radial.xml
// id     : nv.effect.nodevideo-effect-rgb-radial
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_rgb_radialParams {
    float2 _center;
    float _spread;
    float _blend;
};

// --- funcoes auxiliares do efeito
float4 u_xlat0;
float4 u_xlat1;
float2 u_xlat2;

fragment float4 fx_nv_nodevideo_effect_rgb_radial(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_rgb_radialParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> prev_buffer [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.x = u._spread * u._spread;
    u_xlat0.x = u_xlat0.x * u._blend;
    u_xlat0.x = (-u_xlat0.x) * 0.5 + 1.0;
    u_xlat2.xy = in.acScreenNorm.xy + (-u._center.xy);
    u_xlat0.xy = u_xlat2.xy * u_xlat0.xx + u._center.xy;
    u_xlat1 = prev_buffer.sample(__nv_smp, u_xlat0.xy);
    u_xlat0 = inputImg.sample(__nv_smp, u_xlat0.xy);
    u_xlat1 = (-u_xlat0) + u_xlat1;
    __nv_out = u_xlat1 * float4(0.949999988, 0.949999988, 0.949999988, 0.949999988) + u_xlat0;
    return __nv_out;
    return __nv_out;
}
