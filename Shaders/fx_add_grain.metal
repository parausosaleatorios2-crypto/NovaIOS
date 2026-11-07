// ---------------------------------------------------------------------------
// Adicionar grão (Add Grain)
// origem : assets/effects/add-grain.xml
// id     : nova.effect.addgrain
// passes : 6
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct add_grainParams {
    int viewMode;
    float2 previewCenter;
    float previewWidth;
    float previewHeight;
    int showBox;
    float4 boxColor;
    float intensity;
    float grainSize;
    float softness;
    float aspectRatio;
    float redIntensity;
    float greenIntensity;
    float blueIntensity;
    float redSize;
    float greenSize;
    float blueSize;
    int monochromatic;
    float saturation;
    float tintAmount;
    float4 tintColor;
    int blendingMode;
    float shadows;
    float midtones;
    float highlights;
    float midpoint;
    float redShadows;
    float redMidtones;
    float redHighlights;
    float greenShadows;
    float greenMidtones;
    float greenHighlights;
    float blueShadows;
    float blueMidtones;
    float blueHighlights;
    float animationSpeed;
    int animateSmoothly;
    float randomSeed;
    float blendAmount;
    int combineMatchAndMask;
    float blurMatte;
    int matchColorUsing;
    float matchingTolerance;
    float matchingSoftness;
    int invertMatch;
    float4 matchingColor;
    int maskingMode;
};

// --- funcoes auxiliares do efeito
// ============================================================================
// Os sliders do AE são em ponto fixo 16.16 (0x1800097e0: int · 1/65536).
static float fixo(float v) { return floor(v * 65536.0 + 0.5) / 65536.0; }

// ---- o ran2 do Numerical Recipes (0x18000d630) e a gaussiana polar (0x18000dc00) ----
// Em inteiros de 32 bits pelo método de Schrage: nenhum produto passa de 2³¹.
int gIdum;
int gIdum2;
int gIy;
int gIv[32];
bool gTem;
float gGset;

static void semear(int s) {
    // 0x18000dd70: o positivo vira negativo; a primeira chamada toma o módulo (0 seria o relógio no AE)
    int idum = max(abs(s), 1);
    gIdum2 = idum;
    for (int j = 39; j >= 0; j--) {
        int k = idum / 53668;
        idum = 40014 * (idum - k * 53668) - k * 12211;
        if (idum < 0) idum += 2147483563;
        if (j < 32) gIv[j] = idum;
    }
    gIdum = idum;
    gIy = gIv[0];
    gTem = false;
}

static float uniforme() {
    int k = gIdum / 53668;
    gIdum = 40014 * (gIdum - k * 53668) - k * 12211;
    if (gIdum < 0) gIdum += 2147483563;
    k = gIdum2 / 52774;
    gIdum2 = 40692 * (gIdum2 - k * 52774) - k * 3791;
    if (gIdum2 < 0) gIdum2 += 2147483399;
    int j = gIy / 67108862;
    gIy = gIv[j] - gIdum2;
    gIv[j] = gIdum;
    if (gIy < 1) gIy += 2147483562;
    // AM e RNMX exatamente como o plugin os tem em float
    return min(float(gIy) * as_type<float>(0x30000001u), as_type<float>(0x3f7ffffeu));
}

static float gaussiana() {
    if (gTem) {
        gTem = false;
        return gGset;
    }
    float v1 = 0.0;
    float v2 = 0.0;
    float rsq = 0.5;
    for (int tentativa = 0; tentativa < 64; tentativa++) {
        v1 = 2.0 * uniforme() - 1.0;
        v2 = 2.0 * uniforme() - 1.0;
        rsq = v2 * v2 + v1 * v1;
        if (rsq < 1.0 && rsq != 0.0) break;
    }
    float fac = sqrt(-2.0 * log(rsq) / rsq) * 0.5;
    gGset = fac * v2;
    gTem = true;
    return fac * v1;
}

