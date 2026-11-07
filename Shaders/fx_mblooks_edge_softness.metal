// ---------------------------------------------------------------------------
// Looks: Edge Softness
// origem : assets/effects/mblooks-edge-softness.xml
// id     : nova.effect.mblooks.edgesoftness
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mblooks_edge_softnessParams {
    float blurSize;
    float quality;
    float centerX;
    float centerY;
    float radius;
    float spread;
    float aspect;
};

fragment float4 fx_mblooks_edge_softness(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mblooks_edge_softnessParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
