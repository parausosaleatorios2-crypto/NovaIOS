// ---------------------------------------------------------------------------
// uni.VHS
// origem : assets/effects/uni-vhs.xml
// id     : nova.effect.univhs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct uni_vhsParams {
    int tapeStyle;
    int frameStyle;
    float imageOffset;
    int colorControls;
    float blackLevel;
    float saturation;
    float lumaBlur;
    float chromaBlur;
    float sharpenRadius;
    float sharpenMix;
    float chromaOffsetX;
    float chromaOffsetY;
    float chromaWeaveX;
    float chromaWeaveY;
    float speedX;
    float speedY;
    float colorMix;
    float redOffset;
    float greenOffset;
    float blueOffset;
    float redBlur;
    float greenBlur;
    float blueBlur;
    int tapeDamage;
    float popLines;
    float frameJitter;
    float interlace;
    float interlaceScale;
    float4 interlaceColor1;
    float4 interlaceColor2;
    int tapeNoiseType;
    float tapeOffset;
    float tapeNoise;
    float distortion;
    float noiseScale;
    int wrinkle;
    float scrollSpeed;
    float percentChance;
    float wrinkleRadius;
    float randomSeed;
    float blend;
    float postNoise;
    int renderAlpha;
};

fragment float4 fx_uni_vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant uni_vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
    return __nv_out;
}
