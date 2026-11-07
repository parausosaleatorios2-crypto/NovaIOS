// ---------------------------------------------------------------------------
// Optical Flares
// origem : assets/effects/ae-optical-flares.xml
// id     : nova.effect.aeopticalflares
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_optical_flaresParams {
    float2 positionXY;
    float2 centerPosition;
    float brightness;
    float scale;
    float rotationOffset;
    float4 color;
    int colorMode;
    float animationEvolution;
    int renderMode;
    float4 flare;
};

fragment float4 fx_ae_optical_flares(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_optical_flaresParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
