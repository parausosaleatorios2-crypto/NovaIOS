// ---------------------------------------------------------------------------
// Mapa de profundidade
// origem : assets/effects/depth-map.xml
// id     : nova.effect.depthmap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct depth_mapParams {
    int channel;
    int invertDepth;
    float cameraX;
    float cameraY;
    float strength;
    float focusDepth;
    int edges;
    float blurStrength;
    float fogAmount;
    float4 fogColor;
    int showDepth;
};

// --- funcoes auxiliares do efeito
/**
 * A profundidade naquele ponto, 0 (longe) a 1 (perto) — já com canal e
 * inversão resolvidos.
 */
static float profundidadeEm(float2 uv) {
    float4 texel = depthMap.sample(__nv_smp, uv);

    float valor;
    if (u.channel == 1) {
        valor = texel.r;
    } else if (u.channel == 2) {
        valor = texel.g;
    } else if (u.channel == 3) {
        valor = texel.b;
    } else {
        valor = dot(texel.rgb, float3(0.299, 0.587, 0.114));
    }

    return u.invertDepth ? 1.0 - valor : valor;
}

/** Onde buscar, respeitando o comportamento de borda escolhido — mesma regra de `displace.xml`. */
static float2 wrapUv(float2 uv) {
    if (u.edges == 1) {
        return fract(uv);
    }
    if (u.edges == 2) {
        return abs(fract(uv * 0.5) * 2.0 - 1.0);
    }
    if (u.edges == 3) {
        return clamp(uv, 0.0, 1.0);
    }
    return uv;
}

static float4 fetch(float2 uv) {
    if (u.edges == 0 && (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)) {
        return float4(0.0);
    }
    return inputImg.sample(__nv_smp, wrapUv(uv));
}

fragment float4 fx_depth_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant depth_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> depthMap [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float profundidade = profundidadeEm(in.acScreenNorm);

    if (u.showDepth) {
        __nv_out = float4(float3(profundidade), 1.0);
        return __nv_out;
    }

    // O plano do foco fica parado; mais perto anda de um jeito, mais longe do
    // outro — ver a nota do cabeçalho sobre por que não é a profundidade crua.
    float relativo = profundidade - u.focusDepth;

    // Busca no sentido CONTRÁRIO ao da câmera: se a câmera anda para a
    // direita, o que está mais perto do que o foco precisa aparecer mais
    // para a ESQUERDA na tela (é assim que a paralaxe de verdade se
    // comporta — o poste ao lado do carro "fica pra trás" quando o carro
    // anda para a frente). Mesma convenção de sinal de `displace.xml`.
    float2 uv = in.acScreenNorm - float2(u.cameraX, u.cameraY) * eng.acTexelSize * u.strength * eng.acEscalaDePixel * relativo;

    float4 cor = fetch(uv);

    /*
     * DESFOQUE EMBUTIDO — barato de propósito, ver a nota do cabeçalho.
     *
     * O raio cresce com a DISTÂNCIA do plano de foco (`relativo`, o mesmo
     * termo que já move a paralaxe): perto do foco, quase nada; longe dele,
     * o raio cheio. Um círculo de 8 amostras não tem a forma de diafragma
     * do "Desfoque de lente" — é uma média simples —, mas custa um passe só
     * e já resolve "desfoca o fundo" sem precisar empilhar outro efeito.
     */
    if (u.blurStrength > 0.0) {
        /*
         * `relativo` é uma DIFERENÇA DE PROFUNDIDADE NORMALIZADA (0..1), não
         * uma distância física — na prática ela raramente passa de ~0,3 a
         * ~0,5 mesmo entre o assunto e o fundo bem separados. Multiplicar
         * `u.blurStrength` direto por `abs(relativo)` (como era antes) fazia o
         * slider no MÁXIMO (20 px) só chegar perto de 20 px numa separação
         * de profundidade EXTREMA — no caso comum, o raio de verdade ficava
         * em 3-6 px, imperceptível. `FAIXA_DE_QUEDA` é a separação que já
         * conta como "totalmente fora de foco": a partir dali o raio é o
         * valor CHEIO do slider, e o slider passa a significar o que o
         * rótulo promete.
         */
        const float FAIXA_DE_QUEDA = 0.3;
        float queda = clamp(abs(relativo) / FAIXA_DE_QUEDA, 0.0, 1.0);
        float raio = u.blurStrength * queda;
        if (raio > 0.2) {
            const int AMOSTRAS = 8;
            // Cor pré-multiplicada por alfa ao somar, e dividida de volta no
            // fim — mesma regra de `lens-blur.xml`: um pixel transparente
            // não tem cor que signifique nada, e somar sem isso puxaria a
            // borda para preto.
            float3 soma = cor.rgb * cor.a;
            float peso = cor.a;
            for (int i = 0; i < AMOSTRAS; i++) {
                float angulo = (6.28318530718 / float(AMOSTRAS)) * float(i);
                float2 passo = float2(cos(angulo), sin(angulo)) * raio * eng.acEscalaDePixel * eng.acTexelSize;
                float4 amostra = fetch(uv + passo);
                soma += amostra.rgb * amostra.a;
                peso += amostra.a;
            }
            cor = float4(soma / max(peso, 1e-4), peso / float(AMOSTRAS + 1));
        }
    }

    // Névoa: proporcional ao INVERSO da profundidade — o que está mais longe
    // (profundidade baixa) pega mais névoa, como neblina de verdade.
    if (u.fogAmount > 0.0) {
        float neblina = clamp(u.fogAmount * (1.0 - profundidade), 0.0, 1.0);
        cor.rgb = mix(cor.rgb, u.fogColor.rgb, neblina);
    }

    __nv_out = cor;
    return __nv_out;
}
