// ---------------------------------------------------------------------------
// NovaTwitch
// origem : assets/effects/novatwitch.xml
// id     : nova.effect.novatwitch
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct novatwitchParams {
    float quantidade;
    float velocidade;
    int slideEnabled;
    int scaleEnabled;
    int blurEnabled;
    int lightEnabled;
    int colorEnabled;
    int timeEnabled;
    float easeIn;
    float easeOut;
    float minimo;
    float semente;
    int borda;
    float slideAmount;
    float slideTwitches;
    float slideDirection;
    float slideSpread;
    float slideTendency;
    float slideRgb;
    float slideBlur;
    float slideSeed;
    float scaleAmount;
    float scaleTwitches;
    float2 scaleOrigin;
    float scaleOriginRandom;
    float scaleBlur;
    float scaleSeed;
    float blurAmount;
    float blurTwitches;
    float blurSeed;
    float lightAmount;
    float lightTwitches;
    int lightBehaviour;
    float lightSeed;
    float colorAmount;
    float colorTwitches;
    float4 colorize;
    float colorRandom;
    float colorSeed;
    float timeAmount;
    float timeTwitches;
    float timeSeed;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// ------------------------------------------------------------------ sorteio
float hash11(float n) { return fract(sin(n * 12.9898 + 4.1414) * 43758.5453); }
float hash21(float2 p) { return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }
float4 hash4(float k, float s) {
    return float4(hash21(float2(k, s)), hash21(float2(k + 17.31, s * 1.7 + 3.1)),
                hash21(float2(k * 1.31 + 7.7, s + 11.0)), hash21(float2(k + 41.9, s * 2.3 + 5.5)));
}

float duracaoDoQuadro() { return eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0; }

/*
 * O CALENDÁRIO DE TRANCOS — ver o cabeçalho. Devolve o envelope (0..1, o
 * triângulo do tranco) do tranco mais forte em `t`, e em `k` a casa dele
 * (que, com a seed do operador, sorteia tamanho e direção).
 *
 * As casas têm 1/taxa segundos; o tranco cai entre 1/12 e 11/12 de cada uma.
 * A subida/descida pode chegar a 2 casas (Ease 100%), então olhar 3 casas
 * para cada lado cobre tudo.
 */
float envelope(float t, float twitches, float sementeDoCalendario, out float k) {
    k = -1.0;
    float taxa = u.velocidade * twitches;
    if (taxa <= 0.0) return 0.0;
    float casa = 1.0 / taxa;
    float meio = 2.0 * duracaoDoQuadro() / sqrt(max(twitches, 1.0));
    float subida = max(meio, u.easeIn / 100.0 * 2.0 * casa);
    float descida = max(meio, u.easeOut / 100.0 * 2.0 * casa);
    float atual = floor(t / casa);
    float melhor = 0.0;
    for (int i = -3; i <= 3; i++) {
        float kk = atual + float(i);
        float te = (kk + mix(1.0 / 12.0, 11.0 / 12.0, hash21(float2(kk, sementeDoCalendario)))) * casa;
        float d = t - te;
        float e = d < 0.0 ? 1.0 + d / subida : 1.0 - d / descida;
        if (e > melhor) { melhor = e; k = kk; }
    }
    return clamp(melhor, 0.0, 1.0);
}

float sementeDoCalendario(float propria) { return 101.0 + u.semente * 7.13 + propria * 13.7; }

/** O tamanho sorteado do tranco, entre o mínimo e 1 (no AE quase não há tranco abaixo de 7%). */
float tamanho(float u) { return mix(max(u.minimo / 100.0, 0.07), 1.0, u); }

/*
 * OS TRANCOS SE SOMAM (0.753.0). O Slide e o Scale pegavam só o tranco mais forte do instante: quando dois se
 * encostam (dois trancos a 1 quadro um do outro, ou o Ease alargando a rampa), o mais forte troca no meio do caminho
 * e a camada SALTAVA de um lado da tela para o outro — com o motion blur, dois borrões soltos com um buraco no meio
 * (o "very glitchy" do relato). Agora cada tranco entra com o próprio envelope e eles se somam: o mesmo resultado
 * quando estão separados (o caso de quase todo quadro, e o que foi medido no AE) e um caminho contínuo quando se
 * encostam.
 */
float envelopeDaCasa(float t, float kk, float twitches, float sementeDoCalendario) {
    float taxa = u.velocidade * twitches;
    if (taxa <= 0.0) return 0.0;
    float casa = 1.0 / taxa;
    float meio = 2.0 * duracaoDoQuadro() / sqrt(max(twitches, 1.0));
    float subida = max(meio, u.easeIn / 100.0 * 2.0 * casa);
    float descida = max(meio, u.easeOut / 100.0 * 2.0 * casa);
    float te = (kk + mix(1.0 / 12.0, 11.0 / 12.0, hash21(float2(kk, sementeDoCalendario)))) * casa;
    float d = t - te;
    return clamp(d < 0.0 ? 1.0 + d / subida : 1.0 - d / descida, 0.0, 1.0);
}

/** A casa do calendário em que `t` cai (as 3 de cada lado podem ter tranco valendo em `t`). */
float casaAtual(float t, float twitches) {
    float taxa = u.velocidade * twitches;
    return taxa > 0.0 ? floor(t * taxa) : 0.0;
}

/** O deslocamento do Slide (em UV, y para baixo) num instante, para um canal. */
float2 slide(float t, float canal) {
    if (u.velocidade * u.slideTwitches <= 0.0) return float2(0.0);
    float sem = sementeDoCalendario(u.slideSeed);
    float atual = casaAtual(t, u.slideTwitches);
    float2 soma = float2(0.0);
    for (int i = -3; i <= 3; i++) {
        float k = atual + float(i);
        float env = envelopeDaCasa(t, k, u.slideTwitches, sem);
        if (env <= 0.0) continue;
        float4 r = hash4(k, 211.0 + u.semente * 3.1 + u.slideSeed * 5.3 + canal * 97.0);
        float ang = radians(u.slideDirection) + (r.y * 2.0 - 1.0) * u.slideSpread * PI;
        float lado = r.z < 0.5 * (1.0 + u.slideTendency) ? 1.0 : -1.0;
        // ×1,05: o pico medido em 1800 quadros do AE (p50 0,51 e p90 0,85 do máximo, já amostrado).
        float a = 1.05 * tamanho(r.x) * u.quantidade / 100.0 * u.slideAmount / 100.0;
        // Ângulo do AE (0° = para cima, horário) em coordenada normalizada.
        soma += lado * a * env * float2(sin(ang), -cos(ang));
    }
    return soma;
}

float2 slideDoCanal(float t, float canal) {
    float2 verde = slide(t, 0.0);
    if (canal == 0.0 || u.slideRgb <= 0.0) return verde;
    // No AE os canais não se soltam de todo: em 100% a distância entre dois canais fica em
    // torno do tamanho do próprio tranco (mediana 1,07; em 50%, 0,75) — daí 0,7·√split.
    return mix(verde, slide(t, canal), 0.7 * sqrt(u.slideRgb / 100.0));
}

/** Escala (≥ 1) e origem do Scale num instante. */
float3 escala(float t) {
    if (u.velocidade * u.scaleTwitches <= 0.0) return float3(1.0, u.scaleOrigin);
    float sem = sementeDoCalendario(u.scaleSeed);
    float atual = casaAtual(t, u.scaleTwitches);
    // Os trancos somam a escala; a origem é a de cada um, pesada pelo quanto ele aproxima.
    float s = 1.0;
    float2 origens = float2(0.0);
    float pesos = 0.0;
    for (int i = -3; i <= 3; i++) {
        float k = atual + float(i);
        float env = envelopeDaCasa(t, k, u.scaleTwitches, sem);
        if (env <= 0.0) continue;
        float4 r = hash4(k, 307.0 + u.semente * 3.1 + u.scaleSeed * 5.3);
        float ds = tamanho(r.x) * u.quantidade / 100.0 * u.scaleAmount / 100.0 * env;
        s += ds;
        origens += mix(u.scaleOrigin, r.yz, u.scaleOriginRandom / 100.0) * ds;
        pesos += ds;
    }
    return float3(s, pesos > 0.0 ? origens / pesos : u.scaleOrigin);
}

float4 amostrar(float2 uv) {
    if (u.borda == 3) {
        if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return float4(0.0);
    } else if (u.borda == 1) {
        uv = fract(uv);
    } else if (u.borda == 0) {
        uv = 1.0 - abs(1.0 - __nv_mod(uv, 2.0));
    }
    return inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
}

/*
 * O pixel→origem de um canal no instante `t` (o Slide e depois o Scale), como uma conta só: origem = uv · a + b.
 * p = uv − S; p = O + (p − O)/s  ⇒  a = 1/s, b = O − (S + O)/s.
 */
float3 mapa(float t, float canal) {
    float2 s = u.slideEnabled ? slideDoCanal(t, canal) : float2(0.0);
    if (!u.scaleEnabled) return float3(1.0, -s);
    float3 e = escala(t);
    return float3(1.0 / e.x, e.yz - (s + e.yz) / e.x);
}

/** σ do Blur neste quadro ÷ a largura do alvo do passe (1/16 da largura com Amount 50: no
 *  pico o AE apaga os pontos do benchmark — σ ≥ 40 px em 640). */
float fatorDoBlur(float t) {
    if (!u.blurEnabled) return 0.0;
    float k;
    float env = envelope(t, u.blurTwitches, sementeDoCalendario(u.blurSeed), k);
    float4 r = hash4(k, 401.0 + u.semente * 3.1 + u.blurSeed * 5.3);
    return env * tamanho(r.x) * u.quantidade / 100.0 * u.blurAmount / 100.0 / 8.0;
}

/** Time: quantos quadros para trás, durante o tranco (o histórico só tem os de trás). */
int quadrosAtras(float t) {
    if (!u.timeEnabled) return 0;
    float k;
    float env = envelope(t, u.timeTwitches, sementeDoCalendario(u.timeSeed), k);
    float4 r = hash4(k, 503.0 + u.semente * 3.1 + u.timeSeed * 5.3);
    int atras = int(floor(env * tamanho(r.x) * u.quantidade / 100.0 * u.timeAmount / 100.0 * 18.0 + 0.5));
    return clamp(atras, 0, 6);
}

/** Light: o quanto (l) e se escurece (1) ou clareia (0). */
float2 luz(float t) {
    if (!u.lightEnabled) return float2(0.0);
    float k;
    float env = envelope(t, u.lightTwitches, sementeDoCalendario(u.lightSeed), k);
    float4 r = hash4(k, 601.0 + u.semente * 3.1 + u.lightSeed * 5.3);
    float l = env * tamanho(r.x) * u.quantidade / 100.0 * u.lightAmount / 100.0;
    bool escurece = u.lightBehaviour == 1 || (u.lightBehaviour == 2 && r.z < 0.5);
    return float2(l, escurece ? 1.0 : 0.0);
}

/** Color: o quanto (c) e o giro do matiz. */
float2 cor(float t) {
    if (!u.colorEnabled) return float2(0.0);
    float k;
    float env = envelope(t, u.colorTwitches, sementeDoCalendario(u.colorSeed), k);
    float4 r = hash4(k, 701.0 + u.semente * 3.1 + u.colorSeed * 5.3);
    float c = env * tamanho(r.x) * u.quantidade / 100.0 * u.colorAmount / 100.0 * 0.44;
    return float2(c, (r.y * 2.0 - 1.0) * u.colorRandom / 100.0 * PI);
}

/*
 * O CAMINHO DO TRANCO DENTRO DO OBTURADOR, EM PIXELS (0.753.0). Relato da comunidade (22/10/2026): "the motion blur
 * is very glitchy, make it like After Effects's Twitch". Eram 8 imagens fixas por quadro, e um tranco de Slide 50
 * anda até meia tela em um quadro: 8 cópias soltas, a dezenas de pixels uma da outra, em vez do rastro liso do AE.
 * Agora o número de imagens sai do caminho que o pixel mais longe anda no obturador (o Slide em 4 trechos, que pega a
 * ida e a volta do pico, e o Scale no canto da tela), com no máximo ~1,5 px entre duas imagens, até 64.
 * `res` = a resolução da saída (a tabela é montada num alvo de 513 × 10).
 */
float caminhoEmPixels(float t, float2 res) {
    float quadro = duracaoDoQuadro();
    float px = 0.0;
    if (u.slideEnabled && u.slideBlur > 0.0) {
        float o = u.slideBlur / 100.0 * quadro;
        float2 antes = slideDoCanal(t - 0.5 * o, 0.0);
        for (int i = 1; i <= 4; i++) {
            float2 agora = slideDoCanal(t + (float(i) / 4.0 - 0.5) * o, 0.0);
            px += length((agora - antes) * res);
            antes = agora;
        }
        // O RGB Split solta os canais: o caminho do vermelho e do azul pode ser maior que o do verde.
        if (u.slideRgb > 0.0) px *= 1.0 + 0.7 * sqrt(u.slideRgb / 100.0);
    }
    if (u.scaleEnabled && u.scaleBlur > 0.0) {
        float o = u.scaleBlur / 100.0 * quadro;
        float a = 1.0 / escala(t - 0.5 * o).x;
        float m = 1.0 / escala(t).x;
        float b = 1.0 / escala(t + 0.5 * o).x;
        px = max(px, (abs(m - a) + abs(b - m)) * length(res));
    }
    return px;
}

/** A fração do quadro em que o obturador fica aberto: o maior dos motion blur ligados. */
float obturador() {
    float o = 0.0;
    if (u.slideEnabled) o = max(o, u.slideBlur / 100.0);
    if (u.scaleEnabled) o = max(o, u.scaleBlur / 100.0);
    return o;
}

// ------------------------------------------------------------------ a tabela do quadro (ver o cabeçalho)
const int COLUNAS = 512;          // 513 instantes do obturador; a coluna 256 é o instante do quadro
const float FAIXA_B = 16.0;       // o b do mapa, em [−16, 16)
const float CAMINHO_MAX = 4096.0; // o caminho guardado, em px da saída (64 amostras já saem com 96 px)

/** Um número de 0 a 1 em quatro bytes (o da sapphire-distort-chroma: os buffers do motor são RGBA8). */
float4 empacotar(float v) {
    v = clamp(v, 0.0, 0.99999994);
    float4 e = fract(v * float4(1.0, 255.0, 65025.0, 16581375.0));
    e -= e.yzww * float4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
    return e;
}

float desempacotar(float4 c) { return dot(c, float4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0)); }

