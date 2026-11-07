// ---------------------------------------------------------------------------
// S_DissolveShake
// origem : assets/effects/sapphire-dissolve-shake.xml
// id     : nova.effect.sdissolveshake
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_dissolve_shakeParams {
    int transitionDir;
    int autoTrans;
    float dissolvePercent;
    float dissolveSpeed;
    float amplitude;
    float frequency;
    int motionBlur;
    float moBlurLength;
    float seed;
    int wrapX;
    int wrapY;
    int opacity;
    float xRandAmp;
    float xRandFreq;
    float xWaveAmp;
    float xWaveFreq;
    float xPhase;
    float yRandAmp;
    float yRandFreq;
    float yWaveAmp;
    float yWaveFreq;
    float yPhase;
    float zRandAmp;
    float zRandFreq;
    float zWaveAmp;
    float zWaveFreq;
    float zPhase;
    float tiltRandAmp;
    float tiltRandFreq;
    float tiltWaveAmp;
    float tiltWaveFreq;
    float tiltPhase;
};

// --- funcoes auxiliares do efeito
// ---- A TRANSIÇÃO (medida no S_DissolveShake; o resto é o S_Shake) ----
const float phase = 0.0;        // o DissolveShake não tem Phase nem Z Dist
const float zDist = 1.0;

/** Quanto da transição já passou, de 0 a 1. */
static float passou() {
    float p = u.dissolvePercent / 100.0;
    if (u.autoTrans == 1) {
        // Medido: o tempo da camada dividido pela duração dela menos um quadro (o último quadro é 100%).
        float duracao = eng.acProgress > 1e-6 ? eng.acTime / eng.acProgress : 0.0;
        p = duracao > eng.acFrameDuration ? clamp(eng.acTime / (duracao - eng.acFrameDuration), 0.0, 1.0) : 0.0;
    }
    return u.transitionDir == 1 ? 1.0 - p : p;
}

/** Medido: o tremor vale 2 · min(p, 1 − p) — zero nas pontas, inteiro no meio. */
static float tremorDaTransicao() { float p = passou(); return 2.0 * min(p, 1.0 - p); }

/** Medido: a opacidade é uma rampa reta em volta de 50%, com a inclinação do Dissolve Speed. */
static float opacidadeDaTransicao() { return clamp(0.5 - (passou() - 0.5) * u.dissolveSpeed, 0.0, 1.0); }

// ---- A TABELA DO RUÍDO (a do S_Shake: tools/sshake/benchmark/gerar.py) ----
const int LARGURA = 1024;                  // amostras por linha da textura
const float PASSO = 16.0;                    // amostras por unidade de u
const float FAIXA = 0.91;                    // os valores guardados vão de −FAIXA a +FAIXA
const int N_SEMENTES = 5;
static float semente(int k) { if (k == 0) return 0.0; if (k == 1) return 0.098; if (k == 2) return 0.268; if (k == 3) return 29.78; if (k == 4) return 30.35; return 0.0; }
// para cada semente e cada eixo (X, Y, Z, Tilt): a linha onde o trecho começa e quantas amostras tem
// Em FUNÇÕES, não em arrays constantes: índice variável num array constante é o que driver de celular erra
// (o S_Shake e o S_DissolveShake que "não funcionam em alguns celulares", 30/10/2026).
static int linhaDoTrecho(int t) { if (t == 0) return 0; if (t == 1) return 17; if (t == 2) return 34; if (t == 3) return 35; if (t == 4) return 36; if (t == 5) return 37; if (t == 6) return 38; if (t == 7) return 39; if (t == 8) return 40; if (t == 9) return 41; if (t == 10) return 42; if (t == 11) return 43; if (t == 12) return 44; if (t == 13) return 49; if (t == 14) return 54; if (t == 15) return 55; if (t == 16) return 56; if (t == 17) return 58; if (t == 18) return 60; if (t == 19) return 61; return 0; }
static int tamanhoDoTrecho(int t) { if (t == 0) return 16385; if (t == 1) return 16385; if (t == 2) return 513; if (t == 3) return 513; if (t == 4) return 513; if (t == 5) return 513; if (t == 6) return 513; if (t == 7) return 513; if (t == 8) return 513; if (t == 9) return 513; if (t == 10) return 513; if (t == 11) return 513; if (t == 12) return 4097; if (t == 13) return 4097; if (t == 14) return 513; if (t == 15) return 513; if (t == 16) return 1025; if (t == 17) return 1025; if (t == 18) return 513; if (t == 19) return 513; return 0; }
const int AMOSTRAS_DO_BORRAO = 48;
const float PI2 = 6.28318530718;

