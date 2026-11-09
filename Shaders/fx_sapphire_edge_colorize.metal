// ---------------------------------------------------------------------------
// S_EdgeColorize
// origem : assets/effects/sapphire-edge-colorize.xml
// id     : nova.effect.sedgecolorize
// passes : 5
// gerado por glsl2msl.py e consertado a mao no iOS (fix_msl.py): globais passados as funcoes
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaGLSLCompat.h"
using namespace metal;

struct sapphire_edge_colorizeParams {
    float edgeSmooth;
    int subpixelSmooth;
    float brightness;
    float rotateColors;
    float4 background;
    float4 top;
    float4 right;
    float4 bottom;
    float4 left;
    int opacity;
    int maskUse;
    float blurMask;
    int invertMask;
};

// --- funcoes auxiliares do efeito
constant float GIRO = 1.0;          // o sentido do Rotate Colors (medido)

constant float LARGURA_MAX = 720.0;     // a maior largura do desfoque, em px do buffer

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (Blur Matte é em px da composição)
bool gDePe;        // cena de pé (camada de ajuste, grupo solto): a linha 0 do buffer é a base da imagem

static void preparar(constant EngineUniforms& eng, texture2d<float> inputImg) {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    gDePe = eng.acEntradaDePe == 1;
}

/** Espelha o índice na camada repetindo o pixel da borda (abc|cba), quantas voltas forem. */
static int espelhar(int i, int n) {
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static int2 naCamada(int2 q) {
    return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y));
}

// ---- o núcleo das três caixas (o do S_Hotspots e do S_HalfTone) -------------------------------
// Largura inteira n -> raios r0 ≥ r1 ≥ r2 que somam n ((n + 2 − i) div 3); a soma das três caixas em d, em
// inteiros (exata), dividida no fim por (2r0 + 1)(2r1 + 1)(2r2 + 1).
static int somaDoTrapezio(int x, int p, int q) {
    int m = q - p;
    int M = p + q;
    x = min(x, M);
    if (x <= m) return (x + 1) * (2 * p + 1);
    return (m + 1) * (2 * p + 1) + (x - m) * (M + 1) - (x * (x + 1) - m * (m + 1)) / 2;
}

static int acumulado(int x, int p, int q) {
    int total = (2 * p + 1) * (2 * q + 1);
    int meio = (total - (2 * p + 1)) / 2;
    if (x >= 0) return meio + somaDoTrapezio(x, p, q);
    return total - (meio + somaDoTrapezio(-x - 1, p, q));
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

// Um valor de 0..1 em 24 bits num texel RGBA8.
static float4 gravar24(float m) {
    float a = floor(clamp(m, 0.0, 1.0) * 16777215.0 + 0.5);
    float b0 = floor(a / 65536.0);
    float r = a - b0 * 65536.0;
    float b1 = floor(r / 256.0);
    return float4(b0, b1, r - b1 * 256.0, 255.0) / 255.0;
}

static float ler24(float4 v) {
    float3 b = floor(v.rgb * 255.0 + 0.5);
    return (b.x * 65536.0 + b.y * 256.0 + b.z) / 16777215.0;
}

// ---- a máscara (PROCESS_MASKS: a mesma do S_HalfTone e do S_Emboss) ---------------------------
static bool temMascara(texture2d<float> maskImg) { return int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1; }

static float mascara(int2 p, constant sapphire_edge_colorizeParams& u, sampler __nv_smp, texture2d<float> maskImg) {
    float4 m = maskImg.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
    float v = u.maskUse == 1 ? m.a : dot(m.rgb * m.a, float3(0.3125, 0.5, 0.1875));
    return u.invertMask ? 1.0 - v : v;
}

// o blur da máscara é sem subpixel (a largura arredonda)
static int larguraDaMascara(constant sapphire_edge_colorizeParams& u) { return int(clamp(floor(u.blurMask * gEscala + 0.5), 0.0, LARGURA_MAX)); }

static float mascaraDesfocadaX(int2 q, constant sapphire_edge_colorizeParams& u, sampler __nv_smp, texture2d<float> maskImg) {
    int n = larguraDaMascara(u);
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k != 0.0) soma += k * mascara(naCamada(q + int2(d, 0)), u, __nv_smp, maskImg);
    }
    return soma;
}

