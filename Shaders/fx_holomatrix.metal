// ---------------------------------------------------------------------------
// Holomatrix
// origem : assets/effects/holomatrix.xml
// id     : nova.effect.holomatrix
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct holomatrixParams {
    int moreDamage;
    int moreOften;
    int punchIt;
    float effectScale;
    int unmult;
    float frameRate;
    float randomSeed;
    float blendOriginal;
    int colorization;
    float sourceBrightness;
    float sourceContrast;
    float4 colorHighlights;
    float4 colorMidtones;
    float4 colorShadows;
    float colorizePct;
    int glow;
    int secondaryGlow;
    float glowThreshold;
    float glowRadius;
    float glowIntensity;
    float secondaryGlowRadius;
    int scanLines;
    float scanDistance;
    float scanThickness;
    float scanFeather;
    int scanDirection;
    int lines;
    int lineDirection;
    float luSpeed;
    float luHeight;
    float ldSpeed;
    float ldHeight;
    float luSeed;
    float luOpacityMin;
    float luOpacityMax;
    float luStrobe;
    int luFade;
    float ldSeed;
    float ldOpacityMin;
    float ldOpacityMax;
    float ldStrobe;
    int ldFade;
    int staticOn;
    float staticSize;
    float staticOpacity;
    int colorNoise;
    float noiseOpacity;
    float noiseScale;
    int ghost;
    int ghostDistortion;
    float ghostChance;
    float ghostOpacity;
    float ghostXChance;
    float ghostXMin;
    float ghostXMax;
    float ghostYChance;
    float ghostYMin;
    float ghostYMax;
    float ghostDistChance;
    float ghostDistMin;
    float ghostDistMax;
    int colorSeparation;
    float sepChance;
    float sepAmount;
    float sepDuration;
    float sepVariation;
    int lowRes;
    float lowResPct;
    int randomLowRes;
    float rlrMin;
    float rlrMax;
    float rlrChance;
    float rlrDuration;
    float rlrVariation;
    int tvRoll;
    int tvDistortion;
    float rollSpeed;
    float rollChance;
    float rollDuration;
    float rollVariation;
    float tvdChance;
    float tvdAmount;
    float tvdScale;
    int flicker;
    float flickerMin;
    float flickerMax;
    float flickerChance;
    float flickerDuration;
    float flickerVariation;
    int glitch;
    int glitchHoles;
    float glitchChance;
    float glitchAmount;
    float glitchSize;
    float glitchAspect;
    float glitchComplexity;
    float glitchDispH;
    float glitchDispV;
    float glitchSpeed;
    float glitchDuration;
    float glitchVariation;
    float holesChance;
    float holesAmount;
    float holesSize;
    float holesAspect;
    int traveling;
    float tdChance;
    float tdDuration;
    float tdVariation;
    float tdLineSpeed;
    float tdLineHeight;
    float tdSpeed;
    float tdStrengthX;
    float tdStrengthY;
    float tdScale;
    float tdFalloff;
    int blockDistortion;
    float bdChance;
    float bdDuration;
    float bdVariation;
    float bdBlockSpeed;
    float bdAmount;
    float bdSize;
    float bdAspect;
    float bdSpeed;
    float bdStrengthX;
    float bdStrengthY;
    float bdScale;
    int screenDistortion;
    float sdChance;
    float sdDuration;
    float sdVariation;
    float sdSpeed;
    float sdStrengthX;
    float sdStrengthY;
    float sdScale;
};

// --- funcoes auxiliares do efeito
// ------------------------------------------------------------------ sorteio
float h2(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/** Ruído de valor entre −1 e 1 (bilinear suavizado). */
float ruido(float2 p, float semente) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = h2(i + semente), b = h2(i + float2(1.0, 0.0) + semente);
    float c = h2(i + float2(0.0, 1.0) + semente), d = h2(i + float2(1.0, 1.0) + semente);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y) * 2.0 - 1.0;
}