/** Uma amostra da tabela: 16 bits em dois canais (R alto, G baixo). */
static float amostra(int n, int linha, int i) {   // n e linha: o trecho, lido uma vez por eixo (0.915.0, ver o S_Shake)
    // fora da tabela o movimento continua: ela é percorrida de volta, e de novo de ida (sem salto)
    int volta = 2 * (n - 1);
    // o vaivém é simétrico em volta do 0: o índice negativo vale o positivo (e dividir inteiro negativo é
    // indefinido no GLSL ES — cada driver arredonda de um jeito)
    if (i < 0) i = -i;
    i = i - (i / volta) * volta;
    if (i > n - 1) i = volta - i;
    float4 t = tabela.read(uint2(int2(i - (i / LARGURA) * LARGURA, linha + i / LARGURA)), uint(0));
    return ((floor(t.r * 255.0 + 0.5) * 256.0 + floor(t.g * 255.0 + 0.5)) / 65535.0 * 2.0 - 1.0) * FAIXA;
}

/** O ruído do eixo (0 = X, 1 = Y, 2 = Z, 3 = Tilt) no ponto `u`, pela tabela da semente. */
static float ruido(int qual, float u) {
    // A semente: uma das medidas no After Effects (aí o movimento é o MESMO de lá); qualquer outra
    // usa a tabela mais longa a partir de um ponto que depende da semente — outro tremor, do mesmo jeito.
    int s = -1;
    for (int j = 0; j < N_SEMENTES; j++) if (abs(u.seed - semente(j)) < 0.0006) s = j;
    float desvio = 0.0;
    if (s < 0) { s = 0; desvio = fract(u.seed * 0.61803 + float(qual) * 0.37) * 400.0 + 20.0 + float(qual) * 97.0; }
    int trecho = s * 4 + qual;
    int n = tamanhoDoTrecho(trecho), linha = linhaDoTrecho(trecho);
    float x = (abs(u) + desvio) * PASSO;
    float xi = floor(x); float f = x - xi;
    int idx = int(xi);
    float p0 = amostra(n, linha, idx - 1), p1 = amostra(n, linha, idx), p2 = amostra(n, linha, idx + 1), p3 = amostra(n, linha, idx + 2);
    // Catmull–Rom pelas quatro amostras vizinhas
    return p1 + 0.5 * f * (p2 - p0 + f * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3 + f * (3.0 * (p1 - p2) + p3 - p0)));
}

/**
 * Um eixo no instante `t`: a parte aleatória mais a onda.
 * Medido: u = Frequency · Rand Freq · (t − Phase − Phase do eixo); a onda é um seno de frequência
 * Frequency · Wave Freq, com o sinal de cada eixo (`sinalDaOnda`: X anda para o lado contrário).
 */
static float eixo(int qual, float t, float randAmp, float randFreq, float waveAmp, float waveFreq, float fase, float sinalDaOnda, float escalaDaOnda) {
    float tt = t - phase - fase;
    float v = 0.0;
    if (randAmp != 0.0) v += randAmp * ruido(qual, u.frequency * randFreq * tt);
    if (waveAmp != 0.0) v += sinalDaOnda * escalaDaOnda * waveAmp * sin(PI2 * u.frequency * waveFreq * tt);
    return u.amplitude * tremorDaTransicao() * v;
}

/** O movimento no instante `t`: (dx, dy) em px do buffer, 1/zoom e o giro em radianos. */
static float4 movimento(float t, float2 R) {
    float2 d = float2(eixo(0, t, u.xRandAmp, u.xRandFreq, u.xWaveAmp, u.xWaveFreq, u.xPhase, -1.0, 1.0),
                  eixo(1, t, u.yRandAmp, u.yRandFreq, u.yWaveAmp, u.yWaveFreq, u.yPhase, 1.0, 1.0)) * eng.acEscalaDePixel;
    // Medido: 1/zoom = Z Dist + Z Rand Amp · ruído · 6,4 / largura do quadro — o Z é uma distância em
    // pixels, e pesa o dobro num quadro com a metade da largura (a altura não entra). A onda do Z
    // vale 2 / largura por unidade (3,2 vezes menos que a parte aleatória, na escala da tabela).
    float larguraDaComp = R.x / max(eng.acEscalaDePixel, 1e-4);
    float invZoom = zDist + eixo(2, t, u.zRandAmp, u.zRandFreq, u.zWaveAmp, u.zWaveFreq, u.zPhase, 1.0, 1.0 / 3.2) * 6.4 / larguraDaComp;
    float ang = radians(eixo(3, t, u.tiltRandAmp, u.tiltRandFreq, u.tiltWaveAmp, u.tiltWaveFreq, u.tiltPhase, 1.0, 1.0));
    return float4(d, invZoom, ang);
}

/**
 * A borda. Medido com a fonte de coordenadas (em índices de pixel, o centro do pixel i em i):
 * "Tile" repete com período igual à largura; "Reflect" espelha em volta do índice 0 de um lado e do
 * índice `n` do outro (meio pixel além do último), e a leitura fica presa no último pixel.
 */
static float dobrar(float c, float n, int modo) {
    if (modo == 1) return __nv_mod(c + 0.5, n) - 0.5;
    if (modo == 2) {
        float p = 2.0 * n;
        float m = __nv_mod(c, p);
        if (m > n) m = p - m;
        return clamp(m, 0.0, n - 1.0);
    }
    return c;
}

