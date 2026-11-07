// ---------------------------------------------------------------------------
// Raios de luz
// origem : assets/effects/light-rays.xml
// id     : nova.effect.lightrays
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct light_raysParams {
    float rayIntensity;
    float2 center;
    float radius;
    float warpSoftness;
    int shape;
    float direction;
    int colorFromSource;
    int allowBrightening;
    float4 rayColor;
    int transferMode;
};

// --- funcoes auxiliares do efeito
const int AMOSTRAS = 64;
const int ALISAMENTO = 16;

/** Pixels da camada por unidade de UV, nos dois eixos: é neles que o Raio é medido. */
static float2 tamanhoDaCamada() {
    return float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
}

/**
 * A distância do ponto ao Centro, em pixels da camada — redonda ou quadrada.
 * No quadrado, o `Direction` gira o quadrado (só aparece com Shape = Square).
 */
static float distanciaDaFonte(float2 uv) {
    float2 v = (uv - u.center) * tamanhoDaCamada();
    if (u.shape == 1) {
        float a = radians(u.direction);
        float2 r = float2(cos(a) * v.x + sin(a) * v.y, -sin(a) * v.x + cos(a) * v.y);
        return max(abs(r.x), abs(r.y));
    }
    return length(v);
}

/** 1 dentro da fonte, caindo até 0 na largura da Warp Softness. */
static float mascaraDaFonte(float2 uv) {
    float r = max(u.radius * eng.acEscalaDePixel, 0.5);
    float borda = max(r * (0.05 + 1.95 * u.warpSoftness / 100.0), 1.0);
    return 1.0 - smoothstep(r, r + borda, distanciaDaFonte(uv));
}

static float luma(float3 c) {
    return dot(c, float3(0.299, 0.587, 0.114));
}

fragment float4 fx_light_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant light_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> emitBuf [[texture(1)]],
    texture2d<float> raysBuf [[texture(2)]],
    texture2d<float> smoothBuf [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // 0. A emissão: a imagem inteira emite na medida do próprio brilho (sem
    //    limiar — é isso que leva o desenho da cena para dentro dos raios), e a
    //    FONTE, o disco do Raio, emite três vezes mais.
    if (eng.acPass == 0) {
        float4 s = inputImg.sample(__nv_smp, in.acScreenNorm);
        float l = luma(s.rgb);
        float3 cor = u.colorFromSource ? s.rgb : float3(l) * u.rayColor.rgb;
        float m = mascaraDaFonte(in.acScreenNorm);
        __nv_out = float4(cor * l * (1.0 + 2.0 * m) * s.a, 1.0);
        return __nv_out;
    }

    // 1. Os raios: a luz somada do Centro até este pixel, pesando mais o trecho
    //    perto do pixel — é o que mantém o fiapo nítido em vez de virar névoa.
    if (eng.acPass == 1) {
        float3 soma = float3(0.0);
        float pesos = 0.0;
        for (int i = 0; i < AMOSTRAS; i++) {
            float t = (float(i) + 0.5) / float(AMOSTRAS);
            float2 uv = mix(u.center, in.acScreenNorm, t);
            pesos += t;
            if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) continue;
            soma += emitBuf.sample(__nv_smp, uv).rgb * t;
        }
        __nv_out = float4(soma / pesos, 1.0);
        return __nv_out;
    }

    // 2. O alisamento ao longo do raio, dentro de um passo do passe 1: tira os
    //    degraus sem borrar para o lado (o que apagaria os fiapos).
    if (eng.acPass == 2) {
        float3 soma = float3(0.0);
        for (int j = 0; j < ALISAMENTO; j++) {
            float t = 1.0 - (float(j) / float(ALISAMENTO)) / float(AMOSTRAS);
            soma += raysBuf.sample(__nv_smp, mix(u.center, in.acScreenNorm, t)).rgb;
        }
        __nv_out = float4(soma / float(ALISAMENTO), 1.0);
        return __nv_out;
    }

    // 3. A composição.
    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Intensidade 100 = o padrão do AE. O ganho foi acertado simulando o shader
    // numa cena clara: em 100 o miolo acende e a cena continua legível.
    float3 raios = smoothBuf.sample(__nv_smp, in.acScreenNorm).rgb * (u.rayIntensity / 100.0) * 0.5;

    if (u.allowBrightening) {
        // O miolo dos raios estoura para o branco, como luz forte na lente.
        float l = luma(raios);
        raios += raios * l * 0.6 + float3(max(l - 0.8, 0.0) * 0.5);
    } else {
        // Sem clarear: os raios nunca passam do brilho da própria fonte.
        raios = min(raios, float3(1.0));
    }

    float3 o = original.rgb;
    float3 resultado;
    if (u.transferMode == 1) {
        resultado = o + raios;                                    // Add
    } else if (u.transferMode == 2) {
        resultado = max(o, raios);                                // Lighten
    } else if (u.transferMode == 3) {
        float3 r = clamp(raios, 0.0, 1.0);
        resultado = 1.0 - (1.0 - o) * (1.0 - r);                  // Screen
    } else {
        // None: os raios POR CIMA da imagem, cobrindo onde são fortes.
        float cobre = clamp(luma(raios), 0.0, 1.0);
        resultado = o * (1.0 - cobre) + raios;
    }

    // A luz também aparece onde a camada é transparente (é luz no ar), então o
    // alfa ganha a força dos raios.
    float alfa = max(original.a, clamp(luma(raios), 0.0, 1.0));
    __nv_out = float4(clamp(resultado, 0.0, 1.0), alfa);
    return __nv_out;
}
