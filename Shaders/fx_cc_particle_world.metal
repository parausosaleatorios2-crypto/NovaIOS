// ---------------------------------------------------------------------------
// CC Particle World
// origem : assets/effects/cc-particle-world.xml
// id     : nova.effect.ccparticleworld
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_particle_worldParams {
    float birthRate;
    float longevity;
    float posX;
    float posY;
    float posZ;
    float radX;
    float radY;
    float radZ;
    int animation;
    float velocity;
    float inheritVelocity;
    float gravity;
    float resistance;
    float extra;
    float extraAngle;
    float floorPosition;
    int particleVisibility;
    int renderAnimation;
    int floorAction;
    float bounciness;
    float randomBounciness;
    float bounceSpread;
    float axisX;
    float axisY;
    float axisZ;
    float gravityX;
    float gravityY;
    float gravityZ;
    int particleType;
    float scatter;
    int textureTime;
    int alignToDirection;
    float rotationSpeed;
    float initialRotation;
    int rotationAxis;
    float birthSize;
    float deathSize;
    float sizeVariation;
    float maxOpacity;
    int colorMap;
    float4 birthColor;
    float4 deathColor;
    float4 colorAtBirth;
    float4 colorAt25;
    float4 colorAt50;
    float4 colorAt75;
    float4 colorAtDeath;
    float volumeShade;
    int transferMode;
    float camDistance;
    float camRotX;
    float camRotY;
    float camRotZ;
    float fov;
    int depthCueType;
    float depthCueDistance;
    float4 fogColor;
    float lightX;
    float lightY;
    float lightZ;
    float holdParticleRelease;
    int compositeWithOriginal;
    float randomSeed;
};

fragment float4 fx_cc_particle_world(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_particle_worldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> textureLayer [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