// O NoiseNode (0x1800156c0): o trecho de 32 px da linha tem o próprio gerador; o pixel k dele usa as
// gaussianas 3k..3k+2 (× 2: o nó é gaussiana · 2 + 0). `q` em px da camada.
static float3 ruidoDe(int2 q, int semente) {
    int X = q.x + 256;
    int Y = q.y + 256;
    int bloco = X - (X & 31);
    semear((((bloco & 0xffff) ^ (Y << 16)) + 1) ^ semente);
    int pular = (X & 31) * 3;
    for (int i = 0; i < pular; i++) gaussiana();
    float a = gaussiana();
    float b = gaussiana();
    float c = gaussiana();
    return float3(a, b, c) * 2.0;
}

// ---- o que todos os passes dividem -----------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
int gSemente1;
int gSemente2;
float gFade;
float gNorma;
float gA;          // a matriz de cor (0x18000ae50): a·I + b (todos os elementos)
float gB;
float3 gSigma0;      // o desvio de cada canal do ruído depois da matriz
float gEscala;     // a resolução reduzida da prévia (o downsample do AE)
float gMac;        // Softness · Size (o σ base)
int gW;            // o núcleo
int gH;
float3 gSigX;        // o σ de cada canal
float3 gSigY;

static void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;

    // a semente e a mistura (0x1800073a0): o quadro é o tempo da camada
    float dq = eng.acFrameDuration > 0.0 ? eng.acFrameDuration : 1.0 / 30.0;
    int quadro = int(floor(max(eng.acTime, 0.0) / dq + 0.001));
    int semente = int(u.randomSeed + 0.5);
    float vel = fixo(u.animationSpeed);
    gSemente1 = semente;
    gSemente2 = semente;
    gFade = 0.0;
    if (vel != 0.0) {
        float x = vel * float(quadro);
        int e = int(x);
        gSemente1 = semente ^ e;
        gSemente2 = semente ^ (e + 1);
        if (u.animateSmoothly) gFade = x - float(e);
    }
    float x0 = gFade + gFade;
    gNorma = 1.0 / sqrt(x0 * gFade - x0 + 1.0);

    // a matriz: s = Saturation / 2 (Monochromatic = 0)
    float s = u.monochromatic ? 0.0 : fixo(u.saturation) * 0.5;
    gA = 1.0 - abs(1.0 - s) + max(s - 1.0, 0.0);
    gB = max(1.0 - s, 0.0) * (1.0 / 3.0);
    float sig = sqrt((gA + gB) * (gA + gB) + 2.0 * gB * gB);
    gSigma0 = float3(sig);

    // o núcleo (0x180006ee0)
    float tam = fixo(u.grainSize);
    tam = tam > 0.0 ? tam : 0.001;
    gMac = fixo(u.softness) * tam;
    gMac = gMac > 0.0 ? gMac : 0.001;
    float asp = fixo(u.aspectRatio);
    asp = asp > 0.0 ? asp : 0.001;
    gW = clamp(int(gEscala * gMac * asp * 6.0), 9, 255);
    gH = clamp(int(gMac * gEscala * 6.0), 9, 255);
    float3 sc = float3(fixo(u.redSize), fixo(u.greenSize), fixo(u.blueSize)) * gMac;
    sc = mix(float3(0.001), sc, greaterThan(sc, float3(0.0)));
    gSigX = gEscala * sc * asp;
    gSigY = gEscala * sc;
}

// O ruído de um px da camada, já misturado (Animate Smoothly), normalizado e na matriz de cor.
static float3 ruidoV(int2 q) {
    float3 n = ruidoDe(q, gSemente1);
    if (gFade == 1.0) {
        n = ruidoDe(q, gSemente2);
    } else if (gFade != 0.0) {
        float3 n2 = ruidoDe(q, gSemente2);
        n = n + (n2 - n) * gFade;
    }
    n *= gNorma;
    return gA * n + gB * (n.x + n.y + n.z);
}

// O que vai nos buffers é o valor dividido por FAIXA desvios do próprio canal (passar de 8σ é 1 em 10¹⁵).
const float FAIXA = 8.0;

// 3 valores em [−1, 1] em 63 bits — 21 por canal —, em duas palavras de 32 bits (dois buffers RGBA8).
static uint2 palavras(float3 u) {
    uint3 q = uint3(floor((clamp(u, -1.0, 1.0) * 0.5 + 0.5) * 2097151.0 + 0.5));
    return uint2(q.x | (q.y << 21), (q.y >> 11) | (q.z << 10));
}

