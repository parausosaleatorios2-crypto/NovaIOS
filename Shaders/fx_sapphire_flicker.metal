// ---------------------------------------------------------------------------
// S_Flicker
// origem : assets/effects/sapphire-flicker.xml
// id     : nova.effect.sflicker
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_flickerParams {
    float amplitude;
    float randLumaAmp;
    float randColorAmp;
    float randFreq;
    float waveAmp;
    float waveFreq;
    float waveRPhase;
    float waveGPhase;
    float waveBPhase;
    float redAmp;
    float greenAmp;
    float blueAmp;
    float brightness;
    float seed;
};

// --- funcoes auxiliares do efeito
// ---- A TABELA DO RUÍDO (gerada por tools/sflicker/benchmark/gerar.py; não editar à mão) ----
const int LARGURA = 1024;                  // amostras por linha da textura
const float PASSO = 16.0;                    // amostras por unidade de u
const float FAIXA = 0.94;                    // os valores guardados vão de −FAIXA a +FAIXA
const float SEMENTE = 0.122986;                // a semente medida no After Effects (a padrão do plugin)
const int TAMANHO = 32769;                  // amostras de cada trecho
// a linha onde começa cada trecho: brilho, e a cor de cada canal (R, G, B)
// Em FUNÇÕES, não em arrays constantes: índice variável num array constante é o que driver de celular erra
// (como no S_Shake que "não funcionam em alguns celulares", 30/10/2026).
int linhaDoTrecho(int t) { if (t == 0) return 0; if (t == 1) return 33; if (t == 2) return 66; if (t == 3) return 99; return 0; }
const float PI2 = 6.28318530718;

/** Uma amostra da tabela: 16 bits em dois canais (R alto, G baixo). */
float amostra(int trecho, int i) {
    // fora da tabela o pisca continua: ela é percorrida de volta, e de novo de ida (sem salto)
    int volta = 2 * (TAMANHO - 1);
    // o vaivém é simétrico em volta do 0: o índice negativo vale o positivo (e dividir inteiro negativo é
    // indefinido no GLSL ES — cada driver arredonda de um jeito)
    if (i < 0) i = -i;
    i = i - (i / volta) * volta;
    if (i > TAMANHO - 1) i = volta - i;
    float4 t = tabela.read(uint2(int2(i - (i / LARGURA) * LARGURA, linhaDoTrecho(trecho) + i / LARGURA)), uint(0));
    return ((floor(t.r * 255.0 + 0.5) * 256.0 + floor(t.g * 255.0 + 0.5)) / 65535.0 * 2.0 - 1.0) * FAIXA;
}

/** O ruído do trecho (0 = brilho, 1 a 3 = a cor de R, G e B) no ponto `u`. */
float ruido(int trecho, float u) {
    // A semente medida no After Effects dá o MESMO pisca de lá; qualquer outra lê a mesma tabela a
    // partir de um ponto que depende da semente — outro pisca, do mesmo jeito.
    float desvio = abs(u.seed - SEMENTE) < 0.0006 ? 0.0 : fract(u.seed * 0.61803 + 0.137) * 1500.0 + 37.0;
    float x = (abs(u) + desvio) * PASSO;
    float i = floor(x), f = x - i;
    int k = int(i);
    float p0 = amostra(trecho, k - 1), p1 = amostra(trecho, k), p2 = amostra(trecho, k + 1), p3 = amostra(trecho, k + 2);
    // Catmull–Rom pelas quatro amostras vizinhas
    return p1 + 0.5 * f * (p2 - p0 + f * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3 + f * (3.0 * (p1 - p2) + p3 - p0)));
}

fragment float4 fx_sapphire_flicker(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_flickerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabela [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    // Medido: o ruído anda com u = Rand Freq · t (em segundos — não depende da taxa de quadros).
    float u = u.randFreq * eng.acTime;
    float3 pisca = float3(0.0);
    if (u.randLumaAmp != 0.0) pisca += u.randLumaAmp * ruido(0, u);
    if (u.randColorAmp != 0.0) pisca += u.randColorAmp * float3(ruido(1, u), ruido(2, u), ruido(3, u));
    // Medido: a onda é um COSSENO (começa no alto), e a fase de cada canal é em voltas.
    if (u.waveAmp != 0.0) pisca += u.waveAmp * cos(PI2 * (u.waveFreq * eng.acTime - float3(u.waveRPhase, u.waveGPhase, u.waveBPhase)));
    // Medido: ganho = Brightness + Amplitude · (u.amplitude do canal) · pisca, nunca abaixo de zero;
    // multiplica a cor, e o alfa não muda.
    float3 ganho = max(float3(0.0), u.brightness + u.amplitude * float3(u.redAmp, u.greenAmp, u.blueAmp) * pisca);
    __nv_out = float4(clamp(cor.rgb * ganho, 0.0, 1.0), cor.a);
    return __nv_out;
}
