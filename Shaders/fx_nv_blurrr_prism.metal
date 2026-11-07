// ---------------------------------------------------------------------------
// Desfoque Prisma (Blurrr)
// origem : assets/effects/nv-blurrr-prism.xml
// id     : nova.effect.blurrr.prism
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_prismParams {
    float amount;
    float angle;
    float spread;
    float samples;
    float boost;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float2 dir(float graus) {
    float a = graus * PI / 180.0;
    return float2(cos(a), sin(a));
}

float3 amostraCanal(float2 origem, float2 direcao, float raio, int canal, int n) {
    float soma = 0.0;
    float peso = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float2 p = origem + direcao * raio * t;
        float v = inputImg.sample(__nv_smp, p)[canal];
        soma += v;
        peso += 1.0;
    }
    return float3(soma / max(peso, 1e-4));
}

fragment float4 fx_nv_blurrr_prism(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_prismParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.amount <= 0.0) { __nv_out = original; return __nv_out; }

    int n = clamp(int(u.samples), 4, 48);

    // Três pares opostos: R/G/B cada um pega um eixo do leque.
    float2 dR1 = dir(u.angle - u.spread);
    float2 dR2 = dir(u.angle - u.spread + 180.0);
    float2 dG1 = dir(u.angle);
    float2 dG2 = dir(u.angle + 180.0);
    float2 dB1 = dir(u.angle + u.spread);
    float2 dB2 = dir(u.angle + u.spread + 180.0);

    float r = (amostraCanal(in.acScreenNorm, dR1, u.amount, 0, n).r
             + amostraCanal(in.acScreenNorm, dR2, u.amount, 0, n).r) * 0.5;
    float g = (amostraCanal(in.acScreenNorm, dG1, u.amount, 1, n).r
             + amostraCanal(in.acScreenNorm, dG2, u.amount, 1, n).r) * 0.5;
    float b = (amostraCanal(in.acScreenNorm, dB1, u.amount, 2, n).r
             + amostraCanal(in.acScreenNorm, dB2, u.amount, 2, n).r) * 0.5;

    float3 cor = float3(r, g, b) * u.boost;
    __nv_out = float4(cor, original.a);
    return __nv_out;
}