static float4 bytesDe(uint b) {
    return float4(uint4(b & 255u, (b >> 8) & 255u, (b >> 16) & 255u, b >> 24)) / 255.0;
}

static uint palavraDe(float4 c) {
    uint4 o = uint4(floor(c * 255.0 + 0.5));
    return o.x | (o.y << 8) | (o.z << 16) | (o.w << 24);
}

static float3 valores(float4 c0, float4 c1) {
    uint a = palavraDe(c0);
    uint b = palavraDe(c1);
    uint3 q = uint3(a & 2097151u, (a >> 21) | ((b & 1023u) << 11), b >> 10);
    return float3(q) / 2097151.0 * 2.0 - 1.0;
}

// O peso do tap i (gaussiana de σ) — a soma normaliza depois.
static float3 peso(int i, float3 sigma) {
    float fi = float(i * i);
    return exp(-0.5 * fi / (sigma * sigma));
}

// A soma e a soma dos quadrados do núcleo de um eixo (para normalizar e guardar).
static void somas(int n, float3 sigma, out float3 soma, out float3 quad) {
    soma = float3(0.0);
    quad = float3(0.0);
    for (int k = 0; k < n; k++) {
        float3 w = peso(k - (n >> 1), sigma);
        soma += w;
        quad += w * w;
    }
}

// A moldura dos quatro buffers (o `margin` deles): o texel (0, 0) de agN*/agH* é o (−MARGEM, −MARGEM) do buffer
// da camada. Cobre o maior raio do núcleo (127): todo tap que sai da camada cai nela.
const int MARGEM = 128;

// ---- Blend with Original: a máscara (0x18000cf50) ------------------------------------------------
static float3 hsv(float3 c) {
    float mx = max(max(max(0.0, c.r), c.g), c.b);
    float mn = min(min(min(1.0, c.r), c.g), c.b);
    float s = mx == 0.0 ? 0.0 : (mx - mn) / mx;
    if (s == 0.0) return float3(0.0, 0.0, mx);
    float d = mx - mn;
    float h = c.r == mx ? (c.g - c.b) / d : (c.g == mx ? (c.b - c.r) / d + 2.0 : (c.r - c.g) / d + 4.0);
    h *= 60.0;
    if (h < 0.0) h += 360.0;
    return float3(h / 360.0, s, mx);
}

// O espaço do casamento. Na IMAGEM, o ColorspaceNode do plugin trabalha no formato do AE (8 bits): trunca e
// fica com o byte de baixo — o I/Q negativo do Chroma dá a volta (−0,1 vira ~0,9).
static float3 espaco(float3 c, int modo, bool imagem) {
    if (modo == 1) return c;
    if (modo == 2) return hsv(c);
    float3 r;
    if (modo == 3) {
        r = float3(0.0, dot(c, float3(0.596, -0.275, -0.321)), dot(c, float3(0.212, -0.523, 0.311)));
    } else if (modo == 4) {
        r = float3(as_type<float>(0x3eaaaaabu) * (c.r + c.g + c.b));
    } else {
        r = float3(modo == 5 ? c.r : (modo == 6 ? c.g : c.b));
    }
    if (!imagem) return r;
    int3 b = int3(trunc(r * 255.0)) & 255;
    return float3(b) / 255.0;
}

