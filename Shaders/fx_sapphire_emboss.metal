// ---------------------------------------------------------------------------
// S_Emboss
// origem : assets/effects/sapphire-emboss.xml
// id     : nova.effect.semboss
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_embossParams {
    float2 lightDir;
    float brightness;
    float4 lightColor;
    float bumpsScale;
    float bumpsThreshold;
    float bumpsSmooth;
    int subpixelSmooth;
    int opacity;
    float blurMask;
    int invertMask;
    int maskUse;
};

// --- funcoes auxiliares do efeito
const float LARGURA_MAX = 720.0;     // a maior largura do desfoque, em px do buffer

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (Blur Matte é em px da composição)
bool gDePe;        // cena de pé (camada de ajuste, grupo solto): a linha 0 do buffer é a base da imagem

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    gDePe = eng.acEntradaDePe == 1;
}

/** Espelha o índice na camada repetindo o pixel da borda (abc|cba), quantas voltas forem. */
int espelhar(int i, int n) {
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

int2 naCamada(int2 q) {
    return gInicio + int2(espelhar(q.x, gN.x), espelhar(q.y, gN.y));
}

// ---- o núcleo das três caixas (o do S_Hotspots e do S_HalfTone) -------------------------------
// Largura inteira n -> raios r0 ≥ r1 ≥ r2 que somam n ((n + 2 − i) div 3); a soma das três caixas em d, em
// inteiros (exata), dividida no fim por (2r0 + 1)(2r1 + 1)(2r2 + 1).
int somaDoTrapezio(int x, int p, int q) {
    int m = q - p;
    int M = p + q;
    x = min(x, M);
    if (x <= m) return (x + 1) * (2 * p + 1);
    return (m + 1) * (2 * p + 1) + (x - m) * (M + 1) - (x * (x + 1) - m * (m + 1)) / 2;
}

int acumulado(int x, int p, int q) {
    int total = (2 * p + 1) * (2 * q + 1);
    int meio = (total - (2 * p + 1)) / 2;
    if (x >= 0) return meio + somaDoTrapezio(x, p, q);
    return total - (meio + somaDoTrapezio(-x - 1, p, q));
}

float pesoDasCaixas(int d, int n) {
    if (n <= 0) return d == 0 ? 1.0 : 0.0;
    int r0 = (n + 2) / 3;
    int r1 = (n + 1) / 3;
    int r2 = n / 3;
    if (abs(d) > n) return 0.0;
    int c = acumulado(d + r0, r2, r1) - acumulado(d - r0 - 1, r2, r1);
    return float(c) / (float(2 * r0 + 1) * float(2 * r1 + 1) * float(2 * r2 + 1));
}

// Um valor de 0..1 em 24 bits num texel RGBA8.
float4 gravar24(float m) {
    float a = floor(clamp(m, 0.0, 1.0) * 16777215.0 + 0.5);
    float b0 = floor(a / 65536.0);
    float r = a - b0 * 65536.0;
    float b1 = floor(r / 256.0);
    return float4(b0, b1, r - b1 * 256.0, 255.0) / 255.0;
}

float ler24(float4 v) {
    float3 b = floor(v.rgb * 255.0 + 0.5);
    return (b.x * 65536.0 + b.y * 256.0 + b.z) / 16777215.0;
}

// ---- a matte ---------------------------------------------------------------------------------
bool temMascara() { return int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1; }

float mascara(int2 p) {
    float4 m = maskImg.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
    float v = u.maskUse == 1 ? m.a : dot(m.rgb * m.a, float3(0.3125, 0.5, 0.1875));
    return u.invertMask ? 1.0 - v : v;
}

int larguraDaMascara() { return int(clamp(floor(u.blurMask * gEscala + 0.5), 0.0, LARGURA_MAX)); }

float mascaraDesfocadaX(int2 q) {
    int n = larguraDaMascara();
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k != 0.0) soma += k * mascara(naCamada(q + int2(d, 0)));
    }
    return soma;
}

float mascaraDesfocadaY(int2 q) {
    int n = larguraDaMascara();
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k != 0.0) soma += k * ler24(mH.read(uint2(naCamada(q + int2(0, d))), uint(0)));
    }
    return soma;
}

/** A matte no pixel p do buffer (1 sem camada de matte). */
float matte(int2 p) {
    if (!temMascara()) return 1.0;
    return larguraDaMascara() > 0 ? ler24(mV.read(uint2(p), uint(0))) : mascara(p);
}

// ---- os bumps --------------------------------------------------------------------------------
bool temBumps() { return int2(int(bumpsImg.get_width()), int(bumpsImg.get_height())).x > 1; }

// Medido: Normal (1) faz a conta na cor pré-multiplicada; All Opaque (0) e As Premult (2), na cor reta.
float3 corDaFonte(float4 s) { return u.opacity == 1 ? s.rgb * s.a : s.rgb; }

