// ---------------------------------------------------------------------------
// CC Radial Blur
// origem : assets/effects/cc-radial-blur.xml
// id     : nova.effect.ccradialblur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_radial_blurParams {
    int tipo;
    float amount;
    float quality;
    float2 center;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 do plugin
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se funde
// com a soma seguinte num fma: cada produto arredonda sozinho, como no plugin.
float um;
int z0;
float fixa(float x) { return x * um; }
float3 fixa3(float3 x) { return x * um; }
float4 fixa4(float4 x) { return x * um; }
float mul(float a, float b) { return (a * b) * um; }
float3 mul3(float a, float3 b) { return (a * b) * um; }
float4 mul4(float4 a, float b) { return (a * b) * um; }

/** a·b = p + e, exato (Dekker). */
float2 produtoExato(float a, float b) {
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

float restoDaDivisao(float a, float b, float q) {
    float2 p = produtoExato(q, b);
    return fixa(a - p.x) - p.y;
}

/** a / b arredondado como no IEEE (a ≥ 0, b > 0): a divisão da GPU pode errar o último bit. */
float divisao(float a, float b) {
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

/** O valor do controle em 16.16, como o AE o entrega ao plugin (o do CC Lens): o float32 · 65536, meio para longe
 *  do zero. O produto é exato (potência de 2); o + 0,5 não seria (acima de 2²³): compara a fração. */
int fixo(float v) {
    float m = abs(v) * 65536.0;
    float i = floor(m);
    int r = int(i) + (m - i >= 0.5 ? 1 : 0);
    return v < 0.0 ? -r : r;
}

// ============================================================ dois floats (~48 bits): o giro de cada amostra
// v = hi + lo, |lo| ≤ meio ulp de hi. As somas e produtos exatos (Knuth, Dekker) com o `um` entre cada conta.
float2 somaExata(float a, float b) {
    float s = fixa(a + b);
    float bb = fixa(s - a);
    return float2(s, fixa(fixa(a - fixa(s - bb)) + fixa(b - bb)));
}
float2 somaRapida(float a, float b) {
    float s = fixa(a + b);
    return float2(s, fixa(b - fixa(s - a)));
}
float2 dfSoma(float2 a, float2 b) {
    float2 s = somaExata(a.x, b.x);
    float2 t = somaExata(a.y, b.y);
    s = somaRapida(s.x, fixa(s.y + t.x));
    return somaRapida(s.x, fixa(s.y + t.y));
}
float2 dfNeg(float2 a) { return -a; }
float2 dfMul(float2 a, float2 b) {
    float2 p = produtoExato(a.x, b.x);
    return somaRapida(p.x, fixa(p.y + fixa(mul(a.x, b.y) + mul(a.y, b.x))));
}

/** a / b (b > 0) e √a em dois floats (~2⁻⁴⁴): a primeira aproximação em float, um passo de correção exato. */
float2 dfDiv(float2 a, float2 b) {
    float q1 = a.x / b.x;
    float2 r = dfSoma(a, dfNeg(dfMul(float2(q1, 0.0), b)));
    return somaRapida(q1, r.x / b.x);
}
float2 dfRaiz(float2 a) {
    if (!(a.x > 0.0)) return float2(0.0);
    float h = sqrt(a.x);
    float2 r = dfSoma(a, dfNeg(produtoExato(h, h)));
    return somaRapida(h, r.x / (2.0 * h));
}

/**
 * O piso de v quando ele está LONGE de um inteiro: com a parte quebrada a menos de `margem` de 0 ou de 1, o erro dos
 * dois floats poderia trocar o lado da divisa, e `seguro` vira false (a conta volta ao double emulado).
 */
int dfPiso(float2 v, float margem, inout bool seguro) {
    float f = floor(v.x);
    float2 r = dfSoma(v, float2(-f, 0.0));
    float q = r.x + r.y;
    float k = floor(q);
    q -= k;
    if (q < margem || q > 1.0 - margem) seguro = false;
    return int(f) + int(k);
}
int dfCorte(float2 v, float margem, inout bool seguro) { return v.x < 0.0 ? -dfPiso(-v, margem, seguro) : dfPiso(v, margem, seguro); }

/** O inteiro i · k (k potência de 2) em dois floats, exato (|i| < 2³¹). */
float2 dfDeInt(int i, float k) {
    int b = i & 255;
    return somaRapida(float(i - b) * k, float(b) * k);
}

/** trunc (para o zero) de um par normalizado, |v| < 2³¹. */
int dfTrunc(float2 v) {
    float t = trunc(v.x);
    if (t != v.x) return int(t);
    // hi inteiro: o lo decide (para baixo nos positivos, para cima nos negativos)
    return int(t) + int(v.x >= 0.0 ? floor(v.y) : ceil(v.y));
}

// Os coeficientes das séries de sen e cos ((−1)^k/(2k+1)! e (−1)^k/(2k)!) e π/2 em três partes, em dois floats
// (gerados em Python com frações exatas).
const float2 KSEN[10] = float2[10](
    float2(1.0, 0.0), float2(-0.1666666716337204, 4.967053879312289e-09), float2(0.008333333767950535, -4.34617203337595e-10),
    float2(-0.00019841270113829523, 2.725596874933456e-12), float2(2.7557318844628753e-06, 3.793571224297229e-14),
    float2(-2.5052107943679403e-08, -4.4176230446483665e-16), float2(1.6059044372074283e-10, -5.352526511562726e-18),
    float2(-7.647163609812713e-13, -1.2200710471178288e-20), float2(2.8114573589663704e-15, -1.0462084739763658e-22),
    float2(-8.220635078476521e-18, -1.681478096855898e-25));
const float2 KCOS[11] = float2[11](
    float2(1.0, 0.0), float2(-0.5, 0.0), float2(0.0416666679084301, -1.2417634698280722e-09),
    float2(-0.0013888889225199819, 3.3631094437103215e-11), float2(2.4801587642286904e-05, -3.40699609366682e-13),
    float2(-2.755731998149713e-07, 7.575112209051195e-15), float2(2.0876755879584152e-09, 1.1082839147459852e-16),
    float2(-1.147074536050896e-11, -2.372207689231238e-19), float2(4.7794772561329454e-14, 7.62544404448643e-22),
    float2(-1.5619206814541513e-16, -1.5404471465941993e-24), float2(4.110317590937049e-19, 3.237511732860265e-27));
const float PI2_A = 1.5707963705062866, PI2_B = -4.371138828673793e-08, PI2_C = -1.7151245100058819e-15;

/** sen e cos de x (|x| ≤ ~4: o maior passo é 2,5π / 2): o quadrante, depois as séries em |y| ≤ π/4. */
void senCos(float2 x, out float2 s, out float2 c) {
    float k = floor(x.x * 0.63661977 + 0.5);
    float2 y = dfSoma(x, dfNeg(produtoExato(k, PI2_A)));
    y = dfSoma(y, dfNeg(produtoExato(k, PI2_B)));
    y = dfSoma(y, float2(-mul(k, PI2_C), 0.0));
    float2 y2 = dfMul(y, y);
    float2 ps = KSEN[9];
    for (int i = 8; i >= 0; i--) ps = dfSoma(dfMul(ps, y2), KSEN[i]);
    ps = dfMul(ps, y);
    float2 pc = KCOS[10];
    for (int i = 9; i >= 0; i--) pc = dfSoma(dfMul(pc, y2), KCOS[i]);
    int q = int(k) & 3;
    s = q == 0 ? ps : (q == 1 ? pc : (q == 2 ? dfNeg(ps) : dfNeg(pc)));
    c = q == 0 ? pc : (q == 1 ? dfNeg(ps) : (q == 2 ? dfNeg(pc) : ps));
}

// ============================================================ o double do plugin, emulado (o do CC Vector Blur)
// uint2(alto, baixo) com os bits de um double IEEE-754. Só números normais e zero (é o que a conta usa).
const uint2 D_ZERO = uint2(0u, 0u);
const uint2 D_UM = uint2(0x3FF00000u, 0u);
const uint2 D_MEIO = uint2(0x3FE00000u, 0u);
const uint2 D_MENOS_UM = uint2(0xBFF00000u, 0u);
const uint2 D_65536 = uint2(0x40F00000u, 0u);
const uint2 D_CENTESIMO = uint2(0x3F847AE1u, 0x47AE147Bu);   // 0,01
const uint2 D_PI = uint2(0x400921FBu, 0x54442D18u);

bool dZero(uint2 a) { return (a.x & 0x7FFFFFFFu) == 0u && a.y == 0u; }
uint dSinal(uint2 a) { return a.x >> 31; }
int dExpo(uint2 a) { return int((a.x >> 20) & 0x7FFu) - 1023; }
uint2 dMant(uint2 a) { return uint2((a.x & 0xFFFFFu) | 0x100000u, a.y); }
uint2 dNeg(uint2 a) { return dZero(a) ? a : uint2(a.x ^ 0x80000000u, a.y); }
uint2 dAbs(uint2 a) { return uint2(a.x & 0x7FFFFFFFu, a.y); }
uint2 dEscala2(uint2 a, int k) { return dZero(a) ? a : uint2(a.x + uint(k << 20), a.y); }

uint2 soma64(uint2 a, uint2 b) { uint lo = a.y + b.y; return uint2(a.x + b.x + (lo < a.y ? 1u : 0u), lo); }
uint2 sub64(uint2 a, uint2 b) { return uint2(a.x - b.x - (a.y < b.y ? 1u : 0u), a.y - b.y); }
bool menor64(uint2 a, uint2 b) { return a.x < b.x || (a.x == b.x && a.y < b.y); }
uint2 shl64(uint2 a, int n) {
    if (n == 0) return a;
    if (n >= 64) return uint2(0u);
    if (n >= 32) return uint2(a.y << (n - 32), 0u);
    return uint2((a.x << n) | (a.y >> (32 - n)), a.y << n);
}
uint2 shr64(uint2 a, int n) {
    if (n == 0) return a;
    if (n >= 64) return uint2(0u);
    if (n >= 32) return uint2(0u, a.x >> (n - 32));
    return uint2(a.x >> n, (a.y >> n) | (a.x << (32 - n)));
}

uint2 dMontar(uint s, int e, uint2 m) {
    return uint2((s << 31) | (uint(e + 1023) << 20) | (m.x & 0xFFFFFu), m.y);
}

/** m56 em [2^55, 2^56): 53 bits + guarda + 2 de resto (o último já com o que saiu); ao par. */
uint2 dArredondar(uint s, int e, uint2 m56) {
    uint extra = m56.y & 7u;
    uint2 m = shr64(m56, 3);
    if (extra > 4u || (extra == 4u && (m.y & 1u) == 1u)) m = soma64(m, uint2(0u, 1u));
    if (m.x >= 0x200000u) { m = shr64(m, 1); e += 1; }
    return dMontar(s, e, m);
}

/** O produto das mantissas em dígitos de 16 bits (laços de limite fixo: o compilador desenrola). */
uint2 dMul(uint2 a, uint2 b) {
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

uint2 dSoma(uint2 a, uint2 b) {
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

uint2 dSub(uint2 a, uint2 b) { return dSoma(a, dNeg(b)); }

uint2 dDiv(uint2 a, uint2 b) {
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

/**
 * a / n em double, para n inteiro de 1 a 4095, com o arredondamento do IEEE: a divisão longa da mantissa em dígitos
 * de 16 bits (5 divisões de inteiro), no lugar dos 55 passos do dDiv.
 */
uint2 dDivInt(uint2 a, int n) {
    if (dZero(a)) return a;
    uint un = uint(n);
    int bn = 0;
    for (uint t = un; t != 0u; t >>= 1) bn++;
    // D = m · 2^s com s = bits(n) + 3: o quociente cai em [2^55, 2^57)
    int s = bn + 3;
    uint2 m = dMant(a);
    uint2 baixo = shl64(m, s);
    uint dig[5];
    dig[0] = (m.x >> (32 - s)) & 0xFFFFu;
    dig[1] = baixo.x >> 16; dig[2] = baixo.x & 0xFFFFu; dig[3] = baixo.y >> 16; dig[4] = baixo.y & 0xFFFFu;
    uint q[5];
    uint r = 0u;
    for (int i = 0; i < 5; i++) {
        uint c = (r << 16) | dig[i];
        q[i] = c / un;
        r = c - q[i] * un;
    }
    uint2 Q = uint2((q[1] << 16) | q[2], (q[3] << 16) | q[4]);
    int e = dExpo(a) + 3 - s;
    if (Q.x >= 0x1000000u) {
        uint st = Q.y & 1u;
        Q = shr64(Q, 1);
        Q.y |= st;
        e += 1;
    }
    if (r != 0u) Q.y |= 1u;
    return dArredondar(dSinal(a), e, Q);
}

uint2 dSqrt(uint2 a) {
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
int dTrunc(uint2 a) {
    if (dZero(a)) return 0;
    int e = dExpo(a);
    if (e < 0) return 0;
    if (e > 30) return dSinal(a) == 1u ? -0x7FFFFFFF : 0x7FFFFFFF;
    int v = int(shr64(dMant(a), 52 - e).y);
    return dSinal(a) == 1u ? -v : v;
}

uint2 dDeInt(int i) {
    if (i == 0) return uint2(0u);
    uint u = uint(abs(i));
    int e = 31;
    while ((u & 0x80000000u) == 0u) { u <<= 1; e--; }
    return dMontar(i < 0 ? 1u : 0u, e, shl64(uint2(0u, u), 21));
}

uint2 dDeFloat(float f) {
    uint b = as_type<uint>(f);
    uint E = (b >> 23) & 0xFFu;
    if (E == 0u) return uint2(b & 0x80000000u, 0u);
    uint2 m = shl64(uint2(0u, b & 0x7FFFFFu), 29);
    return uint2((b & 0x80000000u) | (uint(int(E) - 127 + 1023) << 20) | m.x, m.y);
}

/** O double para float32, ao par. */
float dParaFloat(uint2 d) {
    if (dZero(d)) return as_type<float>(d.x & 0x80000000u);
    uint2 m = dMant(d);
    int e = dExpo(d);
    uint m24 = shr64(m, 29).y;
    uint resto = m.y & 0x1FFFFFFFu;
    if (resto > 0x10000000u || (resto == 0x10000000u && (m24 & 1u) == 1u)) m24++;
    if (m24 == 0x1000000u) { m24 >>= 1; e++; }
    return as_type<float>((dSinal(d) << 31) | (uint(e + 127) << 23) | (m24 & 0x7FFFFFu));
}

/** O double em dois floats: hi = o float mais perto, lo = o resto (perde só os 5 últimos bits). */
float2 dfDeD(uint2 d) {
    float hi = dParaFloat(d);
    return float2(hi, dParaFloat(dSub(d, dDeFloat(hi))));
}

/** a < b */
bool dMenor(uint2 a, uint2 b) {
    bool za = dZero(a), zb = dZero(b);
    if (za && zb) return false;
    if (za) return dSinal(b) == 0u;
    if (zb) return dSinal(a) == 1u;
    if (dSinal(a) != dSinal(b)) return dSinal(a) == 1u;
    uint2 ma = uint2(a.x & 0x7FFFFFFFu, a.y), mb = uint2(b.x & 0x7FFFFFFFu, b.y);
    return dSinal(a) == 0u ? menor64(ma, mb) : menor64(mb, ma);
}

/** round(fração · lado · 65536), meio para longe do zero — a conta é exata em double (24 + 13 + 16 bits). */
int pontoFixo(float fracao, int lado) {
    uint2 v = dEscala2(dMul(dDeFloat(abs(fracao)), dDeInt(lado)), 16);
    int r = dTrunc(dSoma(v, D_MEIO));
    return fracao < 0.0 ? -r : r;
}

// ============================================================ a camada e a leitura sub-pixel do AE
int W, H;                 // a camada do AE (px), dentro do buffer a partir de `inicio`
int2 inicio;
bool dePe;

/** Um pixel da camada (RGBA 0..255, cor reta) na orientação da IMAGEM (a linha 0 é o topo); fora, transparente. */
int4 daCamada(int x, int y) {
    if (x < 0 || y < 0 || x >= W || y >= H) return int4(0);
    int2 b = inicio + int2(x, dePe ? H - 1 - y : y);
    return int4(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5);
}

/** O índice inteiro de uma posição 16.16 como o AE: (short)(X >> 16). */
int indice(int X) { return int(uint(X >> 16) << 16) >> 16; }

/**
 * O subpixel_sample de 8 bits do AE (PF.dll; o do CC Lens), na ordem da SSE dele. Sem fração: o pixel. Os quatro
 * iguais: o pixel. Alfas iguais: cada canal (p3·w3 + p2·w2) + (p1·w1 + p0·w0) + 0,5. Senão: a cor pesada pelo alfa,
 * vezes 1/S, + 0,5; o alfa S + 0,5. Fora da camada conta como zero.
 */
int4 amostraDoAe(int X, int Y) {
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

// ============================================================ a soma das amostras
const int N_MAXIMO = 4095;   // a tabela dos giros: 1024 × 4 entradas
float4 soma;        // (alfa, R·alfa, G·alfa, B·alfa) em float32
float pesos;      // a soma dos pesos (Rotate Fading)

/** Uma amostra: com `peso` < 0, a soma simples (alfa e cor·alfa); senão, pesada (alfa·peso, cor·alfa·peso). */
void somar(int4 c, float peso) {
    if (peso < 0.0) {
        soma = soma + float4(float(c.a), float(c.r * c.a), float(c.g * c.a), float(c.b * c.a));
    } else {
        float wa = mul(float(c.a), peso);
        soma = soma + float4(wa, mul(float(c.r), wa), mul(float(c.g), wa), mul(float(c.b), wa));
    }
}

/** Alfa = trunc(soma / divisor), cor = trunc(soma da cor / soma do alfa), em float32; sem alfa, nada. */
float4 saida(float divisor) {
    if (soma.x == 0.0) return float4(0.0);
    float4 q = float4(divisor, soma.x, soma.x, soma.x);
    int4 c;
    for (int i = 0; i < 4; i++) c[i] = int(trunc(divisao(soma[i], q[i]))) & 255;
    return float4(float3(c.yzw), float(c.x)) / 255.0;
}

// ============================================================ as constantes do quadro (passe 0) e a tabela dos giros (1)
uint2 cAmt, cQQ, cAng, cMeia;
float2 cC0, cS0;
// as mesmas, em dois floats, para o caminho rápido (texels 12..17)
float2 fAmt, fQQ, fMeia;

/** 0x180004c20: amt = (Amount · −½) · 0,01; qq = (Quality · 0,01) · a escala da resolução (média de x e y; na prévia,
 *  a do buffer), metade em Draft — aqui, a prévia em movimento (`eng.acRascunho`), como o Radial Blur do AE; ang = −2π·amt
 *  (com o amt antes do |·| do Centered); |ang/π · 2|. O Scratch começa girado de −ang/2. */
void calcularConstantes() {
    float esc = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    cAmt = dMul(dNeg(dEscala2(dDeInt(fixo(u.amount)), -17)), D_CENTESIMO);
    cQQ = dMul(dMul(dEscala2(dDeInt(fixo(u.quality)), -16), D_CENTESIMO), dDeFloat(esc));
    if (eng.acRascunho == 1) cQQ = dEscala2(cQQ, -1);
    cAng = dMul(dEscala2(dNeg(cAmt), 1), D_PI);
    cMeia = dAbs(dEscala2(dDiv(cAng, D_PI), 1));
    senCos(dfDeD(dEscala2(dNeg(cAng), -1)), cS0, cC0);
    fAmt = dfDeD(cAmt);
    fQQ = dfDeD(cQQ);
    fMeia = dfDeD(cMeia);
}

// Um uint inteiro nos 4 bytes de um texel RGBA8 (o buffer do motor é de 8 bits).
float4 guardar(uint b) {
    return float4(float(b & 255u), float((b >> 8) & 255u), float((b >> 16) & 255u), float(b >> 24)) / 255.0;
}
uint lerUint(sampler2D t, int2 p) {
    uint4 c = uint4(t.read(uint2(p), uint(0)) * 255.0 + 0.5);
    return c.x | (c.y << 8) | (c.z << 16) | (c.w << 24);
}
uint2 lerDouble(int k) { return uint2(lerUint(constantes, int2(2 * k, 0)), lerUint(constantes, int2(2 * k + 1, 0))); }
float lerFloat(sampler2D t, int2 p) { return as_type<float>(lerUint(t, p)); }
float2 lerPar(int i) { return float2(lerFloat(constantes, int2(i, 0)), lerFloat(constantes, int2(i + 1, 0))); }

/** cos e sen de ang/N (a divisão em double, as séries em dois floats): a coluna N % 1024, as linhas 4·(N / 1024) + 0..3. */
void giroDaTabela(int N, out float2 cs, out float2 sn) {
    int2 p = int2(N & 1023, (N >> 10) * 4);
    cs = float2(lerFloat(giros, p), lerFloat(giros, p + int2(0, 1)));
    sn = float2(lerFloat(giros, p + int2(0, 2)), lerFloat(giros, p + int2(0, 3)));
}

/**
 * Quantas amostras o Straight e o Fading leem (0x180004300): param quando o risco sai da camada — pelo lado em x,
 * depois o menor com o lado em y.
 */
int corte(int x, int y, uint2 dX, uint2 dY, int N) {
    uint2 n = dDeInt(N), xd = dDeInt(x), yd = dDeInt(y), Wd = dDeInt(W), Hd = dDeInt(H);
    int cnt = N;
    uint2 fx = dSoma(xd, dX);
    if (dMenor(Wd, fx)) cnt = dTrunc(dDiv(dMul(dSub(Wd, xd), n), dX)) + 1;
    else if (dMenor(fx, D_MENOS_UM)) cnt = 1 - dTrunc(dDiv(dMul(n, xd), dX));
    uint2 fy = dSoma(yd, dY);
    bool baixo = dMenor(Hd, fy);
    if (baixo || dMenor(fy, D_MENOS_UM)) {
        uint2 t = baixo ? dSoma(dDiv(dMul(dSub(Hd, yd), n), dY), D_UM) : dSub(D_UM, dDiv(dMul(n, yd), dY));
        uint2 c = dDeInt(cnt);
        cnt = dTrunc(dMenor(c, t) ? c : t);
    }
    return cnt;
}

/** O `corte` em dois floats: cada comparação e cada trunc com margem (perto da divisa, `seguro` = false). */
int corteRapido(int x, int y, float2 dX, float2 dY, int N, inout bool seguro) {
    float n = float(N);
    int cnt = N;
    float2 ex = dfSoma(dX, float2(float(x - W), 0.0));        // x + dX − W
    float2 ex1 = dfSoma(dX, float2(float(x + 1), 0.0));       // x + dX + 1
    if (abs(ex.x) < 1.0e-6 || abs(ex1.x) < 1.0e-6) seguro = false;
    if (ex.x > 0.0) cnt = dfCorte(dfDiv(float2(float(W - x) * n, 0.0), dX), 1.0e-6, seguro) + 1;
    else if (ex1.x < 0.0) cnt = 1 - dfCorte(dfDiv(float2(n * float(x), 0.0), dX), 1.0e-6, seguro);
    float2 ey = dfSoma(dY, float2(float(y - H), 0.0));
    float2 ey1 = dfSoma(dY, float2(float(y + 1), 0.0));
    if (abs(ey.x) < 1.0e-6 || abs(ey1.x) < 1.0e-6) seguro = false;
    bool baixo = ey.x > 0.0;
    if (baixo || ey1.x < 0.0) {
        // t perto de inteiro também cobre o empate com cnt (que é inteiro)
        float2 t = baixo ? dfSoma(dfDiv(float2(float(H - y) * n, 0.0), dY), float2(1.0, 0.0))
                       : dfSoma(float2(1.0, 0.0), dfNeg(dfDiv(float2(n * float(y), 0.0), dY)));
        int tt = dfCorte(t, 1.0e-6, seguro);
        if (t.x < float(cnt)) cnt = tt;
    }
    return cnt;
}

// O caminho rápido (dois floats com margem; a conta exata perto das divisas). `false` só para conferir na bancada.
const bool RAPIDO = true;

// dX = (p − c)·amt e dY em double, calculados só quando alguma grandeza do zoom cai perto de uma divisa.
uint2 eX, eY;
bool temExatos = false;
void exatos(int x, int y, uint2 CX, uint2 CY, uint2 amt) {
    if (temExatos) return;
    eX = dMul(dSub(dDeInt(x), CX), amt);
    eY = dMul(dSub(dDeInt(y), CY), amt);
    temExatos = true;
}

fragment float4 fx_cc_radial_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_radial_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> constantes [[texture(1)]],
    texture2d<float> giros [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    z0 = min(eng.acIteration, 0);
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    inicio = (buf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;

    if (eng.acPass == 0) {
        calcularConstantes();
        int i = int(__nv_fragCoord.x);
        uint2 v = i < 2 ? cAmt : i < 4 ? cQQ : i < 6 ? cAng : cMeia;
        float2 par = i < 10 ? cC0 : i < 12 ? cS0 : i < 14 ? fAmt : i < 16 ? fQQ : fMeia;
        __nv_out = guardar(i < 8 ? ((i & 1) == 0 ? v.x : v.y) : as_type<uint>((i & 1) == 0 ? par.x : par.y));
        return __nv_out;
    }
    if (eng.acPass == 1) {
        calcularConstantes();
        int2 t = int2(__nv_fragCoord.xy);
        int N = (t.y >> 2) * 1024 + t.x;
        float2 sn = float2(0.0), cs = float2(1.0, 0.0);
        if (N >= 2) senCos(dfDeD(dDiv(cAng, dDeInt(N))), sn, cs);
        int c = t.y & 3;
        float f = c == 0 ? cs.x : c == 1 ? cs.y : c == 2 ? sn.x : sn.y;
        __nv_out = guardar(as_type<uint>(f));
        return __nv_out;
    }

    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena de pé a linha 0 do buffer é a
    // BASE. Fora da camada o efeito não escreve.
    int2 local = int2(floor(in.acScreenNorm * eng.acResolution)) - inicio;
    if (local.x < 0 || local.y < 0 || local.x >= W || local.y >= H) { __nv_out = float4(0.0); return __nv_out; }
    int x = local.x, y = dePe ? H - 1 - local.y : local.y;

    // Amount 0: N = 2 amostras no próprio pixel (passo zero, nos seis tipos) — a soma dividida devolve o pixel.
    int aF = fixo(u.amount);
    if (aF == 0) {
        int4 p = daCamada(x, y);
        __nv_out = p.a == 0 ? float4(0.0) : float4(p) / 255.0;
        return __nv_out;
    }

    // O centro como FRAÇÃO da camada em float32 (o AE entrega round(fração · lado · 65536)); cru, como no CC Lens, e
    // levado ao buffer só quando a camada não o ocupa inteiro.
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
    int pcx = pontoFixo(fr.x, W), pcy = pontoFixo(fr.y, H);
    uint2 CX = dEscala2(dDeInt(pcx), -16), CY = dEscala2(dDeInt(pcy), -16);
    // o centro e p − c em dois floats, exatos (16.16 com até 31 bits)
    float2 cx = dfDeInt(pcx, 1.0 / 65536.0), cy = dfDeInt(pcy, 1.0 / 65536.0);
    float2 px = dfSoma(float2(float(x), 0.0), dfNeg(cx)), py = dfSoma(float2(float(y), 0.0), dfNeg(cy));

    // No rascunho, além da metade do Quality (o Draft do plugin), no máximo 64 amostras: como o Low do Radial Blur do AE.
    int teto = eng.acRascunho == 1 ? 64 : N_MAXIMO;
    soma = float4(0.0);
    pesos = 0.0;
    bool seguro = RAPIDO;

    if (u.tipo >= 3) {
        // ---- os giros: Rotate (0x180005810), Scratch (o mesmo, começando girado) e Rotate Fading (0x180005ed0) ----
        int N;
        if (seguro) N = dfPiso(dfMul(dfMul(dfRaiz(dfSoma(dfMul(py, py), dfMul(px, px))), lerPar(14)), lerPar(16)), 1.0e-6, seguro) + 2;
        if (!seguro) {
            uint2 Xd = dSub(dDeInt(x), CX), Yd = dSub(dDeInt(y), CY);
            uint2 r = dSqrt(dSoma(dMul(Yd, Yd), dMul(Xd, Xd)));
            N = dTrunc(dMul(dMul(r, lerDouble(1)), lerDouble(3))) + 2;
        }
        N = min(N, teto);
        float2 sn, cs;
        giroDaTabela(N, cs, sn);
        if (u.tipo == 4) {
            float2 c0 = lerPar(8), s0 = lerPar(10);
            float2 nx = dfSoma(dfMul(s0, py), dfMul(c0, px));
            py = dfSoma(dfMul(c0, py), dfNeg(dfMul(s0, px)));
            px = nx;
        }
        bool desvanecer = u.tipo == 5;
        float peso = float(N);
        for (int k = 0; k < N; k++) {
            int X = dfTrunc(dfSoma(px, cx) * 65536.0);
            int Y = dfTrunc(dfSoma(py, cy) * 65536.0);
            int4 c = amostraDoAe(X, Y);
            float2 nx = dfSoma(dfMul(px, cs), dfMul(py, sn));
            py = dfSoma(dfMul(py, cs), dfNeg(dfMul(px, sn)));
            px = nx;
            if (desvanecer) {
                pesos = fixa(pesos + peso);
                somar(c, peso);
                peso = peso - 1.0;
            } else {
                somar(c, -1.0);
            }
        }
        __nv_out = saida(desvanecer ? pesos : float(N));
        return __nv_out;
    }

    // ---- os zooms: Straight (0x180006550), Fading (0x1800071a0), Centered (0x180006b30, com |amt|) ----
    int N, X0, Y0, DX, DY, cnt;
    if (seguro) {
        // Cada grandeza em dois floats; a que cair perto de uma divisa é refeita sozinha em double (os d exatos só
        // são calculados se alguma precisar). Com Amount redondo isso é comum: no Centered 20, o começo do risco
        // cai em inteiro a cada 5 colunas.
        uint2 amtD = lerDouble(0);
        float2 amt = lerPar(12);
        if (u.tipo == 2) { amtD = dAbs(amtD); if (amt.x < 0.0) amt = -amt; }
        float2 dX = dfMul(px, amt), dY = dfMul(py, amt);
        bool ok = true;
        N = dfPiso(dfMul(dfRaiz(dfSoma(dfMul(dY, dY), dfMul(dX, dX))), lerPar(14)), 1.0e-6, ok) + 2;
        if (!ok) {
            exatos(x, y, CX, CY, amtD);
            N = dTrunc(dMul(dSqrt(dSoma(dMul(eY, eY), dMul(eX, eX))), lerDouble(1))) + 2;
        }
        N = min(N, teto);
        float2 n = float2(float(N), 0.0);
        // as posições em 16.16 passam de 10⁷: a margem é de 10⁻⁴ (o erro dos dois floats fica perto de 10⁻⁶)
        ok = true;
        DX = dfCorte(dfDiv(dX * 65536.0, n), 1.0e-4, ok);
        DY = dfCorte(dfDiv(dY * 65536.0, n), 1.0e-4, ok);
        if (!ok) {
            exatos(x, y, CX, CY, amtD);
            if (u.tipo == 2) {
                uint2 u = dDivInt(D_65536, N);
                DX = dTrunc(dMul(u, eX));
                DY = dTrunc(dMul(u, eY));
            } else {
                DX = dTrunc(dDivInt(dEscala2(eX, 16), N));
                DY = dTrunc(dDivInt(dEscala2(eY, 16), N));
            }
        }
        ok = true;
        if (u.tipo == 2) {
            X0 = dfCorte(dfSoma(float2(float(x), 0.0), dfNeg(dX * 0.5)) * 65536.0, 1.0e-4, ok);
            Y0 = dfCorte(dfSoma(float2(float(y), 0.0), dfNeg(dY * 0.5)) * 65536.0, 1.0e-4, ok);
            if (!ok) {
                exatos(x, y, CX, CY, amtD);
                X0 = dTrunc(dEscala2(dSub(dDeInt(x), dEscala2(eX, -1)), 16));
                Y0 = dTrunc(dEscala2(dSub(dDeInt(y), dEscala2(eY, -1)), 16));
            }
            cnt = N;
        } else {
            X0 = x << 16;
            Y0 = y << 16;
            cnt = corteRapido(x, y, dX, dY, N, ok);
            if (!ok) {
                exatos(x, y, CX, CY, amtD);
                cnt = corte(x, y, eX, eY, N);
            }
        }
    } else {
        // a conta toda em double emulado (só para conferir o caminho rápido na bancada)
        uint2 amt = lerDouble(0), qq = lerDouble(1);
        uint2 Xd = dSub(dDeInt(x), CX), Yd = dSub(dDeInt(y), CY);
        if (u.tipo == 2) amt = dAbs(amt);
        uint2 dX = dMul(Xd, amt), dY = dMul(Yd, amt);
        N = min(dTrunc(dMul(dSqrt(dSoma(dMul(dY, dY), dMul(dX, dX))), qq)) + 2, teto);
        uint2 n = dDeInt(N);
        if (u.tipo == 2) {
            uint2 u = dDiv(D_65536, n);
            DX = dTrunc(dMul(u, dX));
            DY = dTrunc(dMul(u, dY));
            X0 = dTrunc(dEscala2(dSub(dDeInt(x), dEscala2(dX, -1)), 16));
            Y0 = dTrunc(dEscala2(dSub(dDeInt(y), dEscala2(dY, -1)), 16));
            cnt = N;
        } else {
            DX = dTrunc(dDiv(dEscala2(dX, 16), n));
            DY = dTrunc(dDiv(dEscala2(dY, 16), n));
            X0 = x << 16;
            Y0 = y << 16;
            cnt = corte(x, y, dX, dY, N);
        }
    }
    bool desvanecer = u.tipo == 1;
    int lx = (W << 16) - 0x10000, ly = (H << 16) - 0x10000;
    float peso = float(N);
    for (int k = 0; k < cnt; k++) {
        int X = X0 + k * DX, Y = Y0 + k * DY;
        // o Centered não lê a amostra fora de [0, (lado − 1)·65536]
        if (u.tipo != 2 || (X >= 0 && Y >= 0 && X <= lx && Y <= ly)) somar(amostraDoAe(X, Y), desvanecer ? peso : -1.0);
        peso = peso - 1.0;
    }
    __nv_out = saida(desvanecer ? mul(float(N * (N + 1)), 0.5) : float(N));
    return __nv_out;
}
