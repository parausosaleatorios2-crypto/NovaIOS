// ---------------------------------------------------------------------------
// Níveis
// origem : assets/effects/levels.xml
// id     : nova.effect.levels
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct levelsParams {
    int channel;
    float inBlack;
    float inWhite;
    float gammaF;
    float outBlack;
    float outWhite;
};

// --- funcoes auxiliares do efeito
static float applyLevels(float value) {
    float range = max(u.inWhite - u.inBlack, 0.0001);
    float stretched = clamp((value - u.inBlack) / range, 0.0, 1.0);
    float shaped = pow(stretched, 1.0 / max(u.gammaF, 0.01));
    return u.outBlack + shaped * (u.outWhite - u.outBlack);
}

fragment float4 fx_levels(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant levelsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    if (u.channel == 1) {
        color.r = applyLevels(color.r);
    } else if (u.channel == 2) {
        color.g = applyLevels(color.g);
    } else if (u.channel == 3) {
        color.b = applyLevels(color.b);
    } else if (u.channel == 4) {
        color.a = applyLevels(color.a);
    } else {
        color.rgb = float3(
            applyLevels(color.r),
            applyLevels(color.g),
            applyLevels(color.b)
        );
    }

    __nv_out = color;
    return __nv_out;
}
