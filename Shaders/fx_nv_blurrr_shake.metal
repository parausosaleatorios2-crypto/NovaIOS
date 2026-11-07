// ---------------------------------------------------------------------------
// Desfoque Tremor (Blurrr)
// origem : assets/effects/nv-blurrr-shake.xml
// id     : nova.effect.blurrr.shake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_shakeParams {
    float amplitude;
    float frequency;
    float blurAmount;
    float samples;
    float seed;
};

// --- funcoes auxiliares do efeito
float ruido(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float2 jitter(float t) {
    float a = ruido(float2(t * u.frequency, u.seed)) * 6.28318;
    float r = ruido(float2(u.seed, t * u.frequency)) * u.amplitude;
    return float2(cos(a), sin(a)) * r;
}

fragment float4 fx_nv_blurrr_shake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_shakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.amplitude <= 0.0 && u.blurAmount <= 0.0) { __nv_out = original; return __nv_out; }

    int n = clamp(int(u.samples), 2, 32);
    float2 offset = jitter(eng.acTime);
    float2 direcao = normalize(offset + float2(1e-5, 0.0));

    float4 soma = float4(0.0);
    float peso = 0.0;
    for (int i = 0; i <= 32; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        float2 uv = in.acScreenNorm + offset + direcao * u.blurAmount * t;
        soma += inputImg.sample(__nv_smp, uv);
        peso += 1.0;
    }
    __nv_out = soma / peso;
    return __nv_out;
}
