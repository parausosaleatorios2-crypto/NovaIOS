// ---------------------------------------------------------------------------
// Glitchify
// origem : assets/effects/glitchify.xml
// id     : nova.effect.glitchify
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct glitchifyParams {
    float amount;
    float speed;
    float seed;
    float completion;
    float softness;
    int transitionChannel;
    float transformSpeed;
    float2 position;
    float positionWiggle;
    float scale;
    float scaleWiggle;
    float2 cropTopLeft;
    float2 cropBottomRight;
    float cropWiggle;
    float opacity;
    int transferMode;
    int compositeOver;
    int channelEnable;
    int splitChannel;
    float splitH;
    float splitV;
    float splitSpeed;
    float scaleAmount;
    int scaleChannel;
    int scaleVertical;
    float scaleOffset;
    float scaleSpeed;
    int fillGaps;
    int channelMode;
    int colorEnable;
    float colorOffset;
    float colorAmount;
    float colorOpacity;
    int colorMode;
    int imageEnable;
    float streak;
    int verticalSort;
    float blockAmount;
    float blockSpeed;
    float blockWidth;
    float blockHeight;
    int blockDirection;
    int blockMode;
    int compressionEnable;
    float compressionMultiplier;
    float ditherAmount;
    float jpegAmount;
    int showNoise;
    float gain;
    float lacunarity;
    float octaves;
    int repeatEdge;
    int sigmoid;
    float quantization;
    int useNoise;
    float noiseCutoff;
    float grouping;
    float wiggleSteps;
    float sliceAmount;
};

fragment float4 fx_glitchify(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant glitchifyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
