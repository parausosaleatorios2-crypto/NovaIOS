// ---------------------------------------------------------------------------
// Extrusão 3D
// origem : assets/effects/extrude3d.xml
// id     : nova.effect.extrude3d
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct extrude3dParams {
    float depth;
    int sideMode;
    float4 sideColor;
    float faceLight;
    float lightAngle;
    float ambient;
    float shine;
    float rim;
    float reflection;
    float metal;
    int ao;
    float aoIntensity;
    float aoRadius;
    float aoContact;
    int aoQuality;
};

fragment float4 fx_extrude3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant extrude3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
