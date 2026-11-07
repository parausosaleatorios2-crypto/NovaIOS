// ---------------------------------------------------------------------------
// CC Burn Film
// origem : assets/effects/cc-burn-film.xml
// id     : nova.effect.ccburnfilm
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cc_burn_filmParams {
    float burn;
    float2 center;
    float seed;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 do plugin
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se funde
// com a soma seguinte num fma: cada produto arredonda sozinho, como no plugin.
float um;
static float fixa(float x) { return x * um; }
static float mul(float a, float b) { return (a * b) * um; }

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

/** O valor do controle em 16.16, como o AE o entrega ao plugin: o float32 · 65536, meio para longe do zero. */
static int fixo(float v) {
    float m = abs(v) * 65536.0;
    float i = floor(m);
    int r = int(i) + (m - i >= 0.5 ? 1 : 0);
    return v < 0.0 ? -r : r;
}

// ============================================================ dois floats (~48 bits)
// v = hi + lo, |lo| ≤ meio ulp de hi. As somas e produtos exatos (Knuth, Dekker) com o `um` entre cada conta.
static float2 somaExata(float a, float b) {
    float s = fixa(a + b);
    float bb = fixa(s - a);
    return float2(s, fixa(fixa(a - fixa(s - bb)) + fixa(b - bb)));
}
static float2 somaRapida(float a, float b) {
    float s = fixa(a + b);
    return float2(s, fixa(b - fixa(s - a)));
}
static float2 dfSoma(float2 a, float2 b) {
    float2 s = somaExata(a.x, b.x);
    float2 t = somaExata(a.y, b.y);
    s = somaRapida(s.x, fixa(s.y + t.x));
    return somaRapida(s.x, fixa(s.y + t.y));
}
static float2 dfNeg(float2 a) { return -a; }
static float2 dfMul(float2 a, float2 b) {
    float2 p = produtoExato(a.x, b.x);
    return somaRapida(p.x, fixa(p.y + fixa(mul(a.x, b.y) + mul(a.y, b.x))));
}

/** √a em dois floats (~2⁻⁴⁴): a primeira aproximação em float, um passo de correção exato. */
static float2 dfRaiz(float2 a) {
    if (!(a.x > 0.0)) return float2(0.0);
    float h = sqrt(a.x);
    float2 r = dfSoma(a, dfNeg(produtoExato(h, h)));
    return somaRapida(h, r.x / (2.0 * h));
}

// ============================================================ o double do plugin, emulado (o do CC Radial Blur)
// uint2(alto, baixo) com os bits de um double IEEE-754. Só números normais e zero. Só multiplicação, soma e a divisão
// por inteiro (dígitos de 16 bits): nada de laço de 55 passos.
const uint2 D_UM = uint2(0x3FF00000u, 0u);
const uint2 D_MEIO = uint2(0x3FE00000u, 0u);

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
        for (int i = 0; i < 60 && m.x < 0x800000u; i++) { m = shl64(m, 1); e -= 1; }
    }
    return dArredondar(dSinal(a), e, m);
}

static uint2 dSub(uint2 a, uint2 b) { return dSoma(a, dNeg(b)); }

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
    for (int k = 0; k < 31 && (u & 0x80000000u) == 0u; k++) { u <<= 1; e--; }
    return dMontar(i < 0 ? 1u : 0u, e, shl64(uint2(0u, u), 21));
}

static uint2 dDeFloat(float f) {
    uint b = as_type<uint>(f);
    uint E = (b >> 23) & 0xFFu;
    if (E == 0u) return uint2(b & 0x80000000u, 0u);
    uint2 m = shl64(uint2(0u, b & 0x7FFFFFu), 29);
    return uint2((b & 0x80000000u) | (uint(int(E) - 127 + 1023) << 20) | m.x, m.y);
}