// ------------------------------------------------------------------ medidas
/** O tamanho do quadro CHEIO (os passes de u.glow rodam em meia resolução). */
float2 quadro() { return float2(int2(int(inputImg.get_width()), int(inputImg.get_height()))); }
/** Pixels do buffer por unidade do plugin: as medidas dele são em pixels de um quadro de 486 linhas. */
float unidade() { return u.effectScale / 100.0 * quadro().y / 486.0; }
/** O tempo do efeito: ele só anda `Frame Rate` vezes por segundo. */
float tempoDoEfeito() { return floor(eng.acTime * u.frameRate + 1e-3) / u.frameRate; }
float quadroDoEfeito() { return floor(eng.acTime * u.frameRate + 1e-3); }
float dano() { return 1.0 + float(u.moreDamage); }

/*
 * OS EVENTOS — medido em 1800 quadros: o tempo é uma fila de trechos de `dur` segundos (cada um
 * esticado ou encolhido em até ±variação), e cada trecho sorteia se o defeito acontece nele
 * (trechos seguidos emendam). Aqui: grade de `dur` com as divisas tremidas — a mesma estatística,
 * sem memória entre quadros. `inicio` = quando o trecho começou; `k` = o número dele.
 */
bool evento(float dur, float variacao, float chance, float semente, out float inicio, out float k) {
    inicio = 0.0; k = 0.0;
    float s = semente + u.randomSeed * 0.731;
    if (u.punchIt) return true;
    float t = eng.acTime;
    dur = max(dur, 0.01);
    float v = clamp(variacao / 100.0, 0.0, 1.0);
    float k0 = floor(t / dur);
    float c = chance / 100.0 * (1.0 + 0.25 * float(u.moreOften));
    for (int i = -1; i <= 1; i++) {
        float kk = k0 + float(i);
        float b0 = (kk + v * (h2(float2(kk, s)) - 0.5)) * dur;
        float b1 = (kk + 1.0 + v * (h2(float2(kk + 1.0, s)) - 0.5)) * dur;
        if (t >= b0 && t < b1) { inicio = b0; k = kk; return h2(float2(kk, s + 7.7)) < c; }
    }
    return false;
}

float4 pre(float4 c) { return float4(c.rgb * c.a, c.a); }

// ------------------------------------------------------------------ passe 0: geometria + cor + linhas + estática
float3 overlay(float3 a, float b) { return mix(2.0 * a * b, 1.0 - 2.0 * (1.0 - a) * (1.0 - b), step(0.5, a)); }
float3 overlay3(float3 a, float3 b) { return mix(2.0 * a * b, 1.0 - 2.0 * (1.0 - a) * (1.0 - b), step(0.5, a)); }

/** Tritone linear pela luma Rec. 709 (medido: 0,2127 / 0,7152 / 0,0720). */
float3 colorir(float3 c) {
    float l = dot(c, float3(0.2126, 0.7152, 0.0722));
    l = l + u.sourceBrightness / 255.0;
    l = clamp(1.0 - (1.0 - l) * (1.0 + u.sourceContrast / 100.0), 0.0, 1.0);   // o contraste gira em volta do BRANCO
    float3 t = l < 0.5 ? mix(u.colorShadows.rgb, u.colorMidtones.rgb, l * 2.0) : mix(u.colorMidtones.rgb, u.colorHighlights.rgb, l * 2.0 - 1.0);
    return mix(c, t, u.colorizePct / 100.0);
}

/** Uma camada de faixas: o cinza sorteado da faixa e a opacidade (pisca a cada X quadros). */
float3 faixas(float3 c, float y, float sentido, float vel, float altura, float semente, float opMin, float opMax, float strobe, bool fade) {
    float h = max(altura * u.effectScale / 100.0 * quadro().y / 715.5, 1.0);
    // A velocidade é em pixels da COMPOSIÇÃO por segundo, em qualquer resolução (medido em 90p, 360p e 720p).
    float andou = vel * eng.acEscalaDePixel * tempoDoEfeito() * sentido;
    float i = floor((y + andou) / h);
    float b = h2(float2(i + semente, 17.0 + sentido * 3.0));
    float q = floor(tempoDoEfeito() / (eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0) + 0.5);
    float fase = q / max(strobe, 1.0);
    float m = fade ? abs(__nv_mod(fase, 2.0) - 1.0) : 1.0 - __nv_mod(floor(fase), 2.0);    // 1 = opacidade máxima
    float op = mix(opMin, opMax, m) / 100.0;
    return mix(c, overlay(c, b), op);
}