// O valor da máscara num texel do buffer (antes do desfoque).
static float mascara(int2 t) {
    float4 o = inputImg.read(uint2(t), uint(0));
    float casa = -1.0;
    int modo = u.matchColorUsing;           // 0 Off, 1 RGB, 2 Hue, 3 Chroma, 4 Luminance, 5..7 R/G/B
    if (modo != 0) {
        float3 p = espaco(o.rgb, modo, true);
        float3 c = espaco(floor(u.matchingColor.rgb * 255.0 + 0.5) / 255.0, modo, false);
        float3 d = p - c;
        float x = (d.x * d.x + d.y * d.y + d.z * d.z) * (1.0 / 3.0);
        float tol = fixo(u.matchingTolerance);
        float mac = fixo(u.matchingSoftness);
        x -= tol * tol;
        float k = mac > 0.0 ? 1.0 / (mac * mac) : 1e35;
        casa = x < 0.0 ? 1.0 : max(1.0 - x * k, 0.0);
        casa = floor(casa * 255.0) / 255.0;          // a máscara sai em 8 bits (truncada) no AE de 8 bpc
        if (u.invertMatch) casa = 1.0 - casa;
    }
    float mask = -1.0;
    if (int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1) {
        // a camada de máscara no lugar dela na composição (sem o If Mask Size Differs: ver o cabeçalho)
        float4 m = maskImg.sample(__nv_smp, (float2(t) + 0.5) / float2(gT));
        int mm = u.maskingMode;              // 0 Intensity, 1 Alpha, 2 Inverted Intensity, 3 Inverted Alpha
        // a "intensidade" do plugin é a média dos três canais (0x1800111f0)
        float v = (mm == 1 || mm == 3) ? m.a : (m.r + m.g + m.b) / 3.0;
        mask = (mm == 2 || mm == 3) ? 1.0 - v : v;
    }
    if (casa < 0.0 && mask < 0.0) return 0.0;
    if (mask < 0.0) return casa;
    if (casa < 0.0) return mask;
    // Combine Match and Mask Using: Multiply (o·g) ou Screen
    return u.combineMatchAndMask == 0 ? casa * mask : 1.0 - (1.0 - casa) * (1.0 - mask);
}

// A máscara num buffer: 16 bits nos dois primeiros bytes.
static float4 gravarMascara(float m) {
    float a = floor(clamp(m, 0.0, 1.0) * 65535.0 + 0.5);
    return float4(floor(a / 256.0), __nv_mod(a, 256.0), 0.0, 255.0) / 255.0;
}

static float lerMascara(float4 v) {
    float2 b = floor(v.rg * 255.0 + 0.5);
    return (b.x * 256.0 + b.y) / 65535.0;
}

// O desfoque da máscara: gaussiana de W = max(9, ⌊3·blur⌋) e σ = blur, com a borda espelhada na CAMADA.
static float desfocarMascara(int2 t, bool emX) {
    float blur = fixo(u.blurMatte);              // em px da camada (o plugin não o reduz na prévia)
    int W = clamp(int(blur * 3.0), 9, 255);
    int r = W >> 1;
    float soma = 0.0;
    float acc = 0.0;
    int eixo = emX ? 0 : 1;
    int lo = gInicio[eixo];
    int n = gN[eixo];
    for (int k = 0; k < W; k++) {
        int i = k - r;
        float w = exp(-0.5 * float(i * i) / (blur * blur));
        soma += w;
        int2 p = t;
        int c = p[eixo] + i - lo;
        c = c < 0 ? -c - 1 : (c >= n ? 2 * n - 1 - c : c);
        p[eixo] = clamp(c, 0, n - 1) + lo;
        float4 v = emX ? agN0.read(uint2(p + MARGEM), uint(0)) : agN1.read(uint2(p + MARGEM), uint(0));
        acc += w * lerMascara(v);
    }
    return clamp(acc / soma, 0.0, 1.0);
}

