// ---------------------------------------------------------------------------
// Desfoque composto
// origem : assets/effects/compound-blur.xml
// id     : nova.effect.compoundblur
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct compound_blurParams {
    float maxBlur;
    int mapChannel;
    int invertBlur;
    float iterations;
};

// --- funcoes auxiliares do efeito
/*
 * Até 49 leituras por passe, espaçadas de no máximo ~um pixel e meio. Eram 9
 * leituras fixas espalhadas pelo raio inteiro: com raio 57 o passo era de 14 px,
 * e o "borrão" era 9 cópias da imagem lado a lado — o "blur feião" do relato de
 * 28/09/2026. Agora o número de leituras acompanha o raio, com peso gaussiano
 * (sigma = raio/2), e raio pequeno continua barato.
 */
const int MAX_LEITURAS = 49;

/** O quanto borrar neste ponto, de 0 a 1, lido do mapa. */
static float valorDoMapa(float2 uv) {
    float4 m = blurMap.sample(__nv_smp, uv);

    // Pré-multiplicado: o que é transparente no mapa vale preto, e preto não
    // borra. Sem isto, o RGB guardado num pixel invisível — que pode ser
    // branco — mandaria borrar onde não há mapa nenhum.
    float3 c = m.rgb * m.a;

    float v;
    if (u.mapChannel == 1) v = m.a;
    else if (u.mapChannel == 2) v = c.r;
    else if (u.mapChannel == 3) v = c.g;
    else if (u.mapChannel == 4) v = c.b;
    else v = dot(c, float3(0.299, 0.587, 0.114));

    v = clamp(v, 0.0, 1.0);
    return u.invertBlur ? (1.0 - v) : v;
}

static float4 lerFonte(float2 uv) {
    return (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
}

fragment float4 fx_compound_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant compound_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> blurMap [[texture(1)]],
    texture2d<float> hblur [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // O raio é o do pixel que está sendo escrito — o mesmo nos dois passes,
    // senão o borrado horizontal e o vertical discordariam na mesma região.
    // Em pixels da COMPOSIÇÃO, levado ao buffer (prévia reduzida < 1).
    //
    // O mapa é lido onde este pixel CAI NA TELA (`eng.acTela`), e não na coordenada
    // da camada: o mapa chega desenhado na tela, e uma camada movida, escalada
    // ou espelhada — um reflexo com escala Y negativa, o caso do relato — lia o
    // chão de cabeça para baixo e fora do lugar. Camada parada: dá no mesmo.
    float raio = u.maxBlur * eng.acEscalaDePixel * valorDoMapa(clamp(__nv_acTela(in.acScreenNorm), 0.0, 1.0));

    float4 fonte = lerFonte(in.acScreenNorm);

    // Meio pixel não muda nada: sai fora cedo.
    if (raio < 0.5) {
        __nv_out = fonte;
        return __nv_out;
    }

    float2 direcao = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);

    // Leituras de -raio a +raio, no máximo MAX_LEITURAS, e nunca mais de ~1,5 px
    // de distância entre duas (com filtro linear, o que fica entre elas entra
    // pela interpolação).
    int n = int(clamp(ceil(raio / 1.5) * 2.0 + 1.0, 3.0, float(MAX_LEITURAS)));
    int meio = n / 2;
    float passo = raio / float(meio);
    float sigma = max(raio * 0.5, 0.5);

    // A soma é feita com a cor PRÉ-MULTIPLICADA pelo alfa e desfeita no fim.
    // O motor guarda cor reta, e somar cor reta através de uma borda faria a
    // cor do lado transparente — que pode ser qualquer uma, ninguém a vê —
    // entrar na média e sujar a borda com um halo. Multiplicando pelo alfa,
    // quem é invisível contribui com zero, que é o certo.
    //
    // Pesos incrementais: um único exp() por passe em vez de um por amostra.
    // w(i) = exp(-i²·passo²/(2σ²)); r = exp(-passo²/(2σ²)), w(i) = r^(i²).
    float passo2 = (passo * passo) / (2.0 * sigma * sigma);
    float r  = exp(-passo2);
    float r2 = r * r;
    float rk = r;   // r^(2i-1) para i=1
    float w  = 1.0;
    float4 central = lerFonte(in.acScreenNorm);
    float4 soma  = float4(central.rgb * central.a, central.a);
    float pesos = 1.0;
    for (int i = 1; i < MAX_LEITURAS; i++) {
        if (i > meio) break;
        w  *= rk;
        rk *= r2;
        float d = float(i) * passo;
        float4 pos = lerFonte(in.acScreenNorm + direcao * eng.acTexelSize *  d);
        float4 neg = lerFonte(in.acScreenNorm - direcao * eng.acTexelSize *  d);
        soma  += (float4(pos.rgb * pos.a, pos.a) + float4(neg.rgb * neg.a, neg.a)) * w;
        pesos += 2.0 * w;
    }
    soma /= max(pesos, 1e-5);

    __nv_out = soma.a > 1e-4
        ? float4(soma.rgb / soma.a, soma.a)
        : float4(fonte.rgb, 0.0);
    return __nv_out;
}
