// ---------------------------------------------------------------------------
// CC Ball Action
// origem : assets/effects/cc-ball-action.xml
// id     : nova.effect.ccballaction
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_ball_actionParams {
    float scatter;
    int rotationAxis;
    float rotation;
    int twistProperty;
    float twistAngle;
    float gridSpacing;
    float ballSize;
    float instabilityState;
};

fragment float4 fx_cc_ball_action(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_ball_actionParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