fragment float4 fx_add_grain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant add_grainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> agN0 [[texture(1)]],
    texture2d<float> agN1 [[texture(2)]],
    texture2d<float> agH0 [[texture(3)]],
    texture2d<float> agH1 [[texture(4)]],
    texture2d<float> maskImg [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    // Os passes 0 a 4 escrevem nos buffers com moldura: o texel deles é o do buffer da camada + MARGEM.
    int2 t = eng.acPass <= 4 ? int2(__nv_fragCoord.xy) - MARGEM
                          : min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    int rx = gW >> 1;
    int ry = gH >> 1;

    if (eng.acPass == 0) {
        // o ruído, só onde a convolução vai ler (a camada e a margem do núcleo; fora do buffer, na moldura)
        if (any(lessThan(q, -int2(rx, ry))) || any(greaterThanEqual(q, gN + int2(rx, ry)))) {
            __nv_out = float4(0.0);
            fragColor1 = float4(0.0);
            return __nv_out;
        }
        uint2 w = palavras(ruidoV(q) / (FAIXA * gSigma0));
        __nv_out = bytesDe(w.x);       // agN0
        fragColor1 = bytesDe(w.y);      // agN1
        return __nv_out;
    }

    if (eng.acPass == 1) {
        // as linhas da camada e as da margem do núcleo, também as que caem fora do buffer (a saída as lê)
        if (any(lessThan(q, int2(0, -ry))) || any(greaterThanEqual(q, gN + int2(0, ry)))) {
            __nv_out = float4(0.0);
            fragColor1 = float4(0.0);
            return __nv_out;
        }
        float3 somaX;
        float3 quadX;
        somas(gW, gSigX, somaX, quadX);
        float3 acc = float3(0.0);
        for (int k = 0; k < gW; k++) {
            int2 p = int2(t.x + k - rx, t.y) + MARGEM;
            float3 v = valores(agN0.read(uint2(p), uint(0)), agN1.read(uint2(p), uint(0))) * FAIXA * gSigma0;
            acc += peso(k - rx, gSigX) * v;
        }
        // normalizado pelo desvio dele: σ0 · √(Σk²) / Σk
        float3 sigH = gSigma0 * sqrt(quadX) / somaX;
        uint2 w = palavras(acc / somaX / (FAIXA * sigH));
        __nv_out = bytesDe(w.x);       // agH0
        fragColor1 = bytesDe(w.y);      // agH1
        return __nv_out;
    }

    if (eng.acPass == 2) {
        if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN))) {
            __nv_out = float4(0.0);
            return __nv_out;
        }
        __nv_out = gravarMascara(mascara(t));
        return __nv_out;
    }

    if (eng.acPass == 3 || eng.acPass == 4) {
        if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN))) {
            __nv_out = float4(0.0);
            return __nv_out;
        }
        __nv_out = gravarMascara(desfocarMascara(t, eng.acPass == 3));
        return __nv_out;
    }

    // ---- 7: a saída ----
    float4 original = inputImg.read(uint2(t), uint(0));
    if (any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN))) {
        __nv_out = original;          // fora da camada do AE
        return __nv_out;
    }

    // a máscara do Blend (a desfocada vem dos passes 2–4)
    float amount = fixo(u.blendAmount) / 100.0;
    bool temMascara = u.matchColorUsing != 0 || int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1;
    float m = 0.0;
    if (temMascara && (amount > 0.0 || u.viewMode == 1)) {
        if (fixo(u.blurMatte) > 0.0) {
            m = lerMascara(agN0.read(uint2(t + MARGEM), uint(0)));
        } else {
            m = mascara(t);
        }
    }
    if (u.viewMode == 1) {
        __nv_out = float4(float3(floor(m * 255.0 + 0.5) / 255.0), 1.0);
        return __nv_out;
    }

    // a convolução vertical
    float3 somaX;
    float3 quadX;
    somas(gW, gSigX, somaX, quadX);
    float3 somaY;
    float3 quadY;
    somas(gH, gSigY, somaY, quadY);
    float3 sigH = gSigma0 * sqrt(quadX) / somaX;
    float3 g = float3(0.0);
    for (int j = 0; j < gH; j++) {
        int y = t.y + j - ry;
        // fora do buffer, até 24 linhas: a linha da moldura (o grão que o AE continua além da camada); mais
        // longe (núcleo enorme encostado na borda), a linha mais perto
        if ((y < 0 || y >= gT.y) && abs(j - ry) > 24) y = clamp(y, 0, gT.y - 1);
        int2 p = int2(t.x, y) + MARGEM;
        float3 w = valores(agH0.read(uint2(p), uint(0)), agH1.read(uint2(p), uint(0))) * FAIXA * sigH;
        g += peso(j - ry, gSigY) * w;
    }
    g /= somaY;

    // a amplitude de cada canal (0x180006ee0 + a Tint de 0x1800073a0)
    float tam = fixo(u.grainSize);
    tam = tam > 0.0 ? tam : 0.001;
    float amp = max(0.0, fixo(u.intensity) * max(tam, 1.0)) * 0.1 * (gEscala * max(gMac, 1.0));
    float3 vec = u.monochromatic ? float3(amp)
        : float3(fixo(u.redIntensity), fixo(u.greenIntensity), fixo(u.blueIntensity)) * amp;
    float3 cor = floor(u.tintColor.rgb * 255.0 + 0.5) / 255.0;
    float soma = cor.r + cor.g + cor.b;
    float3 tinta = soma == 0.0 ? float3(1.0) : cor / (soma / 3.0);
    float qt = fixo(u.tintAmount);
    vec = vec * (qt * tinta / 100.0 + (1.0 - qt / 100.0));
    g *= vec;

    // a curva de cada canal pela imagem (o MultiplierNode)
    float3 o = original.rgb;
    float mid = fixo(u.midpoint);
    float k1 = mid == 0.0 ? 1e30 : 1.0 / mid;
    float k2 = mid == 1.0 ? 1e30 : 1.0 / (1.0 - mid);
    float3 S = fixo(u.shadows) * float3(fixo(u.redShadows), fixo(u.greenShadows), fixo(u.blueShadows));
    float3 M = fixo(u.midtones) * float3(fixo(u.redMidtones), fixo(u.greenMidtones), fixo(u.blueMidtones));
    float3 L = fixo(u.highlights) * float3(fixo(u.redHighlights), fixo(u.greenHighlights), fixo(u.blueHighlights));
    float3 resp;
    for (int c = 0; c < 3; c++) {
        resp[c] = mid > o[c] ? (M[c] - S[c]) * o[c] * k1 + S[c] : (o[c] - mid) * (L[c] - M[c]) * k2 + M[c];
    }
    float3 gg = resp * g;

    // o modo (o BlendNode do plugin)
    float3 r;
    int modo = u.blendingMode;            // 0 Film, 1 Multiply, 2 Add, 3 Screen, 4 Overlay
    if (modo == 0) {
        r = 1.0 - (1.0 - o) * exp(gg);
    } else if (modo == 1) {
        r = exp(gg) * o;
    } else if (modo == 2) {
        r = o + gg;
    } else if (modo == 3) {
        float3 a = mix(1.0 - gg, gg + 1.0, lessThan(gg, float3(0.0)));
        float3 b = mix(1.0 - o, o + 1.0, lessThan(o, float3(0.0)));
        r = 1.0 - b * a;
    } else {
        float3 g5 = gg + 0.5;
        r = mix(g5 * 2.0 * o, 1.0 - (1.0 - g5) * 2.0 * (1.0 - o), greaterThan(o, float3(0.5)));
    }
    r = clamp(r, 0.0, 1.0);

    // Blend with Original: o grão vai em 8 bits para o MatteNode (o AE de 8 bpc)
    if (temMascara && amount > 0.0) {
        r = floor(r * 255.0 + 0.5) / 255.0;
        r = r + (o - r) * m * amount;
    }

    // Preview: o grão só na caixa, com a borda de 2 px
    if (u.viewMode == 0) {
        float2 c = floor(u.previewCenter * float2(gN));
        int cx = clamp(int(c.x), 0, gN.x);
        int cy = clamp(int(c.y), 0, gN.y);
        int lw = int(floor(u.previewWidth + 0.5) * gEscala);
        int lh = int(floor(u.previewHeight + 0.5) * gEscala);
        int x0 = cx - int(float(lw) * 0.5);
        int y0 = cy + int(float(lh) * -0.5);
        int x1 = x0 + lw;
        int y1 = y0 + lh;
        if (q.x < x0 || q.x >= x1 || q.y < y0 || q.y >= y1) {
            __nv_out = original;
            return __nv_out;
        }
        if (u.showBox && (q.x < x0 + 2 || q.x >= x1 - 2 || q.y < y0 + 2 || q.y >= y1 - 2)) {
            r = floor(u.boxColor.rgb * 255.0 + 0.5) / 255.0;
        }
    }
    // Em níveis inteiros, como o AE de 8 bpc (arredonda): o RGBA8 da GPU não arredonda igual em todo aparelho.
    __nv_out = float4(floor(r * 255.0 + 0.5) / 255.0, original.a);
    return __nv_out;
}