static float mascaraDesfocadaY(int2 q, constant sapphire_edge_colorizeParams& u, texture2d<float> mH) {
    int n = larguraDaMascara(u);
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k != 0.0) soma += k * ler24(mH.read(uint2(naCamada(q + int2(0, d))), uint(0)));
    }
    return soma;
}

/** A máscara no pixel p do buffer (1 sem camada de máscara). */
static float mascaraEm(int2 p, constant sapphire_edge_colorizeParams& u, sampler __nv_smp, texture2d<float> mV, texture2d<float> maskImg) {
    if (!temMascara(maskImg)) return 1.0;
    return larguraDaMascara(u) > 0 ? ler24(mV.read(uint2(p), uint(0))) : mascara(p, u, __nv_smp, maskImg);
}

// ---- a luminância ----------------------------------------------------------------------------
// Medido: Normal (1) faz a conta na cor pré-multiplicada; All Opaque (0) e As Premult (2), na cor reta.
static float3 corDaFonte(float4 s, constant sapphire_edge_colorizeParams& u) { return u.opacity == 1 ? s.rgb * s.a : s.rgb; }

/** monochrome (0x180f26020) da camada. */
static float luma(int2 p, constant sapphire_edge_colorizeParams& u, texture2d<float> inputImg) {
    float3 c = corDaFonte(inputImg.read(uint2(p), uint(0)), u);
    return (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b;
}

/** O edge_smooth da definição: o Edge Smooth do AE chega em px da composição e vira px / (W / 8). */
static float suaveInterno(constant sapphire_edge_colorizeParams& u) { return u.edgeSmooth * gEscala * 8.0 / float(gN.x); }

/** A largura do blur: 0,125 · W · edge_smooth, em px do buffer (= o Edge Smooth em px, na escala da prévia). */
static float larguraDoBlur(constant sapphire_edge_colorizeParams& u) {
    float w = clamp(0.125 * float(gN.x) * suaveInterno(u), 0.0, LARGURA_MAX);
    return u.subpixelSmooth ? w : floor(w + 0.5);
}

/** Subpixel: a largura a + f mistura os núcleos de a e a + 1 (a conta do S_GlowAura). */
static float pesoDoBlur(int d, float w) {
    int a = int(floor(w));
    float f = w - float(a);
    float k = pesoDasCaixas(d, a);
    return f > 0.0 ? k + (pesoDasCaixas(d, a + 1) - k) * f : k;
}

static float lumaDesfocadaX(int2 q, constant sapphire_edge_colorizeParams& u, texture2d<float> inputImg) {
    float w = larguraDoBlur(u);
    int n = int(ceil(w));
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDoBlur(d, w);
        if (k != 0.0) soma += k * luma(naCamada(q + int2(d, 0)), u, inputImg);
    }
    return soma;
}

static float lumaDesfocadaY(int2 q, constant sapphire_edge_colorizeParams& u, texture2d<float> bX) {
    float w = larguraDoBlur(u);
    int n = int(ceil(w));
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDoBlur(d, w);
        if (k != 0.0) soma += k * ler24(bX.read(uint2(naCamada(q + int2(0, d))), uint(0)));
    }
    return soma;
}

/** p na coluna x e na linha (da IMAGEM: 0 é o topo) da camada. */
static float altura(int x, int linha, constant sapphire_edge_colorizeParams& u, texture2d<float> inputImg, texture2d<float> bY) {
    int y = gDePe ? gN.y - 1 - linha : linha;
    int2 p = gInicio + int2(x, y);
    return larguraDoBlur(u) > 0.0 ? ler24(bY.read(uint2(p), uint(0))) : luma(p, u, inputImg);
}

