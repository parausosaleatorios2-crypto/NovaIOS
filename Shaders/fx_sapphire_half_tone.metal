// ---------------------------------------------------------------------------
// S_HalfTone
// origem : assets/effects/sapphire-half-tone.xml
// id     : nova.effect.shalftone
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_half_toneParams {
    int dots;
    float dotsFrequency;
    float dotsAngle;
    float dotsRelWidth;
    float dotsSharpness;
    float dotsLighten;
    float smoothSource;
    float4 color1;
    float4 color0;
    float dotsShiftX;
    float dotsShiftY;
    int opacity;
    int maskUse;
    float blurMask;
    int invertMask;
};

// --- funcoes auxiliares do efeito
const float LARGURA_MAX = 720.0;     // a maior largura do desfoque, em px do buffer

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (Smooth Source e Blur Mask são em px da composição)

void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
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

// ---- o núcleo das três caixas (o do S_Hotspots) -----------------------------------------------
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

// ---- a fonte e a máscara --------------------------------------------------------------------
// Medido: Normal (1) faz a conta na cor pré-multiplicada; All Opaque (0) e As Premult (2), na cor reta.
// monochrome (0x180f26020): (0,3125 R + 0,5 G) + 0,1875 B.
float luma(int2 p) {
    float4 s = inputImg.read(uint2(p), uint(0));
    float3 c = u.opacity == 1 ? s.rgb * s.a : s.rgb;
    return (0.3125 * c.r + 0.5 * c.g) + 0.1875 * c.b;
}

bool temMascara() { return int2(int(maskImg.get_width()), int(maskImg.get_height())).x > 1; }

float mascara(int2 p) {
    float4 m = maskImg.sample(__nv_smp, (float2(p) + 0.5) / float2(gT));
    float v = u.maskUse == 1 ? m.a : dot(m.rgb * m.a, float3(0.3125, 0.5, 0.1875));
    return u.invertMask ? 1.0 - v : v;
}

// O subpixel 0 da definição: as larguras arredondam, meio para cima.
int larguraDaFonte() { return int(clamp(floor(u.smoothSource * gEscala + 0.5), 0.0, LARGURA_MAX)); }
int larguraDaMascara() { return int(clamp(floor(u.blurMask * gEscala + 0.5), 0.0, LARGURA_MAX)); }

float lumaDesfocada(int2 q, bool emX) {
    int n = larguraDaFonte();
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k == 0.0) continue;
        int2 p = naCamada(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += k * (emX ? luma(p) : ler24(bX.read(uint2(p), uint(0))));
    }
    return soma;
}

float mascaraDesfocada(int2 q, bool emX) {
    int n = larguraDaMascara();
    float soma = 0.0;
    for (int d = -n; d <= n; d++) {
        float k = pesoDasCaixas(d, n);
        if (k == 0.0) continue;
        int2 p = naCamada(q + (emX ? int2(d, 0) : int2(0, d)));
        soma += k * (emX ? mascara(p) : ler24(mH.read(uint2(p), uint(0))));
    }
    return soma;
}

// ---- a grade ------------------------------------------------------------------------------------
// bounce(v, 1): a dobra em triângulo de período 2 (0..1).
float dobra(float v) {
    float m = __nv_mod(v, 2.0);
    return m > 1.0 ? 2.0 - m : m;
}

float grade(int2 q) {
    // xy do Sapphire: −1..1 na largura da camada, y para cima, no centro do pixel (a cena de pé tem a linha 0 embaixo)
    float W = float(gN.x);
    float linha = eng.acEntradaDePe == 1 ? float(gN.y - 1 - q.y) : float(q.y);
    float2 xy = float2((float(q.x) + 0.5) * 2.0 / W - 1.0, float(gN.y) / W - (linha + 0.5) * 2.0 / W);
    // a definição prende o Rel Width em 0,01 (o AE deixa 0,0099945, o Opium-5 usa)
    float fx = u.dotsFrequency / max(u.dotsRelWidth, 0.01);
    float fy = u.dotsFrequency;
    float2 p = float2(xy.x * fx - u.dotsShiftX, xy.y * fy + u.dotsShiftY);
    // rotate(p, Angle / −360) da DLL, com o ângulo do AE (sinal trocado)
    float t = radians(u.dotsAngle);
    float c = cos(t), s = sin(t);
    float2 r = float2(p.x * c - p.y * s, p.x * s + p.y * c);
    return 0.707 * length(float2(dobra(r.x), dobra(r.y)));
}

fragment float4 fx_sapphire_half_tone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_half_toneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> bX [[texture(1)]],
    texture2d<float> mH [[texture(2)]],
    texture2d<float> maskImg [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) {
        __nv_out = fora ? float4(0.0) : gravar24(lumaDesfocada(q, true));
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = (fora || !temMascara()) ? float4(0.0) : gravar24(mascaraDesfocada(q, true));
        return __nv_out;
    }

    // ---- 2: o resto ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora) {
        __nv_out = s;
        return __nv_out;
    }
    float bw = larguraDaFonte() > 0 ? lumaDesfocada(q, false) : luma(t);
    float g = grade(q);
    if (u.dots == 1) g = 1.0 - g;
    float sh = u.dotsSharpness + 1.0;
    float peso = clamp((g + (-1.0 + (1.0 / sh + 1.0) * (bw + u.dotsLighten))) * sh, 0.0, 1.0);
    // Medido: as cores valem em 8 bits.
    float3 c0 = floor(u.color0.rgb * 255.0 + 0.5) / 255.0, c1 = floor(u.color1.rgb * 255.0 + 0.5) / 255.0;
    float3 cor = c0 + (c1 - c0) * peso;

    // O resultado em pré-multiplicado, com o alfa da saída.
    float a = s.a;
    float3 r;
    if (u.opacity == 0) { a = 1.0; r = cor; }        // All Opaque: sai opaco
    else if (u.opacity == 1) r = min(cor, float3(a));  // Normal: a conta já é a pré-multiplicada (o AE a limita ao alfa)
    else r = cor * a;                              // As Premult: a cor reta com o alfa da fonte

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
