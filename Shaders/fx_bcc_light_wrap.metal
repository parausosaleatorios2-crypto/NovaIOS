// ---------------------------------------------------------------------------
// BCC Light Wrap
// origem : assets/effects/bcc-light-wrap.xml
// id     : nova.effect.bcclightwrap
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_light_wrapParams {
    int view;
    float lightness;
    float softness;
    float width;
    int applyMode;
    float mixWithOriginal;
};

// --- funcoes auxiliares do efeito
const float RAIO_MAX = 1000.0;     // o maior raio dos desfoques, em px do buffer

// ---- a camada do AE no buffer --------------------------------------------------------------
int2 gT;          // o buffer
int2 gN;          // a camada do AE dentro dele, em px
int2 gInicio;     // o canto da camada no buffer
float gEscala;     // a prévia reduzida (Width e Softness são em px da composição)

static void preparar() {
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gN = clamp(int2(floor(max(eng.acCamada, float2(0.001)) * float2(gT) + 0.5)), int2(1), gT);
    gInicio = (gT - gN) / 2;
    gEscala = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
}

static int2 naCamada(int2 q) {
    return gInicio + clamp(q, int2(0), gN - int2(1));     // borda repetida
}

static int4 bytes4(float4 c) { return int4(floor(c * 255.0 + 0.5)); }
static float4 cor4(int4 b) { return float4(b) / 255.0; }

static bool temFundo() { return int2(int(bgImg.get_width()), int(bgImg.get_height())).x > 1; }

// O fundo no lugar dele na composição, em bytes (cor reta).
static int4 fundo(int2 q) {
    return bytes4(bgImg.sample(__nv_smp, (float2(naCamada(q)) + 0.5) / float2(gT)));
}

static int mascara(int2 q) { return 255 - bytes4(inputImg.read(uint2(naCamada(q)), uint(0))).a; }

// ---- a caixa do BCC: raio r, ponta fracionária com peso = fração, total 2r + 1 ----------------
static float raioDoFundo() { return min(u.softness * gEscala, RAIO_MAX); }
static float raioDaMascara() { return min(u.width * gEscala, RAIO_MAX); }

static int4 fundoEmX(int2 q) {
    float r = raioDoFundo();
    if (!(u.softness > 0.1)) return fundo(q);
    int n = int(floor(r));
    float f = r - float(n);
    float4 soma = float4(0.0);
    for (int d = -n - 1; d <= n + 1; d++) {
        float w = abs(d) <= n ? 1.0 : f;
        if (w == 0.0) continue;
        soma += w * float4(fundo(q + int2(d, 0)));
    }
    return int4(floor(soma / (2.0 * r + 1.0) + 0.5));
}

static int4 fundoEmY(int2 q) {
    if (!(u.softness > 0.1)) return fundo(q);
    float r = raioDoFundo();
    int n = int(floor(r));
    float f = r - float(n);
    float4 soma = float4(0.0);
    for (int d = -n - 1; d <= n + 1; d++) {
        float w = abs(d) <= n ? 1.0 : f;
        if (w == 0.0) continue;
        soma += w * float4(bytes4(bX.read(uint2(naCamada(q + int2(0, d))), uint(0))));
    }
    return int4(floor(soma / (2.0 * r + 1.0) + 0.5));
}

static int mascaraEm(int2 q, bool emX) {
    float r = raioDaMascara();
    if (r < 0.05) return emX ? mascara(q) : bytes4(mX.read(uint2(naCamada(q)), uint(0))).r;
    int n = int(floor(r));
    float f = r - float(n);
    float soma = 0.0;
    for (int d = -n - 1; d <= n + 1; d++) {
        float w = abs(d) <= n ? 1.0 : f;
        if (w == 0.0) continue;
        soma += w * (emX ? float(mascara(q + int2(d, 0))) : float(bytes4(mX.read(uint2(naCamada(q + int2(0, d))), uint(0))).r));
    }
    return int(floor(soma / (2.0 * r + 1.0) + 0.5));
}

// ---- contas de 8 bits do plugin ---------------------------------------------------------------
static int div255(int t) { t += 128; return (t + (t >> 8)) >> 8; }          // m·a/255 arredondado
static int truncDiv(int a, int b) { int q = abs(a) / b; return a < 0 ? -q : q; }   // divisão truncada (b > 0)
static int luma(int3 c) { return (c.r * 77 + c.g * 150 + c.b * 29) >> 8; }

static int3 ajustaLuma(int3 d, int lq) {
    int l2 = (d.r * 77 + d.g * 150 + d.b * 29) >> 8;
    return clamp(d + int3(lq - l2), int3(0), int3(255));
}