/** A estática: um grão cinza por célula (N = 0,854·u^2,7), em overlay. */
float graoDaEstatica(float2 px) {
    float hc = quadro().y / eng.acEscalaDePixel;                               // altura em pixels da composição
    float a = min((0.13 + 0.008 * u.staticSize) * pow(hc / 1080.0, 0.8) * u.effectScale / 100.0, 0.95);
    float cel = max(hc / 244.0 / (1.0 - a) * eng.acEscalaDePixel, 1.0);
    float2 p = px / float2(cel, cel / 1.18);
    float2 i = floor(p), f = clamp((fract(p) - 0.3) / 0.4, 0.0, 1.0);
    float s = quadroDoEfeito() * 1.37 + u.randomSeed;
    float u = mix(mix(h2(i + s), h2(i + float2(1.0, 0.0) + s), f.x), mix(h2(i + float2(0.0, 1.0) + s), h2(i + float2(1.0, 1.0) + s), f.x), f.y);
    return 0.008 + 0.854 * pow(u, 2.7);
}

/** O deslocamento "de TV" das distorções: riscos largos e baixos que tremem. */
float2 tremor(float2 px, float escala, float vel, float2 forca, float semente) {
    float u = unidade();
    float2 p = px / (max(escala, 1.0) * u * float2(1.2, 0.2));
    float t = floor(eng.acTime * max(vel, 1.0) / 23.0);
    return forca * u * 2.0 * float2(ruido(p, semente + t * 3.7), ruido(p + 31.0, semente + t * 3.7 + 9.0));
}

/** De onde o pixel lê, depois dos defeitos de geometria. `furo` = o Glitch Holes apagou. */
float2 geometria(float2 px, out bool furo) {
    furo = false;
    float2 res = quadro();
    float u = unidade();
    float ini, k;
    // Low-Res: blocos de 100/% unidades.
    float pct = 0.0;
    if (u.lowRes) pct = u.lowResPct;
    if (u.randomLowRes && evento(u.rlrDuration, u.rlrVariation, u.rlrChance, 31.0, ini, k)) pct = mix(u.rlrMin, u.rlrMax, h2(float2(k, 32.0)));
    if (pct > 0.0 && pct < 100.0) { float b = max(u * 100.0 / pct, 1.0); px = floor(px / b) * b + 0.5; }
    // TV Roll: o quadro rola 0,154 da altura por segundo por unidade de velocidade, de um ponto sorteado.
    if (u.tvRoll && evento(u.rollDuration, u.rollVariation, u.rollChance, 41.0, ini, k)) {
        float volta = fract(h2(float2(k, 42.0)) + u.rollSpeed * 0.154 * (tempoDoEfeito() - ini));
        px.y = __nv_mod(px.y + volta * res.y, res.y);
        if (u.tvDistortion && h2(float2(k, 43.0)) < u.tvdChance / 100.0) {
            float comprimento = max(res.y * 0.12 * pow(u.tvdScale / 100.0, 8.0), 1.5);
            px.x += u.tvdAmount * res.x * 0.17 * ruido(float2(px.y / comprimento, quadroDoEfeito() * 0.37), 44.0);
        }
    }
    // Glitch: blocos deslocados (até 1/4 do quadro por unidade de Displacement).
    if (u.glitch && evento(u.glitchDuration, u.glitchVariation, u.glitchChance, 51.0, ini, k)) {
        float g = floor(eng.acTime * u.glitchSpeed);
        float hb = max(res.y * pow(10.0, (u.glitchSize - 215.0) / 40.0), 2.0);
        for (int n = 0; n < 5; n++) {
            if (float(n) >= u.glitchComplexity) break;
            float2 cel = float2(hb * u.glitchAspect, hb) / exp2(float(n));
            float2 id = floor(px / cel) + float2(g * 13.0 + float(n) * 71.0, u.randomSeed);
            if (h2(id) < u.glitchAmount / 100.0 / u.glitchComplexity * 1.6) {
                px += (float2(h2(id + 3.3), h2(id + 8.8)) * 2.0 - 1.0) * float2(u.glitchDispH, u.glitchDispV) * res * 0.25 * dano();
                break;
            }
        }
        if (u.glitchHoles && h2(float2(k, 55.0)) < u.holesChance / 100.0) {
            float hh = max(res.y * pow(10.0, (u.holesSize - 215.0) / 40.0), 2.0);
            float2 id = floor(px / (0.5 * float2(hh * u.holesAspect, hh))) + float2(g * 7.0, u.randomSeed + 5.0);
            furo = h2(id) < 0.25 * u.holesAmount / 100.0;
        }
    }
    // As três distorções: a tela toda, uma faixa que viaja e blocos.
    if (u.screenDistortion && evento(u.sdDuration, u.sdVariation, u.sdChance, 61.0, ini, k))
        px += tremor(px, u.sdScale, u.sdSpeed, float2(u.sdStrengthX, u.sdStrengthY) * dano(), 62.0);
    if (u.traveling && evento(u.tdDuration, u.tdVariation, u.tdChance, 71.0, ini, k)) {
        float meia = u.tdLineHeight / 100.0 * res.y;
        float yc = __nv_mod(u.tdLineSpeed * res.y / 336.0 * (eng.acTime - ini), res.y + 2.0 * meia) - meia;
        float w = clamp(1.0 - abs(px.y - yc) / meia, 0.0, 1.0);
        w = u.tdFalloff > 0.0 ? pow(w, u.tdFalloff * 0.5) : step(0.001, w);
        px += w * tremor(px, u.tdScale / 15.0, u.tdSpeed, float2(u.tdStrengthX, u.tdStrengthY) * dano(), 72.0);
    }
    if (u.blockDistortion && evento(u.bdDuration, u.bdVariation, u.bdChance, 81.0, ini, k)) {
        float hb = max(u.bdSize * u * 0.31, 2.0);
        float2 p = px / float2(hb * u.bdAspect, hb);
        float2 id = floor(p) + float2(floor(eng.acTime * u.bdBlockSpeed) * 5.0, u.randomSeed + 9.0);
        if (h2(id) < u.bdAmount / 100.0) {
            float2 d = abs(fract(p) - 0.5) * 2.0;
            px += (1.0 - d.y * d.y) * tremor(px, u.bdScale, u.bdSpeed, float2(u.bdStrengthX, u.bdStrengthY) * dano(), 82.0);
        }
    }
    return px;
}

