// ---------------------------------------------------------------------------
// CC Vector Blur
// origem : assets/effects/cc-vector-blur.xml
// id     : nova.effect.ccvectorblur
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_vector_blurParams {
    int tipo;
    float amount;
    float angleOffset;
    float ridge;
    int mapProperty;
    float mapSoftness;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 do plugin
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se
// funde com a soma seguinte num fma: cada produto arredonda sozinho, como no plugin.
float um;
int z0;
int2 tam;
bool dePe;

/** O pixel do buffer de um pixel da IMAGEM (e vice-versa): numa cena de pé, a linha 0 é a base. */
int2 naImagem(int2 p) { return dePe ? int2(p.x, tam.y - 1 - p.y) : p; }

float fixa(float x) { return x * um; }
float3 fixa3(float3 x) { return x * um; }
float mul(float a, float b) { return (a * b) * um; }
float3 mul3(float a, float3 b) { return (a * b) * um; }

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

/** n / d em float32 com o arredondamento do IEEE, para inteiros (n ≤ d · 2^24, d < 2^26): divisão longa. */
float divisaoInteira(uint n, uint d) {
    if (n == 0u) return 0.0;
    uint q = n / d;
    uint resto = n - q * d;
    int e = 0;
    while (q < 0x1000000u) {
        resto <<= 1;
        q <<= 1;
        if (resto >= d) { q |= 1u; resto -= d; }
        e++;
    }
    uint m = q >> 1;
    if ((q & 1u) == 1u && (resto != 0u || (m & 1u) == 1u)) m++;
    int expo = 24 - e;
    if (m == 0x1000000u) { m >>= 1; expo++; }
    return as_type<float>((uint(expo + 127) << 23) | (m & 0x7FFFFFu));
}

/** O valor do controle como o plugin o lê: PF_Fixed (16.16). Cabe num float. */
float fixo(float v) { return rint(v * 65536.0) * (1.0 / 65536.0); }

// O float32 inteiro nos 4 bytes de um texel RGBA8 (o buffer do motor é de 8 bits).
float4 guardar(float v) {
    uint b = as_type<uint>(v);
    return float4(float(b & 255u), float((b >> 8) & 255u), float((b >> 16) & 255u), float(b >> 24)) / 255.0;
}
float lerDe(sampler2D t, int2 p) {
    uint4 c = uint4(t.read(uint2(naImagem(p)), uint(0)) * 255.0 + 0.5);
    return as_type<float>(c.x | (c.y << 8) | (c.z << 16) | (c.w << 24));
}

// ============================================================ o double do plugin, emulado
// uint2(alto, baixo) com os bits de um double IEEE-754. Só números normais e zero (é o que a conta usa).
const uint2 D_ZERO = uint2(0u, 0u);
const uint2 D_UM = uint2(0x3FF00000u, 0u);
const uint2 D_MEIO = uint2(0x3FE00000u, 0u);
const uint2 D_DOIS = uint2(0x40000000u, 0u);
const uint2 D_MENOS_UM = uint2(0xBFF00000u, 0u);
const uint2 D_90 = uint2(0x40568000u, 0u);
const uint2 D_65536 = uint2(0x40F00000u, 0u);
const uint2 D_K_RIDGE = uint2(0x3F60624Du, 0xD2F1A9FCu);   // 0,002
const uint2 D_GRAU = uint2(0x3F91DF46u, 0xA2529D39u);      // π/180
const uint2 D_MEIO_PI = uint2(0x3FF921FBu, 0x54442D18u);
const uint2 D_DOIS_PI = uint2(0x401921FBu, 0x54442D18u);
const uint2 D_K_DIAG = uint2(0x3FF69FBEu, 0x76C8B439u);    // 1,414

bool dZero(uint2 a) { return (a.x & 0x7FFFFFFFu) == 0u && a.y == 0u; }
uint dSinal(uint2 a) { return a.x >> 31; }
int dExpo(uint2 a) { return int((a.x >> 20) & 0x7FFu) - 1023; }
uint2 dMant(uint2 a) { return uint2((a.x & 0xFFFFFu) | 0x100000u, a.y); }
uint2 dNeg(uint2 a) { return dZero(a) ? a : uint2(a.x ^ 0x80000000u, a.y); }
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

/*
 * O produto das mantissas em dígitos de 16 bits. Os laços daqui têm limite FIXO (sem o `+ z0` dos outros): o
 * compilador os desenrola, e `A`, `B` e `P` ficam em registradores. Com o limite variável os três arrays iam para a
 * memória (o índice muda a cada volta), e as ~20 multiplicações por pixel eram quase todo o desfoque (0.569.0, na
 * GPU do PC: o passe do desfoque 84 → 18 ms; compilar continua em 0,4 s). É conta inteira: o resultado não muda.
 */
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

/** trunc, para |a| < 2^31. */
int dTrunc(uint2 a) {
    if (dZero(a)) return 0;
    int e = dExpo(a);
    if (e < 0) return 0;
    if (e > 30) return dSinal(a) == 1u ? -0x7FFFFFFF : 0x7FFFFFFF;
    int v = int(shr64(dMant(a), 52 - e).y);
    return dSinal(a) == 1u ? -v : v;
}

uint2 dDeFloat(float f) {
    uint b = as_type<uint>(f);
    uint E = (b >> 23) & 0xFFu;
    if (E == 0u) return uint2(b & 0x80000000u, 0u);
    uint2 m = shl64(uint2(0u, b & 0x7FFFFFu), 29);
    return uint2((b & 0x80000000u) | (uint(int(E) - 127 + 1023) << 20) | m.x, m.y);
}

uint2 dDeInt(int i) {
    if (i == 0) return uint2(0u);
    uint u = uint(abs(i));
    int e = 31;
    while ((u & 0x80000000u) == 0u) { u <<= 1; e--; }
    return dMontar(i < 0 ? 1u : 0u, e, shl64(uint2(0u, u), 21));
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

// ============================================================ o programa de double
// As contas em double do plugin são uma lista de instruções (operação, destino, a, b) que um laço só executa:
// o compilador copia o corpo de uma função em cada chamada, e com ~90 contas o passe levava 22 s para compilar
// (driver da AMD). Operando >= 64 é a constante K[operando − 64]. Seno e cosseno: os do fdlibm (redução em 3
// etapas, os polinômios do __kernel_sin/cos) — o runtime C do AE fica a até 1 ulp deles.
const uint2 K[28] = uint2[28](
    D_MEIO, D_UM, D_DOIS, D_65536, D_90, D_GRAU, D_MEIO_PI, D_DOIS_PI, D_K_RIDGE, D_K_DIAG,
    uint2(0x3FE45F30u, 0x6DC9C883u), uint2(0x3FF921FBu, 0x54400000u), uint2(0x3DD0B461u, 0x1A600000u),
    uint2(0x3BA3198Au, 0x2E037073u), uint2(0x3BA3198Au, 0x2E000000u), uint2(0x397B839Au, 0x252049C1u),
    uint2(0xBFC55555u, 0x55555549u), uint2(0x3F811111u, 0x1110F8A6u), uint2(0xBF2A01A0u, 0x19C161D5u),
    uint2(0x3EC71DE3u, 0x57B1FE7Du), uint2(0xBE5AE5E6u, 0x8A2B9CEBu), uint2(0x3DE5D93Au, 0x5ACFD57Cu),
    uint2(0x3FA55555u, 0x5555554Cu), uint2(0xBF56C16Cu, 0x16C15177u), uint2(0x3EFA01A0u, 0x19CB1590u),
    uint2(0xBE927E4Fu, 0x809C52ADu), uint2(0x3E21EE9Eu, 0xBDB4B1C4u), uint2(0xBDA8FAE9u, 0xBE8838D4u)
);

// >>> programa (gerado por tools/ccvectorblur/benchmark/programa.py — não edite à mão)
const int OP_SOMA = 0, OP_SUB = 1, OP_MUL = 2, OP_DIV = 3, OP_RAIZ = 4, OP_ESC2 = 5, OP_F32 = 6, OP_TRUNC = 7, OP_ABS = 8, OP_QX = 9, OP_SENQ = 10, OP_COSQ = 11, OP_SINAL = 12;
const int rG0 = 0, rG1 = 1, rRG = 2, rA = 3, rESC = 4, rANG = 5, rP = 6, rX = 7;
const int rY = 8, rW = 9, rH = 10, rAX = 11, rANGRAD = 12, rREV = 13, rTH = 14, rS0 = 15;
const int rC0 = 16, rFN = 17, rKS = 18, rKC = 19, rCOMP = 20, rL = 21, rN = 22, rVX = 23;
const int rVY = 24, rDXV = 25, rDYV = 26, rX0 = 27, rY0 = 28, rDX = 29, rDY = 30, rPXD = 31;
const int rTA = 32, rTB = 33, rPYD = 34, rTC = 35, rTD = 36, t0 = 37, t1 = 38, t2 = 39;
const int t3 = 40, t4 = 41, t5 = 42, t6 = 43, t7 = 44, t8 = 45, t9 = 46, t10 = 47;
const int t11 = 48;
const int N_REG = 49;
const int SEG_COMUM = 0, SEG_THETA = 5, SEG_SENCOS = 10, SEG_GRADIENTE = 72, SEG_DIRECAO = 107, SEG_FIM = 143;
const int4 PROGRAMA[143] = int4[143](
    // ---- COMUM: os valores de todo pixel
    int4(OP_MUL, rAX, rESC, rA),  // AX = escala · Amount
    int4(OP_SOMA, t0, rANG, 64 + 4),
    int4(OP_MUL, rANGRAD, t0, 64 + 5),  // ângulo = (Angle Offset + 90) · π/180
    int4(OP_MUL, rREV, rRG, 64 + 7),  // voltas = Ridge · 2π
    int4(OP_SUB, rTH, rANGRAD, 64 + 6),  // θ do Angle Offset (0 exato com 0°)
    // ---- THETA: Direction: θ = float32(valor · voltas + ângulo − voltas/2)
    int4(OP_ESC2, t0, rREV, -1),
    int4(OP_SUB, t0, rANGRAD, t0),
    int4(OP_MUL, t1, rP, rREV),
    int4(OP_SOMA, t1, t1, t0),
    int4(OP_F32, rTH, t1, 0),
    // ---- SENCOS: seno e cosseno de θ (fdlibm: redução em 3 etapas e os polinômios do __kernel_sin/cos)
    int4(OP_ABS, t0, rTH, 0),  // t = |θ|
    int4(OP_MUL, t1, t0, 64 + 10),
    int4(OP_SOMA, t1, t1, 64 + 0),
    int4(OP_TRUNC, rFN, t1, 0),  // n = trunc(t · 2/π + ½)
    int4(OP_MUL, t2, rFN, 64 + 11),
    int4(OP_SUB, t1, t0, t2),  // r = t − n · π/2 (1ª parte)
    int4(OP_MUL, t2, rFN, 64 + 12),  // w
    int4(OP_SUB, t3, t1, t2),  // r
    int4(OP_SUB, t4, t1, t3),
    int4(OP_SUB, t4, t4, t2),
    int4(OP_MUL, t5, rFN, 64 + 13),
    int4(OP_SUB, t2, t5, t4),  // w
    int4(OP_MUL, t4, rFN, 64 + 14),
    int4(OP_SUB, t1, t3, t4),  // r
    int4(OP_SUB, t5, t3, t1),
    int4(OP_SUB, t5, t5, t4),
    int4(OP_MUL, t6, rFN, 64 + 15),
    int4(OP_SUB, t2, t6, t5),  // w
    int4(OP_SUB, t3, t1, t2),  // y0
    int4(OP_SUB, t4, t1, t3),
    int4(OP_SUB, t4, t4, t2),  // y1
    int4(OP_MUL, t5, t3, t3),  // z
    int4(OP_MUL, t6, t5, t3),  // v
    int4(OP_MUL, t7, t5, 64 + 21),
    int4(OP_SOMA, t7, 64 + 20, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 19, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 18, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 17, t7),  // r do seno
    int4(OP_MUL, t8, 64 + 0, t4),
    int4(OP_MUL, t9, t6, t7),
    int4(OP_SUB, t8, t8, t9),
    int4(OP_MUL, t8, t5, t8),
    int4(OP_SUB, t8, t8, t4),
    int4(OP_MUL, t9, t6, 64 + 16),
    int4(OP_SUB, t8, t8, t9),
    int4(OP_SUB, rKS, t3, t8),  // sen(y) = y0 − ((z·(y1/2 − v·r) − y1) − v·S1)
    int4(OP_MUL, t7, t5, 64 + 27),
    int4(OP_SOMA, t7, 64 + 26, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 25, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 24, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 23, t7),
    int4(OP_MUL, t7, t5, t7),
    int4(OP_SOMA, t7, 64 + 22, t7),
    int4(OP_MUL, t7, t5, t7),  // r do cosseno
    int4(OP_QX, t8, t3, 0),  // qx (0 com |y0| < 0,3)
    int4(OP_MUL, t9, 64 + 0, t5),
    int4(OP_SUB, t9, t9, t8),  // hz
    int4(OP_SUB, t8, 64 + 1, t8),  // a
    int4(OP_MUL, t10, t5, t7),
    int4(OP_MUL, t11, t3, t4),
    int4(OP_SUB, t10, t10, t11),
    int4(OP_SUB, t10, t9, t10),
    int4(OP_SUB, rKC, t8, t10),  // cos(y) = a − (hz − (z·r − y0·y1))
    int4(OP_SENQ, rS0, rFN, rKS),  // o quadrante
    int4(OP_COSQ, rC0, rFN, rKS),
    int4(OP_SINAL, rS0, rS0, rTH),  // sen(−θ) = −sen(θ)
    // ---- GRADIENTE: Natural / Constant Length / Perpendicular (0x180003950 e as outras duas profundidades)
    int4(OP_MUL, rG0, rG0, rESC),  // gx · escala (Perpendicular: gy)
    int4(OP_MUL, rG1, rG1, rESC),  // gy · escala (Perpendicular: −gx)
    int4(OP_MUL, t0, rG1, rG1),
    int4(OP_MUL, t1, rG0, rG0),
    int4(OP_SOMA, t0, t0, t1),
    int4(OP_MUL, t1, rRG, 64 + 8),  // r = Ridge · 0,002
    int4(OP_MUL, t1, t1, t1),
    int4(OP_SOMA, t0, t0, t1),
    int4(OP_RAIZ, rCOMP, t0, 0),  // comp = √((gy² + gx²) + r²)
    int4(OP_DIV, t2, 64 + 1, rCOMP),
    int4(OP_MUL, t3, t2, rG0),
    int4(OP_MUL, rVX, t3, rAX),  // vx = (1/comp) · gx · AX
    int4(OP_MUL, t3, t2, rG1),
    int4(OP_MUL, rVY, t3, rAX),
    int4(OP_MUL, t4, rVY, rVY),
    int4(OP_MUL, t5, rVX, rVX),
    int4(OP_SOMA, t4, t4, t5),
    int4(OP_RAIZ, rL, t4, 0),  // |v|
    int4(OP_TRUNC, rN, rL, 0),
    int4(OP_SOMA, rN, rN, 64 + 2),  // N = trunc(|v|) + 2
    int4(OP_MUL, t5, rC0, rVX),
    int4(OP_MUL, t6, rS0, rVY),
    int4(OP_SUB, rDXV, t5, t6),  // o vetor girado pelo Angle Offset
    int4(OP_MUL, t5, rS0, rVX),
    int4(OP_MUL, t6, rC0, rVY),
    int4(OP_SOMA, rDYV, t5, t6),
    int4(OP_ESC2, t5, rDXV, -1),
    int4(OP_SUB, t5, rX, t5),
    int4(OP_ESC2, rX0, t5, 16),  // X0 = (x − dx/2) · 65536 (Constant Length, Perpendicular)
    int4(OP_ESC2, t5, rDYV, -1),
    int4(OP_SUB, t5, rY, t5),
    int4(OP_ESC2, rY0, t5, 16),
    int4(OP_DIV, t6, 64 + 3, rN),
    int4(OP_MUL, rDX, t6, rDXV),  // DX = (65536 / N) · dx
    int4(OP_MUL, rDY, t6, rDYV),
    // ---- DIRECAO: Direction Center / Direction Fading
    int4(OP_MUL, rVX, rC0, rAX),  // v = (cos θ, sen θ) · AX
    int4(OP_MUL, rVY, rS0, rAX),
    int4(OP_DIV, t0, 64 + 1, rESC),
    int4(OP_SOMA, t0, t0, t0),
    int4(OP_MUL, t0, t0, 64 + 9),
    int4(OP_ESC2, t0, t0, -1),
    int4(OP_DIV, t0, 64 + 1, t0),  // 1 / ((1/sy + 1/sx) · 1,414 / 2)
    int4(OP_ABS, t1, rA, 0),
    int4(OP_MUL, t1, t1, t0),
    int4(OP_TRUNC, rN, t1, 0),
    int4(OP_SOMA, rN, rN, 64 + 2),  // N = floor(|Amount| / 1,414) + 2
    int4(OP_DIV, t2, 64 + 3, rN),
    int4(OP_MUL, rDX, t2, rVX),
    int4(OP_MUL, rDY, t2, rVY),
    int4(OP_ESC2, t3, rVX, -1),
    int4(OP_SUB, t3, rX, t3),
    int4(OP_ESC2, rX0, t3, 16),  // X0 do Center
    int4(OP_ESC2, t3, rVY, -1),
    int4(OP_SUB, t3, rY, t3),
    int4(OP_ESC2, rY0, t3, 16),
    int4(OP_SOMA, rPXD, rX, rVX),  // Fading: onde o risco sai do quadro
    int4(OP_SUB, t4, rW, rX),
    int4(OP_MUL, t4, t4, rN),
    int4(OP_DIV, t4, t4, rVX),
    int4(OP_SOMA, rTA, t4, 64 + 1),  // (W − x)·N / vx + 1
    int4(OP_MUL, t4, rN, rX),
    int4(OP_DIV, t4, t4, rVX),
    int4(OP_SUB, rTB, 64 + 2, t4),  // 2 − N·x / vx
    int4(OP_SOMA, rPYD, rY, rVY),
    int4(OP_SUB, t4, rH, rY),
    int4(OP_MUL, t4, t4, rN),
    int4(OP_DIV, t4, t4, rVY),
    int4(OP_SOMA, rTC, t4, 64 + 1),
    int4(OP_MUL, t4, rN, rY),
    int4(OP_DIV, t4, t4, rVY),
    int4(OP_SUB, rTD, 64 + 2, t4)
);
// <<< programa

uint2 R[N_REG];

uint2 operando(int i) { return i >= 64 ? K[i - 64] : R[i]; }

/** O qx do __kernel_cos: 0 com |x| < 0,3; 0,28125 com |x| > 0,78125; senão |x|/4 truncado. */
uint2 dQx(uint2 x) {
    uint ix = x.x & 0x7FFFFFFFu;
    if (ix < 0x3FD33333u) return D_ZERO;
    return ix > 0x3FE90000u ? uint2(0x3FD20000u, 0u) : uint2(ix - 0x00200000u, 0u);
}

/** Roda os segmentos [ini[s], fim[s]) do PROGRAMA, em ordem. */
void executar(int4 ini, int4 fim, int n) {
    for (int s = 0; s < n; s++) {
        for (int i = ini[s]; i < fim[s]; i++) {
            int4 c = PROGRAMA[i];
            int op = c.x;
            uint2 a = operando(c.z);
            uint2 r;
            if (op == OP_ESC2) r = dEscala2(a, c.w);
            else if (op == OP_RAIZ) r = dSqrt(a);
            else if (op == OP_F32) r = dDeFloat(dParaFloat(a));
            else if (op == OP_TRUNC) r = dDeInt(dTrunc(a));
            else if (op == OP_ABS) r = uint2(a.x & 0x7FFFFFFFu, a.y);
            else if (op == OP_QX) r = dQx(a);
            else if (op == OP_SENQ || op == OP_COSQ) {
                // o quadrante n: seno (sen, cos, −sen, −cos)[n mod 4]; o cosseno é o do quadrante seguinte
                int q = (dTrunc(a) + (op == OP_COSQ ? 1 : 0)) & 3;
                uint2 ks = R[c.w], kc = R[c.w + 1];
                r = q == 0 ? ks : (q == 1 ? kc : (q == 2 ? dNeg(ks) : dNeg(kc)));
            } else {
                uint2 b = operando(c.w);
                if (op == OP_SINAL) r = dSinal(b) == 1u && !dZero(b) ? dNeg(a) : a;
                else if (op == OP_MUL) r = dMul(a, b);
                else if (op == OP_DIV) r = dDiv(a, b);
                else r = dSoma(a, op == OP_SUB ? dNeg(b) : b);
            }
            R[c.y] = r;
        }
    }
}

// ============================================================ a propriedade do mapa (0x1800031b0)
/** O Hue do plugin em graus (0x1800035b0): os ramos e o float32 como lá. */
float matiz(int R, int G, int B) {
    int d, num;
    float off = 0.0;
    if (R > G) {
        if (R > B) {
            if (G > B) { d = R - B; num = G - B; } else { d = R - G; num = G - B; }
        } else {
            d = B - G; num = R - G; off = 4.0;
        }
    } else if (G > B) {
        if (B > R) { d = G - R; num = B - R; } else { d = G - B; num = B - R; }
        off = 2.0;
    } else {
        d = B - R; num = R - G; off = 4.0;
    }
    if (d == 0) return 0.0;
    float h = mul(float(num), divisaoInteira(1u, uint(d)));
    if (off != 0.0) h = fixa(h + off);
    h = mul(h, 60.0);
    if (h < 0.0) h = fixa(h + 360.0);
    return h;
}

float propriedadeDe(int4 c) {
    float UM_255 = as_type<float>(0x3B808081u);
    if (u.mapProperty == 0) return float(c.r) * UM_255;
    if (u.mapProperty == 1) return float(c.g) * UM_255;
    if (u.mapProperty == 2) return float(c.b) * UM_255;
    if (u.mapProperty == 3) return float(c.a) * UM_255;
    // (117 R + 204 G + 64 B)·A / (385·255²) e (R + G + B)·A / (3·255²): o plugin divide em double; o float32
    // que sai é o da divisão exata em todos os valores possíveis (conferido em Python).
    if (u.mapProperty == 4) return divisaoInteira(uint((117 * c.r + 204 * c.g + 64 * c.b) * c.a), 25034625u);
    if (u.mapProperty == 5) return divisaoInteira(uint((c.r + c.g + c.b) * c.a), 195075u);
    if (u.mapProperty == 6) return matiz(c.r, c.g, c.b) * as_type<float>(0x3B360B61u);
    return float(max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b)) * UM_255;
}

// ============================================================ o Map Softness (0x180008170, 0x180007af0)
float formaDoNucleo(float r1, float inv, int i) {
    float x = mul(r1 - float(i), inv);
    if (!(x > 0.0)) return 0.0;
    if (x >= 1.0) return 1.0;
    float a = 3.0 - x * 2.0;
    return mul(a, mul(x, x));
}

/** A soma do fim do núcleo, c[e] = k[topo] + … + k[e], somada de cima para baixo como no plugin. */
float caudaDoNucleo(float r1, float inv, float esc, int topo, int e) {
    float acc = 0.0;
    for (int t = topo; t >= e; t--) acc = acc + mul(formaDoNucleo(r1, inv, t), esc);
    return acc;
}

float lerNoEixo(sampler2D t, int2 p, bool horizontal, int i) {
    return lerDe(t, horizontal ? int2(i, p.y) : int2(p.x, i));
}

/** Uma passada (0x180007a10): k[0]·s[i], depois a esquerda j = 1..M e a direita j = 1..M, em float32. */
float suavizar(sampler2D t, int2 p, bool horizontal, int n, float esc) {
    float s0 = lerDe(t, p);
    float soft = min(fixo(u.mapSoftness), 500.0);
    float2 raioExato = produtoExato(soft, esc);       // o raio é double no plugin: soft · escala
    float raio = raioExato.x;
    int M = int(trunc(raio));
    if (raio == trunc(raio) && raioExato.y < 0.0) M -= 1;
    if (raio > 1000.0) { raio = 1000.0; M = 1000; }
    if (!(raioExato.x > 0.0)) return s0;
    M += 1;
    float r1 = raio + 1.0;
    int topo = int(r1) + 1;
    float inv = divisao(1.0, r1);
    float soma = 0.5;
    for (int j = 1; j <= topo; j++) soma = soma + formaDoNucleo(r1, inv, j);
    float esc0 = divisao(0.5, soma);
    int i = horizontal ? p.x : p.y;
    float tot = mul(s0, esc0);
    for (int lado = 0; lado < 2; lado++) {
        // na borda, o resto do núcleo (c[e]) vai todo no pixel da ponta
        int e = lado == 0 ? max(i, 1) : max(n - 1 - i, 1);
        for (int j = 1; j <= M; j++) {
            if (j > e) break;
            float w = j == e ? caudaDoNucleo(r1, inv, esc0, topo, e) : mul(formaDoNucleo(r1, inv, j), esc0);
            int q = lado == 0 ? max(i - j, 0) : min(i + j, n - 1);
            tot = tot + mul(lerNoEixo(t, p, horizontal, q), w);
        }
    }
    return tot;
}

// ============================================================ a leitura sub-pixel do AE (medida)
int4 texel8(int2 p) {
    if (p.x < 0 || p.y < 0 || p.x >= tam.x || p.y >= tam.y) return int4(0);
    return int4(inputImg.read(uint2(naImagem(p)), uint(0)) * 255.0 + 0.5);
}

/** (R, G, B, A) em 8 bits na posição 16.16 (X, Y). */
int4 amostra(int X, int Y) {
    int2 i = int2(X >> 16, Y >> 16);
    float wx = float(X & 0xFFFF) * (1.0 / 65536.0);
    float wy = float(Y & 0xFFFF) * (1.0 / 65536.0);
    float w11 = mul(wx, wy);
    float w01 = fixa(wx - w11);
    float w10 = fixa(wy - w11);
    float w00 = fixa(fixa(fixa(1.0 - w01) - w10) - w11);
    int4 p0 = texel8(i), p1 = texel8(i + int2(1, 0)), p2 = texel8(i + int2(0, 1)), p3 = texel8(i + int2(1, 1));
    float a0 = mul(w00, float(p0.a)), a1 = mul(w01, float(p1.a)), a2 = mul(w10, float(p2.a)), a3 = mul(w11, float(p3.a));
    float soma = fixa(fixa(a0 + a1) + fixa(a2 + a3));
    int alfa = int(trunc(soma + 0.5));
    if (!(soma > 0.0)) return int4(0, 0, 0, alfa);
    float3 cor;
    if (p1.a == p0.a && p2.a == p0.a && p3.a == p0.a) {     // os 4 alfas iguais: a cor reta (medido)
        cor = fixa3(fixa3(mul3(w00, float3(p0.rgb)) + mul3(w01, float3(p1.rgb))) + fixa3(mul3(w10, float3(p2.rgb)) + mul3(w11, float3(p3.rgb))));
    } else {
        float3 num = fixa3(fixa3(mul3(a0, float3(p0.rgb)) + mul3(a1, float3(p1.rgb))) + fixa3(mul3(a2, float3(p2.rgb)) + mul3(a3, float3(p3.rgb))));
        cor = mul3(divisao(1.0, soma), num);
    }
    return int4(int3(trunc(cor + 0.5)), alfa);
}

/**
 * n amostras de (X0, Y0) em passos (DX, DY). Sem `desvanecer`: fora do quadro não conta, alfa e cor somados
 * (0x180004f00). Com: sem olhar a borda, cada amostra com peso N, N − 1, … (0x180005710).
 */
float4 acumular(int X0, int Y0, int DX, int DY, int n, int N, bool desvanecer) {
    int lx = (tam.x - 1) << 16, ly = (tam.y - 1) << 16;
    float4 s = float4(0.0);
    float peso = float(N);
    for (int k = 0; k < n; k++) {
        int X = X0 + k * DX, Y = Y0 + k * DY;
        if (desvanecer || (X >= 0 && Y >= 0 && X <= lx && Y <= ly)) {
            int4 c = amostra(X, Y);
            if (desvanecer) {
                float wa = mul(float(c.a), peso);
                if (wa != 0.0) s = s + float4(wa, mul(float(c.r), wa), mul(float(c.g), wa), mul(float(c.b), wa));
            } else if (c.a != 0) {
                s = s + float4(float(c.a), float(c.r * c.a), float(c.g * c.a), float(c.b * c.a));
            }
        }
        peso = peso - 1.0;
    }
    return s;
}

/** Alfa = trunc(soma / divisor), cor = trunc(soma da cor / soma do alfa), em float32. */
float4 saida(float4 s, float divisor) {
    if (s.x == 0.0) return float4(0.0);
    float4 q = float4(divisor, s.x, s.x, s.x);
    int4 c;
    for (int i = 0; i < 4; i++) c[i] = int(trunc(divisao(s[i], q[i]))) & 255;
    return float4(float3(c.yzw), float(c.x)) / 255.0;
}

float lerP(int2 p) {
    return u.mapSoftness != 0.0 ? lerDe(valorSuave, p) : lerDe(valor, p);
}

fragment float4 fx_cc_vector_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_vector_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mapImg [[texture(1)]],
    texture2d<float> valor [[texture(2)]],
    texture2d<float> valorH [[texture(3)]],
    texture2d<float> valorSuave [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    z0 = min(eng.acIteration, 0);
    tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    dePe = eng.acEntradaDePe == 1;
    int W = tam.x, H = tam.y;
    // px: o pixel do buffer que este fragmento escreve; pi: o mesmo pixel na orientação da imagem (a da conta)
    int2 px = int2(min(floor(in.acScreenNorm * float2(tam)), float2(tam) - 1.0));
    int2 pi = naImagem(px);
    float esc = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;

    if (eng.acPass == 0) {
        // Sem Vector Map, o motor entrega a própria entrada em `mapImg`.
        int2 tm = int2(int(mapImg.get_width()), int(mapImg.get_height()));
        int2 pm = tm == tam ? px : min(int2((float2(px) + 0.5) * float2(tm) / float2(tam)), tm - 1);
        __nv_out = guardar(propriedadeDe(int4(mapImg.read(uint2(pm), uint(0)) * 255.0 + 0.5)));
        return __nv_out;
    }
    if (eng.acPass == 1) {
        __nv_out = guardar(suavizar(valor, pi, true, W, esc));
        return __nv_out;
    }
    if (eng.acPass == 2) {
        __nv_out = guardar(suavizar(valorH, pi, false, H, esc));
        return __nv_out;
    }

    int x = pi.x, y = pi.y;
    float A = fixo(u.amount);
    float ang = fixo(u.angleOffset);
    bool gradiente = u.tipo <= 2;
    R[rRG] = dDeFloat(fixo(u.ridge));
    R[rA] = dDeFloat(A);
    R[rESC] = dDeFloat(esc);
    R[rANG] = dDeFloat(ang);
    R[rX] = dDeInt(x);
    R[rY] = dDeInt(y);
    R[rW] = dDeInt(W);
    R[rH] = dDeInt(H);
    R[rS0] = D_ZERO;
    R[rC0] = D_UM;
    if (gradiente) {
        // o gradiente: a diferença para o vizinho da esquerda e o de cima (na 1ª linha/coluna, o da 2ª)
        int xp = max(x, 1), yp = max(y, 1);
        float pc = lerP(int2(xp, yp));
        float gx = lerP(int2(xp - 1, yp)) - pc;
        float gy = lerP(int2(xp, yp - 1)) - pc;
        R[rG0] = dDeFloat(u.tipo == 2 ? gy : gx);
        R[rG1] = dDeFloat(u.tipo == 2 ? -gx : gy);
    } else {
        R[rP] = dDeFloat(lerP(pi));
    }
    // Os segmentos: o comum; nos Direction o θ do mapa; o seno e o cosseno (com Angle Offset 0 nos tipos de
    // gradiente o ângulo é 0 exato — 90 · π/180 − π/2 = 0 em double —, cosseno 1 e seno 0); e o u.tipo.
    int4 ini = int4(SEG_COMUM, 0, 0, 0), fim = int4(SEG_THETA, 0, 0, 0);
    int ns = 1;
    if (!gradiente) { ini[ns] = SEG_THETA; fim[ns] = SEG_SENCOS; ns++; }
    if (!gradiente || ang != 0.0) { ini[ns] = SEG_SENCOS; fim[ns] = SEG_GRADIENTE; ns++; }
    if (gradiente) { ini[ns] = SEG_GRADIENTE; fim[ns] = SEG_DIRECAO; }
    else { ini[ns] = SEG_DIRECAO; fim[ns] = SEG_FIM; }
    executar(ini, fim, ns + 1);

    // gradiente zero (sem Ridge) ou vetor nulo: o pixel passa como está
    if (gradiente && (dZero(R[rCOMP]) || !dMenor(D_ZERO, R[rL]))) {
        __nv_out = inputImg.read(uint2(px), uint(0));
        return __nv_out;
    }
    int N = dTrunc(R[rN]);
    int X0 = u.tipo == 0 || u.tipo == 4 ? x << 16 : dTrunc(R[rX0]);
    int Y0 = u.tipo == 0 || u.tipo == 4 ? y << 16 : dTrunc(R[rY0]);
    int n = N;
    float divisor = float(N);
    if (u.tipo == 4) {
        // Direction Fading: a conta acaba onde o risco sai do quadro; o alfa sobre N(N + 1)/2
        if (dMenor(R[rW], R[rPXD])) n = dTrunc(R[rTA]);
        else if (dMenor(R[rPXD], D_MENOS_UM)) n = dTrunc(R[rTB]);
        if (dMenor(R[rH], R[rPYD])) { if (dMenor(R[rTC], dDeInt(n))) n = dTrunc(R[rTC]); }
        else if (dMenor(R[rPYD], D_MENOS_UM)) { if (dMenor(R[rTD], dDeInt(n))) n = dTrunc(R[rTD]); }
        divisor = float((N + 1) * N) * 0.5;
    }
    __nv_out = saida(acumular(X0, Y0, dTrunc(R[rDX]), dTrunc(R[rDY]), n, N, u.tipo == 4), divisor);
    return __nv_out;
}
