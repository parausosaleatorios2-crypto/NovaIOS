// ---------------------------------------------------------------------------
// Effect Depth Generator (NV)
// origem : assets/effects/nv-nodevideo-effect-depth-generator.xml
// id     : nv.effect.nodevideo-effect-depth-generator
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_depth_generatorParams {
    float _black_point;
    float _white_point;
    float _curve_offset;
    float _curve_calculation;
};

// --- funcoes auxiliares do efeito
float u_xlat0;
float u_xlat1;
float u_xlat2;

fragment float4 fx_nv_nodevideo_effect_depth_generator(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_depth_generatorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0 = u._white_point + -9.99999975e-05;
    u_xlat0 = min(u_xlat0, u._black_point);
    u_xlat1 = u_xlat0 + 9.99999975e-05;
    u_xlat1 = max(u_xlat1, u._white_point);
    u_xlat1 = (-u_xlat0) + u_xlat1;
    u_xlat2 = inputImg.sample(__nv_smp, in.acScreenNorm.xy).x;
    u_xlat0 = (-u_xlat0) + u_xlat2;
    u_xlat0 = u_xlat0 / u_xlat1;
    u_xlat0 = u_xlat0 + u._curve_offset;
    u_xlat0 = clamp(u_xlat0, 0.0, 1.0);
    u_xlat1 = u_xlat0 * u_xlat2;
    u_xlat1 = clamp(u_xlat1, 0.0, 1.0);
    __nv_out.xyz = (int(u._curve_calculation) != 0) ? float3(u_xlat0) : float3(u_xlat1);
    __nv_out.w = 1.0;
    return __nv_out;
    return __nv_out;
}
