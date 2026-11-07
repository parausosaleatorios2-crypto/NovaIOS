// ---------------------------------------------------------------------------
// CC Lens
// origem : assets/effects/cc-lens.xml
// id     : nova.effect.cclens
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_lensParams {
    float2 center;
    float size;
    float convergence;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 do AE (PF.dll)
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se funde
// com a soma seguinte num fma: cada produto arredonda sozinho, como na SSE do AE.
float um;
int z0;
static float fixa(float x) { return x * um; }
static float3 fixa3(float3 x) { return x * um; }
static float4 fixa4(float4 x) { return x * um; }
static float mul(float a, float b) { return (a * b) * um; }
static float3 mul3(float a, float3 b) { return (a * b) * um; }
static float4 mul4(float4 a, float b) { return (a * b) * um; }

/** a·b = p + e, exato (Dekker). */
static float2 produtoExato(float a, float b) {
    float p = mul(a, b);
    float t = mul(4097.0, a);
    float ah = t - fixa(t - a);
    float al = a - ah;
    t = mul(4097.0, b);
    float bh = t - fixa(t - b);
    float bl = b - bh;
    float e = fixa(fixa(fixa(mul(ah, bh) - p) + mul(ah, bl)) + mul(al, bh)) + mul(al, bl);
    return float2(p, e);
}

static float restoDaDivisao(float a, float b, float q) {
    float2 p = produtoExato(q, b);
    return fixa(a - p.x) - p.y;
}

/** a / b arredondado como no IEEE (a ≥ 0, b > 0): a divisão da GPU pode errar o último bit. */
static float divisao(float a, float b) {
    if (a == 0.0) return 0.0;
    float q = a / b;
    float e = restoDaDivisao(a, b, q);
    for (int i = 0; i < 4; i++) {
        float q2 = as_type<float>(as_type<uint>(q) + (e > 0.0 ? 1u : 0xFFFFFFFFu));
        float e2 = restoDaDivisao(a, b, q2);
        if (abs(e2) < abs(e)) { q = q2; e = e2; } else break;
    }
    return q;
}

/** O valor do controle em 16.16, como o AE o entrega ao plugin: ele GUARDA o slider em float32 (202,36 fica
 *  202,36000061) e arredonda esse float · 65536, meio para longe do zero — o mesmo float que o app tem. O produto é
 *  exato (potência de 2); o + 0,5 não seria (acima de 2²³ o float não tem a meia unidade): compara a fração. */
static int fixo(float v) {
    float m = abs(v) * 65536.0;
    float i = floor(m);
    int r = int(i) + (m - i >= 0.5 ? 1 : 0);
    return v < 0.0 ? -r : r;
}

// ============================================================ o double do plugin, emulado (o do CC Vector Blur)
// uint2(alto, baixo) com os bits de um double IEEE-754. Só números normais e zero (é o que a conta usa).
const uint2 D_ZERO = uint2(0u, 0u);
const uint2 D_UM = uint2(0x3FF00000u, 0u);
const uint2 D_MEIO = uint2(0x3FE00000u, 0u);
const uint2 D_QUATRO = uint2(0x40100000u, 0u);
const uint2 D_64 = uint2(0x40500000u, 0u);
const uint2 D_CENTESIMO = uint2(0x3F847AE1u, 0x47AE147Bu);   // 0,01
const uint2 D_BORDA = uint2(0x3FF68F5Cu, 0x28F5C28Fu);       // 1,41

static bool dZero(uint2 a) { return (a.x & 0x7FFFFFFFu) == 0u && a.y == 0u; }
static uint dSinal(uint2 a) { return a.x >> 31; }
static int dExpo(uint2 a) { return int((a.x >> 20) & 0x7FFu) - 1023; }
static uint2 dMant(uint2 a) { return uint2((a.x & 0xFFFFFu) | 0x100000u, a.y); }
static uint2 dNeg(uint2 a) { return dZero(a) ? a : uint2(a.x ^ 0x80000000u, a.y); }
static uint2 dAbs(uint2 a) { return uint2(a.x & 0x7FFFFFFFu, a.y); }
static uint2 dEscala2(uint2 a, int k) { return dZero(a) ? a : uint2(a.x + uint(k << 20), a.y); }

static uint2 soma64(uint2 a, uint2 b) { uint lo = a.y + b.y; return uint2(a.x + b.x + (lo < a.y ? 1u : 0u), lo); }
static uint2 sub64(uint2 a, uint2 b) { return uint2(a.x - b.x - (a.y < b.y ? 1u : 0u), a.y - b.y); }
static bool menor64(uint2 a, uint2 b) { return a.x < b.x || (a.x == b.x && a.y < b.y); }
static uint2 shl64(uint2 a, int n) {
    if (n == 0) return a;
    if (n >= 64) return uint2(0u);
    if (n >= 32) return uint2(a.y << (n - 32), 0u);
    return uint2((a.x << n) | (a.y >> (32 - n)), a.y << n);
}
static uint2 shr64(uint2 a, int n) {
    if (n == 0) return a;
    if (n >= 64) return uint2(0u);
    if (n >= 32) return uint2(0u, a.x >> (n - 32));
    return uint2(a.x >> n, (a.y >> n) | (a.x << (32 - n)));
}

static uint2 dMontar(uint s, int e, uint2 m) {
    return uint2((s << 31) | (uint(e + 1023) << 20) | (m.x & 0xFFFFFu), m.y);
}

/** m56 em [2^55, 2^56): 53 bits + guarda + 2 de resto (o último já com o que saiu); ao par. */
static uint2 dArredondar(uint s, int e, uint2 m56) {
    uint extra = m56.y & 7u;
    uint2 m = shr64(m56, 3);
    if (extra > 4u || (extra == 4u && (m.y & 1u) == 1u)) m = soma64(m, uint2(0u, 1u));
    if (m.x >= 0x200000u) { m = shr64(m, 1); e += 1; }
    return dMontar(s, e, m);
}

/** O produto das mantissas em dígitos de 16 bits (laços de limite fixo: o compilador desenrola). */
static uint2 dMul(uint2 a, uint2 b) {
    if (dZero(a) || dZero(b)) return uint2((dSinal(a) ^ dSinal(b)) << 31, 0u);
    uint2 ma = dMant(a), mb = dMant(b);
    uint A[4];
    uint B[4];
    uint P[8];
    A[0] = ma.y & 0xFFFFu; A[1] = ma.y >> 16; A[2] = ma.x & 0xFFFFu; A[3] = ma.x >> 16;
    B[0] = mb.y & 0xFFFFu; B[1] = mb.y >> 16; B[2] = mb.x & 0xFFFFu; B[3] = mb.x >> 16;
    for (int i = 0; i < 8; i++) P[i] = 0u;
    for (int i = 0; i < 4; i++) {
        uint c = 0u;
        for (int j = 0; j < 4; j++) {
            uint t = A[i] * B[j] + P[i + j] + c;
            P[i + j] = t & 0xFFFFu;
            c = t >> 16;
        }
        P[i + 4] = c;
    }
    uint2 alto = uint2((P[7] << 16) | P[6], (P[5] << 16) | P[4]);
    uint2 baixo = uint2((P[3] << 16) | P[2], (P[1] << 16) | P[0]);
    int e = dExpo(a) + dExpo(b);
    int sh = 49;
    if ((alto.x & 0x200u) != 0u) { sh = 50; e += 1; }
    uint2 m = shl64(alto, 64 - sh) | shr64(baixo, sh);
    if (shl64(baixo, 64 - sh) != uint2(0u)) m.y |= 1u;
    return dArredondar(dSinal(a) ^ dSinal(b), e, m);
}

static uint2 dSoma(uint2 a, uint2 b) {
    if (dZero(a)) return dZero(b) ? uint2((dSinal(a) & dSinal(b)) << 31, 0u) : b;
    if (dZero(b)) return a;
    if (menor64(uint2(a.x & 0x7FFFFFFFu, a.y), uint2(b.x & 0x7FFFFFFFu, b.y))) { uint2 t = a; a = b; b = t; }
    int e = dExpo(a);
    int d = e - dExpo(b);
    uint2 ma = shl64(dMant(a), 3), mb = shl64(dMant(b), 3);
    if (d >= 60) {
        mb = uint2(0u, 1u);
    } else if (d > 0) {
        uint2 r = shr64(mb, d);
        if (shl64(r, d) != mb) r.y |= 1u;
        mb = r;
    }
    uint2 m;
    if (dSinal(a) == dSinal(b)) {
        m = soma64(ma, mb);
        if (m.x >= 0x1000000u) {
            uint st = m.y & 1u;
            m = shr64(m, 1);
            m.y |= st;
            e += 1;
        }
    } else {
        m = sub64(ma, mb);
        if (m == uint2(0u)) return uint2(0u);
        while (m.x < 0x800000u) { m = shl64(m, 1); e -= 1; }
    }
    return dArredondar(dSinal(a), e, m);
}

static uint2 dSub(uint2 a, uint2 b) { return dSoma(a, dNeg(b)); }

static uint2 dDiv(uint2 a, uint2 b) {
    uint s = dSinal(a) ^ dSinal(b);
    if (dZero(a)) return uint2(s << 31, 0u);
    uint2 ma = dMant(a), mb = dMant(b);
    int e = dExpo(a) - dExpo(b);
    if (menor64(ma, mb)) { ma = shl64(ma, 1); e -= 1; }
    uint2 q = uint2(0u), resto = ma;
    for (int i = 0; i < 55 + z0; i++) {
        q = shl64(q, 1);
        if (!menor64(resto, mb)) { resto = sub64(resto, mb); q.y |= 1u; }
        resto = shl64(resto, 1);
    }
    q = shl64(q, 1);
    if (resto != uint2(0u)) q.y |= 1u;
    return dArredondar(s, e, q);
}

static uint2 dSqrt(uint2 a) {
    if (dZero(a)) return uint2(0u);
    uint2 m = dMant(a);
    int k = dExpo(a) - 52;
    if ((k & 1) != 0) { m = shl64(m, 1); k -= 1; }
    // a raiz inteira de m · 2^58, dois bits por vez: 56 bits
    uint2 resto = uint2(0u), raiz = uint2(0u);
    for (int i = 0; i < 56 + z0; i++) {
        uint par = i < 27 ? (shr64(m, 52 - 2 * i).y & 3u) : 0u;
        resto = shl64(resto, 2);
        resto.y |= par;
        uint2 tentativa = shl64(raiz, 2);
        tentativa.y |= 1u;
        raiz = shl64(raiz, 1);
        if (!menor64(resto, tentativa)) { resto = sub64(resto, tentativa); raiz.y |= 1u; }
    }
    if (resto != uint2(0u)) raiz.y |= 1u;
    return dArredondar(0u, k / 2 + 26, raiz);
}

/** trunc (para o zero), para |a| < 2^31. */
static int dTrunc(uint2 a) {
    if (dZero(a)) return 0;
    int e = dExpo(a);
    if (e < 0) return 0;
    if (e > 30) return dSinal(a) == 1u ? -0x7FFFFFFF : 0x7FFFFFFF;
    int v = int(shr64(dMant(a), 52 - e).y);
    return dSinal(a) == 1u ? -v : v;
}

static uint2 dDeInt(int i) {
    if (i == 0) return uint2(0u);
    uint u = uint(abs(i));
    int e = 31;
    while ((u & 0x80000000u) == 0u) { u <<= 1; e--; }
    return dMontar(i < 0 ? 1u : 0u, e, shl64(uint2(0u, u), 21));
}

static uint2 dDeFloat(float f) {
    uint b = as_type<uint>(f);
    uint E = (b >> 23) & 0xFFu;
    if (E == 0u) return uint2(b & 0x80000000u, 0u);
    uint2 m = shl64(uint2(0u, b & 0x7FFFFFu), 29);
    return uint2((b & 0x80000000u) | (uint(int(E) - 127 + 1023) << 20) | m.x, m.y);
}

/** a < b */
static bool dMenor(uint2 a, uint2 b) {
    bool za = dZero(a), zb = dZero(b);
    if (za && zb) return false;
    if (za) return dSinal(b) == 0u;
    if (zb) return dSinal(a) == 1u;
    if (dSinal(a) != dSinal(b)) return dSinal(a) == 1u;
    uint2 ma = uint2(a.x & 0x7FFFFFFFu, a.y), mb = uint2(b.x & 0x7FFFFFFFu, b.y);
    return dSinal(a) == 0u ? menor64(ma, mb) : menor64(mb, ma);
}

// ============================================================ a camada
int W, H;                 // a camada do AE (px), dentro do buffer a partir de `inicio`
int2 inicio;
bool dePe;

/** Um pixel da camada (RGBA 0..255, cor reta) na orientação da IMAGEM (a linha 0 é o topo); fora, transparente. */
static int4 daCamada(int x, int y) {
    if (x < 0 || y < 0 || x >= W || y >= H) return int4(0);
    int2 b = inicio + int2(x, dePe ? H - 1 - y : y);
    return int4(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5);
}

/** O índice inteiro de uma posição 16.16 como o AE: (short)(X >> 16). */
static int indice(int X) { return int(uint(X >> 16) << 16) >> 16; }

/**
 * O subpixel_sample de 8 bits do AE (PF_SubpixelSample_Straight, PF.dll; o do Displacement Map), na ordem da SSE
 * dele. Sem fração: o pixel. Os quatro iguais: o pixel. Alfas iguais: cada canal (p3·w3 + p2·w2) + (p1·w1 + p0·w0)
 * + 0,5. Senão: a cor pesada pelo alfa, vezes 1/S, + 0,5; o alfa S + 0,5. Fora da camada conta como zero.
 */
static int4 amostraDoAe(int X, int Y) {
    int ix = indice(X), iy = indice(Y);
    int fx = X & 0xFFFF, fy = Y & 0xFFFF;
    int4 p0 = daCamada(ix, iy);
    if (fx == 0 && fy == 0) return p0;
    int4 p1 = daCamada(ix + 1, iy);
    int4 p2 = daCamada(ix, iy + 1);
    int4 p3 = daCamada(ix + 1, iy + 1);
    if (p0 == p1 && p1 == p2 && p2 == p3) return p0;
    float wx = float(fx) * (1.0 / 65536.0);
    float wy = float(fy) * (1.0 / 65536.0);
    float w3 = mul(wy, wx);
    float w1 = fixa(wx - w3);
    float w2 = fixa(wy - w3);
    float w0 = fixa(fixa(fixa(1.0 - w1) - w2) - w3);
    if (p0.a == p1.a && p2.a == p3.a && p0.a == p2.a) {
        if (p0.a == 0) return int4(0);
        float4 t = fixa4(mul4(float4(p3), w3) + mul4(float4(p2), w2));
        float4 u = fixa4(mul4(float4(p1), w1) + mul4(float4(p0), w0));
        int4 r = int4(floor(fixa4(t + u) + 0.5));
        r.a = p0.a;
        return clamp(r, 0, 255);
    }
    float a0 = mul(float(p0.a), w0), a1 = mul(float(p1.a), w1), a2 = mul(float(p2.a), w2), a3 = mul(float(p3.a), w3);
    float S = fixa(fixa(a3 + a2) + fixa(a1 + a0));
    if (S < 0.5) return int4(0);
    float rcp = divisao(1.0, S);
    float3 n = fixa3(fixa3(mul3(a3, float3(p3.rgb)) + mul3(a2, float3(p2.rgb))) + fixa3(mul3(a1, float3(p1.rgb)) + mul3(a0, float3(p0.rgb))));
    int3 c = int3(floor(mul3(rcp, n) + 0.5));
    return clamp(int4(c, int(floor(S + 0.5))), 0, 255);
}

// ============================================================ o area_sample de 8 bits do AE (PF.dll, 0x1800d83e0)
// A caixa [X − RX + ½, X + RX + ½) × [Y − RY + ½, Y + RY + ½) em 16.16, presa à camada. Cada pixel pesa a parte dele
// que cai dentro — os cantos (borda x · 2⁻³²) · borda y, as bordas (65536 − f)/65536 ou f/65536, o miolo 1 —, vezes
// o alfa; soma em float32 linha a linha, da esquerda para a direita (a ordem muda o último bit). Com RX ou RY de meio
// px ou menos, a caixa é uma linha (ou coluna) de subpixel_sample, sem prender à camada.
const float K32 = 2.3283064365386963e-10;   // 2⁻³²
const float K16 = 1.52587890625e-05;        // 2⁻¹⁶
float S;
float4 A;

static void somar(float wa, int4 p) {
    S = fixa(S + wa);
    A = fixa4(A + mul4(float4(p), wa));
}

/** Uma linha (RY pequeno: x anda, y = Y) ou uma coluna (RX pequeno). */
static void tira(bool linha, int X, int Y, int C0, int C1, float o) {
    int c0 = C0 >> 16, f0 = C0 & 0xFFFF;
    int c1 = C1 >> 16, f1 = C1 & 0xFFFF;
    if (f0 != 0) {
        int4 p = linha ? amostraDoAe(c0 << 16, Y) : amostraDoAe(X, c0 << 16);
        somar(mul(mul(mul(float(65536 - f0), K32), o), float(p.a)), p);
    }
    int ini = f0 != 0 ? c0 + 1 : c0;
    float wm = mul(o, K16);
    for (int t = 0; t < 24; t++) {
        int c = ini + t;
        if (c >= c1) break;
        int4 p = linha ? amostraDoAe(c << 16, Y) : amostraDoAe(X, c << 16);
        somar(mul(wm, float(p.a)), p);
    }
    if (f1 != 0) {
        int4 p = linha ? amostraDoAe(c1 << 16, Y) : amostraDoAe(X, c1 << 16);
        somar(mul(mul(mul(float(f1), K32), o), float(p.a)), p);
    }
}

static int4 areaDoAe(int X, int Y, int RX, int RY) {
    S = 0.0;
    A = float4(0.0);
    int L = X - RX + 0x8000, R = X + RX + 0x8000;
    int T = Y - RY + 0x8000, B = Y + RY + 0x8000;
    bool baixoY = RY <= 0x8000, baixoX = RX <= 0x8000;
    if (baixoY && baixoX) {
        int4 p = amostraDoAe(X, Y);
        somar(mul(mul(mul(float(R - L), K32), float(B - T)), float(p.a)), p);
    } else if (baixoY) {
        tira(true, X, Y, L, R, float(2 * RY));
    } else if (baixoX) {
        tira(false, X, Y, T, B, float(2 * RX));
    } else {
        int Lc = clamp(L, 0, W << 16), Rc = clamp(R, 0, W << 16);
        int Tc = clamp(T, 0, H << 16), Bc = clamp(B, 0, H << 16);
        int fL = Lc & 0xFFFF, fR = Rc & 0xFFFF, fT = Tc & 0xFFFF, fB = Bc & 0xFFFF;
        int x0 = Lc >> 16, y0 = Tc >> 16;
        int ncol = (Rc >> 16) + (fR != 0 ? 1 : 0) - x0;
        int nlin = (Bc >> 16) + (fB != 0 ? 1 : 0) - y0;
        // a caixa tem no máximo 2 · 8,5 px (Convergence ≥ −200): 18 pixels de lado
        for (int j = 0; j < 24; j++) {
            if (j >= nlin) break;
            bool topo = fT != 0 && j == 0;
            bool base = fB != 0 && j == nlin - 1 && !topo;
            float ey = topo ? float(65536 - fT) : float(fB);
            for (int i = 0; i < 24; i++) {
                if (i >= ncol) break;
                bool esq = fL != 0 && i == 0;
                bool dir = fR != 0 && i == ncol - 1 && !esq;
                float ex = esq ? float(65536 - fL) : float(fR);
                int4 p = daCamada(x0 + i, y0 + j);
                float a = float(p.a);
                float wa;
                if ((topo || base) && (esq || dir)) wa = mul(mul(mul(ex, K32), ey), a);
                else if (topo || base) wa = mul(mul(ey, K16), a);
                else if (esq || dir) wa = mul(mul(ex, K16), a);
                else wa = a;
                somar(wa, p);
            }
        }
    }
    if (S == 0.0) return int4(0);
    float alfa = min(mul(S, divisao(1073741824.0, mul(float(RX), float(RY)))), 255.0);
    if (alfa == 0.0) return int4(0);
    float3 c = min(float3(divisao(A.r, S), divisao(A.g, S), divisao(A.b, S)), float3(255.0));
    return clamp(int4(int3(fixa3(c + 0.5)), int(fixa(alfa + 0.5))), 0, 255);
}

// ============================================================ as constantes (passe 0)
uint2 cR, cR2, cI2, cK, cInv, cQ;

static void calcularConstantes(int sF, int cF) {
    uint2 s = dMul(dEscala2(dDeInt(sF), -16), D_CENTESIMO);
    uint2 c = dMul(dEscala2(dDeInt(cF), -16), D_CENTESIMO);
    uint2 Hd = dDeInt(H), Wd = dDeInt(W);
    cR = dEscala2(dMul(dSqrt(dSoma(dMul(Hd, Hd), dMul(Wd, Wd))), s), -1);
    cR2 = dMul(cR, cR);
    cQ = dDiv(D_QUATRO, cR);
    uint2 t = dSub(cR, D_BORDA);
    cI2 = dMul(t, t);
    cK = dDiv(c, cR2);
    cInv = dDiv(D_UM, dSub(cR2, cI2));
}

// Um uint inteiro nos 4 bytes de um texel RGBA8 (o buffer do motor é de 8 bits).
static float4 guardar(uint b) {
    return float4(float(b & 255u), float((b >> 8) & 255u), float((b >> 16) & 255u), float(b >> 24)) / 255.0;
}
static uint lerUint(int i) {
    uint4 c = uint4(constantes.read(uint2(int2(i, 0)), uint(0)) * 255.0 + 0.5);
    return c.x | (c.y << 8) | (c.z << 16) | (c.w << 24);
}
static uint2 lerDouble(int k) { return uint2(lerUint(2 * k), lerUint(2 * k + 1)); }

/** round(fração · lado · 65536), meio para longe do zero — a conta é exata em double (24 + 13 + 16 bits). */
static int pontoFixo(float fracao, int lado) {
    uint2 v = dEscala2(dMul(dDeFloat(abs(fracao)), dDeInt(lado)), 16);
    int r = dTrunc(dSoma(v, D_MEIO));
    return fracao < 0.0 ? -r : r;
}

fragment float4 fx_cc_lens(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_lensParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> constantes [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    z0 = min(eng.acIteration, 0);
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA (a diagonal é a dela).
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    inicio = (buf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;
    int sF = fixo(u.size), cF = fixo(u.convergence);

    if (eng.acPass == 0) {
        calcularConstantes(sF, cF);
        int i = int(__nv_fragCoord.x);
        uint2 v = i < 2 ? cR : i < 4 ? cR2 : i < 6 ? cI2 : i < 8 ? cK : i < 10 ? cInv : cQ;
        __nv_out = guardar((i & 1) == 0 ? v.x : v.y);
        return __nv_out;
    }

    // Size 0: o plugin limpa a saída
    if (sF <= 0) { __nv_out = float4(0.0); return __nv_out; }
    cR = lerDouble(0); cR2 = lerDouble(1); cI2 = lerDouble(2); cK = lerDouble(3); cInv = lerDouble(4); cQ = lerDouble(5);

    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena guardada de pé (camada de
    // ajuste, grupo solto) a linha 0 do buffer é a BASE (o motor já levou o ponto ao buffer).
    int2 aqui = int2(floor(in.acScreenNorm * eng.acResolution));
    int2 local = aqui - inicio;
    int x = local.x, y = dePe ? H - 1 - local.y : local.y;
    // O centro como FRAÇÃO da camada em float32: é assim que o AE guarda o ponto, e o plugin recebe
    // round(fração · lado · 65536). O ponto do app já é a fração da composição em float32 (o conversor divide em
    // float): com a camada do tamanho do buffer, é a MESMA fração. Por isso o ponto chega cru (`pontos="camada"`: o
    // motor não o converte na cena de pé — o 1 − y em float perdia o último bit, e isso dava pixels a 1 nível) e só
    // vai ao buffer quando a camada não o ocupa inteiro (folga, grupo solto, mídia menor).
    float2 uv = __nv_acPontoNoBuffer(u.center);
    float2 simples = dePe ? float2(u.center.x, 1.0 - u.center.y) : u.center;
    float2 fr;
    if (tam == buf && all(lessThan(abs(uv - simples), float2(1.0e-6)))) {
        fr = u.center;
    } else {
        float2 cb = float2(mul(uv.x, float(buf.x)), mul(uv.y, float(buf.y))) - float2(inicio);
        if (dePe) cb.y = fixa(float(H) - cb.y);
        fr = float2(sign(cb.x) * divisao(abs(cb.x), float(W)), sign(cb.y) * divisao(abs(cb.y), float(H)));
    }
    uint2 CX = dEscala2(dDeInt(pontoFixo(fr.x, W)), -16);
    uint2 CY = dEscala2(dDeInt(pontoFixo(fr.y, H)), -16);

    // A saída do efeito (o PreRender): a caixa do círculo; com Convergence ≥ 0, do lado em que o centro cai fora da
    // camada, ela para na borda dela. Fora: nada.
    int l = dTrunc(dSub(CX, cR)), r = dTrunc(dSoma(dSoma(CX, cR), D_UM));
    int t = dTrunc(dSub(CY, cR)), b = dTrunc(dSoma(dSoma(CY, cR), D_UM));
    if (cF >= 0) {
        if (dMenor(CX, D_ZERO)) { l = 0; r = max(r, 0); }
        if (dMenor(dDeInt(W), CX)) { r = W; l = min(l, W); }
        if (dMenor(CY, D_ZERO)) { t = 0; b = max(b, 0); }
        if (dMenor(dDeInt(H), CY)) { b = H; t = min(t, H); }
    }
    if (x < l || x >= r || y < t || y >= b) { __nv_out = float4(0.0); return __nv_out; }

    uint2 X = dDeInt(x), Y = dDeInt(y);
    uint2 dx = dSub(X, CX), dy = dSub(Y, CY);
    uint2 d2 = dSoma(dMul(dy, dy), dMul(dx, dx));
    if (dMenor(cR2, d2)) { __nv_out = float4(0.0); return __nv_out; }
    uint2 kd = dMul(d2, cK);
    uint2 kx = dMul(kd, dx), ky = dMul(kd, dy);
    int SX = dTrunc(dEscala2(dSub(X, kx), 16));
    int SY = dTrunc(dEscala2(dSub(Y, ky), 16));
    int4 p;
    if (cF >= 0) {
        p = amostraDoAe(SX, SY);
    } else {
        // a meia largura da caixa: |k·|d|²·d|·4/r + ½, no máximo 64 — em px da camada cheia (na prévia, × a escala)
        uint2 rx = dSoma(dMul(dAbs(kx), cQ), D_MEIO);
        uint2 ry = dSoma(dMul(dAbs(ky), cQ), D_MEIO);
        if (dMenor(D_64, rx)) rx = D_64;
        if (dMenor(D_64, ry)) ry = D_64;
        float esc = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
        if (esc != 1.0) { rx = dMul(rx, dDeFloat(esc)); ry = dMul(ry, dDeFloat(esc)); }
        p = areaDoAe(SX, SY, dTrunc(dEscala2(rx, 16)), dTrunc(dEscala2(ry, 16)));
    }
    // a borda suave: os últimos 1,41 px do raio
    if (dMenor(cI2, d2)) p.a = dTrunc(dMul(dMul(dSub(cR2, d2), dDeInt(p.a)), cInv));
    __nv_out = float4(p) / 255.0;
    return __nv_out;
}
