// ---------------------------------------------------------------------------
// Looks: Lift-Gamma-Gain
// origem : assets/effects/mblooks-lift-gamma-gain.xml
// id     : nova.effect.mblooks.liftgammagain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mblooks_lift_gamma_gainParams {
    float gammaSpace;
    float strength;
    float exposure;
    float liftRed;
    float liftGreen;
    float liftBlue;
    float gammaRed;
    float gammaGreen;
    float gammaBlue;
    float gainRed;
    float gainGreen;
    float gainBlue;
};

fragment float4 fx_mblooks_lift_gamma_gain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mblooks_lift_gamma_gainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