float4 passeBase(float2 uv) {
    float2 res = quadro();
    bool furo;
    float2 px = geometria(uv * res, furo);
    float2 q = px / res;
    if (furo) return float4(0.0);
    float4 s = inputImg.sample(__nv_smp, fract(q));                           // o que sai de um lado entra pelo outro
    float3 c = s.rgb;
    if (u.colorization) c = colorir(c);
    if (u.lines) {
        float y = uv.y * res.y;
        if (u.lineDirection != 1) c = faixas(c, y, 1.0, u.luSpeed, u.luHeight, u.luSeed, u.luOpacityMin, u.luOpacityMax, u.luStrobe, u.luFade);
        if (u.lineDirection != 0) c = faixas(c, y, -1.0, u.ldSpeed, u.ldHeight, u.ldSeed, u.ldOpacityMin, u.ldOpacityMax, u.ldStrobe, u.ldFade);
    }
    if (u.staticOn) c = mix(c, overlay(c, graoDaEstatica(uv * res)), u.staticOpacity / 100.0);
    if (u.colorNoise) {
        // Manchas de cor suaves (~5 px em 360 linhas com Scale 100; desvio 0,02 com opacidade 100), um sorteio por canal, em overlay.
        float2 p = uv * res / (5.5 * res.y / 360.0 * u.noiseScale / 100.0);
        float sm = quadroDoEfeito() * 2.3 + u.randomSeed;
        float3 n = float3(ruido(p, sm), ruido(p + 19.0, sm + 5.0), ruido(p + 47.0, sm + 11.0));
        c = overlay3(c, 0.5 + 0.05 * u.noiseOpacity / 100.0 * n);
    }
    return pre(float4(clamp(c, 0.0, 1.0), s.a));
}

// ------------------------------------------------------------------ passe 1: fantasma + separação + scan u.lines
float4 lerBase(float2 px) {
    float2 q = px / quadro();
    if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) return float4(0.0);
    return base.sample(__nv_smp, q);
}

