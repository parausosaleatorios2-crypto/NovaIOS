// ---------------------------------------------------------------------------
// Datamosh Pro (movimento)
// origem : assets/effects/datamosh-pro.xml
// id     : nova.effect.datamoshpro
// passes : 10
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct datamosh_proParams {
    float intensity;
    float motionStrength;
    float persistence;
    float blocks;
    float residual;
    float colorAmt;
    int referenceMode;
    int direction;
    int mapSource;
    float motionAverage;
    float deadZone;
    float directionAngle;
    float stretchX;
    float stretchY;
    float pixelSnap;
    float blockSize;
    float blockSoftness;
    int warpMode;
    float warpSteps;
    int edgeMode;
    float refreshEvery;
    float refreshMotion;
    float holdTime;
    float releaseTime;
    float cooldown;
    float cutSensitivity;
    float maxAge;
    float ageCurve;
    float feedbackBlur;
    float feedbackSharpen;
    int blockEdge;
    float blockCarry;
    float blockJump;
    float residualThreshold;
    float residualQuant;
    float dctNoise;
    float dctFrequency;
    float chromaLag;
    float chromaBlock;
    int lumaMode;
    int bitDepth;
    float driftX;
    float driftY;
    float zoomMotion;
    float rotateMotion;
    float shake;
    int waveMode;
    float waveAmount;
    float waveFrequency;
    float waveSpeed;
    float randomVector;
    float taper;
    float mapAmount;
    float mapFeather;
    int mapInvert;
    int sweepOn;
    float sweepProgress;
    float sweepSpeed;
    float sweepAngle;
    float sweepSoftness;
    int pixelsFrom;
    float audioAmount;
    float beatThreshold;
    float audioSensitivity;
    int quality;
    int view;
    float seed;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;
const float PI = 3.14159265359;
/** O vetor mais longo depois dos operadores (compressão suave, item 11). */
const float VETOR_MAXIMO = 160.0;

// ============================================================================
//  ACASO DETERMINÍSTICO (itens 54, 103, 294): semente + quadro + bloco
// ============================================================================

static float semente() {
    return u.seed * 17.13 + 3.7;
}

static float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

static float hash21(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

static float hash31(float3 p) {
    float3 p3 = fract(p * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

static float2 hash32(float3 p) {
    float3 p3 = fract(p * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

// ============================================================================
//  TEMPO, TAMANHO, COR
// ============================================================================

static float duracaoDoQuadro() {
    return eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0;
}

static float indiceDoQuadro() {
    return floor(eng.acTime / duracaoDoQuadro() + 0.5);
}

/** O tamanho da camada em pixels — qualquer passe, qualquer buffer. */
static float2 camadaPx() {
    return float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
}

static float luma(float3 c) {
    return dot(c, float3(0.299, 0.587, 0.114));
}

static float3 paraYcc(float3 c) {
    return float3(
        dot(c, float3(0.299, 0.587, 0.114)),
        dot(c, float3(-0.168736, -0.331264, 0.5)),
        dot(c, float3(0.5, -0.418688, -0.081312)));
}

static float3 deYcc(float3 y) {
    return float3(
        y.x + 1.402 * y.z,
        y.x - 0.344136 * y.y - 0.714136 * y.z,
        y.x + 1.772 * y.y);
}

static float4 preMultiplicar(float4 c) {
    return float4(c.rgb * c.a, c.a);
}

// ============================================================================
//  CODIFICAÇÃO DOS VETORES NOS BUFFERS DE 8 BITS
// ============================================================================

/** 8 bits: nível 128 = zero, meio pixel por nível (±64 px). Linear: aguenta interpolação. */
static float2 codificarMv(float2 v) {
    return clamp(floor(v * 2.0 + 0.5) + 128.0, 0.0, 255.0) / 255.0;
}

static float2 decodificarMv(float2 e) {
    return (e * 255.0 - 128.0) * 0.5;
}

/** 16 bits num par de canais: 1/256 px por nível, ±128 px. */
static float2 codificar16Um(float v) {
    float n = clamp(floor(v * 256.0 + 0.5) + 32768.0, 0.0, 65535.0);
    float alto = floor(n / 256.0);
    return float2(alto, n - alto * 256.0) / 255.0;
}

static float decodificar16Um(float2 e) {
    float2 b = floor(e * 255.0 + 0.5);
    return (b.x * 256.0 + b.y - 32768.0) / 256.0;
}

static float4 codificar16(float2 v) {
    return float4(codificar16Um(v.x), codificar16Um(v.y));
}

static float2 decodificar16(float4 e) {
    return float2(decodificar16Um(e.rg), decodificar16Um(e.ba));
}

/** Contador inteiro (0..65535) num par de canais. */
static float2 codificarContador(float n) {
    float c = clamp(floor(n + 0.5), 0.0, 65535.0);
    float alto = floor(c / 256.0);
    return float2(alto, c - alto * 256.0) / 255.0;
}

static float decodificarContador(float2 e) {
    float2 b = floor(e * 255.0 + 0.5);
    return b.x * 256.0 + b.y;
}

// ============================================================================
//  A IMAGEM ATUAL (com o Swap Motion) E A REFERÊNCIA
// ============================================================================

/** Os pixels que o movimento arrasta: esta camada, ou a escolhida no Swap. */
static float4 atualEm(float2 uv) {
    if (u.pixelsFrom == 1 && int2(int(pixelsLayer.get_width()), int(pixelsLayer.get_height())).x > 1) {
        return preMultiplicar(pixelsLayer.sample(__nv_smp, uv));
    }
    return preMultiplicar(inputImg.sample(__nv_smp, uv));
}

/** A referência (quadro anterior, já moshado), com o modo de borda (item 109). */
static float4 lerRef(float2 q) {
    if (u.edgeMode == 1) {
        q = 1.0 - abs(1.0 - __nv_mod(q, 2.0));
    } else if (u.edgeMode == 2) {
        q = fract(q);
    } else if (u.edgeMode == 3) {
        if (q.x < 0.0 || q.y < 0.0 || q.x > 1.0 || q.y > 1.0) return float4(0.0);
    }
    return referencia.sample(__nv_smp, q);
}

/** Com o desfoque e o realce da realimentação (itens 93 e 94). */
static float4 lerRefFiltrada(float2 q) {
    float4 c = lerRef(q);
    if (u.feedbackBlur <= 0.0 && u.feedbackSharpen <= 0.0) return c;
    float2 t = 1.25 / camadaPx();
    float4 media = (lerRef(q + float2(t.x, 0.0)) + lerRef(q - float2(t.x, 0.0))
                + lerRef(q + float2(0.0, t.y)) + lerRef(q - float2(0.0, t.y))) * 0.25;
    c = mix(c, media, clamp(u.feedbackBlur, 0.0, 1.0));
    c += (c - media) * u.feedbackSharpen * 1.5;
    c.a = clamp(c.a, 0.0, 1.0);
    c.rgb = clamp(c.rgb, 0.0, c.a);
    return c;
}

// ============================================================================
//  SOM
// ============================================================================

static float nivelGrave() {
    float s = somImg.sample(__nv_smp, float2(0.04, 0.5)).r
            + somImg.sample(__nv_smp, float2(0.10, 0.5)).r
            + somImg.sample(__nv_smp, float2(0.17, 0.5)).r;
    return clamp(s / 3.0 * u.audioSensitivity, 0.0, 1.0);
}

/** A intensidade do quadro, com o empurrão do som. */
static float intensidadeAgora() {
    return clamp(u.intensity + u.audioAmount * nivelGrave(), 0.0, 1.0);
}

/** O quanto do movimento a intensidade libera (ver o passe 8). */
static float fatorDeMovimento() {
    return smoothstep(0.0, 0.2, intensidadeAgora());
}

// ============================================================================
//  O CAMPO DE MOVIMENTO BRUTO (depois da média) E OS OPERADORES (itens 42-57)
// ============================================================================

/** A média móvel, com interpolação feita à mão (16 bits não se interpolam no hardware). */
static float2 lerMedio(float2 uv) {
    float2 tam = float2(int2(int(movMedio.get_width()), int(movMedio.get_height())));
    float2 p = uv * tam - 0.5;
    int2 i = int2(floor(p));
    float2 f = fract(p);
    int2 limite = int2(tam) - 1;
    float2 a = decodificar16(movMedio.read(uint2(clamp(i, int2(0), limite)), uint(0)));
    float2 b = decodificar16(movMedio.read(uint2(clamp(i + int2(1, 0), int2(0), limite)), uint(0)));
    float2 c = decodificar16(movMedio.read(uint2(clamp(i + int2(0, 1), int2(0), limite)), uint(0)));
    float2 d = decodificar16(movMedio.read(uint2(clamp(i + int2(1, 1), int2(0), limite)), uint(0)));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/**
 * Este quadro é um corte? O relógio (passe 4) guarda a resposta no texel
 * (1,0), canal B, para todos os passes seguintes.
 */
static bool corteAgora() {
    return tempo.read(uint2(int2(1, 0)), uint(0)).b > 0.5;
}

/**
 * O vetor medido (ou a média dele), em pixels da camada.
 *
 * No quadro do corte, o que a busca "mediu" compara o fim de um plano com o
 * começo de outro — não é movimento, é lixo, e realimentado ele embaralha a
 * imagem inteira no primeiro quadro. Num codec, o quadro do corte é o I-frame
 * que o datamosh remove: ele não tem vetor nenhum. Então aqui também não: o
 * vetor é zero (ou a média continua a de antes), e o movimento do plano novo
 * começa a arrastar a imagem velha no quadro seguinte.
 */
static float2 campoBruto(float2 uv) {
    if (u.motionAverage >= 0.5) return lerMedio(uv);
    if (corteAgora()) return float2(0.0);
    return decodificarMv(campo.sample(__nv_smp, uv).rg);
}

/** O centro do macrobloco; "Organic" tremula a borda (item 97). */
static float2 centroDoBloco(float2 p, float lado) {
    float2 q = p;
    if (u.blockEdge == 2) {
        float2 celula = floor(p / 4.0);
        q += (float2(hash21(celula + semente()), hash21(celula + semente() + 7.0)) - 0.5) * lado * 0.3;
    }
    return (floor(q / lado) + 0.5) * lado;
}

/**
 * O vetor que o decodificador usa neste ponto: o bruto, no macrobloco, com
 * todos os operadores, em pixels da camada. `fator` é o Mosh Map.
 */
static float2 movimentoFinal(float2 uv, float fator) {
    float2 camada = camadaPx();
    float2 p = uv * camada;
    float lado = max(u.blockSize, 1.0);
    float2 pb = centroDoBloco(p, lado);
    float suave = clamp(u.blockSoftness, 0.0, 1.0);
    float2 m = mix(campoBruto(pb / camada), campoBruto(uv), suave);

    // Zona morta: tremor de medição não é movimento (item 297).
    m *= smoothstep(u.deadZone, u.deadZone + 0.75, length(m));

    // Movimento sintético, também por bloco (item 207).
    float2 q = mix(pb, p, suave);
    float2 c = q - camada * 0.5;
    float meiaDiagonal = 0.5 * length(camada);
    m += float2(u.driftX, u.driftY);
    if (u.zoomMotion != 0.0) m += c / max(meiaDiagonal, 1.0) * u.zoomMotion;
    if (u.rotateMotion != 0.0) {
        float a = radians(-u.rotateMotion);
        float2 girado = float2(c.x * cos(a) - c.y * sin(a), c.x * sin(a) + c.y * cos(a));
        m += c - girado;
    }
    float quadro = indiceDoQuadro();
    if (u.shake > 0.0) {
        m += (hash32(float3(quadro, semente(), 1.7)) - 0.5) * 2.0 * u.shake;
    }

    // Direção (itens 47, 98).
    if (u.direction == 1) {
        m.y = 0.0;
    } else if (u.direction == 2) {
        m.x = 0.0;
    } else if (u.direction == 3) {
        float2 d = float2(cos(radians(u.directionAngle)), sin(radians(u.directionAngle)));
        m = d * dot(m, d);
    } else if (u.direction == 4) {
        float2 r = c / max(length(c), 0.001);
        m = r * dot(m, r);
    } else if (u.direction == 5) {
        m.x = -m.x;
    } else if (u.direction == 6) {
        m.y = -m.y;
    }
    m *= float2(u.stretchX, u.stretchY);

    // Onda (itens 50-52, 102).
    if (u.waveMode > 0 && u.waveAmount > 0.0) {
        float t = eng.acTime * u.waveSpeed * TAU;
        float2 w = uv * u.waveFrequency * TAU;
        float2 onda;
        if (u.waveMode == 1) {
            onda = float2(sin(w.y + t), 0.0);
        } else if (u.waveMode == 2) {
            onda = float2(0.0, sin(w.x + t));
        } else if (u.waveMode == 3) {
            onda = float2(sin(w.y + t), cos(w.x + t));
        } else {
            float2 r = c / max(length(c), 0.001);
            onda = r * sin(length(c) / camada.y * u.waveFrequency * TAU - t);
        }
        m += onda * u.waveAmount;
    }

    // Blocos aleatórios, que ficam alguns quadros (itens 55, 69).
    if (u.randomVector > 0.0) {
        float2 bloco = floor(q / lado);
        float carrega = max(u.blockCarry, 1.0);
        float epoca = floor((quadro + hash21(bloco + semente()) * carrega) / carrega);
        m += (hash32(float3(bloco, epoca + semente())) - 0.5) * 2.0 * u.randomVector;
    }

    // Afunilar: some nas bordas (positivo) ou no meio (negativo) — item 100.
    if (u.taper != 0.0) {
        float2 n = c / (camada * 0.5);
        float r2 = clamp(dot(n, n) * 0.5, 0.0, 1.0);
        m *= u.taper > 0.0 ? 1.0 - u.taper * r2 : 1.0 + u.taper * (1.0 - r2);
    }

    m *= u.motionStrength * fator;

    // Encaixe no pixel (itens 57, 111) e o teto suave (item 11).
    m = mix(m, floor(m + 0.5), clamp(u.pixelSnap, 0.0, 1.0));
    float tamanho = length(m);
    if (tamanho > 0.001) m *= VETOR_MAXIMO * tanh(tamanho / VETOR_MAXIMO) / tamanho;
    return m;
}

// ============================================================================
//  O MOSH MAP (itens 5, 29, 30, 81, 101, 127)
// ============================================================================

static float mapaEm(float2 uv, float4 atual, float magnitude) {
    float m = 1.0;
    if (u.mapSource == 1) {
        m = smoothstep(0.5, 0.5 + 6.0 * (0.2 + u.mapFeather), magnitude);
    } else if (u.mapSource == 2) {
        m = luma(atual.rgb);
    } else if (u.mapSource == 3) {
        m = atual.a - luma(atual.rgb);
    } else if (u.mapSource == 4) {
        m = atual.a;
    } else if (u.mapSource >= 5) {
        // Sem camada escolhida (empty="transparent" → 1×1), o mapa não existe.
        if (int2(int(mapLayer.get_width()), int(mapLayer.get_height())).x > 1) {
            float r = u.mapFeather * 0.02;
            float4 t = mapLayer.sample(__nv_smp, uv) * 0.4
                   + (mapLayer.sample(__nv_smp, uv + float2(r, 0.0)) + mapLayer.sample(__nv_smp, uv - float2(r, 0.0))
                    + mapLayer.sample(__nv_smp, uv + float2(0.0, r)) + mapLayer.sample(__nv_smp, uv - float2(0.0, r))) * 0.15;
            m = u.mapSource == 5 ? luma(t.rgb) * t.a : t.a;
        }
    }
    if (u.mapInvert) m = 1.0 - m;
    m = mix(1.0, clamp(m, 0.0, 1.0), clamp(u.mapAmount, 0.0, 1.0));

    if (u.sweepOn) {
        float a = radians(u.sweepAngle);
        float2 d = float2(cos(a), sin(a));
        float alcance = 0.5 * (abs(d.x) + abs(d.y));
        float coord = dot(uv - 0.5, d) / max(alcance, 0.0001) * 0.5 + 0.5;
        float avanco = u.sweepSpeed != 0.0 ? fract(u.sweepProgress + eng.acTime * u.sweepSpeed) : u.sweepProgress;
        avanco = mix(-u.sweepSoftness, 1.0 + u.sweepSoftness, avanco);
        m *= 1.0 - smoothstep(avanco - u.sweepSoftness, avanco + u.sweepSoftness + 0.0001, coord);
    }
    return clamp(m, 0.0, 1.0);
}

// ============================================================================
//  O ENVELOPE DA REFERÊNCIA (itens 32, 89-92, 285)
// ============================================================================

static float envelopeGlobal(float timer, float quadro) {
    float fd = duracaoDoQuadro();
    if (u.referenceMode == 1) {
        float periodo = max(floor(u.refreshEvery + 0.5), 1.0);
        float fase = __nv_mod(quadro, periodo);
        float soltar = u.releaseTime / fd;
        return soltar >= 1.0 ? smoothstep(0.0, soltar, fase) : step(0.5, fase);
    }
    if (u.referenceMode == 3 || u.referenceMode == 4) {
        float segurar = u.holdTime / fd;
        float soltar = max(u.releaseTime / fd, 1.0);
        if (timer <= segurar) return 1.0;
        return 1.0 - smoothstep(0.0, soltar, timer - segurar);
    }
    return 1.0;
}

// ============================================================================
//  PASSES 0 E 1 — A LUMINÂNCIA DE AGORA E DA ANTERIOR
// ============================================================================

/**
 * O que a busca compara: luminância com um piso para o alfa, para um adesivo
 * preto sobre transparente também ter o que seguir.
 */
static float traco(float4 c) {
    return (0.7 * luma(c.rgb) + 0.3) * c.a;
}

static float4 passeLumas() {
    float2 d = eng.acTexelSize * 0.25;
    float atual = 0.0;
    float antes = 0.0;
    float alfaAntes = 0.0;
    for (int i = 0; i < 4; i++) {
        float2 o = float2(i == 0 || i == 2 ? -d.x : d.x, i < 2 ? -d.y : d.y);
        atual += traco(inputImg.sample(__nv_smp, in.acScreenNorm + o));
        float4 h = anterior.sample(__nv_smp, in.acScreenNorm + o);
        antes += traco(h);
        alfaAntes += h.a;
    }
    return float4(atual * 0.25, antes * 0.25, alfaAntes * 0.25, 1.0);
}

static float4 passeLumasB() {
    float2 d = eng.acTexelSize * 0.25;
    float4 s = lumas.sample(__nv_smp, in.acScreenNorm + float2(-d.x, -d.y)) + lumas.sample(__nv_smp, in.acScreenNorm + float2(d.x, -d.y))
           + lumas.sample(__nv_smp, in.acScreenNorm + float2(-d.x, d.y)) + lumas.sample(__nv_smp, in.acScreenNorm + float2(d.x, d.y));
    return float4(s.rgb * 0.25, 1.0);
}

// ============================================================================
//  PASSES 2 E 3 — A BUSCA DE BLOCOS (itens 23, 159-163)
// ============================================================================

/**
 * Grossa: cada texel é um bloco de 32 px; a janela é 4×4 texels do lumasB
 * (64 px), procurando ±4 texels (±64 px) em todas as 81 posições. A soma das
 * diferenças absolutas (SAD) ganha um pequeno custo por distância — o que os
 * codificadores fazem para não inventar movimento em área lisa.
 *
 * Saída: RG = vetor, B = diferença média no melhor encaixe (a base do detector
 * de corte), A = textura do bloco.
 */
static float4 passeGrosso() {
    float2 zero = codificarMv(float2(0.0));
    if (eng.acStateFresh == 1) return float4(zero, 0.0, 0.0);
    float2 tx = 1.0 / float2(int2(int(lumasB.get_width()), int(lumasB.get_height())));
    float2 c0 = in.acScreenNorm;
    if (lumasB.sample(__nv_smp, c0).b < 0.5) return float4(zero, 0.0, 0.0);

    float atual[16];
    float media = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float v = lumasB.sample(__nv_smp, c0 + (float2(float(i), float(j)) - 1.5) * tx).r;
            atual[j * 4 + i] = v;
            media += v;
        }
    }
    media /= 16.0;
    float textura = 0.0;
    for (int k = 0; k < 16; k++) textura += abs(atual[k] - media);
    textura /= 16.0;

    float melhor = 1e9;
    float2 melhorD = float2(0.0);
    for (int dy = -4; dy <= 4; dy++) {
        for (int dx = -4; dx <= 4; dx++) {
            float2 d = float2(float(dx), float(dy));
            float sad = 0.0;
            for (int j = 0; j < 4; j++) {
                for (int i = 0; i < 4; i++) {
                    float2 o = float2(float(i), float(j)) - 1.5;
                    sad += abs(atual[j * 4 + i] - lumasB.sample(__nv_smp, c0 + (o - d) * tx).g);
                }
            }
            sad += 0.02 * length(d);
            if (sad < melhor) {
                melhor = sad;
                melhorD = d;
            }
        }
    }
    float2 mvPx = melhorD * camadaPx() * tx;
    float diferenca = (melhor - 0.02 * length(melhorD)) / 16.0;
    return float4(codificarMv(mvPx), clamp(diferenca, 0.0, 1.0), clamp(textura * 4.0, 0.0, 1.0));
}

/**
 * Um passo de Lucas-Kanade: o deslocamento (em texels do lumas) que, somado a
 * `d`, melhor encaixa o anterior no atual — mínimos quadrados sobre a janela,
 * com o gradiente do anterior no ponto já deslocado. Limitado a ±1 texel.
 */
static float2 passoLk(float atual[16], float2 c0, float2 tx, float2 d) {
    float gxx = 0.0;
    float gxy = 0.0;
    float gyy = 0.0;
    float2 b = float2(0.0);
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 q = c0 + (float2(float(i), float(j)) - 1.5 - d) * tx;
            float centro = lumas.sample(__nv_smp, q).g;
            float gx = (lumas.sample(__nv_smp, q + float2(0.5 * tx.x, 0.0)).g - lumas.sample(__nv_smp, q - float2(0.5 * tx.x, 0.0)).g);
            float gy = (lumas.sample(__nv_smp, q + float2(0.0, 0.5 * tx.y)).g - lumas.sample(__nv_smp, q - float2(0.0, 0.5 * tx.y)).g);
            // anterior(s − d − δ) ≈ anterior(s − d) − ∇·δ ; queremos isso = atual(s)
            float e = centro - atual[j * 4 + i];
            gxx += gx * gx;
            gxy += gx * gy;
            gyy += gy * gy;
            b += float2(gx, gy) * e;
        }
    }
    float det = gxx * gyy - gxy * gxy;
    if (det < 1e-7) return float2(0.0);
    float2 delta = float2(gyy * b.x - gxy * b.y, gxx * b.y - gxy * b.x) / det;
    return clamp(delta, -1.0, 1.0);
}

/** SAD da janela 4×4 do lumas com deslocamento `d` (em texels do lumas). */
static float sadFino(float atual[16], float2 c0, float2 tx, float2 d) {
    float sad = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 o = float2(float(i), float(j)) - 1.5;
            sad += abs(atual[j * 4 + i] - lumas.sample(__nv_smp, c0 + (o - d) * tx).g);
        }
    }
    return sad;
}

/**
 * Fina: cada texel é um bloco de 8 px; a janela é 4×4 texels do lumas (16 px),
 * procurando em volta do vetor grosso (±1 texel = ±4 px no Balanced, ±2 no
 * Quality e Ultra) e também no zero. O texel do lumas tem 4 px — um pan lento
 * de 3 px por quadro sairia 0 ou 4 —, então a fração vem de um passo de
 * Lucas-Kanade (dois no Ultra): o gradiente do quadro anterior diz para onde
 * deslizar o encaixe. A primeira versão usava uma parábola nos vizinhos, e a
 * simulação mostrou o porquê de não: ela errava 1 px em Y num pan puramente
 * horizontal, e 1 px por quadro, realimentado, vira lixo em oito quadros. No
 * Performance, fica o grosso.
 *
 * A CONFIANÇA (itens 26-27): bloco liso (sem textura) ou que não encaixa em
 * lugar nenhum (oclusão, corte) não é confiável. O vetor final mistura o fino
 * com o grosso pela confiança — o grosso vem de uma janela maior e erra menos
 * em área lisa.
 */
static float4 passeFino() {
    float2 zero = codificarMv(float2(0.0));
    if (eng.acStateFresh == 1) return float4(zero, 0.0, 1.0);
    float2 c0 = in.acScreenNorm;
    if (lumas.sample(__nv_smp, c0).b < 0.5) return float4(zero, 0.0, 1.0);

    float4 g = campoGrosso.sample(__nv_smp, c0);
    float2 mvGrosso = decodificarMv(g.rg);
    float confGrossa = smoothstep(0.01, 0.06, g.a) * (1.0 - smoothstep(0.04, 0.15, g.b));
    if (u.quality == 0) return float4(codificarMv(mvGrosso * confGrossa), confGrossa, 1.0);

    float2 tx = 1.0 / float2(int2(int(lumas.get_width()), int(lumas.get_height())));
    float2 pxPorTexel = camadaPx() * tx;
    float atual[16];
    float media = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float v = lumas.sample(__nv_smp, c0 + (float2(float(i), float(j)) - 1.5) * tx).r;
            atual[j * 4 + i] = v;
            media += v;
        }
    }
    media /= 16.0;
    float textura = 0.0;
    for (int k = 0; k < 16; k++) textura += abs(atual[k] - media);
    textura /= 16.0;

    int alcance = u.quality == 1 ? 1 : 2;
    float2 base = mvGrosso / pxPorTexel;
    float melhor = sadFino(atual, c0, tx, float2(0.0));
    float2 melhorD = float2(0.0);
    for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -2; dx <= 2; dx++) {
            if (abs(dx) > alcance || abs(dy) > alcance) continue;
            float2 d = base + float2(float(dx), float(dy));
            float sad = sadFino(atual, c0, tx, d) + 0.02 * length(d);
            if (sad < melhor) {
                melhor = sad;
                melhorD = d;
            }
        }
    }
    // A fração: Lucas-Kanade, e só fica se o encaixe melhorar.
    int iteracoes = u.quality == 3 ? 2 : 1;
    for (int it = 0; it < 2; it++) {
        if (it >= iteracoes) break;
        float2 d = melhorD + passoLk(atual, c0, tx, melhorD);
        float sad = sadFino(atual, c0, tx, d);
        if (sad < melhor) {
            melhor = sad;
            melhorD = d;
        }
    }
    float2 mvFino = melhorD * pxPorTexel;
    float diferenca = melhor / 16.0;
    float conf = smoothstep(0.006, 0.03, textura) * (1.0 - smoothstep(0.03, 0.12, diferenca));
    float2 efetivo = mix(mvGrosso * confGrossa, mvFino, conf);
    return float4(codificarMv(efetivo), conf, 1.0);
}

