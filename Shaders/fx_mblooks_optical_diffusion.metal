// ---------------------------------------------------------------------------
// Looks: Optical Diffusion
// origem : assets/effects/mblooks-optical-diffusion.xml
// id     : nova.effect.mblooks.opticaldiffusion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mblooks_optical_diffusionParams {
    float density;
    float size;
    float falloff;
    float glow;
    float highlightsOnly;
    float luster;
    float red;
    float green;
    float blue;
    int filterOn;
    int quality;
    int previewHighlights;
    float filterType;
};

fragment float4 fx_mblooks_optical_diffusion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mblooks_optical_diffusionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