/*
 * Um texel da tabela (passe 0). Linhas 0–8: a, b.x e b.y do mapa do verde (0–2), do vermelho (3–5) e do azul (6–8)
 * na coluna `j`, o instante t + (j/512 − ½) · obturador · quadro. Linha 9, um número por coluna: o caminho do tranco
 * (0), o Blur (1), o Time (2), o Light (3, 4) e o Color (5, 6).
 */
float4 texelDaTabela(int j, int linha, float t) {
    if (linha < 9) {
        int c = linha / 3;
        int componente = linha - 3 * c;
        float tj = t + (float(j) / float(COLUNAS) - 0.5) * obturador() * duracaoDoQuadro();
        float3 m = mapa(tj, float(c));
        if (componente == 0) return empacotar(m.x);
        return empacotar(((componente == 1 ? m.y : m.z) + FAIXA_B) / (2.0 * FAIXA_B));
    }
    if (j == 0) return empacotar(caminhoEmPixels(t, float2(int2(int(inputImg.get_width()), int(inputImg.get_height())))) / CAMINHO_MAX);
    if (j == 1) return empacotar(fatorDoBlur(t) / 4.0);
    if (j == 2) return empacotar(float(quadrosAtras(t)) / 8.0);
    if (j == 3) return empacotar(luz(t).x / 8.0);
    if (j == 4) return empacotar(luz(t).y > 0.5 ? 0.75 : 0.25);
    if (j == 5) return empacotar(cor(t).x / 4.0);
    if (j == 6) return empacotar((cor(t).y + 4.0) / 8.0);
    return float4(0.0);
}