// ============================================================================
//  PASSES 4 E 5 — OS ESTADOS: A MÉDIA DO MOVIMENTO E O RELÓGIO
// ============================================================================

/** Média móvel exponencial: equivale à média dos últimos N quadros (itens 10, 114, 115). */
static float4 passeMedia() {
    float2 agora = decodificarMv(campo.sample(__nv_smp, in.acScreenNorm).rg);
    if (eng.acStateFresh == 1 || u.motionAverage < 0.5) return codificar16(agora);
    float2 antes = decodificar16(movMedio.read(uint2(int2(__nv_fragCoord.xy)), uint(0)));
    // No corte, a média não engole o vetor de lixo (ver `campoBruto`).
    if (corteAgora()) return codificar16(antes);
    return codificar16(mix(antes, agora, 1.0 / (1.0 + u.motionAverage)));
}

/**
 * O corte (item 76). Não é a diferença pura: uma cena de textura forte erra
 * mais no melhor encaixe do que uma lisa, e um limiar fixo ou dispara à toa ou
 * nunca. É a RAZÃO entre o erro do melhor encaixe e a textura do bloco — num
 * plano contínuo o encaixe acha o bloco e a razão fica baixa (0,2 a 0,35 na
 * simulação); num corte não há o que achar, e ela salta (0,77).
 */