/** monochrome (0x180f26020) dos Bumps, vezes a matte, menos o limiar. */
float bumpsCrus(int2 p) {
    float3 c;
    if (temBumps()) {
        float4 b = bumpsImg.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
        c = b.rgb * b.a;
    } else {
        c = corDaFonte(inputImg.read(uint2(p), uint(0)));
    }
    float m = (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b;
    if (u.bumpsThreshold != 0.0) m = max(0.0, m - u.bumpsThreshold);
    return matte(p) * m;
}

/** O bumps_smooth da definição: o Bumps Smooth do AE chega em px da composição e vira px / (W / 8). */
float suaveInterno() { return u.bumpsSmooth * gEscala * 8.0 / float(gN.x); }

/** A largura do blur: 0,125 · W · bumps_smooth, em px do buffer (= o Bumps Smooth em px, na escala da prévia). */
float larguraDosBumps() {
    float w = clamp(0.125 * float(gN.x) * suaveInterno(), 0.0, LARGURA_MAX);
    return u.subpixelSmooth ? w : floor(w + 0.5);
}

/** Subpixel: a largura a + f mistura os núcleos de a e a + 1 (a conta do S_GlowAura). */
float pesoDoBlur(int d, float w) {
    int a = int(floor(w));
    float f = w - float(a);
    float k = pesoDasCaixas(d, a);
    return f > 0.0 ? k + (pesoDasCaixas(d, a + 1) - k) * f : k;
}

float bumpsDesfocadosX(int2 q) {
    float w = larguraDosBumps();
    int n = int(ceil(w));
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDoBlur(d, w);
        if (k != 0.0) soma += k * bumpsCrus(naCamada(q + int2(d, 0)));
    }
    return soma;
}

float bumpsDesfocadosY(int2 q) {
    float w = larguraDosBumps();
    int n = int(ceil(w));
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDoBlur(d, w);
        if (k != 0.0) soma += k * ler24(bX.read(uint2(naCamada(q + int2(0, d))), uint(0)));
    }
    return soma;
}

/** p na coluna x e na linha (da IMAGEM: 0 é o topo) da camada. */
float altura(int x, int linha) {
    int y = gDePe ? gN.y - 1 - linha : linha;
    int2 p = gInicio + int2(x, y);
    return larguraDosBumps() > 0.0 ? ler24(bY.read(uint2(p), uint(0))) : bumpsCrus(p);
}

// ---- a luz -----------------------------------------------------------------------------------
/** O Light Dir XY (fração da camada, y para baixo) visto do centro, no xy do Sapphire: −1..1 na largura, y para cima. */
float2 direcaoDaLuz() {
    return float2((u.lightDir.x - 0.5) * 2.0, (0.5 - u.lightDir.y) * 2.0 * float(gN.y) / float(gN.x));
}

/** grad_in_direction (o lambda 0x180b721a0): diferença central sem dividir por 2; na borda, um lado só vezes 2. */
float gradienteNaDirecao(int2 q, float2 D) {
    int x = q.x;
    int linha = gDePe ? gN.y - 1 - q.y : q.y;
    float gx, gy;
    if (gN.x < 2) gx = 0.0;
    else if (x == 0) gx = (altura(1, linha) - altura(0, linha)) * 2.0;
    else if (x == gN.x - 1) gx = (altura(x, linha) - altura(x - 1, linha)) * 2.0;
    else gx = altura(x + 1, linha) - altura(x - 1, linha);
    if (gN.y < 2) gy = 0.0;
    else if (linha == 0) gy = (altura(x, 0) - altura(x, 1)) * 2.0;
    else if (linha == gN.y - 1) gy = (altura(x, linha - 1) - altura(x, linha)) * 2.0;
    else gy = altura(x, linha - 1) - altura(x, linha + 1);
    return gx * D.x + gy * D.y;
}

fragment float4 fx_sapphire_emboss(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_embossParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mH [[texture(1)]],
    texture2d<float> mV [[texture(2)]],
    texture2d<float> bX [[texture(3)]],
    texture2d<float> bY [[texture(4)]],
    texture2d<float> bumpsImg [[texture(5)]],
    texture2d<float> maskImg [[texture(6)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) { __nv_out = (fora || !temMascara()) ? float4(0.0) : gravar24(mascaraDesfocadaX(q)); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = (fora || !temMascara()) ? float4(0.0) : gravar24(mascaraDesfocadaY(q)); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = fora ? float4(0.0) : gravar24(bumpsDesfocadosX(q)); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = fora ? float4(0.0) : gravar24(bumpsDesfocadosY(q)); return __nv_out; }

    // ---- 4: o gradiente e a luz ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = s; return __nv_out; }

    float2 ld = direcaoDaLuz();
    float z = min(1.0 - length(ld), 1.0);
    float2 D = -ld * u.bumpsScale * (suaveInterno() + 0.1) * 0.05 * float(gN.x);
    float g = gradienteNaDirecao(q, D);
    // Medido: as cores valem em 8 bits.
    float3 luz = floor(u.lightColor.rgb * 255.0 + 0.5) / 255.0 * u.brightness;
    float3 cor = corDaFonte(s) * (g + z) * luz;

    // O resultado em pré-multiplicado, com o alfa da saída.
    float a = s.a;
    float3 r;
    if (u.opacity == 0) { a = 1.0; r = clamp(cor, 0.0, 1.0); }      // All Opaque: sai opaco
    else if (u.opacity == 1) r = clamp(cor, float3(0.0), float3(a));     // Normal: a conta já é a pré-multiplicada
    else r = clamp(cor, 0.0, 1.0) * a;                             // As Premult: a cor reta com o alfa da fonte

    if (temMascara()) {
        float m = matte(t);
        float3 sp = s.rgb * s.a;
        r = sp + (r - sp) * m;
        a = s.a;
    }

    float3 reta = a > 0.0 ? min(r / a, float3(1.0)) : float3(0.0);
    // a saída em níveis inteiros, arredondada como o AE de 8 bpc (a da GPU não arredonda igual)
    __nv_out = float4(floor(reta * 255.0 + 0.5) / 255.0, a);
    return __nv_out;
}