/** Um número do quadro (a linha 9 da tabela). */
float doQuadro(int j) { return desempacotar(trilha.read(uint2(int2(j, 9)), uint(0))); }

/** Onde, na camada, cai o pixel `uv` no instante da coluna `j`, pelo mapa do `bloco` (0 verde, 1 vermelho, 2 azul). */
float2 origemNaTabela(float2 uv, int j, int bloco) {
    float a = desempacotar(trilha.read(uint2(int2(j, 3 * bloco)), uint(0)));
    float2 b = float2(desempacotar(trilha.read(uint2(int2(j, 3 * bloco + 1)), uint(0))),
                  desempacotar(trilha.read(uint2(int2(j, 3 * bloco + 2)), uint(0))));
    return uv * a + b * (2.0 * FAIXA_B) - FAIXA_B;
}

/** A camada com o Slide e o Scale do quadro (com o motion blur: a posição integrada ao longo do
 *  obturador, lida da tabela). `limite` = o máximo de instantes do obturador neste passe. */
float4 comTranco(float2 uv, int limite) {
    int amostras = 1;
    if (obturador() > 0.0) {
        // O caminho guardado é em px da saída; o passe do Blur é menor (1/4).
        float px = doQuadro(0) * CAMINHO_MAX * eng.acResolution.x / float(int2(int(inputImg.get_width()), int(inputImg.get_height())).x);
        if (px > 0.75) amostras = int(clamp(ceil(px / 1.5), 2.0, float(limite)));
    }
    // Um deslocamento por pixel (menos de uma imagem) desfaz o degrau que sobra quando o caminho passa do limite.
    // (o ruído de gradiente intercalado: fixo na tela, sem cintilar de um quadro para o outro)
    float tremido = amostras > 1 ? fract(52.9829189 * fract(dot(__nv_fragCoord.xy, float2(0.06711056, 0.00583715)))) : 0.5;
    bool juntos = !u.slideEnabled || u.slideRgb <= 0.0;
    float3 soma = float3(0.0);
    float alfa = 0.0;
    for (int i = 0; i < 64; i++) {
        if (i >= amostras) break;
        int j = amostras > 1
            ? min(int(floor((float(i) + tremido) / float(amostras) * float(COLUNAS) + 0.5)), COLUNAS)
            : COLUNAS / 2;
        if (juntos) {
            // Sem RGB Split os três canais vêm do mesmo ponto: uma leitura só.
            float4 cor = amostrar(origemNaTabela(uv, j, 0));
            soma += cor.rgb;
            alfa += cor.a;
            continue;
        }
        for (int c = 0; c < 3; c++) {
            // O verde (c = 1) leva o tranco original; vermelho e azul, os próprios.
            float4 cor = amostrar(origemNaTabela(uv, j, c == 1 ? 0 : (c == 0 ? 1 : 2)));
            soma[c] += cor[c];
            if (c == 1) alfa += cor.a;
        }
    }
    return float4(soma, alfa) / float(amostras);
}