/** O fantasma num ponto: uma cópia da base deslocada (às vezes com a lente torta), já na opacidade dele. */
float4 fantasma(float2 px) {
    if (!u.ghost) return float4(0.0);
    float q = quadroDoEfeito();
    float s = u.randomSeed * 0.917;
    // Um sorteio por quadro do efeito, sem duração (medido: trechos de 1 quadro).
    if (!u.punchIt && h2(float2(q, 91.0 + s)) >= u.ghostChance / 100.0 * (1.0 + float(u.moreOften))) return float4(0.0);
    float u = unidade() * dano();
    float2 des = float2(0.0);
    // O deslocamento sorteado é triangular em volta do meio da faixa (medido: metade da meia-faixa).
    if (h2(float2(q, 92.0 + s)) < u.ghostXChance / 100.0)
        des.x = 0.5 * (u.ghostXMin + u.ghostXMax) + 0.25 * (u.ghostXMax - u.ghostXMin) * (h2(float2(q, 93.0 + s)) + h2(float2(q, 94.0 + s)) - 1.0);
    if (h2(float2(q, 95.0 + s)) < u.ghostYChance / 100.0)
        des.y = 0.5 * (u.ghostYMin + u.ghostYMax) + 0.25 * (u.ghostYMax - u.ghostYMin) * (h2(float2(q, 96.0 + s)) + h2(float2(q, 97.0 + s)) - 1.0);
    float2 p = px - des * u;
    if (u.ghostDistortion && h2(float2(q, 98.0 + s)) < u.ghostDistChance / 100.0) {
        // Lente: desvio −0,0047·valor·r·(1 − r²/R²), R = meia diagonal (medido com ±30).
        float2 res = quadro();
        float2 centro = res * (0.5 + 0.15 * (float2(h2(float2(q, 99.0 + s)), h2(float2(q, 100.0 + s))) - 0.5));
        float2 d = p - centro;
        float r2 = dot(d, d) / (0.25 * dot(res, res));
        p += -0.0047 * mix(u.ghostDistMin, u.ghostDistMax, h2(float2(q, 101.0 + s))) * d * (1.0 - r2);
    }
    return u.ghostOpacity / 100.0 * lerBase(p);
}

const float PERFIL_A[21] = float[21](0.0, 0.0201, 0.0714, 0.1568, 0.2618, 0.3801, 0.5007, 0.6176, 0.7196, 0.8028, 0.8729,
                                     0.9246, 0.9585, 0.9796, 0.9918, 0.9965, 0.9989, 0.9995, 0.9997, 0.9999, 1.0);
const float PERFIL_D[21] = float[21](0.0, 0.0066, 0.0233, 0.0502, 0.0833, 0.1229, 0.1691, 0.2256, 0.2924, 0.3651, 0.4520,
                                     0.5452, 0.6326, 0.7163, 0.7967, 0.8529, 0.9061, 0.9462, 0.9758, 0.9905, 1.0);

/**
 * A scan line num eixo: x = quanto o pixel está DENTRO da linha mais próxima (0 = na borda,
 * 1 = feather inteiro para dentro). Devolve (cor, alfa): o plugin escurece a cor mais devagar do
 * que devolve o alfa — as duas curvas foram tiradas dos renders (tools/holomatrix/benchmark).
 */
float2 scanNoEixo(float coordPx) {
    float d = u.scanDistance, t = u.scanThickness;
    if (d <= 0.0) return float2(1.0);
    float yu = coordPx / unidade();
    float meio = 0.5 * min(t, d);                                 // medido: o centro fica em min(t, d)/2
    float i = floor((yu - meio) / d + 0.5);
    float e = 0.5 * t - abs(yu - (i * d + meio));
    // O feather vai da borda PARA DENTRO, e tem ~1 pixel a mais do que o valor (medido com 3, 8, 24 e 48).
    float x = clamp(e / (u.scanFeather + 1.07 * eng.acEscalaDePixel / unidade()), 0.0, 1.0) * 20.0;
    int n = int(min(floor(x), 19.0));
    float f = x - float(n);
    return float2(mix(PERFIL_D[n], PERFIL_D[n + 1], f), mix(PERFIL_A[n], PERFIL_A[n + 1], f));
}

/** Quanto do quadro as scan u.lines deixam passar no alfa (a média de um período). */
float coberturaDaScan() {
    float soma = 0.0;
    float periodo = max(u.scanDistance, 1e-3) * unidade();
    for (int n = 0; n < 16; n++) soma += scanNoEixo((float(n) + 0.5) / 16.0 * periodo).y;
    return soma / 16.0;
}