// ---- o grad (o do S_DistortChroma e do S_Emboss) ----------------------------------------------
/** Diferença central sem dividir por 2; na borda, um lado só vezes 2; y = a linha de cima menos a de baixo. */
static float2 gradiente(int2 q, constant sapphire_edge_colorizeParams& u, texture2d<float> inputImg, texture2d<float> bY) {
    int x = q.x;
    int linha = gDePe ? gN.y - 1 - q.y : q.y;
    float gx, gy;
    if (gN.x < 2) gx = 0.0;
    else if (x == 0) gx = (altura(1, linha, u, inputImg, bY) - altura(0, linha, u, inputImg, bY)) * 2.0;
    else if (x == gN.x - 1) gx = (altura(x, linha, u, inputImg, bY) - altura(x - 1, linha, u, inputImg, bY)) * 2.0;
    else gx = altura(x + 1, linha, u, inputImg, bY) - altura(x - 1, linha, u, inputImg, bY);
    if (gN.y < 2) gy = 0.0;
    else if (linha == 0) gy = (altura(x, 0, u, inputImg, bY) - altura(x, 1, u, inputImg, bY)) * 2.0;
    else if (linha == gN.y - 1) gy = (altura(x, linha - 1, u, inputImg, bY) - altura(x, linha, u, inputImg, bY)) * 2.0;
    else gy = altura(x, linha - 1, u, inputImg, bY) - altura(x, linha + 1, u, inputImg, bY);
    return float2(gx, gy);
}

static float3 cor8(float4 c) { return floor(c.rgb * 255.0 + 0.5) / 255.0; }

fragment float4 fx_sapphire_edge_colorize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_edge_colorizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mH [[texture(1)]],
    texture2d<float> mV [[texture(2)]],
    texture2d<float> bX [[texture(3)]],
    texture2d<float> bY [[texture(4)]],
    texture2d<float> maskImg [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar(eng, inputImg);
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) { __nv_out = (fora || !temMascara(maskImg)) ? float4(0.0) : gravar24(mascaraDesfocadaX(q, u, __nv_smp, maskImg)); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = (fora || !temMascara(maskImg)) ? float4(0.0) : gravar24(mascaraDesfocadaY(q, u, mH)); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = fora ? float4(0.0) : gravar24(lumaDesfocadaX(q, u, inputImg)); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = fora ? float4(0.0) : gravar24(lumaDesfocadaY(q, u, bX)); return __nv_out; }

    // ---- 4: o gradiente e as cores ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = s; return __nv_out; }

    float2 g = gradiente(q, u, inputImg, bY) * (0.05 * float(gN.x) * u.brightness * (suaveInterno(u) + 0.1));
    float ang = radians(GIRO * u.rotateColors);
    float c = cos(ang), sn = sin(ang);
    g = float2(g.x * c - g.y * sn, g.x * sn + g.y * c);
    // Medido: as cores valem em 8 bits.
    float3 fundo = cor8(u.background);
    float3 cx = g.x > 0.0 ? cor8(u.left) : cor8(u.right);
    float3 cy = g.y > 0.0 ? cor8(u.bottom) : cor8(u.top);
    float3 cor = fundo + (cx - fundo) * abs(g.x) + (cy - fundo) * abs(g.y);

    // Medido: a máscara mistura ANTES de prender (o dissolve do Autogen roda no efeito; o Opacity, depois, no AE),
    // com a Fonte na cor do Opacity (pré-multiplicada no Normal, reta nos outros dois).
    if (temMascara(maskImg)) cor = mix(corDaFonte(s, u), cor, mascaraEm(t, u, __nv_smp, mV, maskImg));

    // Opacity: Normal toma o resultado como JÁ pré-multiplicado, limitado ao alfa; As Premult, como cor reta com o alfa
    // da fonte; All Opaque sai opaco.
    float a;
    float3 r;
    if (u.opacity == 0) { a = 1.0; r = clamp(cor, 0.0, 1.0); }
    else if (u.opacity == 1) { a = s.a; r = clamp(cor, float3(0.0), float3(a)); }
    else { a = s.a; r = clamp(cor, 0.0, 1.0) * a; }

    float3 reta = a > 0.0 ? min(r / a, float3(1.0)) : float3(0.0);
    // a saída em níveis inteiros, arredondada como o AE de 8 bpc (a da GPU não arredonda igual)
    __nv_out = float4(floor(reta * 255.0 + 0.5) / 255.0, a);
    return __nv_out;
}
