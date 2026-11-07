// ---------------------------------------------------------------------------
// S_Hotspots
// origem : assets/effects/sapphire-hotspots.xml
// id     : nova.effect.shotspots
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_hotspotsParams {
    float blurInput;
    float threshold;
    float4 thresholdAddColor;
    float saturation;
    float brightness;
    int opacity;
    int maskUse;
    float blurMask;
    int invertMask;
};

// --- funcoes auxiliares do efeito
const float LARGURA_MAX = 720.0;     // a maior largura do desfoque, em px do buffer

// Os sliders do Sapphire chegam em ponto fixo 16.16 (medido: o limiar 0,3 é 0,3000031 no AE).
static float fixo(float v) { return floor(v * 65536.0 + 0.5) / 65536.0; }

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (o Blur Input é em px da composição)

static void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
}

/** Espelha o índice na camada repetindo o pixel da borda (abc|cba), quantas voltas forem. */
static int espelhar(int i, int n) {
    // Dentro do quadro o espelho é o próprio índice: sem a divisão inteira, que em todo tap custava caro (0.569.0)
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static int2 naCamada(int2 q) {
    return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y));
}

// ---- o núcleo das três caixas --------------------------------------------------------------
// Largura inteira n -> raios r0 ≥ r1 ≥ r2 que somam n ((n + 2 − i) div 3). A soma das caixas r1 e r2 é um
// trapézio T (contagens); a das três, em d, é Σ T(d − i) com |i| ≤ r0 = S(d + r0) − S(d − r0 − 1), S a soma
// acumulada de T. Tudo em inteiros (exato), dividido no fim por (2r0 + 1)(2r1 + 1)(2r2 + 1).

// Σ T(j) para 0 ≤ j ≤ x (x ≥ 0), com p = r2 ≤ q = r1.
static int somaDoTrapezio(int x, int p, int q) {
    int m = q - p;
    int M = p + q;
    x = min(x, M);
    if (x <= m) return (x + 1) * (2 * p + 1);
    return (m + 1) * (2 * p + 1) + (x - m) * (M + 1) - (x * (x + 1) - m * (m + 1)) / 2;
}

// Σ T(j) para j ≤ x.
static int acumulado(int x, int p, int q) {
    int total = (2 * p + 1) * (2 * q + 1);
    int meio = (total - (2 * p + 1)) / 2;      // os j < 0 (T(0) = 2p + 1)
    if (x >= 0) return meio + somaDoTrapezio(x, p, q);
    return total - (meio + somaDoTrapezio(-x - 1, p, q));       // T é simétrico
}

static float pesoDasCaixas(int d, int n) {
    if (n <= 0) return d == 0 ? 1.0 : 0.0;
    int r0 = (n + 2) / 3;
    int r1 = (n + 1) / 3;
    int r2 = n / 3;
    if (abs(d) > n) return 0.0;
    int c = acumulado(d + r0, r2, r1) - acumulado(d - r0 - 1, r2, r1);
    return float(c) / (float(2 * r0 + 1) * float(2 * r1 + 1) * float(2 * r2 + 1));
}

// ---- 21 bits por canal em dois buffers (do Add Grain) ---------------------------------------
static uint2 palavras(float3 u) {
    uint3 q = uint3(floor(clamp(u, 0.0, 1.0) * 2097151.0 + 0.5));
    return uint2(q.x | (q.y << 21), (q.y >> 11) | (q.z << 10));
}

static float4 bytes(uint w) {
    return float4(float(w & 255u), float((w >> 8) & 255u), float((w >> 16) & 255u), float(w >> 24)) / 255.0;
}

static uint palavra(float4 c) {
    uint4 b = uint4(floor(c * 255.0 + 0.5));
    return b.x | (b.y << 8) | (b.z << 16) | (b.w << 24);
}

static float3 valores(float4 c0, float4 c1) {
    uint a = palavra(c0);
    uint b = palavra(c1);
    return float3(uint3(a & 2097151u, (a >> 21) | ((b & 1023u) << 11), b >> 10)) / 2097151.0;
}

// ---- a fonte e a máscara --------------------------------------------------------------------
// Opacity (medido): Normal (1) trabalha na cor pré-multiplicada; All Opaque (0) e As Premult (2), na cor reta.
static float3 entrada(int2 p) {
    float4 s = inputImg.read(uint2(p), uint(0));
    return u.opacity == 1 ? s.rgb * s.a : s.rgb;
}

static bool temMascara() { return int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1; }

// A camada de máscara no lugar dela na composição: (5R + 8G + 3B)/16 da cor pré-multiplicada, ou o alfa.
static float mascara(int2 p) {
    float4 m = maskImg.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
    float v = u.maskUse == 1 ? m.a : dot(m.rgb * m.a, float3(0.3125, 0.5, 0.1875));
    return u.invertMask ? 1.0 - v : v;
}

