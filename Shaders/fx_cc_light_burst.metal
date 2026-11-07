// ---------------------------------------------------------------------------
// CC Light Burst 2.5
// origem : assets/effects/cc-light-burst.xml
// id     : nova.effect.cclightburst
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_light_burstParams {
    float2 center;
    float intensity;
    float rayLength;
    int burst;
    int haloAlpha;
    int setColor;
    float4 cor;
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

/** O valor do controle em 16.16, como o AE o entrega ao plugin: o float32 · 65536, meio para longe do zero. */
int fixo(float v) {
    float m = abs(v) * 65536.0;
    float i = floor(m);
    int r = int(i) + (m - i >= 0.5 ? 1 : 0);
    return v < 0.0 ? -r : r;
}

// ============================================================ dois floats (~48 bits)
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
 * O piso de v quando ele está LONGE de um inteiro: a menos de `margem` do inteiro mais perto, o erro dos dois floats
 * poderia trocar o lado da divisa, e `seguro` vira false. A distância é medida direto (q − round(q)): com margem de
 * 10⁻⁹, "1 − margem" em float32 já é 1, e um v um fio abaixo do inteiro passaria por seguro.
 */
int dfPiso(float2 v, float margem, inout bool seguro) {
    float f = floor(v.x);
    float2 r = dfSoma(v, float2(-f, 0.0));
    float q = r.x + r.y;
    if (abs(q - floor(q + 0.5)) < margem) seguro = false;
    return int(f) + int(floor(q));
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
    return int(t) + int(v.x >= 0.0 ? floor(v.y) : ceil(v.y));
}

#ifndef NV_LEVE
// ============================================================ o double do plugin, emulado (o do CC Radial Blur)
// uint2(alto, baixo) com os bits de um double IEEE-754. Só números normais e zero. Só multiplicação, soma e a divisão
// por inteiro (dígitos de 16 bits): nada de laço de 55 passos.
const uint2 D_UM = uint2(0x3FF00000u, 0u);
const uint2 D_MEIO = uint2(0x3FE00000u, 0u);
const uint2 D_MENOS_0005 = uint2(0xBF747AE1u, 0x47AE147Bu);   // −0,005

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
        for (int i = 0; i < 60 && m.x < 0x800000u; i++) { m = shl64(m, 1); e -= 1; }
    }
    return dArredondar(dSinal(a), e, m);
}

uint2 dSub(uint2 a, uint2 b) { return dSoma(a, dNeg(b)); }

/**
 * a / n em double, para n inteiro de 1 a 4095, com o arredondamento do IEEE: a divisão longa da mantissa em dígitos
 * de 16 bits (5 divisões de inteiro).
 */