/**
 * A base com o u.glow secundário, o fantasma e as scan u.lines num ponto. Medido: o fantasma é SOMADO
 * sem o u.glow secundário, e as scan u.lines valem para os dois; a separação de cor vem depois.
 */
float4 comScan(float2 px) {
    float4 c = lerBase(px);
    float4 f = fantasma(px);
    if (!u.scanLines) {
        // Glow secundário sem scan u.lines (medido): c·(1 + 2·borrão(c)), canal por canal.
        if (u.secondaryGlow) c.rgb = min(c.rgb * (1.0 + 2.0 * sv.sample(__nv_smp, clamp(px / quadro(), 0.0, 1.0)).rgb), c.a);
        return min(c + f, 1.0);
    }
    float2 m = u.scanDirection == 0 ? scanNoEixo(px.y) : u.scanDirection == 1 ? scanNoEixo(px.x) : min(scanNoEixo(px.y), scanNoEixo(px.x));
    if (u.secondaryGlow) {
        // Com o u.glow secundário as linhas não chegam ao preto: sobra ~30% da imagem no vão e a
        // linha fica 1,3–1,6× mais clara. Medido linha a linha em dois desenhos: o padrão (cobre
        // 75% do quadro: 1,6·m + 0,31) e linhas separadas (37%: 1,3·m + 0,3 + 0,76·m·cor).
        float t = clamp((coberturaDaScan() - 0.37) / 0.38, 0.0, 1.0);
        c = float4(c.rgb * ((1.3 + 0.3 * t) * m.x + 0.3 + 0.76 * (1.0 - t) * m.x * c.rgb), c.a * (0.68 * m.y + 0.28));
    } else {
        c = float4(c.rgb * m.x, c.a * m.y);
    }
    // O fantasma soma na cor; no alfa ele só completa o que faltava (a camada opaca continua opaca).
    float semLinhas = max(lerBase(px).a, 1e-4);
    // (A cor pode passar do alfa aqui: o limiar do u.glow olha para ela antes do corte da saída.)
    return float4(min(c.rgb + f.rgb * m.x, 1.0), c.a * min(semLinhas + f.a, 1.0) / semLinhas);
}

float4 passeMistura(float2 uv) {
    float2 res = quadro();
    float2 px = uv * res;
    float4 c;
    float ini, k;
    if (u.colorSeparation && evento(u.sepDuration, u.sepVariation, u.sepChance, 21.0, ini, k)) {
        // Vermelho lê à direita, azul à esquerda; o alfa é a UNIÃO dos três (1 − Π(1 − a), medido).
        float2 d = float2(u.sepAmount * unidade() * dano(), 0.0);
        float4 r = comScan(px + d), g = comScan(px), b = comScan(px - d);
        c = float4(r.r, g.g, b.b, 1.0 - (1.0 - r.a) * (1.0 - g.a) * (1.0 - b.a));
    } else {
        c = comScan(px);
    }
    return c;
}

// ------------------------------------------------------------------ u.glow
/** σ do u.glow em pixels do quadro cheio (medido em 360 linhas: 1,1 + 0,28·raio, nunca menos de 2,06). */
float sigmaDoGlow() { return quadro().y / 360.0 * max(2.06, 1.1 + 0.28 * u.glowRadius * u.effectScale / 100.0); }
float sigmaDoSegundo() { return quadro().y / 360.0 * max(0.8, 0.41 * u.secondaryGlowRadius * u.effectScale / 100.0); }
/** Com raio pequeno o u.glow é quase a própria imagem: só 0,236·raio dela vai para o borrão (medido com 1, 2 e 5). */
float parteBorrada() { return min(0.236 * u.glowRadius * u.effectScale / 100.0, 1.0); }

/** Só o que passa do limiar, canal por canal. O alfa vai inteiro: o borrão dele enche o vão das scan u.lines. */
float4 limiar(float4 c) { return float4(c.rgb * step(u.glowThreshold / 100.0, c.rgb - 1e-4), c.a); }

