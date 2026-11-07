// ---------------------------------------------------------------------------
// VHS
// origem : assets/effects/vhs.xml
// id     : nova.effect.vhs
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct vhsParams {
    float vhsAmount;
    int screenAspect;
    int osdOverlay;
    int glitchOverlay;
    float glitchAmount;
    float tracking;
    float jitter;
    float aberration;
    float noiseAmount;
    float softness;
    float bleed;
    float saturation;
    float tubeCurvature;
    float scanlines;
    float vignette;
    float reception;
    float turnOff;
    float halo;
    float4 tintColor;
    float tintAmount;
    float blackLift;
    int aberrationMode;
    float bandSpeed;
    float bounce;
    float headSwitch;
    float glitchDisplace;
    int glitchBlend;
    float tubeLines;
    float flicker;
    float tubeVignette;
    float tvPixels;
    float staticAmp;
    float interference;
    float humBars;
    float colorStripes;
    float hHold;
    float vRoll;
    float osdOpacity;
    float osdSize;
    float osdDamage;
    float4 barColor;
    float seed;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

// ============================================================================
//  ACASO
// ============================================================================

float semente() {
    return u.seed * 13.71 + 1.37;
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/** Ruído de valor 1D, -1..1, liso. */
float ruido1(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash11(i + semente()), hash11(i + 1.0 + semente()), u) * 2.0 - 1.0;
}

float indiceDoQuadro() {
    float fd = eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0;
    return floor(eng.acTime / fd + 0.5);
}

// ============================================================================
//  COR (YIQ: o NTSC separa luz e cor, e a fita trata as duas de jeitos diferentes)
// ============================================================================

float luma(float3 c) {
    return dot(c, float3(0.299, 0.587, 0.114));
}

float3 paraYiq(float3 c) {
    return float3(
        dot(c, float3(0.299, 0.587, 0.114)),
        dot(c, float3(0.596, -0.274, -0.322)),
        dot(c, float3(0.211, -0.523, 0.312)));
}

float3 deYiq(float3 q) {
    return float3(
        q.x + 0.956 * q.y + 0.621 * q.z,
        q.x - 0.272 * q.y - 0.647 * q.z,
        q.x - 1.106 * q.y + 1.703 * q.z);
}

// ============================================================================
//  O QUADRO DA TELA (as barras pretas)
// ============================================================================

/**
 * A proporção da tela. "Automática" é 4:3 numa camada deitada e 3:4 numa em pé:
 * um quadro 4:3 deitado num vídeo vertical ficaria minúsculo.
 */
float proporcaoDaTela() {
    if (u.screenAspect == 1) return eng.acAspect >= 1.0 ? 4.0 / 3.0 : 3.0 / 4.0;
    if (u.screenAspect == 2) return 4.0 / 3.0;
    if (u.screenAspect == 3) return 3.0 / 4.0;
    if (u.screenAspect == 4) return 1.0;
    if (u.screenAspect == 5) return 16.0 / 9.0;
    return eng.acAspect;
}

/** O tamanho da tela dentro da camada (0..1), centrada. */
float2 tamanhoDaTela() {
    float a = proporcaoDaTela();
    return a < eng.acAspect ? float2(a / eng.acAspect, 1.0) : float2(1.0, eng.acAspect / max(a, 0.0001));
}

/** A imagem PREENCHE a tela (corta o que sobra), como uma TV 4:3 passando algo mais largo. */
float2 escalaDoConteudo() {
    float a = proporcaoDaTela();
    return a < eng.acAspect ? float2(a / eng.acAspect, 1.0) : float2(1.0, eng.acAspect / max(a, 0.0001));
}

float2 paraTela(float2 uv) {
    return (uv - 0.5) / tamanhoDaTela() + 0.5;
}

bool foraDe(float2 p) {
    return p.x < 0.0 || p.y < 0.0 || p.x > 1.0 || p.y > 1.0;
}

/**
 * Onde, na tela da câmera gravada (OSD, filmado em 4:3), cai o ponto p da tela.
 *
 * Deitada: o OSD cobre a tela, como sempre. EM PÉ (relato do snow, 27/09/2026:
 * "numa composição em pé os elementos ficam meio fora da cena — o REC e tal"):
 * espremer o 4:3 numa tela 3:4 achatava o texto e tirava os cantos do lugar.
 * Agora o OSD mantém a proporção, ocupa a largura toda, e os TRÊS TERÇOS dele
 * ficam presos onde fazem sentido numa tela alta: o de cima (REC, bateria) no
 * alto, o do meio (foco, pausa) no meio, o de baixo (data, contador) embaixo.
 * Entre eles, nada. Devolve (-1, -1) para "sem OSD aqui".
 */
float2 uvDoOsd(float2 p) {
    float2 tela = tamanhoDaTela();
    float aspectoDaTela = eng.acAspect * tela.x / max(tela.y, 0.0001);
    if (aspectoDaTela >= 1.0) return p;
    float altura = 1.0 / aspectoDaTela;      // altura da tela, em larguras
    float yW = p.y * altura;
    float terco = 0.75 / 3.0;                // um terço do OSD (4:3 = 0,75 de altura por largura)
    if (yW < terco) return float2(p.x, yW / 0.75);
    if (yW > altura - terco) return float2(p.x, 1.0 - (altura - yW) / 0.75);
    float meio = altura * 0.5;
    if (abs(yW - meio) < terco * 0.5) return float2(p.x, 0.5 + (yW - meio) / 0.75);
    return float2(-1.0);
}

// ============================================================================
//  O SINAL: TUDO QUE DESLOCA A IMAGEM (em larguras da tela)
// ============================================================================

/** A energia das linhas claras do glitch filmado nesta altura. */
float energiaDoGlitch(float y) {
    if (u.glitchOverlay == 0) return 0.0;
    float soma = 0.0;
    float maior = 0.0;
    for (int i = 0; i < 5; i++) {
        float l = luma(glitchImg.sample(__nv_smp, float2(0.1 + 0.2 * float(i), y)).rgb);
        soma += l;
        maior = max(maior, l);
    }
    return clamp(maior * 0.6 + soma * 0.08, 0.0, 1.0);
}

/** A faixa de u.tracking: onde ela está nesta altura (0..1). */
float faixaDeTracking(float y) {
    if (u.tracking <= 0.0) return 0.0;
    float centro = fract(eng.acTime * u.bandSpeed * 0.08 + hash11(semente() + 3.0));
    float d = abs(fract(y - centro + 0.5) - 0.5);
    return 1.0 - smoothstep(0.0, 0.05 + u.tracking * 0.05, d);
}

float2 deslocamento(float2 p) {
    float k = u.vhsAmount;
    float q = indiceDoQuadro();
    float s = semente();
    float linha = floor(p.y * 480.0);
    float2 d = float2(0.0);

    // Tremor de base de tempo: as linhas oscilam um pouco, cada uma, e o conjunto
    // ondula devagar. É o "vivo" de uma fita parada.
    d.x += u.jitter * k * ruido1(p.y * 60.0 + q * 0.7 + s) * 0.0022;
    d.x += u.jitter * k * (hash21(float2(linha, q + s)) - 0.5) * 0.0008;

    // Pulo vertical, de vez em quando.
    if (u.bounce > 0.0) {
        float trecho = floor(q / 3.0);
        float pula = step(0.8, hash11(trecho * 1.7 + s));
        d.y += u.bounce * k * pula * (hash11(q + s + 5.0) - 0.5) * 0.012;
    }

    // Tracking: uma dobra LISA, que anda devagar — e não linhas soltas ao acaso.
    float w = faixaDeTracking(p.y);
    if (w > 0.0) {
        d.x += u.tracking * k * w * (ruido1(p.y * 22.0 + eng.acTime * 5.0 + s) * 0.03 + 0.012);
    }

    // Head switching: o pé da imagem torto para a direita, com ruído.
    if (u.headSwitch > 0.0) {
        float pe = smoothstep(0.972, 1.0, p.y);
        d.x += u.headSwitch * k * pe * (0.018 + 0.03 * hash21(float2(linha, q + s)));
    }

    // O glitch filmado rasga a imagem onde tem linha clara.
    if (u.glitchDisplace > 0.0 && u.glitchAmount > 0.0) {
        float e = energiaDoGlitch(p.y);
        d.x += u.glitchDisplace * u.glitchAmount * e * ((hash21(float2(linha * 0.5, q + s)) - 0.5) * 0.08 + 0.02);
    }
    return d;
}

// ============================================================================
//  PASSE 0 — A FITA
// ============================================================================

float4 amostra(float2 c) {
    return inputImg.sample(__nv_smp, clamp(c, 0.0, 1.0));
}

float4 passeFita() {
    float2 p = paraTela(in.acScreenNorm);
    if (foraDe(p)) return float4(0.0);
    float k = u.vhsAmount;
    float2 pd = p + deslocamento(p);
    float2 escala = escalaDoConteudo();
    float2 c = 0.5 + (pd - 0.5) * escala;
    // Um pixel da saída, em coordenada do conteúdo.
    float passo = eng.acTexelSize.x / tamanhoDaTela().x * escala.x;

    // Luz: pouca nitidez na horizontal (a fita perdia resolução sobretudo aí).
    float passoLuz = u.softness * k * 0.5 * passo;
    float Y = luma(amostra(c).rgb) * 0.36
            + (luma(amostra(c + float2(passoLuz, 0.0)).rgb) + luma(amostra(c - float2(passoLuz, 0.0)).rgb)) * 0.24
            + (luma(amostra(c + float2(passoLuz * 2.0, 0.0)).rgb) + luma(amostra(c - float2(passoLuz * 2.0, 0.0)).rgb)) * 0.08;

    // Cor: bem mais borrada, e ATRASADA para a direita — a croma da fita
    // chega depois da luz. Sete amostras, cinco delas à esquerda (a cor que
    // aparece aqui é a que estava à esquerda).
    float passoCor = u.bleed * k * 0.5 * passo;
    float2 iq = float2(0.0);
    float Ylargo = 0.0;
    for (int i = 0; i < 7; i++) {
        float3 q = paraYiq(amostra(c - float2(float(i - 1) * passoCor, 0.0)).rgb);
        iq += q.yz / 7.0;
        Ylargo += q.x / 7.0;
    }

    // O contorno claro do realce: o videocassete "afiava" a imagem e deixava
    // um u.halo em volta das bordas.
    Y += u.halo * k * (Y - Ylargo);
    iq *= u.saturation;
    float lava = u.blackLift * k;
    Y = lava + Y * (1.0 - lava);

    float3 cor = deYiq(float3(Y, iq));
    float3 tom = u.tintColor.rgb / max(luma(u.tintColor.rgb), 0.05);
    cor *= mix(float3(1.0), tom, u.tintAmount);

    // No pé da imagem, o head switching também embaralha a cor.
    if (u.headSwitch > 0.0) {
        float pe = smoothstep(0.972, 1.0, p.y) * u.headSwitch * k;
        float r = hash21(float2(floor(in.acScreenNorm.x * eng.acResolution.x / 3.0), floor(p.y * 480.0) + indiceDoQuadro()));
        cor = mix(cor, float3(r) * 0.8 + cor * 0.3, pe * 0.45);
    }
    return float4(clamp(cor, 0.0, 1.0), amostra(c).a);
}

// ============================================================================
//  PASSE 1 — A TELA (o que a câmera gravou, com as barras)
// ============================================================================

float4 passeTela() {
    float2 uv = in.acScreenNorm;
    float2 p = paraTela(uv);
    if (foraDe(p)) return float4(u.barColor.rgb, 1.0);

    float k = u.vhsAmount;
    float q = indiceDoQuadro();
    float s = semente();

    // Aberração: o vermelho e o azul separados do verde.
    float2 dir = float2(1.0, 0.0);
    if (u.aberrationMode == 1) {
        float2 v = (p - 0.5) * float2(eng.acAspect * tamanhoDaTela().x / max(tamanhoDaTela().y, 0.0001), 1.0);
        dir = length(v) > 0.0001 ? v / length(v) * min(length(v) * 2.0, 1.0) : float2(0.0);
    }
    float2 ab = dir * u.aberration * eng.acTexelSize;
    float4 c = fita.sample(__nv_smp, uv);
    c.r = fita.sample(__nv_smp, uv + ab).r;
    c.b = fita.sample(__nv_smp, uv - ab).b;

    // A tela da câmera: o azul do fundo sai por croma, o texto fica.
    if (u.osdOverlay > 0 && u.osdOpacity > 0.0) {
        float2 d = deslocamento(p) * u.osdDamage;
        float2 base = uvDoOsd(p);
        float2 o = (base + d - 0.5) / max(u.osdSize, 0.01) + 0.5;
        if (base.x >= 0.0 && !foraDe(o)) {
            float4 t = osdImg.sample(__nv_smp, o);
            // Gravada na fita: a cor do OSD também escorre um pouco.
            float4 t2 = osdImg.sample(__nv_smp, o - float2(u.bleed * k * eng.acTexelSize.x * 0.5, 0.0));
            t = mix(t, (t + t2) * 0.5, u.osdDamage * 0.6);
            float azul = t.b - max(t.r, t.g);
            float a = 1.0 - smoothstep(0.22, 0.5, azul);
            float3 corOsd = t.rgb;
            corOsd.b = min(corOsd.b, max(corOsd.r, corOsd.g) + 0.08);
            c.rgb = mix(c.rgb, corOsd, a * u.osdOpacity);
            c.a = max(c.a, a * u.osdOpacity);
        }
    }

    // O glitch filmado por cima.
    if (u.glitchOverlay > 0 && u.glitchAmount > 0.0) {
        float3 g = glitchImg.sample(__nv_smp, p).rgb;
        if (u.glitchBlend == 0) {
            c.rgb = 1.0 - (1.0 - c.rgb) * (1.0 - g * u.glitchAmount);
        } else if (u.glitchBlend == 1) {
            c.rgb += g * u.glitchAmount;
        } else {
            float3 sob = mix(2.0 * c.rgb * g, 1.0 - 2.0 * (1.0 - c.rgb) * (1.0 - g), step(0.5, c.rgb));
            c.rgb = mix(c.rgb, sob, u.glitchAmount);
        }
    }

    // Riscos de dropout dentro da faixa de u.tracking.
    float w = faixaDeTracking(p.y);
    if (w > 0.0) {
        float celula = floor(uv.x * eng.acResolution.x / 14.0);
        float risco = step(0.975 - u.tracking * 0.03, hash21(float2(celula, floor(p.y * 480.0) + q + s)));
        c.rgb += risco * w * u.tracking * k * 0.8;
    }

    // Ruído: grão de luz fino e ruído de cor em riscos horizontais (a cor da
    // fita tinha menos resolução, então o ruído dela também é mais largo).
    float nk = u.noiseAmount * k;
    if (nk > 0.0) {
        float2 px = uv * eng.acResolution;
        float grao = hash21(floor(px) + float2(q * 13.1, q * 7.7) + s) - 0.5;
        float2 celulaCor = floor(px / float2(6.0, 1.0));
        float2 ruidoCor = float2(hash21(celulaCor + float2(q * 3.1, s)), hash21(celulaCor + float2(q * 5.3, s + 9.0))) - 0.5;
        float3 y = paraYiq(c.rgb);
        y.x += grao * nk * 0.5;
        y.yz += ruidoCor * nk * 0.3;
        c.rgb = deYiq(y);
    }

    // Vinheta dentro da tela. (As linhas agora são as do tubo, no passe 2.)
    if (u.vignette > 0.0) {
        float2 v = (p - 0.5) * 2.0;
        c.rgb *= 1.0 - u.vignette * smoothstep(0.55, 1.6, length(v * float2(1.0, 0.9)));
    }
    return float4(clamp(c.rgb, 0.0, 1.0), c.a);
}

// ============================================================================
//  PASSE 2 — A TV
// ============================================================================
//
//  A fita passando numa TV de tubo, na ordem em que o snow empilhou: a TV
//  recebe o sinal (horizontal e vertical soltos), olha a imagem na resolução
//  dela, e o que ela olha é o TUBO (curvatura, linhas, tremida, vinheta). Por
//  cima, o que a recepção ruim soma: listras de cor, barras de zumbido,
//  chuvisco e pontos de interferência. Os detalhes que ele deixou nos
//  padrões (pontos a 0,63, barras com nitidez 1,95, três oitavas no
//  horizontal a 1,9...) viraram constantes.

const float PI = 3.14159265359;

float sementeTv() {
    return u.seed * 37.0 + 140.0;
}

float hash31(float3 p) {
    float3 p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

float3 hash33(float3 p) {
    float3 p3 = fract(p * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

float ruidoTv(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    float s = sementeTv();
    return mix(hash11(i + s), hash11(i + 1.0 + s), u) * 2.0 - 1.0;
}

/** Gira a fase da croma: é o que um sinal de cor fora de fase faz. */
float3 girarCroma(float3 c, float angulo) {
    float3 q = paraYiq(c);
    float cs = cos(angulo);
    float sn = sin(angulo);
    q.yz = float2(cs * q.y - sn * q.z, sn * q.y + cs * q.z);
    return deYiq(q);
}

/**
 * O tubo num ponto da camada (pré-multiplicado): a tela envergada, as linhas,
 * a tremida e a vinheta do vidro. Fora do vidro é a moldura: a cor das barras,
 * opaca.
 */
float4 noTubo(float2 a) {
    float4 moldura = float4(u.barColor.rgb, 1.0);
    if (foraDe(a)) return moldura;
    float2 c = a * 2.0 - 1.0;
    float2 b = (c + c.yx * c.yx * c * u.tubeCurvature) * 0.5 + 0.5;
    if (foraDe(b)) return moldura;
    float4 t = tela.sample(__nv_smp, b);
    float3 rgb = t.rgb * t.a;

    // As linhas, só onde cabem (abaixo de ~2 px por par vira moiré).
    if (u.scanlines > 0.0) {
        float periodo = 2.0 / max(u.tubeLines, 1.0) * eng.acResolution.y;
        float some = smoothstep(1.5, 2.5, periodo);
        rgb *= 1.0 - u.scanlines * some * (0.5 + 0.5 * sin(b.y * u.tubeLines * PI)) * 0.5;
    }
    // A tremida do sincronismo vertical.
    rgb *= 1.0 - u.flicker * (0.5 + 0.5 * sin(eng.acTime * 47.0));
    // A vinheta do vidro. No painel há uma "Vinheta" só, a da fita: abaixo do
    // padrão dela (0,3) ela apaga a do vidro junto; acima, só a da fita cresce.
    float d = length((b - 0.5) * 2.0 * float2(eng.acAspect, 1.0));
    rgb *= 1.0 - u.tubeVignette * clamp(u.vignette / 0.3, 0.0, 1.0) * smoothstep(0.6, 1.6, d);
    return float4(rgb, t.a);
}

/**
 * A imagem como a TV a vê: `tvRes` amostras, reconstruídas com interpolação
 * (sem degrau torto quando a conta não dá inteira).
 */
float4 lerNaTv(float2 uv, float2 tvRes) {
    float2 p = uv * tvRes - 0.5;
    float2 i = floor(p);
    float2 f = fract(p);
    float4 a = noTubo((i + float2(0.5, 0.5)) / tvRes);
    float4 b = noTubo((i + float2(1.5, 0.5)) / tvRes);
    float4 c = noTubo((i + float2(0.5, 1.5)) / tvRes);
    float4 d = noTubo((i + float2(1.5, 1.5)) / tvRes);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/**
 * A faixa entre um quadro e outro, que aparece quando a imagem rola: o código
 * de tempo em blocos e a legenda oculta (a fileira de tracinhos piscando).
 */
float3 faixaDeServico(float y, float x, float2 tv, float quadro, float2 tvRes) {
    float s = sementeTv();
    float total = max(floor(0.1 * tvRes.y), 1.0);
    float linha = floor(y * total);
    float3 v = float3(hash31(float3(floor(tv), quadro + s)) * 0.1);
    float quadroDoSinal = floor(eng.acTime * 30.0);
    if (abs(linha - floor(total * 0.4)) < 0.5 && x > 0.08 && x < 0.9) {
        float bloco = floor(x * 90.0);
        float muda = bloco > 60.0 ? quadroDoSinal : floor(quadroDoSinal / 30.0);
        v = float3(step(0.5, hash21(float2(bloco, muda + s))) * 0.75);
    }
    if (abs(linha - floor(total * 0.72)) < 0.5 && x > 0.03 && x < 0.92) {
        if (x < 0.13) {
            v = float3(0.5 + 0.5 * sin(x * TAU * 55.0)) * 0.8;
        } else {
            float bit = floor(x * 48.0);
            v = float3(step(0.45, hash21(float2(bit, floor(quadroDoSinal / 2.0) + s))) * 0.85);
        }
    }
    return v;
}

float4 passeTv() {
    float2 uvTela = in.acScreenNorm;
    float s = sementeTv();
    float quadro = floor(eng.acTime * 60.0);
    float rec = max(u.reception, 0.0);
    float pixelsDaTv = max(u.tvPixels, 8.0);
    float2 tvRes = float2(pixelsDaTv, pixelsDaTv / max(eng.acAspect, 0.0001));
    float2 tv = uvTela * tvRes;                  // a grade do aparelho (fica na tela)

    // ------------------------------------------------ desligar: a imagem encolhe
    float2 uv = uvTela;
    float escalaX = 1.0;
    bool apagada = false;
    if (u.turnOff > 0.0) {
        float escalaY = mix(1.0, 0.004, pow(smoothstep(0.0, 0.55, u.turnOff), 0.7));
        escalaX = mix(1.0, 0.003, smoothstep(0.5, 0.9, u.turnOff));
        float2 c = uv - 0.5;
        apagada = abs(c.y) > escalaY * 0.5 || abs(c.x) > escalaX * 0.5;
        uv = 0.5 + c / float2(escalaX, escalaY);
    }
    float yDaTela = uv.y;

    // ------------------------------------------------ imagem rolando
    // O tempo em episódios de 2,5 s; "Imagem rolando" × recepção é a fração
    // deles em que o vertical solta. No padrão é zero: rolar sozinho, de tempos
    // em tempos, num efeito que se aplica e esquece, pareceria defeito do app.
    bool naFaixaV = false;
    float yNaFaixa = 0.0;
    float vAmt = clamp(u.vRoll * rec, 0.0, 1.0);
    if (vAmt > 0.0) {
        float duracao = 2.5;
        float episodio = floor(eng.acTime / duracao);
        if (hash11(episodio * 3.17 + s) < vAmt) {
            float t = eng.acTime - episodio * duracao;
            float passos = t * 2.0;
            float tranco = smoothstep(0.0, 1.0, fract(passos));
            float pos = 0.7 * (floor(passos) + tranco) / 2.0;
            pos += 0.004 * ruidoTv(t * 11.0 + episodio * 5.3);
            float w = __nv_mod(uv.y + pos, 1.1);
            if (w > 1.0) {
                naFaixaV = true;
                yNaFaixa = (w - 1.0) / 0.1;
            }
            uv.y = w;
        }
    }

    // ------------------------------------------------ horizontal solto
    bool naFaixaH = false;
    // No painel há um "Tremor" só, o das linhas: abaixo do padrão dele (0,25) ele
    // acalma o horizontal solto junto; acima, só o das linhas cresce.
    float hAmp = u.hHold * rec * clamp(u.jitter / 0.25, 0.0, 1.0);
    if (hAmp > 0.0) {
        float soma = 0.0;
        float peso = 0.0;
        float a = 1.0;
        float fr = 1.0;
        for (int o = 0; o < 3; o++) {
            soma += a * ruidoTv(yDaTela * 1.9 * 3.0 * fr + eng.acTime * 0.9 * fr + float(o) * 19.7);
            peso += a;
            a *= 0.55;
            fr *= 2.1;
        }
        soma /= peso;
        float varia = 1.0 + 0.5 * (hash11(floor(eng.acTime * 12.0) * 1.3 + s) * 2.0 - 1.0);
        float w = __nv_mod(uv.x + soma * hAmp * 0.06 * varia, 1.05);
        if (w > 1.0) naFaixaH = true;
        uv.x = w;
    }

    // ------------------------------------------------ a imagem recebida
    float4 img;
    if (naFaixaV) {
        img = float4(faixaDeServico(yNaFaixa, uv.x, tv, quadro, tvRes), 1.0);
    } else if (naFaixaH) {
        img = float4(0.0, 0.0, 0.0, 1.0);
    } else if (tvRes.x < eng.acResolution.x * 0.95) {
        img = lerNaTv(uv, tvRes);
    } else {
        img = noTubo(uv);
    }
    float3 cor = img.rgb;
    float alfa = img.a;

    // ------------------------------------------------ listras de cor
    float listras = u.colorStripes * rec;
    if (listras > 0.0) {
        float ang = radians(160.0);
        float2 pp = float2((uvTela.x - 0.5) * eng.acAspect, uvTela.y - 0.5);
        float fase = dot(pp, float2(cos(ang), sin(ang))) * 10.0 + eng.acTime * 3.0;
        cor = girarCroma(cor, sin(fase * TAU) * listras * PI * 0.35);
        float3 arco = 0.5 + 0.5 * cos(TAU * (fase + float3(0.0, 0.333, 0.667)));
        cor += (arco - 0.5) * listras * 0.2 * alfa;
    }

    // ------------------------------------------------ barras de zumbido
    // A rede elétrica vaza no sinal: faixas largas de brilho que rolam devagar,
    // e outras seis vezes mais finas por cima. A média fica no lugar.
    float zumbido = u.humBars * rec;
    if (zumbido > 0.0) {
        float f1 = fract(uvTela.y + eng.acTime * 0.1);
        float m1 = 0.5 / (1.0 + 1.95 * 8.0);
        float b1 = smoothstep(0.0, m1, f1) * (1.0 - smoothstep(0.35, 0.35 + m1, f1));
        float g1 = 1.0 + zumbido * (b1 - 0.35) * 1.2;
        float f2 = fract(uvTela.y * 6.0 + eng.acTime * 0.13);
        float b2 = smoothstep(0.0, 0.1, f2) * (1.0 - smoothstep(0.5, 0.6, f2));
        float g2 = 1.0 + zumbido * (b2 - 0.5) * 0.5;
        cor *= max(g1 * g2, 0.0);
    }

    // ------------------------------------------------ chuvisco
    // Na grade da TV, e na tela inteira: as barras pretas também chuviscam.
    float chuvisco = u.staticAmp * rec;
    if (chuvisco > 0.0) {
        float3 celula = float3(floor(tv), quadro + s);
        float tem = step(hash31(celula + float3(0.0, 0.0, 91.3)), 0.7);
        float3 neve = mix(float3(hash31(celula)), hash33(celula), 0.25);
        cor += (neve - 0.5) * chuvisco * 0.9 * tem * alfa;
    }

    // ------------------------------------------------ pontos de interferência
    float interf = u.interference * rec;
    if (interf > 0.0) {
        float2 tremor = (float2(hash11(quadro * 1.31 + s), hash11(quadro * 2.77 + s)) - 0.5) * 2.0 * float2(1.0, 0.1);
        float2 p = tv + float2(100.0, -10.0) * eng.acTime + tremor;
        float fila = floor(p.y);
        float x = p.x / 9.0 + fila * 0.63;
        float celulaX = floor(x);
        float f = fract(x);
        float tem = step(hash21(float2(celulaX, fila) + s), 0.28);
        float ponto = smoothstep(0.0, 0.06, f) * (1.0 - smoothstep(0.14, 0.26, f));
        float rajada = smoothstep(-0.2, 0.6, ruidoTv(p.y / tvRes.y * 4.0 + eng.acTime * 0.7));
        float3 corDoPonto = 0.35 + 0.9 * hash33(float3(celulaX, fila, s));
        cor += corDoPonto * ponto * tem * rajada * interf * 0.8 * alfa;
    }

    // ------------------------------------------------ desligar
    // A imagem esbranquiça e desaba num risco (até 0,55), o risco vira um
    // ponto (até 0,9), e o ponto some com um clarão.
    if (u.turnOff > 0.0) {
        cor = mix(cor, float3(alfa), smoothstep(0.04, 0.5, u.turnOff));
        if (apagada) cor = float3(0.0);
        float apagando = smoothstep(0.3, 1.0, u.turnOff);
        cor *= 1.0 - apagando * apagando;
        if (u.turnOff < 1.0) {
            float2 c = (uvTela - 0.5) * float2(eng.acAspect, 1.0);
            float quando = smoothstep(0.6, 0.88, u.turnOff) * (1.0 - smoothstep(0.9, 1.0, u.turnOff));
            float redondo = exp(-dot(c, c) / 0.0025);
            float risco = exp(-abs(c.y) / 0.006) * exp(-abs(c.x) / (0.35 * max(escalaX, 0.05)));
            cor += float3(1.0, 0.97, 0.92) * (redondo * 0.6 + risco * 0.4) * quando * alfa;
        }
    }

    float a = clamp(alfa, 0.0, 1.0);
    float3 rgb = clamp(cor, 0.0, max(a, 0.0001));
    return float4(a > 0.0001 ? rgb / a : float3(0.0), a);
}

fragment float4 fx_vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fita [[texture(1)]],
    texture2d<float> tela [[texture(2)]],
    texture2d<float> osdImg [[texture(3)]],
    texture2d<float> glitchImg [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = passeFita(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = passeTela(); return __nv_out; }
    __nv_out = passeTv();
    return __nv_out;
}
