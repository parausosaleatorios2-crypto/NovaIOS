// ---------------------------------------------------------------------------
// BCC 3D Image Shatter
// origem : assets/effects/bcc-3d-image-shatter.xml
// id     : nova.effect.bcc3dimageshatter
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_3d_image_shatterParams {
    float scatter;
    int automate;
    int particleX;
    int shatter;
    float shatterExtra;
    int explosion;
    float speed;
    float light;
    float lightAngle;
    float4 lightColor;
    int velocity;
    float speedZ;
    float variance;
    float adjustment;
    float velocityAngle;
    float2 centerOfVelocity;
    float radius;
    int rotateMode;
    float rotX;
    float rotY;
    float rotZ;
    float rotateVariance;
    float chaosWind;
    int wipe;
    int invertGradient;
    float wipeAngle;
    float wipeSpeed;
    float gravity;
    int gravityType;
    float gravityAngle;
    float2 centerOfGravity;
    int velocity3d;
    float grid;
    float density;
    float positionVariance;
    float size;
    float sizeVariance;
    float xyRatio;
    float opacity;
    float opacityVariance;
    float seed;
    float frameSize;
    float suppression;
    float mixWithOriginal;
};

fragment float4 fx_bcc_3d_image_shatter(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_3d_image_shatterParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
