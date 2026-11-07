// ---------------------------------------------------------------------------
// Estilhaçar
// origem : assets/effects/shatter.xml
// id     : nova.effect.shatter
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shatterParams {
    int render;
    int reverse;
    int pattern;
    float repetitions;
    float direction;
    float2 origin;
    float extrusionDepth;
    float2 forcePosition;
    float forceDepth;
    float forceRadius;
    float forceStrength;
    float rotationSpeed;
    int tumbleAxis;
    float randomness;
    float viscosity;
    float massVariance;
    float gravity;
    float gravityDirection;
    float gravityInclination;
    int lightType;
    float lightIntensity;
    float4 lightColor;
    float2 lightPosition;
    float lightDepth;
    float ambientLight;
    float specular;
    int ao;
    float aoIntensity;
    float aoRadius;
    float aoContact;
    int aoQuality;
    float seed;
};

fragment float4 fx_shatter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shatterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