/** O double para float32, ao par. */
static float dParaFloat(uint2 d) {
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
static float2 dfDeD(uint2 d) {
    float hi = dParaFloat(d);
    return float2(hi, dParaFloat(dSub(d, dDeFloat(hi))));
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

/** round(fração · lado · 65536), meio para longe do zero — a conta é exata em double (24 + 13 + 16 bits). */
static int pontoFixo(float fracao, int lado) {
    uint2 v = dEscala2(dMul(dDeFloat(abs(fracao)), dDeInt(lado)), 16);
    int r = dTrunc(dSoma(v, D_MEIO));
    return fracao < 0.0 ? -r : r;
}

// ============================================================ a camada
int W, H;                 // a camada do AE (px), dentro do buffer a partir de `inicio`
int2 inicio;
bool dePe;
float sx, sy, isx, isy;   // a escala da resolução no plugin (1 na exportação) e 1/escala, em float32

/** Um pixel da camada (RGBA 0..255, cor reta) na orientação da IMAGEM (a linha 0 é o topo); fora, transparente. */
static int4 daCamada(int x, int y) {
    if (x < 0 || y < 0 || x >= W || y >= H) return int4(0);
    int2 b = inicio + int2(x, dePe ? H - 1 - y : y);
    return int4(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5);
}

// Um uint inteiro nos 4 bytes de um texel RGBA8 (o buffer do motor é de 8 bits).
static float4 guardar(uint b) {
    return float4(float(b & 255u), float((b >> 8) & 255u), float((b >> 16) & 255u), float(b >> 24)) / 255.0;
}
static uint lerUint(sampler2D t, int2 p) {
    uint4 c = uint4(t.read(uint2(p), uint(0)) * 255.0 + 0.5);
    return c.x | (c.y << 8) | (c.z << 16) | (c.w << 24);
}
static float lerFloat(sampler2D t, int2 p) { return as_type<float>(lerUint(t, p)); }

// ============================================================ a linha da mancha (0x1800045c0)
/**
 * O fx depois de k subtrações de d em float32: o plugin anda a linha subtraindo 1/sx do fx a cada pixel. Sem andar
 * passo a passo: enquanto fx ≥ d cada subtração é exata; de [0, d) para baixo, uma arredonda; e com |fx| crescendo,
 * dentro de uma mesma potência de 2 a soma de d é exata — só arredonda quando |fx| cruza para a potência de cima (um
 * passo por potência). Conferida contra o passo a passo em 20 mil sorteios (`modelo.py cadeia`).
 */
static float cadeia(float fx0, int k, float d) {
    float v = fx0;
    int n = k;
    if (n <= 0) return v;
    if (v >= d) {
        int s = min(n, int(floor(v / d)));
        v = fixa(v - mul(float(s), d));
        n -= s;
    }
    if (n > 0 && v >= 0.0) {
        v = fixa(v - d);
        n--;
    }
    float a = -v;
    for (int i = 0; i < 64 && n > 0; i++) {
        uint e = (as_type<uint>(a) >> 23) & 0xFFu;      // a ∈ [2^(e−127), 2^(e−126))
        float B = as_type<float>((e + 1u) << 23);
        int s = int(ceil(fixa(B - a) / d));
        if (n < s) {
            a = fixa(a + mul(float(n), d));
            n = 0;
        } else {
            a = fixa(a + mul(float(s), d));
            n -= s;
        }
    }
    return -a;
}

// ============================================================ as 64 manchas (0x180002fc0 e o laço de 0x180003830)
const int NM = 64;
float mXs[NM], mYs[NM], mR2[NM], mInv[NM], mAmp[NM];
int mX0[NM], mX1[NM], mY0[NM], mY1[NM];

/** A mancha i: o centro em px do buffer, R², 1/R², amp e a caixa (x0..x1, y0..y1). Fora da camada, caixa vazia. */
static void mancha(int i, float x, float y, float raio, float amp) {
    mX0[i] = 0; mX1[i] = 0; mY0[i] = 0; mY1[i] = 0;
    if (1.0 > raio) raio = 1.0;
    float xs = mul(sx, x), ys = mul(y, sy);
    float rx = mul(raio, sx), ry = mul(raio, sy);
    int x0 = int(fixa(xs - rx));
    int x1 = int(fixa(fixa(xs + rx) + 1.0));
    if (!(x0 < W) || x1 < 0) return;
    int y0 = int(fixa(ys - ry));
    int y1 = int(fixa(fixa(ys + ry) + 1.0));
    if (!(y0 < H) || y1 < 0) return;
    float R2 = mul(raio, raio);
    mXs[i] = xs; mYs[i] = ys; mR2[i] = R2; mInv[i] = divisao(1.0, R2); mAmp[i] = amp;
    mX0[i] = max(x0, 0); mX1[i] = min(x1, W); mY0[i] = max(y0, 0); mY1[i] = min(y1, H);
}

/** O que a mancha m soma ao pixel (x, y) do buffer que vale `acc`. */
static float somaMancha(int m, int x, int y, float acc) {
    if (x < mX0[m] || x >= mX1[m] || y < mY0[m] || y >= mY1[m]) return acc;
    float fx = cadeia(mul(fixa(mXs[m] - float(mX0[m])), isx), x - mX0[m], isx);
    float fy = mul(fixa(mYs[m] - float(y)), isy);
    float d2 = fixa(mul(fx, fx) + mul(fy, fy));
    if (!(d2 < mR2[m])) return acc;
    float t = fixa(1.0 - mul(d2, mInv[m]));
    return fixa(mul(mul(t, mAmp[m]), t) + acc);
}

static uint lcg(uint r) { return r * 0x41C64E6Du + 0x3039u; }
static int g15(uint r) { return int((r >> 16) & 0x7FFFu); }

// ============================================================ as constantes do quadro
const uint2 D_0_01 = uint2(0x3F847AE1u, 0x47AE147Bu);
const uint2 D_TRES = uint2(0x40080000u, 0u);

int modo;                  // 0 a conta; 1 Burn ≤ 0 (a camada como está); 2 Burn ≥ 100 (vazia)
float fundo, R0, kRaio, xc, yc;
uint2 WD, HD;
uint semente;

static void constantes(float2 fr) {
    int bF = fixo(u.burn);
    modo = bF <= 0 ? 1 : (bF >= 6553600 ? 2 : 0);
    if (modo != 0) return;
    // b = Burn · 0,01 e 2b, em double
    uint2 b2 = dEscala2(dMul(dEscala2(dDeInt(bF), -16), D_0_01), 1);
    // a camada em px do tamanho cheio: largura · (1/sx)
    WD = dMul(dDeInt(W), dDeFloat(isx));
    HD = dMul(dDeInt(H), dDeFloat(isy));
    // R₀ = (float)(√(H² + W²) · 2b) — a raiz em dois floats
    float2 diag = dfRaiz(dfDeD(dSoma(dMul(HD, HD), dMul(WD, WD))));
    R0 = dfMul(diag, dfDeD(b2)).x;
    kRaio = mul(R0, as_type<float>(0x36CCCCCDu));          // 0,2/32768 em float32
    // o fundo: suave(2b − 1) em double, só acima de Burn 50
    fundo = 0.0;
    if (dMenor(D_UM, b2)) {
        uint2 x = dSub(b2, D_UM);
        fundo = dParaFloat(dMul(dSub(D_TRES, dEscala2(x, 1)), dMul(x, x)));
    }
    // o centro: (1/sx) · (16.16 do ponto)/65536, em double, para float32
    int pcx = pontoFixo(fr.x, W), pcy = pontoFixo(fr.y, H);
    xc = dParaFloat(dMul(dDeFloat(isx), dEscala2(dDeInt(pcx), -16)));
    yc = dParaFloat(dMul(dDeFloat(isy), dEscala2(dDeInt(pcy), -16)));
    semente = uint(fixo(u.seed) + 1);
}

/** As manchas 0..alvo, em ordem: a 0 no centro; cada uma das outras lê o buffer no ponto sorteado dela. */
static void calcularManchas(int alvo) {
    mancha(0, xc, yc, R0, 1.0);
    uint st = semente;
    for (int j = 1; j < NM; j++) {
        if (j > alvo) break;
        uint r1 = lcg(st), r2 = lcg(r1), r3 = lcg(r2), r4 = lcg(r3);
        st = r4;
        mX0[j] = 0; mX1[j] = 0; mY0[j] = 0; mY1[j] = 0;
        // (r · W) · 1/32768 em double, para float32
        float px = dParaFloat(dEscala2(dMul(dDeInt(g15(r1)), WD), -15));
        float py = dParaFloat(dEscala2(dMul(dDeInt(g15(r2)), HD), -15));
        int ix = int(mul(sx, px)), iy = int(mul(sy, py));
        if (ix < 0 || iy < 0 || ix >= W || iy >= H) continue;
        float val = fundo;
        for (int m = 0; m < NM; m++) {
            if (m >= j) break;
            val = somaMancha(m, ix, iy, val);
        }
        if (!(val > 0.0 && val < 2.0)) continue;
        float amp = mul(mul(float(g15(r3)), val), as_type<float>(0x372AAAABu));   // 1/98304 em float32
        float raio = mul(mul(fixa(2.0 - val), float(g15(r4))), kRaio);
        mancha(j, px, py, raio, amp);
    }
}

/** A máscara das manchas cuja caixa passa pela coluna (ou linha) `pos`: 64 bits, a mancha m no bit m. */
static uint2 mascara(int pos, bool linha) {
    int k = (linha ? 16384 : 0) + 2 * pos;
    int2 p = int2(k & 1023, 512 + (k >> 10));
    return uint2(lerUint(colunas, p), lerUint(colunas, p + int2(1, 0)));
}

// ============================================================ o efeito

fragment float4 fx_cc_burn_film(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cc_burn_filmParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> manchas [[texture(1)]],
    texture2d<float> colunas [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    int2 buf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA. Fora dela não há saída.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    inicio = (buf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;
    // A escala da resolução do plugin: 1 na exportação; na prévia reduzida, a dela (a mesma conta numa resolução menor).
    sx = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    sy = sx;
    isx = sx == 1.0 ? 1.0 : 1.0 / sx;
    isy = isx;

    if (eng.acPass == 0) {
        // O centro como FRAÇÃO da camada em float32 (o AE entrega round(px · 65536) do ponto); cru, como no CC Light
        // Burst, e levado ao buffer só quando a camada não o ocupa inteiro.
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
        constantes(fr);
        int2 t = int2(__nv_fragCoord.xy);
        if (t.y == 7) {
            __nv_out = guardar(t.x == 0 ? as_type<uint>(modo == 0 ? fundo : 0.0) : (t.x == 1 ? uint(modo) : 0u));
            return __nv_out;
        }
        if (modo != 0) { __nv_out = float4(0.0); return __nv_out; }
        int i = t.x;
        calcularManchas(i);
        uint v = 0u;
        if (t.y == 0) v = as_type<uint>(mXs[i]);
        else if (t.y == 1) v = as_type<uint>(mYs[i]);
        else if (t.y == 2) v = as_type<uint>(mR2[i]);
        else if (t.y == 3) v = as_type<uint>(mInv[i]);
        else if (t.y == 4) v = as_type<uint>(mAmp[i]);
        else if (t.y == 5) v = uint(mX0[i]) | (uint(mX1[i]) << 16);
        else v = uint(mY0[i]) | (uint(mY1[i]) << 16);
        __nv_out = guardar(v);
        return __nv_out;
    }

    int modoDoQuadro = int(lerUint(manchas, int2(1, 7)));
    if (eng.acPass == 1) {
        int2 t = int2(__nv_fragCoord.xy);
        if (modoDoQuadro != 0) { __nv_out = float4(0.0); return __nv_out; }
        if (t.y < 512) {
            // o fx² da mancha m na coluna c: a `cadeia` uma vez por coluna
            int m = t.y >> 3, c = ((t.y & 7) << 10) | t.x;
            uint cx = lerUint(manchas, int2(m, 5));
            int x0 = int(cx & 0xFFFFu), x1 = int(cx >> 16);
            if (c < x0 || c >= x1) { __nv_out = float4(0.0); return __nv_out; }
            float fx = cadeia(mul(fixa(lerFloat(manchas, int2(m, 0)) - float(x0)), isx), c - x0, isx);
            __nv_out = guardar(as_type<uint>(mul(fx, fx)));
            return __nv_out;
        }
        // as máscaras: k = 2·coluna + metade (0..16383), 16384 + 2·linha + metade
        int k = ((t.y - 512) << 10) | t.x;
        bool linha = k >= 16384;
        k &= 16383;
        int pos = k >> 1, metade = k & 1;
        uint bits = 0u;
        if (pos < (linha ? H : W)) {
            for (int b = 0; b < 32; b++) {
                uint cx = lerUint(manchas, int2(32 * metade + b, linha ? 6 : 5));
                int lo = int(cx & 0xFFFFu), hi = int(cx >> 16);
                if (pos >= lo && pos < hi) bits |= 1u << uint(b);
            }
        }
        __nv_out = guardar(bits);
        return __nv_out;
    }

    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena de pé a linha 0 do buffer é a
    // BASE. Fora da camada o efeito não escreve.
    int2 local = int2(floor(in.acScreenNorm * eng.acResolution)) - inicio;
    if (local.x < 0 || local.y < 0 || local.x >= W || local.y >= H) { __nv_out = float4(0.0); return __nv_out; }
    int x = local.x, y = dePe ? H - 1 - local.y : local.y;
    int4 p = daCamada(x, y);
    if (modoDoQuadro == 2 || p.a == 0) { __nv_out = float4(0.0); return __nv_out; }
    if (modoDoQuadro == 1 || x >= 8192 || y >= 8192) { __nv_out = float4(p) / 255.0; return __nv_out; }

    // o buffer de queima no pixel: o fundo e as manchas das duas máscaras, em ordem
    float acc = lerFloat(manchas, int2(0, 7));
    uint2 mm = mascara(x, false) & mascara(y, true);
    for (int h = 0; h < 2; h++) {
        uint bits = h == 0 ? mm.x : mm.y;
        for (int q = 0; q < 32; q++) {
            if (bits == 0u) break;
            uint menor = bits & (~bits + 1u);                          // o bit mais baixo (findLSB é do 3.10)
            int m = 32 * h + int(as_type<uint>(float(menor)) >> 23) - 127;
            bits ^= menor;
            float fxx = lerFloat(colunas, int2(x & 1023, m * 8 + (x >> 10)));
            float fy = mul(fixa(lerFloat(manchas, int2(m, 1)) - float(y)), isy);
            float d2 = fixa(fxx + mul(fy, fy));
            if (d2 < lerFloat(manchas, int2(m, 2))) {
                float t = fixa(1.0 - mul(d2, lerFloat(manchas, int2(m, 3))));
                acc = fixa(mul(mul(t, lerFloat(manchas, int2(m, 4))), t) + acc);
            }
        }
    }

    // o pixel (0x180002c60): a cor vezes suave(t), o alfa vezes suave(6t), truncados
    float v = fixa(acc - 0.5);
    if (!(v > 0.0)) { __nv_out = float4(p) / 255.0; return __nv_out; }
    if (v >= 1.0) { __nv_out = float4(0.0); return __nv_out; }
    float t = fixa(1.0 - v);
    float s = t >= 1.0 ? 1.0 : mul(fixa(3.0 - mul(t, 2.0)), mul(t, t));
    float u = mul(t, 6.0);
    float a = u >= 1.0 ? 1.0 : mul(fixa(3.0 - mul(u, 2.0)), mul(u, u));
    int3 c = int3(mul(float(p.r), s), mul(float(p.g), s), mul(float(p.b), s));
    int A = int(mul(float(p.a), a));
    __nv_out = A == 0 ? float4(0.0) : float4(float3(c), float(A)) / 255.0;
    return __nv_out;
}
