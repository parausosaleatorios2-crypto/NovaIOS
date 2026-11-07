// ---------------------------------------------------------------------------
// Rendercommand  Time Displacement (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-time-displacement.xml
// id     : nv.effect.nodevideo-rendercommand-time-displacement
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_time_displacementParams {
    float _tex_array_count;
};

// --- funcoes auxiliares do efeito
float3 u_xlat0;
float u_xlat1;
int u_xlati1;

fragment float4 fx_nv_nodevideo_rendercommand_time_displacement(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_time_displacementParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tex_array [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = inputImg.sample(__nv_smp, in.acScreenNorm.xy).xyz;
    u_xlat0.x = u_xlat0.y + u_xlat0.x;
    u_xlat0.x = u_xlat0.z + u_xlat0.x;
    u_xlat0.x = u_xlat0.x * 0.333333343;
    u_xlati1 = u._tex_array_count + int(0xFFFFFFFFu);
    u_xlat1 = float(u_xlati1);
    u_xlat0.z = u_xlat1 * u_xlat0.x;
    u_xlat0.xy = in.acScreenNorm.xy;
    __nv_out = tex_array.sample(__nv_smp, u_xlat0.xyz);
    return __nv_out;
    return __nv_out;
}
