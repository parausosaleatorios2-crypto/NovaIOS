// ---------------------------------------------------------------------------
// TV Danificada
// origem : assets/effects/tv-damage.xml
// id     : nova.effect.tvdamage
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tv_damageParams {
    int effectMode;
    float reception;
    float staticAmp;
    float interferenceAmp;
    float ghostAmp;
    float horizontalHold;
    float verticalHold;
    float barsBrightness;
    float colorStripesAmp;
    float fastForward;
    float dropoutBrightness;
    float staticDensity;
    float interferenceFreq;
    float dotsSpeedX;
    float dotsSpeedY;
    float jitterAmount;
    float numGhosts;
    float negativeGhosts;
    float ghostSpacing;
    float varyPosition;
    float ghostShift;
    float ghostBlur;
    float hFrequency;
    float hTimeVary;
    float hOctaves;
    float borderWidth;
    float vFrequency;
    float vSpeed;
    float vRandom;
    float borderHeight;
    float borderData;
    float barRollSpeed;
    float barSharpness;
    float barFrequency;
    float bar1Width;
    float bar2RelFrequency;
    float bar2Sharpness;
    float colorFrequency;
    float colorAngle;
    float stripesRollSpeed;
    float ffBandFrequency;
    float ffBandShift;
    float ffBandHeight;
    float dropoutLength;
    float dropoutGap;
    float dropoutYFreq;
    float dropoutYThreshold;
    float dropoutsAlways;
    float scanlines;
    float scanlinesRelFreq;
    float orthicon;
    float orthiconThreshold;
    float darksWidth;
    float turnOff;
    float flareWidth;
    float flareBrightness;
    float fadeOutTime;
    float vignetteDarkness;
    float vignetteRadius;
    float vignetteSoftness;
    float vignetteRelHeight;
    float fishEye;
    float hueShift;
    float saturationAmt;
    float scaleLights;
    float offsetDarks;
    float4 tintLights;
    float4 tintDarks;
    float tvPixels;
    int downsample;
    float seed;
    int maskUse;
    float blurMask;
    int invertMask;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;
const float PI = 3.14159265359;

// ============================================================================
//  ACASO — hashes sem seno (o seno perde precisão em GPU de celular)
// ============================================================================

float semente() {
    return u.seed * 1000.0 + 17.0;
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

/** Ruído de valor 1D, -1..1, liso. */
float ruido1(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    float s = semente();
    return mix(hash11(i + s), hash11(i + 1.0 + s), u) * 2.0 - 1.0;
}

// ============================================================================
//  COR — a TV pensa em luminância e croma (YIQ, o NTSC)
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

/** Gira a fase da croma: é o que um sinal de cor fora de fase faz. */
float3 girarCroma(float3 c, float angulo) {
    float3 q = paraYiq(c);
    float cs = cos(angulo);
    float sn = sin(angulo);
    q.yz = float2(cs * q.y - sn * q.z, sn * q.y + cs * q.z);
    return deYiq(q);
}

// ============================================================================
//  LEITURA DA IMAGEM (pré-multiplicada; fora da camada é o apagamento: preto)
// ============================================================================

float4 lerP(float2 uv) {
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return float4(0.0);
    float4 c = inputImg.sample(__nv_smp, uv);
    return float4(c.rgb * c.a, c.a);
}

/**
 * A imagem como a TV a vê: `tvRes` amostras, reconstruídas com interpolação.
 *
 * É o "Downsample". Reconstruir em vez de pintar blocos evita o degrau torto
 * quando a conta não dá inteira (720 pixels de TV numa camada de 1080).
 */
float4 lerNaTv(float2 uv, float2 tvRes) {
    float2 p = uv * tvRes - 0.5;
    float2 i = floor(p);
    float2 f = fract(p);
    float4 a = lerP((i + float2(0.5, 0.5)) / tvRes);
    float4 b = lerP((i + float2(1.5, 0.5)) / tvRes);
    float4 c = lerP((i + float2(0.5, 1.5)) / tvRes);
    float4 d = lerP((i + float2(1.5, 1.5)) / tvRes);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ============================================================================
//  PASSES 0 a 2 — o halo do u.orthicon
// ============================================================================

float4 claroParaOrthicon() {
    if (u.orthicon <= 0.0) return float4(0.0);
    float2 d = eng.acTexelSize * 0.25;
    float soma = 0.0;
    for (int i = 0; i < 4; i++) {
        float2 o = float2(i == 0 || i == 2 ? -d.x : d.x, i < 2 ? -d.y : d.y);
        float4 c = inputImg.sample(__nv_smp, in.acScreenNorm + o);
        soma += smoothstep(u.orthiconThreshold, u.orthiconThreshold + 0.15, luma(c.rgb)) * c.a;
    }
    return float4(soma * 0.25, 0.0, 0.0, 1.0);
}

float4 desfocar(sampler2D t, float2 uv) {
    if (u.orthicon <= 0.0) return float4(0.0);
    float2 d = eng.acTexelSize * (1.0 + u.darksWidth * 5.0);
    float s = t.sample(__nv_smp, uv).r * 0.25;
    s += (t.sample(__nv_smp, uv + float2(d.x, 0.0)).r + t.sample(__nv_smp, uv - float2(d.x, 0.0)).r
        + t.sample(__nv_smp, uv + float2(0.0, d.y)).r + t.sample(__nv_smp, uv - float2(0.0, d.y)).r) * 0.125;
    s += (t.sample(__nv_smp, uv + d).r + t.sample(__nv_smp, uv - d).r
        + t.sample(__nv_smp, uv + float2(d.x, -d.y)).r + t.sample(__nv_smp, uv + float2(-d.x, d.y)).r) * 0.0625;
    return float4(s, 0.0, 0.0, 1.0);
}

// ============================================================================
//  A FAIXA ENTRE UM QUADRO E OUTRO (o "vertical blanking")
// ============================================================================

/**
 * O que aparece na faixa preta quando o vertical solta: não é só preto. A TV
 * mostra lá as linhas de serviço — o código de tempo em blocos e a legenda
 * oculta, que é aquela fileira de tracinhos brancos piscando.
 */
float3 faixaDeServico(float y, float x, float2 tv, float quadro, float2 tvRes) {
    float s = semente();
    float total = max(floor(u.borderHeight * tvRes.y), 1.0);
    float linha = floor(y * total);
    float3 v = float3(hash31(float3(floor(tv), quadro + s)) * 0.1);

    float quadroDoSinal = floor(eng.acTime * 30.0);
    // Código de tempo (VITC): blocos; só os da direita (os quadros) mudam sempre.
    if (abs(linha - floor(total * 0.4)) < 0.5 && x > 0.08 && x < 0.9) {
        float bloco = floor(x * 90.0);
        float muda = bloco > 60.0 ? quadroDoSinal : floor(quadroDoSinal / 30.0);
        v = float3(step(0.5, hash21(float2(bloco, muda + s))) * 0.75);
    }
    // Legenda oculta: o "clock run-in" (uma onda) e depois os bits.
    if (abs(linha - floor(total * 0.72)) < 0.5 && x > 0.03 && x < 0.92) {
        if (x < 0.13) {
            v = float3(0.5 + 0.5 * sin(x * TAU * 55.0)) * 0.8;
        } else {
            float bit = floor(x * 48.0);
            v = float3(step(0.45, hash21(float2(bit, floor(quadroDoSinal / 2.0) + s))) * 0.85);
        }
    }
    return v * u.borderData;
}

// ============================================================================
//  PASSE 3 — A TV
// ============================================================================

float4 aTv() {
    float2 uvTela = in.acScreenNorm;
    float4 naTela = inputImg.sample(__nv_smp, uvTela);   // a área da tela: a camada como está
    float s = semente();
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

    // ------------------------------------------------ olho de peixe do vidro
    if (u.fishEye != 0.0) {
        float2 q = (uv - 0.5) * float2(eng.acAspect, 1.0);
        float r2 = clamp(dot(q, q) / (0.25 * (eng.acAspect * eng.acAspect + 1.0)), 0.0, 1.0);
        q *= max(1.0 - u.fishEye * 0.5 * (1.0 - r2), 0.1);
        uv = q / float2(eng.acAspect, 1.0) + 0.5;
    }
    float yDaTela = uv.y;

    // ------------------------------------------------ vertical solto
    bool naFaixaV = false;
    float yNaFaixa = 0.0;
    float vAmt = clamp(u.verticalHold * rec, 0.0, 1.0);
    if (vAmt > 0.0 && u.vSpeed > 0.0) {
        float duracao = 2.5;
        float episodio = floor(eng.acTime / duracao);
        if (hash11(episodio * 3.17 + s) < vAmt) {
            float t = eng.acTime - episodio * duracao;
            float f = max(u.vFrequency, 0.05);
            float passos = t * f;
            float tranco = smoothstep(0.0, 1.0, fract(passos));
            float pos = u.vSpeed * 0.35 * (floor(passos) + tranco) / f;
            pos += u.vRandom * 0.04 * ruido1(t * 11.0 + episodio * 5.3);
            float periodo = 1.0 + u.borderHeight;
            float w = __nv_mod(uv.y + pos, periodo);
            if (w > 1.0) {
                naFaixaV = true;
                yNaFaixa = (w - 1.0) / max(u.borderHeight, 0.0001);
            }
            uv.y = w;
        }
    }

    // ------------------------------------------------ horizontal solto
    bool naFaixaH = false;
    float hAmp = u.horizontalHold * rec;
    if (hAmp > 0.0) {
        float soma = 0.0;
        float peso = 0.0;
        float a = 1.0;
        float fr = 1.0;
        for (int o = 0; o < 10; o++) {
            if (float(o) >= u.hOctaves) break;
            soma += a * ruido1(yDaTela * u.hFrequency * 3.0 * fr + eng.acTime * 0.9 * fr + float(o) * 19.7);
            peso += a;
            a *= 0.55;
            fr *= 2.1;
        }
        soma /= max(peso, 0.0001);
        // Uns quadros empurram mais que outros.
        float varia = 1.0 + u.hTimeVary * (hash11(floor(eng.acTime * 12.0) * 1.3 + s) * 2.0 - 1.0);
        float dx = soma * hAmp * 0.06 * max(varia, 0.0);
        float periodo = 1.0 + u.borderWidth;
        float w = __nv_mod(uv.x + dx, periodo);
        if (w > 1.0) naFaixaH = true;
        uv.x = w;
    }

    // ------------------------------------------------ a imagem recebida
    float3 cor;
    float alfa;
    bool naFaixa = naFaixaV || naFaixaH;
    if (naFaixaV) {
        cor = faixaDeServico(yNaFaixa, uv.x, tv, quadro, tvRes) * naTela.a;
        alfa = naTela.a;
    } else if (naFaixaH) {
        cor = float3(0.0);
        alfa = naTela.a;
    } else {
        bool reduz = u.downsample && tvRes.x < eng.acResolution.x * 0.95;
        float4 img = reduz ? lerNaTv(uv, tvRes) : lerP(uv);
        cor = img.rgb;
        alfa = img.a;
    }
    if (u.effectMode == 1) cor = float3(luma(cor));

    // ------------------------------------------------ fantasmas (multipercurso)
    /*
     * O sinal chega pela antena e também refletido num prédio, um pouco
     * depois: uma cópia deslocada para a direita. Algumas chegam antes, a
     * maioria depois, algumas invertidas. Cada cópia entra pela DIFERENÇA
     * para o sinal de agora (o ganho automático da TV segura a média): num
     * trecho liso ela não muda nada, e onde a cópia difere ela aparece — o sol
     * vira um disco fraco sobre o céu, e o céu escurece um pouco o sol.
     * Somadas, as cópias nunca passam de 80% do sinal: com trinta fantasmas
     * fortes a imagem vira uma bagunça de ecos, e não um borrão estourado.
     */
    float gAmp = u.ghostAmp * rec;
    if (gAmp > 0.0 && u.numGhosts >= 1.0 && !naFaixa) {
        float3 soma = float3(0.0);
        float pesos = 0.0;
        float n = floor(u.numGhosts);
        for (int i = 0; i < 30; i++) {
            float fi = float(i);
            if (fi >= n) break;
            float base = mix((fi + 0.5) / n, hash11(fi * 7.7 + s), clamp(u.varyPosition, 0.0, 1.0));
            float pos = (base - 0.5 + u.ghostShift * 0.5) * u.ghostSpacing;
            float queda = exp(-abs(pos) / max(u.ghostSpacing, 0.001) * 1.5);
            float forca = queda * (0.45 + 0.55 * hash11(fi * 1.93 + s + 11.0));
            float sinal = hash11(fi * 3.31 + s + 5.0) < u.negativeGhosts ? -1.0 : 1.0;
            float2 uvG = float2(uv.x - pos, uv.y);
            float3 g;
            if (u.ghostBlur > 0.0) {
                float2 d = float2(u.ghostBlur * 0.004, 0.0);
                g = (lerP(uvG).rgb * 2.0 + lerP(uvG - d).rgb + lerP(uvG + d).rgb) * 0.25;
            } else {
                g = lerP(uvG).rgb;
            }
            if (u.effectMode == 1) g = float3(luma(g));
            soma += sinal * forca * (g - cor);
            pesos += forca;
        }
        cor += soma * min(gAmp * 0.5, 0.8 / max(pesos, 0.0001));
    }

    // ------------------------------------------------ u.orthicon
    if (u.orthicon > 0.0 && !naFaixa) {
        float halo = claroB.sample(__nv_smp, uv).r * 0.5 + claroC.sample(__nv_smp, uv).r;
        float aqui = smoothstep(u.orthiconThreshold, u.orthiconThreshold + 0.15, luma(cor / max(alfa, 0.0001)));
        cor *= 1.0 - clamp(u.orthicon * max(halo - aqui, 0.0) * 0.8, 0.0, 0.95);
    }

    // ------------------------------------------------ listras de cor
    float listras = u.colorStripesAmp * rec;
    if (listras > 0.0) {
        float ang = radians(u.colorAngle);
        float2 pp = float2((uvTela.x - 0.5) * eng.acAspect, uvTela.y - 0.5);
        float fase = dot(pp, float2(cos(ang), sin(ang))) * u.colorFrequency + eng.acTime * u.stripesRollSpeed;
        if (u.effectMode == 0) {
            cor = girarCroma(cor, sin(fase * TAU) * listras * PI * 0.35);
            float3 arco = 0.5 + 0.5 * cos(TAU * (fase + float3(0.0, 0.333, 0.667)));
            cor += (arco - 0.5) * listras * 0.2 * alfa;
        } else {
            cor *= 1.0 + sin(fase * TAU) * listras * 0.25;
        }
    }

    // ------------------------------------------------ barras de zumbido
    /*
     * A rede elétrica vaza no sinal e o brilho sobe e desce em faixas largas
     * que rolam devagar. Duas famílias: as grandes (parte clara = Bar1 Width)
     * e as finas, `Bar2 Rel Frequency` vezes mais juntas. O produto das duas
     * é o batimento que a documentação chama de "interferem entre si". A
     * média fica no lugar: o claro sobe tanto quanto o escuro desce.
     */
    float zumbido = u.barsBrightness * rec;
    if (zumbido > 0.0) {
        float f1 = fract(uvTela.y * u.barFrequency + eng.acTime * u.barRollSpeed * 0.2);
        float m1 = 0.5 / (1.0 + u.barSharpness * 8.0);
        float b1 = smoothstep(0.0, m1, f1) * (1.0 - smoothstep(u.bar1Width, u.bar1Width + m1, f1));
        float g1 = 1.0 + zumbido * min(u.barSharpness * 10.0, 1.0) * (b1 - u.bar1Width) * 1.2;
        float f2 = fract(uvTela.y * u.barFrequency * u.bar2RelFrequency + eng.acTime * u.barRollSpeed * 0.26);
        float m2 = 0.5 / (1.0 + u.bar2Sharpness * 8.0);
        float b2 = smoothstep(0.0, m2, f2) * (1.0 - smoothstep(0.5, 0.5 + m2, f2));
        float g2 = 1.0 + zumbido * min(u.bar2Sharpness * 10.0, 1.0) * (b2 - 0.5) * 0.5;
        cor *= max(g1 * g2, 0.0);
    }

    // ------------------------------------------------ chuvisco
    float chuvisco = u.staticAmp * rec;
    if (chuvisco > 0.0) {
        float3 celula = float3(floor(tv), quadro + s);
        float tem = step(hash31(celula + float3(0.0, 0.0, 91.3)), u.staticDensity);
        float3 neve = float3(hash31(celula));
        // A TV em cores faz um pouco de "confete" colorido no chuvisco.
        if (u.effectMode == 0) neve = mix(neve, hash33(celula), 0.25);
        cor += (neve - 0.5) * chuvisco * 0.9 * tem * max(alfa, naTela.a);
    }

    // ------------------------------------------------ interferência elétrica
    float interf = u.interferenceAmp * rec;
    if (interf > 0.0) {
        float2 tremor = (float2(hash11(quadro * 1.31 + s), hash11(quadro * 2.77 + s)) - 0.5) * u.jitterAmount * float2(1.0, 0.1);
        float2 p = tv + float2(u.dotsSpeedX, u.dotsSpeedY) * eng.acTime + tremor;
        float fila = floor(p.y);
        float x = p.x / 9.0 + fila * u.interferenceFreq;
        float celulaX = floor(x);
        float f = fract(x);
        float tem = step(hash21(float2(celulaX, fila) + s), 0.28);
        float ponto = smoothstep(0.0, 0.06, f) * (1.0 - smoothstep(0.14, 0.26, f));
        // A interferência vem em rajadas, não na tela inteira.
        float rajada = smoothstep(-0.2, 0.6, ruido1(p.y / tvRes.y * 4.0 + eng.acTime * 0.7));
        float3 corDoPonto = u.effectMode == 0 ? 0.35 + 0.9 * hash33(float3(celulaX, fila, s)) : float3(1.0);
        cor += corDoPonto * ponto * tem * rajada * interf * 0.8 * max(alfa, naTela.a);
    }

    // ------------------------------------------------ avanço rápido do vídeo
    if (u.fastForward > 0.0 && u.ffBandFrequency > 0.0) {
        float periodo = 1.0 / u.ffBandFrequency;
        float yy = uvTela.y - u.ffBandShift;
        float faixa = floor(yy / periodo);
        float d = abs(__nv_mod(yy, periodo) - periodo * 0.5);
        float meia = u.ffBandHeight * 0.5;
        // A borda é rasgada: ruído ao longo da largura.
        float borda = meia * (1.0 + 0.35 * ruido1(uvTela.x * 30.0 + quadro * 0.7 + faixa * 13.0));
        float dentro = 1.0 - smoothstep(borda * 0.8, borda, d);
        if (dentro > 0.0) {
            float fil = floor(tv.y);
            float rasgo = (hash21(float2(fil, quadro + s)) - 0.5) * 0.3;
            float3 rasgada = lerP(float2(uv.x + rasgo, uv.y)).rgb * 0.6;
            if (u.effectMode == 1) rasgada = float3(luma(rasgada));
            float neve = hash31(float3(floor(tv.x * 0.5), fil, quadro + s));
            float3 banda = mix(rasgada, float3(neve) * naTela.a, 0.55);
            banda += smoothstep(borda * 0.5, borda, d) * 0.35 * neve * naTela.a;
            cor = mix(cor, banda * max(u.fastForward, 1.0), dentro * clamp(u.fastForward, 0.0, 1.0));
            alfa = mix(alfa, max(alfa, naTela.a), dentro * clamp(u.fastForward, 0.0, 1.0));
        }
    }

    // ------------------------------------------------ dropouts da fita
    if (u.dropoutBrightness > 0.0) {
        float quadroDaFita = floor(eng.acTime * 30.0);
        if (hash11(quadroDaFita * 1.37 + s + 3.0) < u.dropoutsAlways) {
            float fil = floor(tv.y);
            // Em que faixas da altura a fita está ruim neste quadro.
            float nY = ruido1(uvTela.y * u.dropoutYFreq + quadroDaFita * 7.13) * 0.5 + 0.5;
            float faixaRuim = smoothstep(1.0 - u.dropoutYThreshold * 0.6, 1.02 - u.dropoutYThreshold * 0.6, nY);
            float linhaRuim = step(hash21(float2(fil, quadroDaFita + s)), 0.18) * faixaRuim;
            if (linhaRuim > 0.0) {
                float ciclo = max(u.dropoutLength + u.dropoutGap, 0.001);
                float xx = uvTela.x / ciclo + hash21(float2(fil * 1.7, quadroDaFita + s + 2.0));
                float pedaco = floor(xx);
                float f = fract(xx) * ciclo;
                float comprimento = u.dropoutLength * (0.4 + 1.2 * hash21(float2(pedaco, fil + quadroDaFita)));
                float risco = smoothstep(0.0, 0.01, f) * (1.0 - smoothstep(comprimento * 0.8, comprimento, f));
                risco *= step(hash21(float2(pedaco * 3.1, fil + s)), 0.6);
                float grao = 0.7 + 0.3 * hash31(float3(floor(tv), quadro + s));
                cor += float3(risco * u.dropoutBrightness * grao) * max(alfa, naTela.a);
            }
        }
    }

    // ------------------------------------------------ linhas de varredura
    if (u.scanlines > 0.0) {
        float linhas = tvRes.y * max(u.scanlinesRelFreq, 0.01);
        float fw = linhas * eng.acTexelSize.y;
        float perfil = 0.5 + 0.5 * cos(TAU * (fract(uvTela.y * linhas) - 0.5));
        // Abaixo de ~2 px por linha a grade vira moiré: some aos poucos.
        float some = 1.0 - smoothstep(0.3, 0.6, fw);
        cor *= clamp(1.0 - u.scanlines * (1.0 - perfil) * some, 0.0, 1.0);
    }

    // ------------------------------------------------ correção de cor
    if (u.hueShift != 0.0) cor = girarCroma(cor, radians(u.hueShift));
    if (u.saturationAmt != 1.0) {
        float l = luma(cor);
        cor = float3(l) + (cor - float3(l)) * u.saturationAmt;
    }
    cor *= u.scaleLights * u.tintLights.rgb;
    cor += (float3(u.offsetDarks) + u.tintDarks.rgb) * max(alfa - cor, float3(0.0));

    // ------------------------------------------------ vinheta
    if (u.vignetteDarkness > 0.0) {
        float2 q = float2((uvTela.x - 0.5) * 2.0, (uvTela.y - 0.5) * 2.0 / max(eng.acAspect, 0.0001));
        float d = length(float2(q.x, q.y / max(u.vignetteRelHeight, 0.1)));
        float v = smoothstep(u.vignetteRadius, u.vignetteRadius + max(u.vignetteSoftness, 0.001), d);
        cor *= 1.0 - clamp(u.vignetteDarkness, 0.0, 1.0) * v;
    }

    // ------------------------------------------------ desligar
    /*
     * A TV de tubo desligando: a imagem esbranquiça e desaba num risco
     * horizontal (até 0,55), o risco encolhe até um ponto (até 0,9), e o ponto
     * some com um clarão. `Fade Out Time` é o quanto do fim é o apagar.
     */
    if (u.turnOff > 0.0) {
        cor = mix(cor, float3(max(alfa, naTela.a)), smoothstep(0.04, 0.5, u.turnOff));
        if (apagada) cor = float3(0.0);
        alfa = naTela.a;
        // O apagar vem ao quadrado: o risco segura o brilho e cai no fim.
        float inicio = 1.0 - clamp(u.fadeOutTime, 0.0, 1.0);
        float apagando = smoothstep(inicio, 1.0, u.turnOff);
        float resta = u.fadeOutTime > 0.0
            ? 1.0 - apagando * apagando
            : (u.turnOff >= 1.0 ? 0.0 : 1.0);
        cor *= resta;
        // O clarão fica de fora do apagar — senão ele sumiria justo no fim,
        // que é onde ele acontece. Tem o próprio envelope: sobe com o ponto se
        // formando e morre no último décimo.
        if (u.flareWidth > 0.0 && u.turnOff < 1.0) {
            float2 c = (uvTela - 0.5) * float2(eng.acAspect, 1.0);
            float quando = smoothstep(0.6, 0.88, u.turnOff) * (1.0 - smoothstep(0.9, 1.0, u.turnOff));
            float w = 0.05 * u.flareWidth;
            float redondo = exp(-dot(c, c) / (w * w));
            float risco = exp(-abs(c.y) / (0.006 * u.flareWidth))
                        * exp(-abs(c.x) / (0.35 * u.flareWidth * max(escalaX, 0.05)));
            cor += float3(1.0, 0.97, 0.92) * (redondo * 0.6 + risco * 0.4) * quando * u.flareBrightness * 0.5 * alfa;
        }
    }

    // ------------------------------------------------ máscara e saída
    float quanto = 1.0;
    if (u.maskUse > 0 && int2(int(maskLayer.get_width()), int(maskLayer.get_height())).x > 1) {
        // Sem camada escolhida o motor entrega uma textura 1×1 (empty="transparent"):
        // aí a máscara não existe, e o efeito vale na camada inteira.
        float r = u.blurMask * 0.02;
        float4 m = maskLayer.sample(__nv_smp, uvTela) * 0.4
               + (maskLayer.sample(__nv_smp, uvTela + float2(r, 0.0)) + maskLayer.sample(__nv_smp, uvTela - float2(r, 0.0))
                + maskLayer.sample(__nv_smp, uvTela + float2(0.0, r)) + maskLayer.sample(__nv_smp, uvTela - float2(0.0, r))) * 0.15;
        float v = u.maskUse == 1 ? luma(m.rgb) * m.a : m.a;
        quanto = u.invertMask ? 1.0 - v : v;
    }
    float4 efeito = float4(clamp(cor, 0.0, max(alfa, 0.0001)), clamp(alfa, 0.0, 1.0));
    float4 original = float4(naTela.rgb * naTela.a, naTela.a);
    float4 saida = mix(original, efeito, clamp(quanto, 0.0, 1.0));
    return float4(saida.a > 0.0001 ? saida.rgb / saida.a : float3(0.0), saida.a);
}

fragment float4 fx_tv_damage(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tv_damageParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> claroA [[texture(1)]],
    texture2d<float> claroB [[texture(2)]],
    texture2d<float> claroC [[texture(3)]],
    texture2d<float> maskLayer [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = claroParaOrthicon(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = desfocar(claroA, in.acScreenNorm); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = desfocar(claroB, in.acScreenNorm); return __nv_out; }
    __nv_out = aTv();
    return __nv_out;
}