static float pontuacaoDeCorte() {
    float soma = 0.0;
    for (int j = 0; j < 3; j++) {
        for (int i = 0; i < 4; i++) {
            float2 uv = (float2(float(i), float(j)) + 0.5) / float2(4.0, 3.0);
            float4 g = campoGrosso.sample(__nv_smp, uv);
            soma += g.b / max(g.a * 0.25, 0.01);
        }
    }
    return soma / 12.0;
}

/**
 * O relógio global. Todo texel faz a mesma conta; o texel (0,0) guarda o
 * contador desde o último gatilho e a idade da referência (16 bits cada), e o
 * (1,0) guarda o grave do quadro anterior (para o gatilho pegar a SUBIDA).
 */
static float4 passeTempo() {
    bool primeiro = eng.acStateFresh == 1;
    float4 a0 = tempo.read(uint2(int2(0, 0)), uint(0));
    float4 a1 = tempo.read(uint2(int2(1, 0)), uint(0));
    float timer = primeiro ? 65535.0 : decodificarContador(a0.rg);
    float idade = primeiro ? 0.0 : decodificarContador(a0.ba);
    float graveAntes = primeiro ? 1.0 : a1.r;
    float corte = primeiro ? 0.0 : pontuacaoDeCorte();
    float grave = nivelGrave();
    float espera = u.cooldown / duracaoDoQuadro();

    // O corte precisa passar de um piso E saltar em relação ao quadro anterior.
    float corteAntes = primeiro ? 100.0 : a1.g * 4.0;
    bool saltou = corte > mix(1.0, 0.4, u.cutSensitivity) && corte > corteAntes * mix(2.5, 1.4, u.cutSensitivity);
    bool dispara = false;
    if (u.referenceMode == 3 && saltou && timer > espera) dispara = true;
    if (u.referenceMode == 4 && grave > u.beatThreshold && graveAntes <= u.beatThreshold && timer > espera) dispara = true;
    timer = dispara ? 0.0 : min(timer + 1.0, 65535.0);

    float segurando = u.persistence * envelopeGlobal(timer, indiceDoQuadro());
    idade = segurando > 0.5 ? min(idade + 1.0, 65535.0) : (segurando < 0.05 ? 0.0 : idade);

    if (int(__nv_fragCoord.x) == 0) return float4(codificarContador(timer), codificarContador(idade));
    return float4(grave, clamp(corte * 0.25, 0.0, 1.0), saltou ? 1.0 : 0.0, 1.0);
}

