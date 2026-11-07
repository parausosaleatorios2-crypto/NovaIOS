// ---------------------------------------------------------------------------
// Espectro de áudio
// origem : assets/effects/audio-spectrum.xml
// id     : nova.effect.audiospectrum
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct audio_spectrumParams {
    int mode;
    float height;
    float4 barColor;
    float bars;
    float gapF;
    float2 anchor;
    float ringSize;
    float rotation;
    float4 peakColor;
    float glow;
    float boost;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

/** O nível de uma faixa, com o ganho aplicado. `t` vai de 0 a 1. */
static float nivel(float t) {
    return clamp(spectrumImg.sample(__nv_smp, float2(clamp(t, 0.0, 1.0), 0.5)).r * u.boost, 0.0, 1.0);
}

/**
 * O nível suavizado, para a onda.
 *
 * A textura do espectro tem 32 texels e o filtro é linear, então a leitura crua
 * é uma poligonal: cada faixa vira um segmento reto e a linha sai em zigue-zague.
 * Três amostras com peso 1-2-1, espaçadas de meia faixa, arredondam os vértices —
 * é a mesma ideia de um filtro de suavização, e custa duas leituras a mais.
 */
static float nivelSuave(float t) {
    // Meia faixa na coordenada da textura: ela sempre tem 32 texels.
    const float MEIA_FAIXA = 1.0 / 64.0;
    return (nivel(t - MEIA_FAIXA) + 2.0 * nivel(t) + nivel(t + MEIA_FAIXA)) * 0.25;
}

static float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    return float4((cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a, a);
}

fragment float4 fx_audio_spectrum(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant audio_spectrumParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> spectrumImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 uv = in.acScreenNorm;
    float quantas = float(clamp(int(u.bars + 0.5), 4, 64));

    float dentro = 0.0;   // 1 onde a forma está
    float topo = 0.0;     // 1 perto da ponta, para a cor do topo

    // Um pixel e meio, na mesma medida das coordenadas. É com isto que as bordas
    // ficam macias: um `step` cru serrilha o anel inteiro, e serrilhado é a
    // primeira coisa que se nota num efeito que fica na tela o vídeo todo.
    float px = max(1.5 * eng.acEscalaDePixel, 1.0) / max(eng.acResolution.y, 1.0);

    if (u.mode == 2) {
        // ------------------------------------------------------------- anel
        float2 p = (uv - u.anchor) * float2(eng.acAspect, 1.0);
        float raio = length(p);
        float ang = __nv_atan(p.y, p.x) + u.rotation * PI / 180.0;
        float volta = fract(ang / (2.0 * PI) + 1.0);

        float faixa = floor(volta * quantas);
        float posicaoNaFaixa = fract(volta * quantas);
        float valor = nivel(faixa / quantas);

        float interno = u.ringSize;
        float externo = u.ringSize + valor * u.height;

        // A folga angular de um pixel depende do RAIO: perto do centro, um pixel
        // cobre muito mais ângulo do que na ponta da barra.
        //
        // E ela só entra quando existe espaço entre as fatias. Com espaço zero, a
        // divisa entre duas fatias é um degrau de verdade — barras de alturas
        // diferentes encostadas —, e suavizar ali abriria uma costura escura.
        // O `max` não é detalhe: com folga zero as duas bordas do `smoothstep`
        // ficariam iguais, e a especificação não define divisão por zero ali.
        float folgaAng = max(px * quantas / (6.2831853 * max(raio, 1e-3)) * step(0.001, u.gapF), 1e-5);
        float dentroDaFatia =
            smoothstep(u.gapF * 0.5 - folgaAng, u.gapF * 0.5 + folgaAng, posicaoNaFaixa) *
            (1.0 - smoothstep(1.0 - u.gapF * 0.5 - folgaAng, 1.0 - u.gapF * 0.5 + folgaAng, posicaoNaFaixa));

        dentro = smoothstep(interno - px, interno + px, raio) *
                 (1.0 - smoothstep(externo - px, externo + px, raio)) *
                 dentroDaFatia;
        topo = dentro * smoothstep(externo - 0.01, externo, raio);
    } else if (u.mode == 1) {
        // -------------------------------------------------------------- onda
        //
        // A onda usa o nível como ALTURA de uma linha contínua, e não como barra.
        float valor = nivelSuave(uv.x);
        float linha = u.anchor.y - valor * u.height;

        // A linha engrossa onde está alta: o traço fino some contra o vídeo, e
        // engrossar só no que importa mantém a leitura sem virar uma faixa.
        float espessura = 0.004 + valor * 0.01;

        dentro = 1.0 - smoothstep(espessura, espessura * 2.0, abs(uv.y - linha));

        // Na onda não existe "ponta da barra", então a cor do topo vira a cor do
        // ALTO: quanto mais forte o trecho, mais ele puxa para ela. Deixar
        // `topo = dentro` pintaria a linha inteira de branco e apagaria a cor.
        topo = dentro * valor;
    } else {
        // ------------------------------------------------- barras / espelhado
        float faixa = floor(uv.x * quantas);
        float posicaoNaFaixa = fract(uv.x * quantas);
        float valor = nivel(faixa / quantas);

        float dentroDaBarra = step(u.gapF * 0.5, posicaoNaFaixa) *
                              step(posicaoNaFaixa, 1.0 - u.gapF * 0.5);

        if (u.mode == 3) {
            // Espelhado: cresce para os dois lados a partir da base.
            float distancia = abs(uv.y - u.anchor.y);
            float meio = valor * u.height * 0.5;
            dentro = (1.0 - smoothstep(meio - px, meio + px, distancia)) * dentroDaBarra;
            topo = dentro * smoothstep(meio - 0.01, meio, distancia);
        } else {
            float alto = u.anchor.y - valor * u.height;
            dentro = smoothstep(alto - px, alto + px, uv.y) *
                     (1.0 - smoothstep(u.anchor.y - px, u.anchor.y + px, uv.y)) *
                     dentroDaBarra;
            // `smoothstep` com as bordas invertidas e COMPORTAMENTO INDEFINIDO pela
            // especificação — alguns drivers devolvem o que se espera, outros não.
            // A forma certa é a subtração de 1.
            topo = dentro * (1.0 - smoothstep(alto, alto + 0.02, uv.y));
        }
    }

    float3 cor = mix(u.barColor.rgb, u.peakColor.rgb, clamp(topo, 0.0, 1.0) * u.peakColor.a);

    // O brilho vem do próprio nível da faixa daquela coluna: barra alta acende
    // mais. Sem isso o brilho seria um véu uniforme por cima de tudo.
    float brilhoDaColuna = nivel(uv.x) * u.glow;
    cor += brilhoDaColuna * u.barColor.rgb * dentro;

    float4 desenhado = float4(cor, clamp(dentro, 0.0, 1.0) * u.barColor.a);
    __nv_out = sobre(original, desenhado);
    return __nv_out;
}