static float4 gravarMascara(float m) {
    float a = floor(clamp(m, 0.0, 1.0) * 16777215.0 + 0.5);
    float b0 = floor(a / 65536.0);
    float r = a - b0 * 65536.0;
    float b1 = floor(r / 256.0);
    return float4(b0, b1, r - b1 * 256.0, 255.0) / 255.0;
}

static float lerMascara(float4 v) {
    float3 b = floor(v.rgb * 255.0 + 0.5);
    return (b.x * 65536.0 + b.y * 256.0 + b.z) / 16777215.0;
}

// A largura do desfoque em px do buffer.
static float larguraDaEntrada() { return clamp(fixo(u.blurInput) * gEscala, 0.0, LARGURA_MAX); }
// A da máscara, arredondada (o subpixel 0 da definição: meio para cima).
static int larguraDaMascara() { return int(clamp(floor(fixo(u.blurMask) * gEscala + 0.5), 0.0, LARGURA_MAX)); }

// O desfoque da fonte num eixo: (1 − f)·núcleo(⌊W⌋) + f·núcleo(⌊W⌋ + 1).
static float3 desfoqueEmX(int2 q) {
    float w = larguraDaEntrada();
    int a = int(floor(w));
    float f = w - float(a);
    float3 soma = float3(0.0);
    for (int d = -a - 1; d <= a + 1; d++) {
        float k = (1.0 - f) * pesoDasCaixas(d, a) + f * pesoDasCaixas(d, a + 1);
        if (k == 0.0) continue;
        soma += k * entrada(naCamada(q + int2(d, 0)));
    }
    return soma;
}

static float3 desfoqueEmY(int2 q) {
    float w = larguraDaEntrada();
    int a = int(floor(w));
    float f = w - float(a);
    float3 soma = float3(0.0);
    for (int d = -a - 1; d <= a + 1; d++) {
        float k = (1.0 - f) * pesoDasCaixas(d, a) + f * pesoDasCaixas(d, a + 1);
        if (k == 0.0) continue;
        int2 p = naCamada(q + int2(0, d));
        soma += k * valores(hA.read(uint2(p), uint(0)), hB.read(uint2(p), uint(0)));
    }
    return soma;
}

static float mascaraDesfocada(int2 q, bool emX) {
    int n = larguraDaMascara();
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k == 0.0) continue;
        int2 p = naCamada(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += k * (emX ? mascara(p) : lerMascara(mH.read(uint2(p), uint(0))));
    }
    return soma;
}

fragment float4 fx_sapphire_hotspots(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_hotspotsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hA [[texture(1)]],
    texture2d<float> hB [[texture(2)]],
    texture2d<float> mH [[texture(3)]],
    texture2d<float> maskImg [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) {
        __nv_out = fora ? float4(0.0) : bytes(palavras(desfoqueEmX(q)).x);
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = fora ? float4(0.0) : bytes(palavras(desfoqueEmX(q)).y);
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = (fora || !temMascara()) ? float4(0.0) : gravarMascara(mascaraDesfocada(q, true));
        return __nv_out;
    }

    // ---- 3: o resto ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) {
        __nv_out = s;
        return __nv_out;
    }
    float3 x = larguraDaEntrada() > 0.0 ? desfoqueEmY(q) : entrada(t);

    // hotspots (0x180fa6320): a cor vezes Σ max(c − th, 0) / Σ max(c, 0)
    float3 th = fixo(u.threshold) + floor(u.thresholdAddColor.rgb * 255.0 + 0.5) / 255.0;
    float b = fixo(u.brightness) / max(0.01, 1.0 - min(th.r, min(th.g, th.b)));
    float3 passa = max(x - th, float3(0.0));
    float3 pos = max(x, float3(0.0));
    float e = passa.r + passa.g + passa.b;
    float sm = pos.r + pos.g + pos.b;
    float3 h = (e > 0.0 && sm > 0.0) ? x * (e / sm) : float3(0.0);

    // sat_scale (0x180f16c20)
    float3 c = b * h;
    float sat = fixo(u.saturation);
    float luma = (0.1875 * c.b + 0.5 * c.g) + 0.3125 * c.r;      // na ordem do plugin
    float3 r = clamp(c * sat + luma * (1.0 - sat), 0.0, 1.0);

    float a = s.a;
    if (u.opacity == 0) a = 1.0;                 // All Opaque: sai opaco
    else if (u.opacity == 2) r *= a;             // As Premult: o resultado volta reto (em pré-multiplicado, r · alfa)

    if (temMascara()) {
        float m = larguraDaMascara() > 0 ? mascaraDesfocada(q, false) : mascara(t);
        float3 sp = s.rgb * s.a;
        r = sp + (r - sp) * m;
        a = s.a;
    }

    float3 reta = a > 0.0 ? min(r / a, float3(1.0)) : float3(0.0);
    // a saída em níveis inteiros, arredondada como o AE de 8 bpc (a da GPU não arredonda igual)
    __nv_out = float4(floor(reta * 255.0 + 0.5) / 255.0, a);
    return __nv_out;
}
