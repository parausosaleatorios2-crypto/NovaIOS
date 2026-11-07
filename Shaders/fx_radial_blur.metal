// ---------------------------------------------------------------------------
// Desfoque radial
// origem : assets/effects/radial-blur.xml
// id     : nova.effect.radialblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct radial_blurParams {
    float2 center;
    float strength;
    int mode;
    float falloff;
};

// --- funcoes auxiliares do efeito
const int SAMPLES = 16;

fragment float4 fx_radial_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant radial_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 toCenter = in.acScreenNorm - u.center;

    // O quanto este pixel borra depende de quão longe do centro ele está: é o
    // que faz o efeito parecer movimento e não um desfoque uniforme.
    float radiusNorm = length(toCenter * float2(eng.acAspect, 1.0));
    float weight = u.strength * mix(1.0, radiusNorm, u.falloff);

    float4 sum = float4(0.0);
    for (int i = 0; i < SAMPLES; i++) {
        float t = float(i) / float(SAMPLES - 1);

        float2 uv;
        if (u.mode == 0) {
            // Zoom: cada amostra é um degrau na direção do centro.
            uv = u.center + toCenter * (1.0 - weight * t);
        } else {
            // Giro: cada amostra gira um pouco em torno do centro.
            float angle = weight * t;
            float c = cos(angle);
            float s = sin(angle);
            uv = u.center + float2x2(c, -s, s, c) * toCenter;
        }

        sum += inputImg.sample(__nv_smp, uv);
    }

    __nv_out = sum / float(SAMPLES);
    return __nv_out;
}
