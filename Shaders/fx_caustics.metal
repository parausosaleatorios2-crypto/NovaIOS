// ---------------------------------------------------------------------------
// Cáusticas
// origem : assets/effects/caustics.xml
// id     : nova.effect.caustics
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct causticsParams {
    float scale;
    float speed;
    float intensity;
    float detail;
    float4 lightColor;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_CAMADAS = 8;
const float TAU = 6.2831853;

/**
 * As cáusticas pelo método de Shane: para cada camada, um ponto que gira num
 * círculo pequeno vira a semente de uma distância ao ponto mais próximo —
 * acumulando por camada e normalizando pelo número delas.
 */
static float causticas(float2 uv, float t, int camadas) {
    float2 p = uv;
    float soma = 0.0;
    float amplitude = 1.0;
    float peso = 0.0;

    for (int i = 0; i < MAXIMO_DE_CAMADAS; i++) {
        if (i >= camadas) break;
        float fi = float(i);
        // Cada camada rotaciona num ângulo diferente: dá a sensação de várias ondas cruzando.
        float ang = TAU * fi / float(max(camadas, 1));
        float2 centro = 0.5 + float2(cos(ang + t), sin(ang + t)) * 0.3;
        float2 d = p - centro;
        // 1 − |cos| dá linhas brilhantes onde a distância ao centro é múltiplo da fase.
        float linha = abs(cos(length(d) * 15.0 - t * 2.0));
        linha = 1.0 - linha;
        soma += linha * amplitude;
        peso += amplitude;
        amplitude *= 0.75;
    }
    return soma / max(peso, 1e-4);
}

fragment float4 fx_caustics(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant causticsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y) * u.scale * 0.2;
    float t = eng.acTime * u.speed;
    int n = clamp(int(u.detail + 0.5), 1, MAXIMO_DE_CAMADAS);

    float linhas = causticas(p, t, n);

    // Concentra as linhas: quem está fraco vira zero, quem está forte vira forte.
    linhas = pow(linhas, 3.0) * u.intensity;

    float3 luz = u.lightColor.rgb * linhas;

    // Screen: a luz nunca escurece pixel claro.
    float3 cor = 1.0 - (1.0 - original.rgb) * (1.0 - luz);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
