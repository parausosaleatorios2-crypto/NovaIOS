// ---------------------------------------------------------------------------
// Signal
// origem : assets/effects/signal.xml
// id     : nova.effect.signal
// passes : 19
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct signalParams {
    float seed;
    float amplification;
    float cutoff;
    float lumaNoise;
    float chromaNoise;
    float hueNoise;
    float chromaLoss;
    float sharpen;
    float connections;
    int vhsSpeed;
    int destruction;
    int lumaModulation;
    float frequency;
    float phase;
    float lightness;
    float quantize;
    int tapeErrors;
    float teStart;
    float teEnd;
    float teProbability;
    float teFade;
    float teGamma;
    float thick;
    float fine;
    float distortionSpeed;
    float rollSpeed;
    int lpfIn;
    int lpfOut;
    float phaseShift;
    float phaseShiftOffset;
    int sVideoOut;
    int chromaVerticalBlend;
    int sharpenOn;
    float scanlinesBlur;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
// Tamanho dos ruídos, medido contra o AE (desvio na saída por unidade do controle).
const float LUMA_NOISE = 9.0;
const float CHROMA_NOISE = 0.117;
const float HUE_NOISE = 1.3;
const float TE_A = 0.55;
const float DIST_GROSSA = 47.0;
const float DIST_FINA = 10.5;
const float DIST_ROLA = 30.0;
const float TE_B = 0.049;

// ------------------------------------------------------------- codificação
// Buffers de 8 bits: valores com sinal guardados com deslocamento; os que precisam de
// precisão (luma, composto, fase) em 16 bits, dois canais.
static float2 enc16(float v, float lo, float hi) {
    float q = floor(clamp((v - lo) / (hi - lo), 0.0, 1.0) * 65535.0 + 0.5);
    float a = floor(q / 256.0);
    return float2(a, q - a * 256.0) / 255.0;
}
static float dec16(float2 c, float lo, float hi) {
    float2 b = floor(c * 255.0 + 0.5);
    return lo + (b.x * 256.0 + b.y) / 65535.0 * (hi - lo);
}
static float enc8(float v, float r) { return clamp(v / (2.0 * r) + 0.5, 0.0, 1.0); }
static float dec8(float c, float r) { return (c - 0.5) * 2.0 * r; }

const float CL = 0.75;   // faixa de I e Q
static float3 rgb2yiq(float3 c) {
    return float3(dot(c, float3(0.299, 0.587, 0.114)), dot(c, float3(0.596, -0.274, -0.322)), dot(c, float3(0.211, -0.523, 0.312)));
}
static float3 yiq2rgb(float3 y) {
    return float3(y.x + 0.956 * y.y + 0.621 * y.z, y.x - 0.272 * y.y - 0.647 * y.z, y.x - 1.106 * y.y + 1.703 * y.z);
}

// ------------------------------------------------------------- aleatório
static float hash31(float3 p) {
    p = fract(p * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return fract((p.x + p.y) * p.z);
}
static float quadro() { return eng.acFrameDuration > 0.0 ? floor(eng.acTime / eng.acFrameDuration + 0.5) : floor(eng.acTime * 30.0 + 0.5); }
/** Ruído de gradiente 1D (Perlin): espectro em banda, com o lóbulo negativo que a distorção do AE tem. */
static float perlin1(float x, float s) {
    float i = floor(x);
    float f = fract(x);
    float g0 = hash31(float3(i, s, 7.0)) * 2.0 - 1.0;
    float g1 = hash31(float3(i + 1.0, s, 7.0)) * 2.0 - 1.0;
    float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(g0 * f, g1 * (f - 1.0), u);
}
static int2 px() { return int2(__nv_fragCoord.xy); }
/** A fase da subportadora em cada linha (em quartos de ciclo): Phase shift por par de linhas,
 *  a partir do Phase shift offset — o padrão do ntscQT (0/90/180/270). Só muda o desenho do
 *  "dot crawl" nas bordas de cor (efeito medido de 0,2–0,3% da imagem). */
static int faseDaLinha(int y) {
    float par = floor(float(y) / (2.0 * max(eng.acEscalaDePixel, 1e-3)));
    return int(floor((u.phaseShiftOffset + par * u.phaseShift) / 90.0 + 0.5)) & 3;
}
// As contas foram medidas num quadro de 540 linhas; a prévia reduzida mantém o mesmo desenho.
static float escala() { return max(eng.acEscalaDePixel, 1e-3); }

// ------------------------------------------------------------- 0: a fonte
static float4 passeFonte() {
    float2 res = eng.acResolution;
    float t = eng.acTime;
    float linha = __nv_fragCoord.y;
    // Roll: o quadro rola para cima, 13,2 linhas por segundo por unidade num quadro de 540
    // (medido em 0,5, 1 e 2 s), dando a volta sem faixa de apagamento.
    float rolado = __nv_mod(linha + u.rollSpeed * t * 13.2 / 540.0 * res.y, res.y);
    // TV distortion: deslocamento horizontal da linha (com volta na borda).
    float yn = rolado / escala();
    float semente = u.seed * 0.6180339;
    // Medido: a grossa tem ondas de 135–270 linhas (desvio 5,3 px por unidade), a fina de
    // 10–50 linhas (1,4 px por unidade). A Distortion speed não muda o desenho: rola as duas
    // para baixo, 30 linhas por segundo por unidade (1 linha por quadro a 30 qps).
    float yd = yn - t * u.distortionSpeed * DIST_ROLA;
    float d = u.thick * DIST_GROSSA * perlin1(yd / 110.0, semente)
            + u.fine * DIST_FINA * perlin1(yd / 11.0, semente + 3.0);
    d *= escala();
    float x = __nv_mod(__nv_fragCoord.x - d, res.x);
    float4 c = inputImg.sample(__nv_smp, float2(x, rolado + 0.5) / res);
    float3 y = rgb2yiq(c.rgb);
    return float4(y.x, enc8(y.y, CL), enc8(y.z, CL), c.a);
}

// ------------------------------------------------------------- 1–13: a fase da FM
static float nuEm(int2 p) {
    float Y = fonte.read(uint2(clamp(p, int2(0), int2(eng.acResolution) - 1)), uint(0)).r;
    return 0.1579 * u.frequency + 0.1395 * u.phase * (Y - 0.3825);
}
static float4 passeFase(int k) {
    int2 p = px();
    if (k == 0) return float4(enc16(fract(nuEm(p)), 0.0, 1.0), 0.0, 1.0);
    int off = 1 << (k - 1);
    float soma = dec16((k % 2 == 1 ? fa.read(uint2(p), uint(0)) : fb.read(uint2(p), uint(0))).rg, 0.0, 1.0);
    if (p.x - off >= 0) {
        int2 q = int2(p.x - off, p.y);
        soma += dec16((k % 2 == 1 ? fa.read(uint2(q), uint(0)) : fb.read(uint2(q), uint(0))).rg, 0.0, 1.0);
    }
    return float4(enc16(fract(soma), 0.0, 1.0), 0.0, 1.0);
}

// ------------------------------------------------------------- 14: o composto
const float CLO = -1.5;
const float CHI = 2.5;
static float4 passeComposto() {
    int2 p = px();
    float4 f = fonte.read(uint2(p), uint(0));
    float Y = f.r;
    float I = dec8(f.g, CL);
    float Q = dec8(f.b, CL);
    float fr = quadro();
    if (u.lumaModulation) {
        float nu = nuEm(p);
        float nc = 0.1579 * u.frequency;
        float ph = max(u.phase, 1e-3);
        // O centro do demodulador do AE fica acima de |sen(π·ν0)| quando a portadora passa de
        // 0,13 ciclo/px (Frequency > 0,8): a luma escurece, mais com Phase baixa (medido de 1 a 4).
        float x = max(nc - 0.13, 0.0);
        float centro = abs(sin(PI * nc)) + 0.62 * x + 1.4 * x * x;
        float fm = (abs(sin(PI * nu)) - centro) / (PI * 0.1395 * ph) * 1.274 + 0.3825 + 0.4421 - 0.7148 * u.lightness;
        // A ondulação no 2º harmônico da portadora (maior perto de ν = 0 e ν = 0,25).
        float fase = dec16(fa.read(uint2(p), uint(0)).rg, 0.0, 1.0);
        float amp = 0.018 + 0.05 * exp(-pow((nu - 0.04) / 0.018, 2.0)) + 0.07 * exp(-pow((nu - 0.25) / 0.02, 2.0));
        fm += amp * cos(4.0 * PI * fase);
        if (u.quantize > 0.0) {
            float n = max(256.0 - u.quantize * 2.5, 2.0);
            fm = floor(fm * n + 0.5) / n;
        }
        Y = clamp(fm, 0.0, 1.0);
    }
    // Tape errors (só com a FM ligada, como no AE): faixas de chuvisco de 22 linhas, a cada 30,
    // a partir de 8 linhas abaixo do TE start — no mesmo lugar em todo quadro, semente e imagem;
    // dentro delas, manchas de ~6 px sorteadas por quadro, claras (assimetria pelo TE gamma).
    if (u.lumaModulation && u.tapeErrors && u.teEnd > u.teStart) {
        float H = eng.acResolution.y;
        float lin = __nv_fragCoord.y;
        float pos = (lin - u.teStart * H) / escala() - 8.0;
        if (lin >= u.teStart * H && lin <= u.teEnd * H && pos >= 0.0) {
            float dentro = __nv_mod(pos, 30.0);
            if (dentro < 22.0) {
                float borda = clamp(min(dentro + 0.5, 22.0 - dentro) / max(u.teFade * 0.4, 0.01), 0.0, 1.0);
                float xc = __nv_fragCoord.x / (6.0 * escala());
                float a = hash31(float3(floor(xc), floor(lin), fr + 91.0 + u.seed));
                float b = hash31(float3(floor(xc) + 1.0, floor(lin), fr + 91.0 + u.seed));
                float u = mix(a, b, smoothstep(0.0, 1.0, fract(xc)));
                float dens = clamp(u.teProbability * 10.0, 0.0, 1.0);
                float mancha = pow(u, u.teGamma) * TE_A - TE_B;
                Y += mancha * borda * dens;
            }
        }
    }
    // A cor na subportadora (¼ da taxa: 1, 0, −1, 0 e 0, 1, 0, −1).
    int fase4 = (p.x + faseDaLinha(p.y)) & 3;
    float u = fase4 == 0 ? 1.0 : (fase4 == 2 ? -1.0 : 0.0);
    float w = fase4 == 1 ? 1.0 : (fase4 == 3 ? -1.0 : 0.0);
    float c = Y + I * u + Q * w;
    return float4(enc16(c, CLO, CHI), f.a, 1.0);
}
static float compEm(int x, int y) {
    return dec16(comp.read(uint2(int2(clamp(x, 0, int(eng.acResolution.x) - 1), y)), uint(0)).rg, CLO, CHI);
}

// ------------------------------------------------------------- 15: a pré-ênfase
/** A faixa do sinal depois da pré-ênfase: cresce com a Signal u.amplification (o AE não corta). */
static float faixaEnfase() { return 1.5 + 0.45 * u.amplification; }
// Depois da demodulação: luma em 16 bits numa faixa que cresce com a amplificação (e com a
// nitidez, no VHS); croma em 8 bits comprimida (asinh), fina perto de zero.
static float faixaY() { return 1.5 + 0.17 * u.amplification; }
static float faixaYVhs() { return faixaY() * (1.0 + 0.3 * (u.sharpenOn ? u.sharpen : 0.0)); }
static float faixaC() { return 1.0 + 0.3 * u.amplification + 0.04 * u.chromaNoise; }
static float encC(float v) { return clamp(0.5 + 0.5 * asinh(v * 4.0) / asinh(faixaC() * 4.0), 0.0, 1.0); }
static float decC(float c) { return sinh((c - 0.5) * 2.0 * asinh(faixaC() * 4.0)) * 0.25; }
static float4 passePreEnfase() {
    int2 p = px();
    float c = compEm(p.x, p.y);
    if (u.amplification > 0.0) {
        // Passa-baixas causal de 1 polo como FIR: Σ α(1−α)^k c[x−k].
        float a = 1.0 / (1.0 + 0.0073 * u.cutoff);
        float lp = 0.0;
        float peso = a;
        float soma = 0.0;
        for (int k = 0; k < 48; k++) {
            lp += peso * compEm(p.x - k, p.y);
            soma += peso;
            peso *= (1.0 - a);
            if (peso < 1e-4) break;
        }
        lp /= max(soma, 1e-6);
        c += u.amplification * (c - lp);
    }
    // Luma noise (depois da pré-ênfase, senão o ruído ganha agudos): ruído branco num
    // passa-baixas de 1 polo (α = 0,5) — a correlação horizontal do AE, 0,9/0,67/0,07 depois
    // da cadeia; desvio = valor/255 na saída.
    if (u.lumaNoise > 0.0) {
        float fr = quadro();
        float h = 0.0;
        float w = 0.5;
        for (int k = 0; k < 8; k++) {
            h += w * (hash31(float3(float(p.x - k), float(p.y), fr + u.seed * 13.0)) - 0.5);
            w *= 0.5;
        }
        // O AE satura o ruído forte (desvio 44 e 57 em 50 e 100, não 50 e 100): o ruído não
        // leva o sinal para fora de [0, 1] (aqui 47 e 62). O sinal em si não é cortado.
        c = clamp(c + h * u.lumaNoise / 255.0 * LUMA_NOISE, min(c, 0.0), max(c, 1.0));
    }

    return float4(enc16(c, -faixaEnfase(), faixaEnfase()), comp.read(uint2(p), uint(0)).b, 1.0);
}
static float comp2Em(int x, int y) {
    return dec16(comp2.read(uint2(int2(clamp(x, 0, int(eng.acResolution.x) - 1), y)), uint(0)).rg, -faixaEnfase(), faixaEnfase());
}

// ------------------------------------------------------------- 16: a demodulação
static float lumaDemod(int x, int y) {
    return 0.25 * (comp2Em(x - 1, y) + comp2Em(x, y) + comp2Em(x + 1, y) + comp2Em(x + 2, y));
}
static float4 passeDemod() {
    int2 p = px();
    float Y = lumaDemod(p.x, p.y);
    float I = 0.0;
    float Q = 0.0;
    for (int j = -1; j <= 2; j++) {
        int x = p.x + j;
        float ch = comp2Em(x, p.y) - lumaDemod(x, p.y);
        int f4 = (x + faseDaLinha(p.y)) & 3;
        float u = f4 == 0 ? 1.0 : (f4 == 2 ? -1.0 : 0.0);
        float w = f4 == 1 ? 1.0 : (f4 == 3 ? -1.0 : 0.0);
        I += ch * u;
        Q += ch * w;
    }
    I *= 0.5;
    Q *= 0.5;
    float fr = quadro();
    float linha = floor(__nv_fragCoord.y / escala());
    // Chroma noise.
    I += (hash31(float3(float2(p), fr + u.seed * 5.0 + 1.0)) - 0.5) * u.chromaNoise * CHROMA_NOISE;
    Q += (hash31(float3(float2(p), fr + u.seed * 5.0 + 2.0)) - 0.5) * u.chromaNoise * CHROMA_NOISE;
    // Hue noise: uma fase por linha, suavizada entre linhas (gaussiana de σ 1,2 linha: a
    // correlação do AE é 0,88/0,66/0,29 a 1/2/4 linhas).
    if (u.hueNoise > 0.0) {
        float r = 0.0;
        for (int k = -3; k <= 3; k++) {
            r += exp(-float(k * k) / (2.0 * 1.44)) * (hash31(float3(linha + float(k), fr, u.seed + 17.0)) - 0.5);
        }
        float ang = radians(r * u.hueNoise * HUE_NOISE);
        float c = cos(ang);
        float s = sin(ang);
        float2 iq = float2(I * c - Q * s, I * s + Q * c);
        I = iq.x;
        Q = iq.y;
    }
    return float4(enc16(Y, -faixaY(), faixaY()), encC(I), encC(Q));
}
static float3 demEm(int x, int y) {
    float4 c = dem.read(uint2(int2(clamp(x, 0, int(eng.acResolution.x) - 1), y)), uint(0));
    return float3(dec16(c.rg, -faixaY(), faixaY()), decC(c.b), decC(c.a));
}

// ------------------------------------------------------------- 17: o VHS
static float4 passeVhs() {
    int2 p = px();
    float3 c = demEm(p.x, p.y);
    float Y = c.x;
    if (u.sharpenOn && u.sharpen > 0.0) {
        // 3 polos em cascata (α = 0,298) como FIR: o núcleo binomial negativo.
        float a = 0.298;
        float lp = 0.0;
        float b = 1.0;   // (1−a)^k · C(k+2, 2)
        for (int k = 0; k < 40; k++) {
            float w = a * a * a * b;
            lp += w * demEm(p.x - k, p.y).x;
            b = b * (1.0 - a) * float(k + 3) / float(k + 1);
        }
        Y += (Y - lp) * u.sharpen * 0.2883;
    }
    // Croma do VHS: 4 polos (α por velocidade), adiantada 9/12/14 px.
    float a = u.vhsSpeed == 0 ? 0.1157 : (u.vhsSpeed == 1 ? 0.1112 : 0.1066);
    float atrasoF = u.vhsSpeed == 0 ? 9.0 : (u.vhsSpeed == 1 ? 12.0 : 14.0);
    // Os filtros de croma de entrada e de saída já estão dentro desta banda (medida com eles
    // ligados): desligar um deixa a croma ~8% mais larga e 2 px mais adiantada. Cada conexão
    // entre aparelhos (e o S-video desligado, que vale uma) adianta mais 1–2 px e alarga um
    // pouco (medido com 1 e 3 conexões).
    if (!u.lpfIn) { a *= 1.08; atrasoF += 2.0; }
    if (u.lpfOut == 0) { a *= 1.08; atrasoF += 2.0; } else if (u.lpfOut == 1) { a *= 1.1; }
    float conexoes = u.connections + (u.sVideoOut ? 0.0 : 1.0);
    if (conexoes > 0.0) { a *= 1.0 + 0.013 * conexoes; atrasoF += 1.0 + 0.5 * conexoes; }
    int atraso = int(floor(atrasoF + 0.5));
    float2 iq = float2(0.0);
    float soma = 0.0;
    float b = 1.0;   // (1−a)^k · C(k+3, 3)
    for (int k = 0; k < 96; k++) {
        float w = b;
        iq += w * demEm(p.x + atraso - k, p.y).yz;
        soma += w;
        b = b * (1.0 - a) * float(k + 4) / float(k + 1);
        if (k > 24 && b < 1e-3 * soma) break;
    }
    iq /= max(soma, 1e-6);
    return float4(enc16(Y, -faixaYVhs(), faixaYVhs()), encC(iq.x), encC(iq.y));
}
static float3 vhsEm(int x, int y) {
    y = clamp(y, 0, int(eng.acResolution.y) - 1);
    float4 c = vhs.read(uint2(int2(x, y)), uint(0));
    return float3(dec16(c.rg, -faixaYVhs(), faixaYVhs()), decC(c.b), decC(c.a));
}

/** Chroma loss: a linha perde a cor com probabilidade = valor (depois do Chroma vertical blend,
 *  como no AE: a linha sem cor só se espalha pelo Scanlines blur). */
static float corDaLinha(int y) {
    float linha = floor(float(clamp(y, 0, int(eng.acResolution.y) - 1)) / escala());
    return hash31(float3(linha, quadro(), u.seed + 29.0)) < u.chromaLoss ? 0.0 : 1.0;
}
static float3 linhaFinal(int x, int y) {
    float3 v = vhsEm(x, y);
    if (u.chromaVerticalBlend) v.yz = 0.5 * (v.yz + vhsEm(x, y - 1).yz);
    v.yz *= corDaLinha(y);
    return v;
}

// ------------------------------------------------------------- 18: a saída

fragment float4 fx_signal(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant signalParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fonte [[texture(1)]],
    texture2d<float> fa [[texture(2)]],
    texture2d<float> fb [[texture(3)]],
    texture2d<float> comp [[texture(4)]],
    texture2d<float> comp2 [[texture(5)]],
    texture2d<float> dem [[texture(6)]],
    texture2d<float> vhs [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = passeFonte(); return __nv_out; }
    if (eng.acPass >= 1 && eng.acPass <= 13) { __nv_out = passeFase(eng.acPass - 1); return __nv_out; }
    if (eng.acPass == 14) { __nv_out = passeComposto(); return __nv_out; }
    if (eng.acPass == 15) { __nv_out = passePreEnfase(); return __nv_out; }
    if (eng.acPass == 16) { __nv_out = passeDemod(); return __nv_out; }
    if (eng.acPass == 17) { __nv_out = passeVhs(); return __nv_out; }

    int2 p = px();
    // Scanlines blur: gaussiana vertical de σ = valor/2 linhas — no padrão 1,5 a linha vizinha
    // pesa 0,42, que é a correlação vertical do ruído no AE.
    float3 c = linhaFinal(p.x, p.y);
    float sigma = u.scanlinesBlur * 0.5 * escala();
    if (sigma > 0.05) {
        float3 s = float3(0.0);
        float pesos = 0.0;
        int passo = max(1, int(ceil(3.0 * sigma / 24.0)));
        for (int k = -24; k <= 24; k++) {
            float d = float(k * passo);
            if (abs(d) > 3.0 * sigma + 0.5) continue;
            float w = exp(-d * d / (2.0 * sigma * sigma));
            s += w * linhaFinal(p.x, p.y + k * passo);
            pesos += w;
        }
        c = s / max(pesos, 1e-6);
    }
    float alfa = fonte.read(uint2(p), uint(0)).a;
    float3 rgb = yiq2rgb(c);
    // Destruction: a saída não é cortada em [0, 1], dá a volta (estouro de 8 bits, como no AE):
    // o branco que passa de 1 vira escuro e a sombra abaixo de 0 vira manchas de cor forte.
    if (u.destruction) rgb = fract(rgb);
    __nv_out = float4(clamp(rgb, 0.0, 1.0), alfa);
    return __nv_out;
}