/** Da tela para a fonte, pelo movimento `m` (px do buffer; o centro do pixel i fica em i + 0,5). */
static float2 paraAFonte(float2 px, float2 R, float4 m) {
    float2 c = 0.5 * R;
    float2 q = px - c - m.xy;
    float cs = cos(m.w), sn = sin(m.w);
    // a tela é a fonte girada e ampliada em volta do centro, e depois deslocada: aqui, o caminho de volta
    return float2(cs * q.x + sn * q.y, -sn * q.x + cs * q.y) * m.z + c;
}

/** Da fonte para a tela (o caminho de ida). */
static float2 paraATela(float2 fonte, float2 R, float4 m) {
    float2 c = 0.5 * R;
    float2 q = (fonte - c) / m.z;
    float cs = cos(m.w), sn = sin(m.w);
    return float2(cs * q.x - sn * q.y, sn * q.x + cs * q.y) + c + m.xy;
}

/** A fonte lida no ponto `fonte` (px), com a borda escolhida. Sai pré-multiplicada. */
static float4 ler(float2 fonte, float2 R, bool noPixel) {
    float2 i = fonte - 0.5;                        // em índices de pixel
    // Medido: com o Motion Blur ligado o AE lê o pixel mais próximo em cada amostra (onde nada se
    // mexe — o centro de um giro — as linhas finas saem serrilhadas lá, e aqui também).
    if (noPixel) i = floor(i + 0.5);
    if ((u.wrapX == 0 && (i.x < -0.5 || i.x > R.x - 0.5)) || (u.wrapY == 0 && (i.y < -0.5 || i.y > R.y - 0.5))) return float4(0.0);
    i = float2(dobrar(i.x, R.x, u.wrapX), dobrar(i.y, R.y, u.wrapY));
    float2 uv = (i + 0.5) / R;
    // a conta é com a linha 0 no TOPO, como no plugin; numa cena de pé (camada de ajuste) ela é a base do buffer
    if (eng.acEntradaDePe == 1) uv.y = 1.0 - uv.y;
    float4 cor = inputImg.sample(__nv_smp, uv);
    return float4(cor.rgb * cor.a, cor.a);
}

fragment float4 fx_sapphire_dissolve_shake(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_dissolve_shakeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> tabela [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 R = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 px = in.acScreenNorm * R;
    // Na camada de ajuste a cena chega de pé (a linha 0 do buffer é a BASE): sem virar, Y e giro saíam ao contrário.
    if (eng.acEntradaDePe == 1) px.y = R.y - px.y;
    float4 agora = movimento(eng.acTime, R);
    float4 soma;
    if (u.motionBlur && u.moBlurLength > 0.0 && eng.acFrameDuration > 0.0) {
        // Medido: o borrão é a LINHA RETA do movimento deste quadro até o do quadro seguinte,
        // percorrida por igual e esticada pelo Mo Blur Length (1 = até o quadro seguinte; 3 = três
        // vezes esse caminho, na mesma direção).
        //
        // Na BORDA a ordem importa (medido): o AE dobra a borda UMA vez, na pose deste quadro, e o
        // borrão corre a partir desse ponto já dobrado — a faixa espelhada sai simétrica em volta da
        // borda da imagem deslocada, em vez de cada amostra dobrar num lugar diferente.
        float4 depois = movimento(eng.acTime + eng.acFrameDuration, R);
        float2 aqui = paraAFonte(px, R, agora);
        float2 dentro = float2(u.wrapX == 0 ? aqui.x : dobrar(aqui.x - 0.5, R.x, u.wrapX) + 0.5,
                           u.wrapY == 0 ? aqui.y : dobrar(aqui.y - 0.5, R.y, u.wrapY) + 0.5);
        float2 naTela = paraATela(dentro, R, agora);
        soma = float4(0.0);
        for (int k = 0; k < AMOSTRAS_DO_BORRAO; k++) {
            float f = (float(k) + 0.5) / float(AMOSTRAS_DO_BORRAO) * u.moBlurLength;
            soma += ler(paraAFonte(naTela, R, agora + (depois - agora) * f), R, false);
        }
        soma /= float(AMOSTRAS_DO_BORRAO);
    } else {
        soma = ler(paraAFonte(px, R, agora), R, false);
    }
    // Medido: "Normal" multiplica o alfa; "All Opaque" deixa o alfa em 1 e escurece a cor; "As Premult" faz os dois.
    float a = opacidadeDaTransicao();
    float3 cor = soma.a > 0.0 ? soma.rgb / soma.a : float3(0.0);
    if (u.opacity == 0) __nv_out = float4(cor * a, 1.0);
    else if (u.opacity == 2) __nv_out = float4(cor * a, soma.a * a);
    else __nv_out = float4(cor, soma.a * a);
    if (__nv_out.a <= 0.0) __nv_out = float4(0.0);
    return __nv_out;
}
