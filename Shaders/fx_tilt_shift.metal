// ---------------------------------------------------------------------------
// Tilt-shift (miniatura)
// origem : assets/effects/tilt-shift.xml
// id     : nova.effect.tilt-shift
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tilt_shiftParams {
    float focus;
    float band;
    float softness;
    float maxBlur;
    float angleDeg;
};

// --- funcoes auxiliares do efeito
/**
 * A distância ao plano da faixa nítida, projetada no eixo perpendicular à faixa.
 * `u.angleDeg` gira a faixa — 0° deixa horizontal, 90° vertical.
 */
static float distanciaAoFoco(float2 uv) {
    float2 centro = float2(0.5, u.focus);
    float2 d = uv - centro;
    float a = radians(u.angleDeg);
    // Eixo perpendicular à faixa: a faixa segue cos/sin, a normal segue −sin/cos.
    float2 normal = float2(-sin(a), cos(a));
    return abs(dot(d, normal));
}

/**
 * 9 amostras em cruz (5 horizontais + 5 verticais, o centro conta duas vezes).
 * Dá um box blur aproximado controlado por `raioPx`.
 */
static float4 borrar(float2 uv, float raioPx) {
    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 passo = raioPx / tam;

    float4 soma = float4(0.0);
    soma += inputImg.sample(__nv_smp, uv + float2(-passo.x, 0.0));
    soma += inputImg.sample(__nv_smp, uv + float2(passo.x, 0.0));
    soma += inputImg.sample(__nv_smp, uv + float2(-passo.x * 0.5, 0.0));
    soma += inputImg.sample(__nv_smp, uv + float2(passo.x * 0.5, 0.0));
    soma += inputImg.sample(__nv_smp, uv + float2(0.0, -passo.y));
    soma += inputImg.sample(__nv_smp, uv + float2(0.0, passo.y));
    soma += inputImg.sample(__nv_smp, uv + float2(0.0, -passo.y * 0.5));
    soma += inputImg.sample(__nv_smp, uv + float2(0.0, passo.y * 0.5));
    soma += inputImg.sample(__nv_smp, uv) * 2.0;

    return soma / 10.0;
}

fragment float4 fx_tilt_shift(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tilt_shiftParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float distancia = distanciaAoFoco(in.acScreenNorm);

    // Fora da banda nítida, o raio cresce com a distância, limitado em `u.maxBlur`.
    float inicioDaFalta = u.band * 0.5;
    float fimDaTransicao = inicioDaFalta + max(u.softness, 1e-4);
    float t = smoothstep(inicioDaFalta, fimDaTransicao, distancia);
    float raio = t * u.maxBlur;

    float4 cor = raio < 0.01 ? inputImg.sample(__nv_smp, in.acScreenNorm) : borrar(in.acScreenNorm, raio);

    __nv_out = cor;
    return __nv_out;
}