// 0x180425fe0: o croma de P com a luma de Q.
static int3 setLum(int3 P, int3 Q) {
    int lp = luma(P), lq = luma(Q);
    int3 d = P - int3(lp);
    float s = 1.0;
    for (int i = 0; i < 3; i++) {
        float si = 1.0;
        if (d[i] + lq > 255) si = float(255 - lq) / float(d[i]);
        else if (d[i] + lq < 0) si = float(-lq) / float(d[i]);
        s = min(s, si);
    }
    if (s < 1.0) d = int3(trunc(s * float3(d)));
    return ajustaLuma(d, lq);
}

static int amplitude(int3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }

// Hue e Saturation: o croma D escalado pela razão (limitada com 256 − luma) e a luma lq.
static int3 setSat(int3 D, int lq, float razao) {
    float r = razao;
    if (r > 1.0) {
        for (int i = 0; i < 3; i++) {
            if (D[i] == 0) continue;
            float inv = 1.0 / float(D[i]);
            float lim = D[i] > 0 ? (256.0 - float(lq)) * inv : -(inv * float(lq));
            r = min(r, lim);
        }
    }
    return ajustaLuma(int3(trunc(float3(D) * r)), lq);
}

static int3 matiz(int3 P, int3 Q) {           // 0x1804261c0: P = o wrap, Q = a camada
    int lq = luma(Q), sp = amplitude(P), sq = amplitude(Q);
    if (sp == 0) return int3(lq);
    return setSat(P - int3(luma(P)), lq, float(sq) / float(sp));
}

static int3 saturacao(int3 P, int3 Q) {       // 0x180426450: P = o wrap, Q = a camada
    int lq = luma(Q), sp = amplitude(P), sq = amplitude(Q);
    if (sq == 0) return Q;
    return setSat(Q - int3(lq), lq, float(sp) / float(sq));
}

static int luzDura(int B, int A) {               // 0x1804273f0: B = a camada, A = o wrap
    if (A > 128) {
        int s = 255 - ((((255 - B) * (255 - A)) * 0x8081) >> 23);
        return truncDiv((s - B) * (A - 128), 127) + B;
    }
    int u = ((B * A) >> 8) - B;
    return truncDiv(u * (128 - A), 128) + B;
}

// 0x18042a480: a = o wrap, b = a camada (os dois em bytes). Devolve a cor e se a camada inteira foi escolhida.
static int3 modo(int m, int3 a, int3 b, out bool pegaB) {
    pegaB = false;
    if (m == 0) return max(a, b);                                          // Lighten
    if (m == 1) return min(a, b);                                          // Darken
    if (m == 2) return int3(a.r == 255 ? b.r : (b.r * a.r) >> 8, a.g == 255 ? b.g : (b.g * a.g) >> 8,
                             a.b == 255 ? b.b : (b.b * a.b) >> 8);         // Multiply
    if (m == 3) return int3(255) - ((((int3(0x80007f) - b * 0x8081) * (int3(255) - a)) >> 23) & 255);   // Screen
    if (m == 4) return abs(a - b);                                         // Difference
    if (m == 5 || m == 23) {                                               // Lighter (e o Boost Eq Power −, medido)
        pegaB = (b.r * 77 + b.g * 150 + b.b * 29) > (a.r * 77 + a.g * 150 + a.b * 29);
        return pegaB ? b : a;
    }
    if (m == 6) {                                                          // Darker
        pegaB = (b.r * 77 + b.g * 150 + b.b * 29) < (a.r * 77 + a.g * 150 + a.b * 29);
        return pegaB ? b : a;
    }
    if (m == 7) return min(int3(255), (b * a) >> 6);                      // Scale Multiply
    if (m == 8) return int3(255) - min(int3(255), (((int3(255) - b) * (int3(255) - a)) * 0x8081) >> 22);   // Scale Screen
    if (m == 9) return min(int3(255), abs(2 * (b - a)));                  // Difference X 2
    if (m == 10) return min(int3(255), abs(4 * (b - a)));                 // Difference X 4
    if (m == 11) return min(int3(255), a + b);                            // Add
    if (m == 12) return (a - b) & 255;                                     // Subtract (com a volta do byte)
    if (m == 13) {                                                         // Overlay
        int3 r;
        for (int i = 0; i < 3; i++) r[i] = b[i] < 128 ? (b[i] * a[i]) >> 7 : 255 - (((255 - b[i]) * (255 - a[i])) >> 7);
        return r;
    }
    if (m == 14) return ((((a - int3(128)) * (int3(255) - b) * b) >> 15) + b) & 255;   // Soft Light
    if (m == 15) return int3(luzDura(b.r, a.r), luzDura(b.g, a.g), luzDura(b.b, a.b)); // Hard Light
    if (m == 16) return matiz(a, b);                                       // Hue
    if (m == 17) return saturacao(a, b);                                   // Saturation
    if (m == 18) return setLum(a, b);                                      // Color
    if (m == 19) return setLum(b, a);                                      // Lightness
    if (m == 24) {                                                         // Boost Bias: o mais próximo (Lighter)
        pegaB = (b.r * 77 + b.g * 150 + b.b * 29) > (a.r * 77 + a.g * 150 + a.b * 29);
        return pegaB ? b : a;
    }
    if (m == 25) return int3(a.r == 255 ? b.r : (b.r * a.r) >> 8, a.g == 255 ? b.g : (b.g * a.g) >> 8,
                              a.b == 255 ? b.b : (b.b * a.b) >> 8);        // 50 50 Mix: o mais próximo (Multiply)
    return a;                                                              // 21, 22 (medido) e 23: Normal
}

