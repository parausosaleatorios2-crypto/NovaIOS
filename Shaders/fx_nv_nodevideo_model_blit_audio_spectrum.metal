// ---------------------------------------------------------------------------
// Model Blit Audio Spectrum (NV)
// origem : assets/effects/nv-nodevideo-model-blit-audio-spectrum.xml
// id     : nv.effect.nodevideo-model-blit-audio-spectrum
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_model_blit_audio_spectrumParams { int __vazio; };

// --- funcoes auxiliares do efeito
float3 u_xlat0;

fragment float4 fx_nv_nodevideo_model_blit_audio_spectrum(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_model_blit_audio_spectrumParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    u_xlat0.xyz = in.vs_COLOR0.xyz * float3(0.305306017, 0.305306017, 0.305306017) + float3(0.682171106, 0.682171106, 0.682171106);
    u_xlat0.xyz = in.vs_COLOR0.xyz * u_xlat0.xyz + float3(0.0125228781, 0.0125228781, 0.0125228781);
    __nv_out.xyz = u_xlat0.xyz * in.vs_COLOR0.xyz;
    __nv_out.w = in.vs_COLOR0.w;
    return __nv_out;
    return __nv_out;
}