// ============================================================================
//  PASSES 6 E 7 — O RESÍDUO DO BLOCO (itens 58-62, 222-223)
// ============================================================================

/**
 * O resíduo de verdade é atual − previsão. Aqui ele é medido por bloco de 8 px
 * e guardado em 4 coeficientes de cosseno (o DC, uma meia-onda em X, uma em Y
 * e a cruzada) — a mesma base da DCT, só as quatro frequências mais baixas.
 * É o que dá o visual de codec com pouca banda: o bloco novo chega como um
 * gradiente borrado, e o detalhe fino da referência antiga continua por cima.
 */
static float4 passeResiduo() {
    if (eng.acStateFresh == 1) return float4(0.5);
    float2 camada = camadaPx();
    float2 bloco = floor(in.acScreenNorm * eng.acResolution);
    float2 centro = (bloco + 0.5) / eng.acResolution;
    float4 atualC = atualEm(centro);
    float fator = mapaEm(centro, atualC, length(campoBruto(centro))) * fatorDeMovimento();
    float2 m = movimentoFinal(centro, fator);
    float dc = 0.0;
    float x1 = 0.0;
    float y1 = 0.0;
    float xy = 0.0;
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            float2 f = (float2(float(i), float(j)) + 0.5) / 4.0;
            float2 uv = (bloco + f) / eng.acResolution;
            float r = luma(atualEm(uv).rgb) - luma(lerRef(uv - m / camada).rgb);
            float bx = cos(PI * f.x);
            float by = cos(PI * f.y);
            dc += r;
            x1 += r * bx;
            y1 += r * by;
            xy += r * bx * by;
        }
    }
    float4 k = float4(dc, x1 * 2.0, y1 * 2.0, xy * 4.0) / 16.0;
    return clamp(k * 0.5 + 0.5, 0.0, 1.0);
}

