// ---------------------------------------------------------------------------
// Element 3D
// origem : assets/effects/ae-element-3d.xml
// id     : nova.effect.aeelement
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_element_3dParams {
    float extrude;
    float bevelSize;
    float bevelDepth;
    float bevelCurve;
    float bevelSegments;
    float4 diffuseColor;
    float specular;
    float shininess;
    int lighting;
    float lightBrightness;
    int compLights;
    float gamma;
    int moEnable;
    float moSize;
    float moSizeRandom;
    float moRotX;
    float moRotY;
    float moRotZ;
    int moRotOrder;
    float moRotRandom;
    float moDisplace;
    float moDisplaceRandom;
    float moScatter;
    float moNoise;
    float moNoiseEvolution;
    float moNoiseScale;
    int deform;
    int twist;
    float twistX;
    float twistY;
    float twistZ;
    int bend;
    int bendAxis;
    float bendAngle;
    float bendDirection;
    int bendCenter;
    int taper;
    float taperAmount;
    float taperCurve;
    int taperSymmetrical;
    int noise;
    int noiseMethod;
    float noiseIntensity;
    float noiseScale;
    float noiseEvolution;
    int aeEnable;
    int aeStartGroup;
    int aeFinishGroup;
    float aeAnimation;
    int aeType;
    float aeSmoothness;
    float aeRandomness;
    int aeEase;
    int aeDisconnect;
    float aeSeed;
};

fragment float4 fx_ae_element_3d(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_element_3dParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ambiente [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
