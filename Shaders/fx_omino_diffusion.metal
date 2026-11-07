// ---------------------------------------------------------------------------
// omino diffusion
// origem : assets/effects/omino-diffusion.xml
// id     : nova.effect.ominodiffusion
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct omino_diffusionParams {
    float across;
    float aside;
    float4 phase;
    int direction;
    float count;
    float4 color1;
    float width1;
    float4 color2;
    float width2;
    float4 color3;
    float width3;
    float4 color4;
    float width4;
    float4 color5;
    float width5;
    float4 color6;
    float width6;
};

fragment float4 fx_omino_diffusion(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant omino_diffusionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