static float4 passeResiduoCor() {
    if (eng.acStateFresh == 1) return float4(0.5, 0.5, 0.5, 1.0);
    float2 camada = camadaPx();
    float2 bloco = floor(in.acScreenNorm * eng.acResolution);
    float2 centro = (bloco + 0.5) / eng.acResolution;
    float4 atualC = atualEm(centro);
    float fator = mapaEm(centro, atualC, length(campoBruto(centro))) * fatorDeMovimento();
    float2 m = movimentoFinal(centro, fator);
    float3 soma = float3(0.0);
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            float2 uv = (bloco + (float2(float(i), float(j)) + 0.5) / 2.0) / eng.acResolution;
            float4 a = atualEm(uv);
            float4 p = lerRef(uv - m / camada);
            soma += float3(paraYcc(a.rgb).yz - paraYcc(p.rgb).yz, a.a - p.a);
        }
    }
    return float4(clamp(soma * 0.25 * 0.5 + 0.5, 0.0, 1.0), 1.0);
}

// ============================================================================
//  PASSE 8 — O MOSH (itens 31-41, 58-72, 95-97, 219, 278-282)
// ============================================================================

/** Um caminho pelo campo, de 1 a 3 passos seguindo o fluxo (item 39). */
static float4 amostrarCaminho(float2 uv, float2 m0, int passos, float sinal, float fator) {
    float2 texel = 1.0 / camadaPx();
    float2 q = uv;
    float2 m = m0;
    for (int i = 0; i < 3; i++) {
        if (i >= passos) break;
        q -= sinal * m * texel;
        if (i + 1 < passos) m = movimentoFinal(q, fator);
    }
    return lerRefFiltrada(q);
}

