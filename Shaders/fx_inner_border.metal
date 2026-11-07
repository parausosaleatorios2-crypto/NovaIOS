// ---------------------------------------------------------------------------
// Bordas internas
// origem : assets/effects/inner-border.xml
// id     : nova.effect.inner-border
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct inner_borderParams {
    float4 borderColor;
    float width;
    float offset;
    float softness;
    float opacity;
};

// --- funcoes auxiliares do efeito
const int AMOSTRAS = 8;

/** O alfa num pixel com deslocamento em px (vai pra UV pela textura de entrada). */
static float alfaEm(float2 uv, float2 deslocamentoPx) {
    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    return inputImg.sample(__nv_smp, uv + deslocamentoPx / tam).a;
}

/**
 * A menor "proximidade do limite" nas 8 amostras em volta, no raio dado (px).
 * Retorna 0 = tudo opaco em volta; 1 = alguém ali está transparente.
 */
static float probaForaNoRaio(float2 uv, float raio) {
    float maximo = 0.0;
    for (int i = 0; i < AMOSTRAS; i++) {
        float a = 6.2831853 * (float(i) + 0.5) / float(AMOSTRAS);
        float2 d = float2(cos(a), sin(a)) * raio;
        float fora = 1.0 - alfaEm(uv, d);
        maximo = max(maximo, fora);
    }
    return maximo;
}

fragment float4 fx_inner_border(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant inner_borderParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Fora do alfa, o pixel não ganha borda.
    if (original.a < 1e-3) {
        __nv_out = original;
        return __nv_out;
    }

    // Dois raios: o INÍCIO da faixa (perto da quina) e o FIM (afastado por u.width+u.softness).
    // O `u.offset` empurra a faixa para dentro, saindo da quina.
    float raioInicio = max(u.offset, 0.5);
    float raioFim = raioInicio + max(u.width, 0.5);
    float extra = max(u.softness, 0.5);

    float noInicio = probaForaNoRaio(in.acScreenNorm, raioInicio);
    float noFim = probaForaNoRaio(in.acScreenNorm, raioFim + extra);

    // Dentro da faixa: inicio detecta algum vizinho fora, fim não vê mais nada fora.
    // (noInicio - noFim) dá o ANEL: alto no meio, zero nas duas pontas.
    float dentroDoAnel = clamp(noInicio - noFim, 0.0, 1.0);

    // A borda sempre pinta sobre o alfa original (não transborda).
    float forca = dentroDoAnel * u.opacity * original.a * u.borderColor.a;

    float3 corDePintura = u.borderColor.rgb;
    float3 saidaCor = mix(original.rgb, corDePintura, forca);

    __nv_out = float4(saidaCor, original.a);
    return __nv_out;
}