/** Um eixo do gaussiano (33 toques até 3σ; passo maior que 1 px quando o σ pede). */
float4 gauss(sampler2D tex, float2 uv, float2 eixo, float sigma) {
    if (sigma < 0.3) return tex.sample(__nv_smp, uv);
    float passo = max(1.0, ceil(3.0 * sigma / 16.0));
    float4 acc = float4(0.0);
    float pesos = 0.0;
    for (int k = -16; k <= 16; k++) {
        float d = float(k) * passo;
        float w = exp(-0.5 * d * d / (sigma * sigma));
        acc += tex.sample(__nv_smp, clamp(uv + eixo * d * eng.acTexelSize, 0.0, 1.0)) * w;
        pesos += w;
    }
    return acc / pesos;
}

fragment float4 fx_novatwitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant novatwitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ant1 [[texture(1)]],
    texture2d<float> ant2 [[texture(2)]],
    texture2d<float> ant3 [[texture(3)]],
    texture2d<float> ant4 [[texture(4)]],
    texture2d<float> ant5 [[texture(5)]],
    texture2d<float> ant6 [[texture(6)]],
    texture2d<float> trilha [[texture(7)]],
    texture2d<float> tw [[texture(8)]],
    texture2d<float> bh [[texture(9)]],
    texture2d<float> bv [[texture(10)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float t = eng.acTime;
    float2 uv = in.acScreenNorm;

    // Passe 0: a tabela do quadro. É o ÚNICO lugar que sorteia (513 × 10 px).
    if (eng.acPass == 0) {
        int2 p = int2(__nv_fragCoord.xy);
        __nv_out = texelDaTabela(p.x, p.y, t);
        return __nv_out;
    }

    // Passes 1–3 (em 1/4 da resolução): a camada com o tranco, e o gaussiano em X e em Y.
    // Com o Blur desligado não rodam; ligado e parado neste quadro, um pixel preto em 1/16 da área.
    if (eng.acPass < 4) {
        float s = doQuadro(1) * 4.0 * eng.acResolution.x;
        if (s <= 0.0) { __nv_out = float4(0.0); return __nv_out; }
        if (eng.acPass == 1) __nv_out = comTranco(uv, 16);
        else if (eng.acPass == 2) __nv_out = gauss(tw, uv, float2(1.0, 0.0), s);
        else __nv_out = gauss(bh, uv, float2(0.0, 1.0), s);
        return __nv_out;
    }

    float4 resultado = comTranco(uv, 64);
    // Blur: o gaussiano dos passes (liso, como o do AE). Abaixo de ~3 px o buffer de 1/4 já é
    // mais borrado que o pedido: entra aos poucos.
    float sigma = doQuadro(1) * 4.0 * eng.acResolution.x;
    if (sigma > 0.5) resultado = mix(resultado, bv.sample(__nv_smp, uv), smoothstep(0.5, 3.0, sigma));

    // Time: um quadro ANTERIOR, durante o tranco (o histórico só tem os de trás).
    if (u.timeEnabled) {
        int atras = int(floor(doQuadro(2) * 8.0 + 0.5));
        if (atras == 1) resultado = ant1.sample(__nv_smp, uv);
        else if (atras == 2) resultado = ant2.sample(__nv_smp, uv);
        else if (atras == 3) resultado = ant3.sample(__nv_smp, uv);
        else if (atras == 4) resultado = ant4.sample(__nv_smp, uv);
        else if (atras == 5) resultado = ant5.sample(__nv_smp, uv);
        else if (atras == 6) resultado = ant6.sample(__nv_smp, uv);
    }

    // Light: clareia, escurece ou sorteia, com o ganho medido no AE.
    if (u.lightEnabled) {
        float l = doQuadro(3) * 8.0;
        bool escurece = doQuadro(4) > 0.5;
        // Medido na curva de tons do AE: clarear é só ganho (até 2,2× com Amount 50);
        // escurecer tira pouco contraste e desce o preto (x·(1 − 0,42l) − 0,36l − 0,03).
        if (escurece) resultado.rgb = max(resultado.rgb * (1.0 - 0.42 * l) - (0.36 * l + 0.03 * min(l * 20.0, 1.0)) * resultado.a, 0.0);
        else resultado.rgb = resultado.rgb * (1.0 + 2.6 * l);
    }

    // Color: multiplica pela cor do Colorize (×1,9), com o matiz sorteado.
    if (u.colorEnabled) {
        float c = doQuadro(5) * 4.0;
        // Giro de matiz (Rodrigues em volta do cinza) pelo Color Randomize.
        float giro = doQuadro(6) * 8.0 - 4.0;
        float3 eixo = float3(0.57735);
        float3 tinta = u.colorize.rgb * cos(giro) + cross(eixo, u.colorize.rgb) * sin(giro)
                   + eixo * dot(eixo, u.colorize.rgb) * (1.0 - cos(giro));
        resultado.rgb *= mix(float3(1.0), max(tinta, 0.0) * 1.9, c);
    }

    __nv_out = resultado;
    return __nv_out;
}