/** A previsão: a referência antiga, arrastada pelo movimento novo (itens 35-40). */
static float4 predizer(float2 uv, float2 m, float fator) {
    int teto = u.quality == 0 ? 1 : (u.quality == 1 ? 2 : 3);
    int passos = min(int(clamp(u.warpSteps, 1.0, 3.0)), teto);
    passos = min(passos, 1 + int(length(m) / 8.0));
    if (u.warpMode == 1) return amostrarCaminho(uv, m, passos, -1.0, fator);
    float4 frente = amostrarCaminho(uv, m, passos, 1.0, fator);
    if (u.warpMode == 2) return (frente + amostrarCaminho(uv, m, passos, -1.0, fator)) * 0.5;
    return frente;
}

/**
 * O MOSH DO PRIMEIRO QUADRO (e do quadro PARADO).
 *
 * Sem estado ainda (primeiro quadro, cursor arrastado, vídeo parado), a referência
 * nasceria do quadro atual LIMPO — e aí, parado, o efeito não mostrava nada e não
 * dava pra ajustar sem tocar a timeline (relato do snow, 24/09/2026). Aqui, quando
 * há movimento (o medido do vídeo OU o sintético — Drift/Zoom/Onda), a imagem atual
 * é ARRASTADA ao longo desse movimento num rastro acumulado: um derretimento
 * visível JÁ no primeiro quadro e com o vídeo parado. Sem movimento nenhum (foto
 * parada e sem Drift), não há o que derreter, e volta o quadro limpo.
 */
static float4 moshFresco(float2 uv, float4 atual) {
    float2 camada = camadaPx();
    float fator = mapaEm(uv, atual, length(campoBruto(uv)));
    float2 m = movimentoFinal(uv, fator * fatorDeMovimento());
    if (length(m) < 0.01) return atual;
    float I = intensidadeAgora();
    // Quanto mais intensidade, mais longe o rastro arrasta.
    float rastro = 0.5 + 1.5 * I;
    float4 acc = atual;
    float wsum = 1.0;
    const int N = 12;
    for (int i = 1; i <= N; i++) {
        float t = float(i) / float(N);
        float w = 1.0 - t;
        acc += atualEm(uv - m * t * rastro / camada) * w;
        wsum += w;
    }
    float4 r = acc / wsum;
    r.a = clamp(r.a, 0.0, 1.0);
    r.rgb = clamp(r.rgb, 0.0, r.a);
    return r;
}