/** Gaussiano de um eixo neste buffer (meia resolução). `fonte`: 0 = base, 1 = sh, 2 = lim, 3 = gh. */
float4 borrar(int fonte, float2 eixo, float sigmaCheio) {
    float2 uv = in.acScreenNorm;
    float sigma = max(sigmaCheio * eng.acResolution.y / quadro().y, 0.5);
    float passo = max(1.0, ceil(3.0 * sigma / 20.0));
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int n = -20; n <= 20; n++) {
        float d = float(n) * passo;
        if (abs(d) > 3.0 * sigma + 0.5) continue;
        float w = exp(-0.5 * d * d / (sigma * sigma));
        float2 q = uv + eixo * d * eng.acTexelSize;
        float4 v = float4(0.0);
        if (q.x >= 0.0 && q.x <= 1.0 && q.y >= 0.0 && q.y <= 1.0) {
            if (fonte == 0) v = base.sample(__nv_smp, q);
            else if (fonte == 1) v = sh.sample(__nv_smp, q);
            else if (fonte == 2) v = lim.sample(__nv_smp, q);
            else v = gh.sample(__nv_smp, q);
        }
        soma += w * v;
        pesos += w;
    }
    return soma / max(pesos, 1e-6);
}

fragment float4 fx_holomatrix(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant holomatrixParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> base [[texture(1)]],
    texture2d<float> mixado [[texture(2)]],
    texture2d<float> lim [[texture(3)]],
    texture2d<float> gh [[texture(4)]],
    texture2d<float> gv [[texture(5)]],
    texture2d<float> sh [[texture(6)]],
    texture2d<float> sv [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = passeBase(uv); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = u.secondaryGlow ? borrar(0, float2(1.0, 0.0), sigmaDoSegundo()) : float4(0.0); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = u.secondaryGlow ? borrar(1, float2(0.0, 1.0), sigmaDoSegundo()) : float4(0.0); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = passeMistura(uv); return __nv_out; }
    if (eng.acPass == 4) {
        // O limiar é tirado pixel a pixel do quadro CHEIO (as scan u.lines têm 1–2 px: a média de
        // dois vizinhos ficaria abaixo dele e o u.glow sumiria) e só então cai para meia resolução.
        float4 soma = float4(0.0);
        if (u.glow) {
            float2 d = 0.25 * eng.acTexelSize;
            soma = 0.25 * (limiar(mixado.sample(__nv_smp, uv + float2(-d.x, -d.y))) + limiar(mixado.sample(__nv_smp, uv + float2(d.x, -d.y)))
                         + limiar(mixado.sample(__nv_smp, uv + float2(-d.x, d.y))) + limiar(mixado.sample(__nv_smp, uv + d)));
        }
        __nv_out = soma;
        return __nv_out;
    }
    if (eng.acPass == 5) { __nv_out = u.glow ? borrar(2, float2(1.0, 0.0), sigmaDoGlow()) : float4(0.0); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = u.glow ? borrar(3, float2(0.0, 1.0), sigmaDoGlow()) : float4(0.0); return __nv_out; }

    float4 c = mixado.sample(__nv_smp, uv);
    if (u.glow) {
        // A cor ganha Intensity × o que passa do limiar, borrado. O alfa NÃO depende do limiar nem
        // da Intensity (medido com 1, 3 e 6): é a união dele com o próprio borrão.
        float4 borrao = gv.sample(__nv_smp, uv);
        c.rgb = min(c.rgb + u.glowIntensity * mix(limiar(c).rgb, borrao.rgb, parteBorrada()), 1.0);
        c.a = 1.0 - (1.0 - c.a) * (1.0 - parteBorrada() * borrao.a);
    }
    c.rgb = min(c.rgb, c.a);
    float ini, k;
    if (u.flicker && evento(u.flickerDuration, u.flickerVariation, u.flickerChance, 11.0, ini, k)) {
        float g = mix(u.flickerMin, u.flickerMax, h2(float2(quadroDoEfeito(), 12.0 + u.randomSeed))) / 100.0;
        c = float4(c.rgb * g * g, c.a * g);                           // medido: a cor reta E o alfa caem juntos
    }
    float4 original = pre(inputImg.sample(__nv_smp, uv));
    c = mix(c, original, u.blendOriginal / 100.0);
    if (u.unmult) c.a = max(c.r, max(c.g, c.b));
    __nv_out = c.a > 1e-5 ? float4(min(c.rgb / c.a, 1.0), c.a) : float4(0.0);
    return __nv_out;
}
