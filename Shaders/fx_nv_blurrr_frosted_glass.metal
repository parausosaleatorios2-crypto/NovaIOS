// ---------------------------------------------------------------------------
// Vidro Fosco (Blurrr)
// origem : assets/effects/nv-blurrr-frosted-glass.xml
// id     : nova.effect.blurrr.frostedglass
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_frosted_glassParams {
    float blur;
    float jitter;
    float seed;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

const int N = 9;
const float OFF[9] = float[9](-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0);
const float WT[9]  = float[9](0.028,0.070,0.133,0.196,0.228,0.196,0.133,0.070,0.028);

fragment float4 fx_nv_blurrr_frosted_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_frosted_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float r = u.blur * eng.acEscalaDePixel;
    float2 passo = d * eng.acTexelSize * r;

    float2 j = float2(
        hash21(in.acScreenNorm * eng.acResolution + float2(u.seed, 0.0)) - 0.5,
        hash21(in.acScreenNorm * eng.acResolution + float2(0.0, u.seed + 7.0)) - 0.5
    ) * u.jitter;

    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i] + j;
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u) : hblur.sample(__nv_smp, u);
        soma += c * WT[i];
        pesoTot += WT[i];
    }
    __nv_out = soma / pesoTot;
    return __nv_out;
}