static float4 passeMosh() {
    float2 uv = in.acScreenNorm;
    float4 atual = atualEm(uv);
    // Sem quadro anterior de verdade (primeiro quadro, cursor arrastado, parado):
    // a referência já nasce MOSHADA pelo movimento, para o efeito aparecer na hora
    // e dar pra ajustar sem tocar a timeline. Ver [moshFresco].
    if (eng.acStateFresh == 1) return moshFresco(uv, atual);

    float2 camada = camadaPx();
    float2 p = uv * camada;
    float fd = duracaoDoQuadro();
    float quadro = indiceDoQuadro();
    float s = semente();

    float4 g0 = tempo.read(uint2(int2(0, 0)), uint(0));
    float timer = decodificarContador(g0.rg);
    float idadeSeg = decodificarContador(g0.ba) * fd;

    /*
     * A INTENSIDADE NÃO É LINEAR (itens 278-282): o slider libera os
     * componentes em faixas. Até 0,3 é só arrasto e memória; os blocos entram
     * entre 0,45 e 0,75; o ruído de DCT entre 0,5 e 0,8; a cor por último.
     */
    float I = intensidadeAgora();
    float kMemoria = smoothstep(0.0, 0.3, I);
    float kMovimento = fatorDeMovimento();
    float kBlocos = smoothstep(0.45, 0.75, I);
    float kDct = smoothstep(0.5, 0.8, I);
    float kCor = smoothstep(0.6, 1.0, I);

    float magnitude = length(campoBruto(uv));
    float fator = mapaEm(uv, atual, magnitude);
    // O fator entra DENTRO dos operadores (o encaixe no pixel e o teto vêm
    // depois dele), e é o mesmo que os passes do resíduo e o multi-step usam.
    float2 m = movimentoFinal(uv, fator * kMovimento);

    float segura = u.persistence * kMemoria * envelopeGlobal(timer, quadro) * fator;
    if (u.referenceMode == 2) segura *= smoothstep(u.refreshMotion * 0.5, u.refreshMotion * 1.5 + 0.01, magnitude);
    if (u.maxAge > 0.0) segura *= 1.0 - smoothstep(u.maxAge * 0.85, u.maxAge, idadeSeg);
    float fatorIdade = u.ageCurve > 0.0 ? smoothstep(0.0, u.ageCurve, idadeSeg) : 1.0;

    float4 pred = predizer(uv, m, fator * kMovimento);

    // Onde nada se mexe, pouca corrupção (itens 28 e 297): bloco e ruído de
    // DCT seguem o movimento. Sem isso, a corrupção caía no fundo parado a cada
    // quadro, realimentava, e em oito quadros a imagem inteira era ruído.
    float ondeMexe = mix(0.1, 1.0, smoothstep(0.5, 4.0, length(m)));
    float3 pY = paraYcc(pred.rgb);
    float3 cY = paraYcc(atual.rgb);

    // --------------------------------------------- o resíduo do codec
    float2 tamR = float2(int2(int(residuo.get_width()), int(residuo.get_height())));
    int2 celR = clamp(int2(uv * tamR), int2(0), int2(tamR) - 1);
    float2 f = fract(uv * tamR);
    float4 k = (residuo.read(uint2(celR), uint(0)) - 0.5) * 2.0;
    float degrau = mix(0.02, 0.25, clamp(u.residualQuant, 0.0, 1.0));
    float4 kq = floor(k / degrau + 0.5) * degrau;
    // Bloco com resíduo pequeno é PULADO, como o codificador faz: a
    // referência errada continua ali (item 62).
    float usa = step(u.residualThreshold, abs(k.x) + 0.5 * (abs(k.y) + abs(k.z)));
    float bx = cos(PI * f.x);
    float by = cos(PI * f.y);
    float rY = (kq.x + kq.y * bx + kq.z * by + kq.w * bx * by) * usa;

    float ladoCor = max(u.chromaBlock, 1.0);
    float2 pc = (floor(p / ladoCor) + 0.5) * ladoCor;
    float2 tamC = float2(int2(int(residuoCor.get_width()), int(residuoCor.get_height())));
    int2 celC = clamp(int2(pc / camada * tamC), int2(0), int2(tamC) - 1);
    float3 rC = (residuoCor.read(uint2(celC), uint(0)).xyz - 0.5) * 2.0;
    rC.xy = floor(rC.xy / degrau + 0.5) * degrau * step(u.residualThreshold, abs(rC.x) + abs(rC.y));

    float3 mY = pY + u.residual * float3(rY, rC.xy);
    float mA = pred.a + u.residual * rC.z;

    // --------------------------------------------- ruído de DCT (item 60)
    if (u.dctNoise > 0.0 && u.quality >= 1) {
        float2 b8 = float2(celR);
        float carrega = max(u.blockCarry, 1.0);
        float epoca = floor((quadro + hash21(b8 + s) * carrega) / carrega);
        float chance = u.dctNoise * kDct * fator * (0.4 + 0.6 * fatorIdade) * ondeMexe;
        if (hash31(float3(b8, epoca + s)) < chance) {
            float2 h = hash32(float3(b8, epoca + s + 3.1));
            float fx = 1.0 + floor(h.x * u.dctFrequency);
            float fy = floor(h.y * (u.dctFrequency + 1.0));
            float amp = (hash31(float3(b8, epoca + s + 9.7)) - 0.5) * 0.4;
            mY.x += amp * cos(PI * fx * f.x) * cos(PI * fy * f.y);
            mY.yz += (h - 0.5) * amp * 0.5;
        }
    }
    float4 M = float4(deYcc(mY), mA);

    // --------------------------------------------- macroblocos (itens 66-69)
    float lado = max(u.blockSize, 1.0);
    float2 pOrg = p;
    if (u.blockEdge == 2) {
        float2 celula = floor(p / 4.0);
        pOrg += (float2(hash21(celula + s), hash21(celula + s + 7.0)) - 0.5) * lado * 0.3;
    }
    float2 bid = floor(pOrg / lado);
    float carrega = max(u.blockCarry, 1.0);
    float epoca = floor((quadro + hash21(bid + s + 1.3) * carrega) / carrega);
    float chanceBloco = u.blocks * kBlocos * fator * (0.5 + 0.5 * fatorIdade) * ondeMexe;
    if (hash31(float3(bid, epoca + s)) < chanceBloco) {
        float tipo = hash31(float3(bid, epoca + s + 7.7));
        float4 fonte;
        if (tipo < 0.35) {
            fonte = lerRef(uv);                                // referência parada
        } else if (tipo < 0.55) {
            float4 h = preMultiplicar(anterior.sample(__nv_smp, uv));    // o quadro anterior cru
            fonte = h.a > 0.0 ? h : lerRef(uv);
        } else if (tipo < 0.75) {
            float2 viz = floor(hash32(float3(bid, epoca + s + 2.2)) * 3.0) - 1.0;
            fonte = lerRef(uv + viz * lado / camada);          // o bloco vizinho
        } else if (tipo < 0.9) {
            float2 salto = (hash32(float3(bid, epoca + s + 5.5)) - 0.5) * 2.0 * u.blockJump;
            fonte = lerRef(uv - (m + salto) / camada);         // o vetor errado
        } else {
            fonte = lerRef((bid + 0.5) * lado / camada - m / camada);   // o bloco chapado
        }
        float w = 1.0;
        if (u.blockEdge == 1) {
            float2 dentro = fract(pOrg / lado);
            float borda = min(min(dentro.x, 1.0 - dentro.x), min(dentro.y, 1.0 - dentro.y));
            w = smoothstep(0.0, 0.2, borda);
        }
        M = mix(M, fonte, w);
    }

    // --------------------------------------------- a cor (itens 63-65, 95-96)
    float3 Y2 = paraYcc(M.rgb);
    float kc = u.colorAmt * kCor * fator;
    if (kc > 0.0) {
        float atraso = u.chromaLag * (u.lumaMode == 2 ? 2.0 : 1.0);
        float4 arrastada = lerRef(uv - m * (1.0 + atraso * 2.0) / camada);
        Y2.yz = mix(Y2.yz, paraYcc(arrastada.rgb).yz, clamp(kc * (0.5 + atraso), 0.0, 1.0));
        float4 blocoDeCor = lerRef(pc / camada - m / camada);
        Y2.yz = mix(Y2.yz, paraYcc(blocoDeCor.rgb).yz, kc * 0.6);
        // O ganho vale para o erro de cor DESTE quadro (em relação à previsão),
        // e não para o desvio acumulado em relação ao quadro limpo: aquele,
        // realimentado, crescia 1,14× por quadro e virava confete.
        float ganho = 1.0 + kc * (u.lumaMode == 4 ? 3.0 : 1.2);
        Y2.yz = pY.yz + (Y2.yz - pY.yz) * ganho;
    }
    if (u.lumaMode == 1) {
        Y2.x = mix(Y2.x, cY.x, 0.85);
    } else if (u.lumaMode == 2) {
        Y2.x = mix(Y2.x, cY.x, 0.5);
    }
    M.rgb = deYcc(Y2);

    // --------------------------------------------- profundidade de bits (item 219)
    if (u.bitDepth > 0) {
        float niveis = pow(2.0, float(7 - u.bitDepth));
        M.rgb = floor(M.rgb * niveis + 0.5) / niveis;
    }
    M.a = clamp(M.a, 0.0, 1.0);
    M.rgb = clamp(M.rgb, 0.0, M.a);

    // A referência nova: o resultado, e não o quadro limpo (itens 88, 151).
    float4 saida = mix(atual, M, clamp(segura, 0.0, 1.0));
    if (u.lumaMode == 3) saida.rgb = float3(luma(saida.rgb));
    return saida;
}