uint2 dDivInt(uint2 a, int n) {
    if (dZero(a)) return a;
    uint un = uint(n);
    int bn = 0;
    for (int i = 0; i < 13 && (un >> uint(bn)) != 0u; i++) bn++;
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
    for (int k = 0; k < 31 && (u & 0x80000000u) == 0u; k++) { u <<= 1; e--; }
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

// ============================================================ comparações exatas (inteiros de 144 bits)
// Para decidir de que lado de um inteiro cai um quociente ou uma raiz do plugin sem dividir nem tirar raiz em double
// emulado: a·2^sh contra b·v, os dois produtos inteiros inteiros, em dígitos de 16 bits.

/** O sinal de A·2^sh − B·V (A, B, V inteiros sem sinal de até 64 bits, uint2(alto, baixo); |sh| até ~80). */
int compara(uint2 A, int sh, uint2 B, uint2 V) {
    uint b[4];
    uint v[4];
    uint P[9];
    uint Q[9];
    b[0] = B.y & 0xFFFFu; b[1] = B.y >> 16; b[2] = B.x & 0xFFFFu; b[3] = B.x >> 16;
    v[0] = V.y & 0xFFFFu; v[1] = V.y >> 16; v[2] = V.x & 0xFFFFu; v[3] = V.x >> 16;
    for (int i = 0; i < 9; i++) { P[i] = 0u; Q[i] = 0u; }
    for (int i = 0; i < 4; i++) {
        uint c = 0u;
        for (int j = 0; j < 4; j++) {
            uint t = b[i] * v[j] + P[i + j] + c;
            P[i + j] = t & 0xFFFFu;
            c = t >> 16;
        }
        P[i + 4] = c;
    }
    bool sobra = false;            // os bits de A que saíram pela direita (sh < 0)
    if (sh < 0) {
        int n = -sh;
        if (n >= 64) { sobra = A != uint2(0u); A = uint2(0u); }
        else { uint2 r = shr64(A, n); sobra = shl64(r, n) != A; A = r; }
        sh = 0;
    }
    uint a[4];
    a[0] = A.y & 0xFFFFu; a[1] = A.y >> 16; a[2] = A.x & 0xFFFFu; a[3] = A.x >> 16;
    int ls = sh >> 4, bs = sh & 15;
    for (int i = 0; i < 4; i++) {
        if (a[i] == 0u) continue;
        int k = i + ls;
        uint baixo = (a[i] << uint(bs)) & 0xFFFFu, alto = bs == 0 ? 0u : a[i] >> uint(16 - bs);
        if (k >= 9 || (k == 8 && alto != 0u)) return 1;      // A·2^sh passa de 2^144 > B·V
        Q[k] |= baixo;
        if (k + 1 < 9) Q[k + 1] |= alto;
    }
    for (int i = 8; i >= 0; i--) {
        if (Q[i] != P[i]) return Q[i] > P[i] ? 1 : -1;
    }
    return sobra ? 1 : 0;
}

/** O expoente de 2 do maior bit de M ≥ 1. */
int log2Int(int M) {
    int k = 0;
    for (int i = 0; i < 30 && (M >> (k + 1)) != 0; i++) k++;
    return k;
}

/** O par de dois floats como double (o mais perto). */
uint2 dDeDf(float2 v) { return dSoma(dDeFloat(v.x), dDeFloat(v.y)); }

/**
 * fl(a/b), o quociente em double do plugin (a inteiro exato, b ≠ 0 exato), sem dividir em double emulado: `aprox` é o
 * quociente em dois floats. Longe de um inteiro ele basta (só o trunc dele importa). Perto do inteiro m, fl(a/b) é
 * m + j·ulp com j pequeno: j sai comparando a com b·(|m| ± (2i + 1)·½ulp), exato (`compara`); o empate vai ao par
 * (m tem a mantissa par). |j| ≥ 3 conta como 3: daí em diante nenhuma soma com 1 ou 2 volta ao inteiro.
 */
uint2 quocienteExato(uint2 a, uint2 b, float2 aprox) {
    if (dZero(a)) return uint2(0u);
    float qf = aprox.x + aprox.y;
    int m = int(floor(qf + 0.5));
    if (abs(qf - float(m)) > 1.0e-6 || m == 0) return dDeDf(aprox);
    int M = abs(m), k = log2Int(M);
    int pAc = k - 52, pAb = M == (1 << k) ? k - 53 : k - 52;
    int ea = dExpo(a), eb = dExpo(b);
    uint2 ma = dMant(a), mb = dMant(b);
    uint2 baseAc = shl64(uint2(0u, uint(M)), 1 - pAc), baseAb = shl64(uint2(0u, uint(M)), 1 - pAb);
    int j = 0;
    // para cima: o quociente passa de |m| + (i + ½)·ulp?
    for (int i = 0; i < 3; i++) {
        int c = compara(ma, ea - eb - pAc + 1, mb, soma64(baseAc, uint2(0u, uint(2 * i + 1))));
        if (c > 0) { j = i + 1; continue; }
        if (c == 0) j = (i & 1) == 0 ? i : i + 1;
        break;
    }
    if (j == 0) {
        // para baixo: fica abaixo de |m| − (i + ½)·ulp?
        for (int i = 0; i < 3; i++) {
            int c = compara(ma, ea - eb - pAb + 1, mb, sub64(baseAb, uint2(0u, uint(2 * i + 1))));
            if (c < 0) { j = -(i + 1); continue; }
            if (c == 0) j = (i & 1) == 0 ? -i : -(i + 1);
            break;
        }
    }
    uint2 q = dDeInt(M);
    if (j != 0) q = dSoma(q, dEscala2(dDeInt(j), j > 0 ? pAc : pAb));
    return (dSinal(a) ^ dSinal(b)) == 0u ? q : dNeg(q);
}

/** round(fração · lado · 65536), meio para longe do zero — a conta é exata em double (24 + 13 + 16 bits). */
int pontoFixo(float fracao, int lado) {
    uint2 v = dEscala2(dMul(dDeFloat(abs(fracao)), dDeInt(lado)), 16);
    int r = dTrunc(dSoma(v, D_MEIO));
    return fracao < 0.0 ? -r : r;
}
#else
// ---- A VERSAO LEVE (NV_LEVE, 0.915.0) ----
// Mali e PowerVR recusavam o shader inteiro (log vazio ou "Compile failed.", 24 aparelhos na 0.894.0): o double
// emulado com inteiros e as comparacoes de 144 bits passam do que o compilador deles aguenta. Quando o driver recusa,
// o motor compila de novo com NV_LEVE (ver `EffectPipeline.programFor`): sem o double, tudo nos dois floats (~48 bits).
// Muda so o pixel que cai perto da divisa de um inteiro (o passo, o comeco do Center e o corte na borda), por 1 nivel.
int pontoFixo(float fracao, int lado) {
    bool ok = true;
    float2 v = produtoExato(abs(fracao), float(lado)) * 65536.0;
    int r = dfPiso(dfSoma(v, float2(0.5, 0.0)), 0.0, ok);
    return fracao < 0.0 ? -r : r;
}
#endif

// ============================================================ a camada e a leitura sub-pixel do AE
int W, H;                 // a camada do AE (px), dentro do buffer a partir de `inicio`
int2 inicio;
bool dePe;

/** Um pixel da camada (RGBA 0..255, u.cor reta) na orientação da IMAGEM (a linha 0 é o topo); fora, transparente. */
int4 daCamada(int x, int y) {
    if (x < 0 || y < 0 || x >= W || y >= H) return int4(0);
    int2 b = inicio + int2(x, dePe ? H - 1 - y : y);
    return int4(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5);
}

/** O índice inteiro de uma posição 16.16 como o AE: (short)(X >> 16). */
int indice(int X) { return int(uint(X >> 16) << 16) >> 16; }

/**
 * O subpixel_sample de 8 bits do AE (PF.dll; o do CC Lens), na ordem da SSE dele. Sem fração: o pixel. Os quatro
 * iguais: o pixel. Alfas iguais: cada canal (p3·w3 + p2·w2) + (p1·w1 + p0·w0) + 0,5. Senão: a u.cor pesada pelo alfa,
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

// ============================================================ o corte do raio na borda da camada
/**
 * Quantas amostras o raio lê (o mesmo trecho nas seis funções de pixel): para quando o fim do raio sai da camada —
 * pelo lado em x (`base` − trunc(N·x / dX) à esquerda, trunc((W − x)·N / dX) + 1 à direita), depois o menor com o
 * lado em y. O `base` é 2, menos no Straight com Set Color (0x180003bf0), que usa 1. Em dois floats.
 */
int corte(int x, int y, float2 dX, float2 dY, int N, int base, inout bool ok) {
    float n = float(N);
    int cnt = N;
    float2 fx = dfSoma(dX, float2(float(x), 0.0));
    if (fx.x > float(W) || (fx.x == float(W) && fx.y > 0.0)) {
        cnt = dfCorte(dfDiv(float2(float(W - x) * n, 0.0), dX), 1.0e-9, ok) + 1;
    } else if (fx.x < -1.0 || (fx.x == -1.0 && fx.y < 0.0)) {
        cnt = base - dfCorte(dfDiv(float2(n * float(x), 0.0), dX), 1.0e-9, ok);
    }
    float2 fy = dfSoma(dY, float2(float(y), 0.0));
    bool baixo = fy.x > float(H) || (fy.x == float(H) && fy.y > 0.0);
    bool cima = !baixo && (fy.x < -1.0 || (fy.x == -1.0 && fy.y < 0.0));
    if (baixo || cima) {
        float2 t = baixo ? dfSoma(dfDiv(float2(float(H - y) * n, 0.0), dY), float2(1.0, 0.0))
                       : dfSoma(float2(float(base), 0.0), dfNeg(dfDiv(float2(n * float(y), 0.0), dY)));
        if (t.x < float(cnt) || (t.x == float(cnt) && t.y < 0.0)) cnt = dfCorte(t, 1.0e-9, ok);
        else if (abs(t.x - float(cnt)) < 1.0e-6) ok = false;
    }
    if (abs(fx.x - float(W)) < 1.0e-6 || abs(fx.x + 1.0) < 1.0e-6 || abs(fy.x - float(H)) < 1.0e-6 || abs(fy.x + 1.0) < 1.0e-6) ok = false;
    return cnt;
}

#ifndef NV_LEVE
/**
 * O `corte` exato (quando os dois floats caem perto de uma divisa): as comparações com a borda e as somas em double
 * emulado, e cada quociente pelo `quocienteExato` (sem dividir). O + 1 e o `base` − de y também arredondam no plugin
 * (2 − (−14,999999999999998) dá 17: cruza a potência de 2 e o empate vai ao par).
 */
int corteExato(int x, int y, uint2 eX, uint2 eY, float2 dX, float2 dY, int N, int base) {
    float n = float(N);
    int cnt = N;
    uint2 fx = dSoma(dDeInt(x), eX);
    if (dMenor(dDeInt(W), fx)) {
        cnt = dTrunc(quocienteExato(dDeInt((W - x) * N), eX, dfDiv(float2(float(W - x) * n, 0.0), dX))) + 1;
    } else if (dMenor(fx, dDeInt(-1))) {
        cnt = base - dTrunc(quocienteExato(dDeInt(N * x), eX, dfDiv(float2(n * float(x), 0.0), dX)));
    }
    uint2 fy = dSoma(dDeInt(y), eY);
    bool baixo = dMenor(dDeInt(H), fy);
    if (baixo || dMenor(fy, dDeInt(-1))) {
        int a = baixo ? (H - y) * N : N * y;
        uint2 q = quocienteExato(dDeInt(a), eY, dfDiv(float2(float(a), 0.0), dY));
        uint2 t = baixo ? dSoma(q, D_UM) : dSub(dDeInt(base), q);
        // "t > cnt ? cnt : trunc(t)"
        if (!dMenor(dDeInt(cnt), t)) cnt = dTrunc(t);
    }
    return cnt;
}
#endif

// ============================================================ o efeito
const int N_MAXIMO = 4095;

fragment float4 fx_cc_light_burst(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_light_burstParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    z0 = min(eng.acIteration, 0);
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA; o que sobra do buffer em volta é o "fora da camada" para onde o brilho se espalha.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    inicio = (buf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;

    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena de pé a linha 0 do buffer é a
    // BASE. Fora da camada o pixel também é calculado (o raio dele pode alcançar a camada).
    int2 local = int2(floor(in.acScreenNorm * eng.acResolution)) - inicio;
    int x = local.x, y = dePe ? H - 1 - local.y : local.y;

    int tipo = clamp(u.burst, 0, 2);           // 0 Straight, 1 Fade, 2 Center
    int rlF = fixo(u.rayLength);
    // Ray Length 0 sem Set Color nem Halo Alpha: N = 2 amostras no próprio pixel e brilho 1 — o pixel como está.
    if (rlF == 0 && !u.setColor && !u.haloAlpha) {
        int4 p = daCamada(x, y);
        __nv_out = p.a == 0 ? float4(0.0) : float4(p) / 255.0;
        return __nv_out;
    }

    // O centro como FRAÇÃO da camada em float32 (o AE entrega round(fração · lado · 65536)); cru, como no CC Radial
    // Blur, e levado ao buffer só quando a camada não o ocupa inteiro.
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
#ifndef NV_LEVE
    uint2 CX = dEscala2(dDeInt(pcx), -16), CY = dEscala2(dDeInt(pcy), -16);
#endif
    float2 cx = dfDeInt(pcx, 1.0 / 65536.0), cy = dfDeInt(pcy, 1.0 / 65536.0);
    float2 px = dfSoma(float2(float(x), 0.0), dfNeg(cx)), py = dfSoma(float2(float(y), 0.0), dfNeg(cy));

    // s = Ray Length · −0,005 em double (o Center usa −|s|), levado aos dois floats (Ray Length múltiplo de 12,5: exato)
#ifndef NV_LEVE
    uint2 sD = dMul(dEscala2(dDeInt(rlF), -16), D_MENOS_0005);
    if (tipo == 2) sD = dNeg(dAbs(sD));
    float2 s = dfDeD(sD);
#else
    float2 s = dfMul(dfDeInt(rlF, 1.0 / 65536.0), float2(-0.004999999888241291, -1.1175870645585562e-10));
    if (tipo == 2 && s.x > 0.0) s = -s;
#endif
    float2 dX = dfMul(px, s), dY = dfMul(py, s);
    float2 r = dfRaiz(dfSoma(dfMul(dY, dY), dfMul(dX, dX)));

    // N = ⌊|d| · peso⌋ + 2: 0,71 (1 com Halo Alpha); no rascunho, 0,33 — o Draft do próprio plugin
    float2 peso = eng.acRascunho == 1 ? float2(0.33000001311302185, -1.3113021779531664e-08)
              : (u.haloAlpha ? float2(1.0, 0.0) : float2(0.7099999785423279, 2.1457672971791908e-08));
    float2 t = dfMul(r, peso);
    bool ok = true;
    int N = dfPiso(t, 1.0e-9, ok);
#ifndef NV_LEVE
    uint2 eX = uint2(0u), eY = uint2(0u);
    bool temExatos = false;
    if (!ok) {
        int m = int(floor(t.x + t.y + 0.5));
        N = m;
        if (u.haloAlpha && eng.acRascunho != 1 && m > 0) {
            // peso 1: t = r = fl(√R), R = fl(dy² + dx²) do plugin. r ≥ m ⟺ R − m² > −m·ulp(abaixo de m) (sem raiz):
            // um raio "pitagórico" (3, 4, 5 vezes um s inexato) cai um fio abaixo ou acima do inteiro
            eX = dMul(dSub(dDeInt(x), CX), sD);
            eY = dMul(dSub(dDeInt(y), CY), sD);
            temExatos = true;
            uint2 R = dSoma(dMul(eY, eY), dMul(eX, eX));
            int k = log2Int(m);
            uint2 mu = dEscala2(dDeInt(m), m == (1 << k) ? k - 53 : k - 52);
            if (!dMenor(dNeg(mu), dSub(R, dDeInt(m * m)))) N = m - 1;
        }
        // sem Halo Alpha (peso 0,71) |d|·peso quase nunca cai em inteiro: arredonda
    }
#else
    if (!ok) N = int(floor(t.x + t.y + 0.5));
#endif
    // o teto vale para o N (o raio inteiro com menos amostras, os pesos coerentes), antes do passo
    int teto = eng.acRascunho == 1 ? 96 : N_MAXIMO;
    N = min(N + 2, teto);

    // o passo trunc((65536 · d) · (1/N)) e o começo (Center: trunc((p − d/2) · 65536)); perto da divisa, em double
    float2 n = float2(float(N), 0.0);
    ok = true;
    int DX = dfCorte(dfDiv(dX * 65536.0, n), 1.0e-4, ok);
    int DY = dfCorte(dfDiv(dY * 65536.0, n), 1.0e-4, ok);
#ifndef NV_LEVE
    if (!ok) {
        if (!temExatos) {
            eX = dMul(dSub(dDeInt(x), CX), sD);
            eY = dMul(dSub(dDeInt(y), CY), sD);
            temExatos = true;
        }
        uint2 q = dDivInt(D_UM, N);
        DX = dTrunc(dMul(dEscala2(eX, 16), q));
        DY = dTrunc(dMul(dEscala2(eY, 16), q));
    }
#endif
    int X0 = x * 65536, Y0 = y * 65536;
    if (tipo == 2) {
        ok = true;
        X0 = dfCorte(dfSoma(float2(float(x), 0.0), dfNeg(dX * 0.5)) * 65536.0, 1.0e-4, ok);
        Y0 = dfCorte(dfSoma(float2(float(y), 0.0), dfNeg(dY * 0.5)) * 65536.0, 1.0e-4, ok);
#ifndef NV_LEVE
        if (!ok) {
            if (!temExatos) {
                eX = dMul(dSub(dDeInt(x), CX), sD);
                eY = dMul(dSub(dDeInt(y), CY), sD);
                temExatos = true;
            }
            X0 = dTrunc(dEscala2(dSub(dDeInt(x), dEscala2(eX, -1)), 16));
            Y0 = dTrunc(dEscala2(dSub(dDeInt(y), dEscala2(eY, -1)), 16));
        }
#endif
    }
    int base = u.setColor && tipo == 0 ? 1 : 2;
    ok = true;
    int cnt = corte(x, y, dX, dY, N, base, ok);
#ifndef NV_LEVE
    if (!ok) {
        if (!temExatos) {
            eX = dMul(dSub(dDeInt(x), CX), sD);
            eY = dMul(dSub(dDeInt(y), CY), sD);
        }
        cnt = corteExato(x, y, eX, eY, dX, dY, N, base);
    }
#endif
    // fora da camada o corte pode passar de N (o plugin varre até a borda): o mesmo teto
    cnt = min(cnt, N_MAXIMO);

    // ---- a soma das amostras (as seis funções: 0x1800089a0, 0x180008ee0, 0x180009b40, 0x1800094f0 sem u.cor;
    //      0x180003bf0/0x180004630 + 0x1800085a0, 0x180007ec0, 0x180008210 com u.cor) ----
    bool fade = tipo == 1;
    float4 soma = float4(0.0);          // (alfa, R·alfa, G·alfa, B·alfa) em float32; com u.cor, só o alfa
    float pesoF = float(N);         // o peso em float (Fade sem u.cor)
    int pesoI = N;                  // o peso inteiro (Fade com u.cor)
    for (int k = 0; k < cnt; k++) {
        int4 c = amostraDoAe(X0 + k * DX, Y0 + k * DY);
        int a = c.a;
        if (u.haloAlpha) a = a >= 128 ? 255 - a : a;
        if (u.setColor) {
            soma.x = fixa(soma.x + float(fade ? a * pesoI : a));
        } else if (fade) {
            if (!u.haloAlpha || a != 0) {
                float wa = u.haloAlpha ? mul(mul(float(a), 2.0), pesoF) : mul(float(a), pesoF);
                soma = fixa4(soma + float4(wa, mul(float(c.r), wa), mul(float(c.g), wa), mul(float(c.b), wa)));
            }
        } else {
            if (!u.haloAlpha || a != 0) {
                int a2 = u.haloAlpha ? 2 * a : a;
                soma = fixa4(soma + float4(float(a2), float(c.r * a2), float(c.g * a2), float(c.b * a2)));
            }
        }
        pesoF = fixa(pesoF - 1.0);
        pesoI -= 1;
    }

    int4 o;
    if (u.setColor) {
        float A = u.haloAlpha ? mul(soma.x, 2.0) : soma.x;
        float div = fade ? float(((N + 1) * N) >> 1) : float(N);
        o.a = int(trunc(divisao(A, div))) & 255;
        o.rgb = int3(floor(u.cor.rgb * 255.0 + 0.5));
    } else {
        if (soma.x == 0.0) { __nv_out = float4(0.0); return __nv_out; }
        float div = fade ? (u.haloAlpha ? mul(mul(fixa(float(N) + 1.0), float(N)), 0.5) : mul(float((N + 1) * N), 0.5))
                         : float(N);
        o.a = int(trunc(divisao(soma.x, div))) & 255;
        for (int i = 0; i < 3; i++) o[i] = int(trunc(divisao(soma[i + 1], soma.x))) & 255;
    }
    if (o.a == 0) { __nv_out = float4(0.0); return __nv_out; }

    // ---- o brilho (0x1800032f0): cada canal · (1 + força / (|d| + diag/32)), em double, cortado em 0..255 ----
    int iF = fixo(u.intensity);
    if (iF != 0) {
        float2 diag = dfRaiz(dfSoma(dfMul(float2(float(H), 0.0), float2(float(H), 0.0)), dfMul(float2(float(W), 0.0), float2(float(W), 0.0))));
        float2 k32 = diag * 0.03125;
        // força = (Intensity · 0,01) · (|s| · (diag/32 · 2,5)), na ordem do plugin
        float2 i01 = dfMul(dfDeInt(iF, 1.0 / 65536.0), float2(0.009999999776482582, 2.2351741291171123e-10));
        float2 forca = dfMul(i01, dfMul(s.x < 0.0 ? -s : s, dfMul(k32, float2(2.5, 0.0))));
        float2 f = dfSoma(dfDiv(forca, dfSoma(r, k32)), float2(1.0, 0.0));
        for (int i = 0; i < 3; i++) {
            float2 v = dfMul(float2(float(o[i]), 0.0), f);
            bool cheio = v.x > 255.0 || (v.x == 255.0 && v.y >= 0.0);
            o[i] = v.x <= 0.0 ? 0 : (cheio ? 255 : dfTrunc(v));
        }
    }
    __nv_out = float4(float3(o.rgb), float(o.a)) / 255.0;
    return __nv_out;
}