// 0x180426d00: Y sobre X em 8 bits.
static int4 sobre(int4 X, int4 Y) {
    if (Y.a == 0) return X;
    if (Y.a == 255 || X.a == 0) return Y;
    if (X.a == 255) return int4(X.rgb + (((Y.rgb - X.rgb) * Y.a) >> 8), 255);
    int k = ((255 - Y.a) * X.a) >> 8;
    int ao = Y.a + k;
    int inv = 0x10000 / ao;
    return int4(((Y.rgb * Y.a + X.rgb * k) * inv) >> 16, ao);
}

// 0x1804283b0: M = o resultado do modo, X = o wrap, Y = a camada. Só a cor (o alfa sai o da camada).
static int3 compor(int4 M, int4 X, int4 Y) {
    if (X.a == 0) return Y.rgb;
    if (Y.a == 0) return X.rgb;
    if (Y.a == 255) return X.a == 255 ? M.rgb : (Y.rgb + (((M.rgb - Y.rgb) * X.a) >> 8)) & 255;
    int4 o68 = sobre(Y, int4(M.rgb, X.a));
    if (X.a > Y.a) {
        int4 o20 = sobre(Y, X);
        int f = int(trunc(float(abs(Y.a - X.a)) * 255.0 / float(X.a)));
        return (o68.rgb + (((o20.rgb - o68.rgb) * f) >> 8)) & 255;
    }
    return o68.rgb;
}

fragment float4 fx_bcc_light_wrap(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_light_wrapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> bX [[texture(1)]],
    texture2d<float> mX [[texture(2)]],
    texture2d<float> bgImg [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    preparar();
    int2 t = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, gN));

    if (eng.acPass == 0) {
        __nv_out = (fora || !temFundo()) ? float4(0.0) : cor4(fundoEmX(q));
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = (fora || !temFundo()) ? float4(0.0) : float4(float(mascaraEm(q, true)) / 255.0, 0.0, 0.0, 1.0);
        return __nv_out;
    }

    // ---- 2: o resto ----
    float4 s = inputImg.read(uint2(t), uint(0));
    if (fora || !temFundo()) {          // sem fundo o BCC desenha um aviso de erro; aqui a camada passa como está
        __nv_out = s;
        return __nv_out;
    }
    int4 A = bytes4(s);               // a camada (cor reta)
    int4 B = fundoEmY(q);             // o fundo desfocado

    // Lightness (0x1809fe9a0): o valor chega ao renderer como float(double(float(L·100))·0,01)
    float L = u.lightness;
    if (abs(L) > 0.01) {
        int k = int(65536.0 - abs(L) * 32768.0);
        if (L < 0.0) B.rgb = (B.rgb * k + 0x8000) >> 16;
        else B.rgb = int3(255) - (((int3(255) - B.rgb) * k + 0x8000) >> 16);
    }

    int m = mascaraEm(q, false);
    B.a = div255(m * B.a);             // o wrap

    int4 R;
    if (u.view == 0) {
        bool pegaB;
        int3 c = modo(u.applyMode, B.rgb, A.rgb, pegaB);
        int4 M = pegaB ? A : int4(c, B.a);
        R = int4(compor(M, B, A), A.a);
    } else {
        int a = min(B.a, A.a);
        R = int4(B.rgb, a);
        if (u.view == 2) {
            R.rgb = a == 0 ? int3(0) : (a < 255 ? int3(div255(R.r * a), div255(R.g * a), div255(R.b * a)) : R.rgb);
            R.a = 255;
        }
    }

    // Mix with Original (BlendFramesRenderer, 0x1804098d0): pesos em 1/1024 na cor pré-multiplicada (não medido)
    if (u.mixWithOriginal > 0.1) {
        int w = int((u.mixWithOriginal / 100.0) * 1024.0);
        int3 pr = int3(div255(R.r * R.a), div255(R.g * R.a), div255(R.b * R.a));
        int3 po = int3(div255(A.r * A.a), div255(A.g * A.a), div255(A.b * A.a));
        int ao = (A.a * w + R.a * (1024 - w)) >> 10;
        int3 pc = (po * w + pr * (1024 - w)) >> 10;
        R = int4(ao > 0 ? min(int3(255), (pc * 255 + ao / 2) / ao) : int3(0), ao);
    }
    __nv_out = cor4(R);
    return __nv_out;
}