// ============================================================================
//  PASSE 9 — A SAÍDA E AS VISTAS DE DEPURAÇÃO (itens 146-149)
// ============================================================================

static float3 corDoVetor(float2 v) {
    float mag = clamp(length(v) / 16.0, 0.0, 1.0);
    float h = __nv_atan(v.y, v.x) / TAU + 0.5;
    float3 roda = clamp(abs(fract(h + float3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
    return mix(float3(0.5), roda, mag) * (0.3 + 0.7 * mag);
}

static float4 semPreMultiplicar(float4 c) {
    return c.a > 0.0001 ? float4(c.rgb / c.a, c.a) : float4(0.0);
}

static float4 passeSaida() {
    float2 uv = in.acScreenNorm;
    float4 moshado = referencia.sample(__nv_smp, uv);
    if (u.view == 0) return semPreMultiplicar(moshado);

    float2 camada = camadaPx();
    float2 p = uv * camada;
    float4 atual = atualEm(uv);
    if (u.view == 1) return float4(corDoVetor(campoBruto(uv)), 1.0);
    if (u.view == 2) return float4(float3(campo.sample(__nv_smp, uv).b), 1.0);
    if (u.view == 3) {
        // A referência guardada, sem a mesclagem do efeito, sobre um xadrez
        // (o transparente dela aparece).
        float2 casa = floor(p / 16.0);
        float3 xadrez = float3(0.25 + 0.15 * __nv_mod(casa.x + casa.y, 2.0));
        return float4(moshado.rgb + xadrez * (1.0 - moshado.a), 1.0);
    }
    if (u.view == 4) {
        float fator = mapaEm(uv, atual, length(campoBruto(uv)));
        float4 g0 = tempo.read(uint2(int2(0, 0)), uint(0));
        float segura = u.persistence * envelopeGlobal(decodificarContador(g0.rg), indiceDoQuadro()) * fator;
        return float4(float3(clamp(segura, 0.0, 1.0)), 1.0);
    }
    if (u.view == 5) {
        float2 dentro = fract(p / max(u.blockSize, 1.0)) * max(u.blockSize, 1.0);
        float linha = step(min(dentro.x, dentro.y), 1.0);
        float4 base = semPreMultiplicar(moshado);
        return float4(mix(base.rgb, float3(0.1, 1.0, 0.4), linha * 0.8), 1.0);
    }
    if (u.view == 6) {
        float4 lado = uv.x < 0.5 ? semPreMultiplicar(atual) : semPreMultiplicar(moshado);
        float divisa = 1.0 - step(1.5, abs(p.x - camada.x * 0.5));
        return float4(mix(lado.rgb, float3(1.0, 0.2, 0.2), divisa), 1.0);
    }
    if (u.view == 7) {
        float mag = clamp(length(campoBruto(uv)) / 24.0, 0.0, 1.0);
        return float4(mix(float3(0.02, 0.02, 0.1), float3(1.0, 0.9, 0.3), sqrt(mag)), 1.0);
    }
    // 8: a idade da referência, em barra no topo, sobre o mapa do segurar.
    float4 g0 = tempo.read(uint2(int2(0, 0)), uint(0));
    float idadeSeg = decodificarContador(g0.ba) * duracaoDoQuadro();
    float barra = step(1.0 - uv.y, 0.04) * step(uv.x, clamp(idadeSeg / 5.0, 0.0, 1.0));
    float4 base = semPreMultiplicar(moshado);
    return float4(mix(base.rgb * 0.4, float3(1.0, 0.5, 0.1), barra), 1.0);
}

fragment float4 fx_datamosh_pro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant datamosh_proParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> anterior [[texture(1)]],
    texture2d<float> somImg [[texture(2)]],
    texture2d<float> lumas [[texture(3)]],
    texture2d<float> lumasB [[texture(4)]],
    texture2d<float> campoGrosso [[texture(5)]],
    texture2d<float> campo [[texture(6)]],
    texture2d<float> residuo [[texture(7)]],
    texture2d<float> residuoCor [[texture(8)]],
    texture2d<float> movMedio [[texture(9)]],
    texture2d<float> tempo [[texture(10)]],
    texture2d<float> referencia [[texture(11)]],
    texture2d<float> mapLayer [[texture(12)]],
    texture2d<float> pixelsLayer [[texture(13)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = passeLumas(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = passeLumasB(); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = passeGrosso(); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = passeFino(); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = passeTempo(); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = passeMedia(); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = passeResiduo(); return __nv_out; }
    if (eng.acPass == 7) { __nv_out = passeResiduoCor(); return __nv_out; }
    if (eng.acPass == 8) { __nv_out = passeMosh(); return __nv_out; }
    __nv_out = passeSaida();
    return __nv_out;
}
