// ---------------------------------------------------------------------------
// BCC Magic Sharp
// origem : assets/effects/bcc-magic-sharp.xml
// id     : nova.effect.bccmagicsharp
// passes : 19
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_magic_sharpParams {
    float amount;
    float threshold;
    float radius;
    float noise;
    int finePass;
    float fineSharpen;
    int smallPass;
    float smallSharpen;
    int mediumPass;
    float mediumSharpen;
    int coarsePass;
    float coarseSharpen;
    float lumaSharpen;
    float chromaSharpen;
    float redSharpen;
    float greenSharpen;
    float blueSharpen;
    int rangeOn;
    float highlightRange;
    float midHighRange;
    float midLowRange;
    float shadowRange;
    float highlightSharpen;
    float midtoneSharpen;
    float shadowSharpen;
    int reduceGrit;
    float gritRadius;
    float gritSensitivity;
    float mixWithOriginal;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 da DLL
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se funde
// com a soma seguinte num fma: cada produto arredonda sozinho, como no plugin.
float um;
float UM_255;                  // float32(1/255) da DLL: 0x3B808081
static float fixa(float x) { return x * um; }
static float3 fixa3(float3 x) { return x * um; }
static float mul(float a, float b) { return (a * b) * um; }
static float3 mul3(float3 a, float3 b) { return (a * b) * um; }

// 2^k exato (k de −126 a 127), sem o exp2 da GPU.
static float pot2(int k) { return as_type<float>(uint(k + 127) << 23); }

// float32 de num/den arredondado UMA vez (ao par), por divisão longa em inteiros: o que o host faz em double e
// converte. num e den abaixo de 2^31.
static float divExata(uint num, uint den) {
    if (num == 0u) return 0.0;
    uint q = num / den;
    uint r = num % den;
    int e = 0;
    for (int i = 0; i < 80 && q < 33554432u; i++) {      // até 26 bits significativos
        r <<= 1;
        q <<= 1;
        if (r >= den) { r -= den; q |= 1u; }
        e--;
    }
    bool resto = r != 0u;
    for (int i = 0; i < 8 && q >= 67108864u; i++) {
        if ((q & 1u) != 0u) resto = true;
        q >>= 1;
        e++;
    }
    uint fica = q >> 2;
    if ((q & 1u) != 0u) resto = true;
    if (((q >> 1) & 1u) == 1u && (resto || (fica & 1u) == 1u)) fica += 1u;
    return float(fica) * pot2(e + 2);
}

// x = m·2^e com m de 24 bits (x > 0, normal).
static uint mantissa(float x) { return (as_type<uint>(x) & 8388607u) | 8388608u; }
static int expoente(float x) { return int((as_type<uint>(x) >> 23) & 255u) - 150; }

// O AE entrega o slider ao BCC em ponto fixo 16.16 (o 1,6 chega como 1,60000610…).
static float fx16(float v) { return floor(v * 65536.0 + 0.5) * pot2(-16); }

// float32(fx16(v) · 0,01) com a conta em double: |v|·65536 é inteiro, então é esse inteiro / 100 · 2^-16.
static float pct(float v) {
    float f = fx16(v);
    float r = divExata(uint(abs(f) * 65536.0), 100u) * pot2(-16);
    return f < 0.0 ? -r : r;
}

// float32(x · 2,56) em double = x · 64 / 25, arredondado uma vez.
static float vezes256(float x) {
    if (x <= 0.0) return 0.0;
    return divExata(mantissa(x) * 64u, 25u) * pot2(expoente(x));
}

// float32(1 / x), arredondado uma vez.
static float inverso(float x) { return divExata(1u, mantissa(x)) * pot2(-expoente(x)); }

// ============================================================ a imagem
int2 gT;
int2 gP;

static float canal(int2 p, int c) { return float(int(inputImg.read(uint2(p), uint(0))[c] * 255.0 + 0.5)) * UM_255; }
static float3 fonte(int2 p) { return float3(int3(inputImg.read(uint2(p), uint(0)).rgb * 255.0 + 0.5)) * UM_255; }

static float lerF(sampler2D t, int2 p) {
    uint4 b = uint4(t.read(uint2(p), uint(0)) * 255.0 + 0.5);
    return as_type<float>(b.r | (b.g << 8) | (b.b << 16) | (b.a << 24));
}
static float4 gravarF(float v) {
    uint u = as_type<uint>(v);
    return float4(float(u & 255u), float((u >> 8) & 255u), float((u >> 16) & 255u), float(u >> 24)) / 255.0;
}
static float3 acumulado(int2 p) { return float3(lerF(accR, p), lerF(accG, p), lerF(accB, p)); }

// ============================================================ o bilateral (`DiffusionPassRenderer`)
// Meia-largura n = ⌈raio⌉ e o peso espacial float32(exp(−0,5·i²/raio)).
static int meia(float raio) {
    int n = int(raio);
    if (raio > 0.0 && fract(raio) != 0.0) n++;
    return min(n, 4000);
}
static float peso(int i, float raio) {
    if (i == 0) return 1.0;
    float fi = float(i);
    return exp((fi * -0.5) * fi / raio);
}
// No rascunho do play/arraste, janela maior que ±24 lê de passo em passo.
static int passoDaJanela(int n) { return (eng.acRascunho == 1 && n > 24) ? (n + 23) / 24 : 1; }
static float limiar(float t) { return inverso(t * t) * 65536.0; }

// Um bilateral ao longo de y num buffer (o 2º eixo): centro e vizinhos do próprio buffer.
static float bilateralY(sampler2D t, float raio, float K) {
    int n = meia(raio);
    int passo = passoDaJanela(n);
    int ini = -(n / passo) * passo;
    float centro = lerF(t, gP);
    float sw = 0.0;
    float swv = 0.0;
    for (int j = ini; j <= n; j += passo) {
        float q = lerF(t, int2(gP.x, clamp(gP.y + j, 0, gT.y - 1)));
        float d = centro - q;
        float w = peso(j, raio) / (mul(mul(d, d), K) + 1.0);
        sw += w;
        swv += mul(q, w);
    }
    return swv / sw;
}

// ============================================================ os controles
static bool passeLigado(int k) { return k == 0 ? u.finePass : (k == 1 ? u.smallPass : (k == 2 ? u.mediumPass : u.coarsePass)); }
static float nitidezDoPasse(int k) { return k == 0 ? u.fineSharpen : (k == 1 ? u.smallSharpen : (k == 2 ? u.mediumSharpen : u.coarseSharpen)); }
static float raioDoPasse(int k) {
    float r = fx16(u.radius);
    for (int i = 0; i < 3; i++) if (i < k) r = r * 2.0;            // o fator escondido 9962015 = 200 %
    return r * eng.acEscalaDePixel;
}

// `SharpenCompositeRenderer`: o 3a do passe k.
static float tresA(int k) {
    float a1 = pct(u.amount) * fx16(nitidezDoPasse(k));
    float a = vezes256(a1) * pot2(-8);
    return a * 3.0;
}
static float ruido() { return 1.0 - (255.0 - fx16(u.noise)) * pot2(-8); }

static float nitidez(float A, float B, float a3, float nr) {
    float x = mul(a3 + 1.0, A) - mul(a3, B);
    float xp = x > A + nr ? x - nr : (x < A - nr ? x + nr : A);
    return fixa(xp - A) + A;
}

// `EffectScaler`: cada bloco só roda se algum ganho dele sair de 1 por mais de 1e-5.
const float gYiq[15] = float[15](0.299, 0.587, 0.114, 0.596, -0.275, -0.321, 0.212, -0.523, 0.311, 0.956, 0.621, -0.272,
                           -0.647, -1.105, 1.702);
static float3 yiq(float3 X) {
    return float3((mul(X.r, gYiq[0]) + mul(X.g, gYiq[1])) + mul(X.b, gYiq[2]),
                (mul(X.r, gYiq[3]) + mul(X.g, gYiq[4])) + mul(X.b, gYiq[5]),
                (mul(X.r, gYiq[6]) + mul(X.g, gYiq[7])) + mul(X.b, gYiq[8]));
}
static float3 sintonia(float3 A, float3 B) {
    float3 kc = float3(pct(u.redSharpen), pct(u.greenSharpen), pct(u.blueSharpen));
    if (max(max(abs(kc.r - 1.0), abs(kc.g - 1.0)), abs(kc.b - 1.0)) > 1e-5) B = mul3(B - A, kc) + A;
    float kl = pct(u.lumaSharpen);
    float kk = pct(u.chromaSharpen);
    if (max(abs(kl - 1.0), abs(kk - 1.0)) > 1e-5) {
        float3 a = yiq(A);
        float3 b = yiq(B);
        float Y = mul(b.x - a.x, kl) + a.x;
        float I = mul(b.y - a.y, kk) + a.y;
        float Q = mul(b.z - a.z, kk) + a.z;
        B = float3((mul(I, gYiq[9]) + fixa(Y)) + mul(Q, gYiq[10]),
                 (mul(I, gYiq[11]) + fixa(Y)) + mul(Q, gYiq[12]),
                 (mul(I, gYiq[13]) + fixa(Y)) + mul(Q, gYiq[14]));
    }
    float ks = pct(u.shadowSharpen);
    float km = pct(u.midtoneSharpen);
    float kh = pct(u.highlightSharpen);
    if (u.rangeOn && max(max(abs(ks - 1.0), abs(km - 1.0)), abs(kh - 1.0)) > 1e-5) {
        float t0 = pct(u.shadowRange);
        float t1 = pct(u.midLowRange);
        float t2 = pct(u.midHighRange);
        float t3 = pct(u.highlightRange);
        float lum = (mul(A.g, 0.5859375) + mul(A.r, 0.30078125)) + mul(A.b, 0.11328125);
        float f01 = (lum - t0) / (t1 - t0);
        float f23 = (lum - t2) / (t3 - t2);
        float s = lum < t0 ? 1.0 : (lum < t1 ? 1.0 - f01 : 0.0);
        float m = lum < t0 ? 0.0 : (lum < t1 ? f01 : (lum < t2 ? 1.0 : (lum < t3 ? 1.0 - f23 : 0.0)));
        float h = lum < t2 ? 0.0 : (lum < t3 ? f23 : 1.0);
        float g = (mul(s, ks) + mul(m, km)) + mul(h, kh);
        B = mul3(float3(g), B - A) + A;
    }
    return B;
}
static float3 sintonizado(int2 p) { return sintonia(fonte(p), acumulado(p)); }

// ============================================================ os passes

fragment float4 fx_bcc_magic_sharp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_magic_sharpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> h0 [[texture(1)]],
    texture2d<float> h1 [[texture(2)]],
    texture2d<float> h2 [[texture(3)]],
    texture2d<float> h3 [[texture(4)]],
    texture2d<float> accR [[texture(5)]],
    texture2d<float> accG [[texture(6)]],
    texture2d<float> accB [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    UM_255 = as_type<float>(0x3B808081u);
    gT = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    gP = min(int2(floor(in.acScreenNorm * float2(gT))), gT - int2(1));
    float K = limiar(fx16(u.threshold));

    if (eng.acPass < 15) {
        int c = eng.acPass / 5;
        int k = eng.acPass - 5 * c;
        if (k < 4) {
            // ---- o bilateral em x do canal c no nível k, a partir da fonte
            if (!passeLigado(k)) { __nv_out = float4(0.0); return __nv_out; }
            float raio = raioDoPasse(k);
            int n = meia(raio);
            int passo = passoDaJanela(n);
            int ini = -(n / passo) * passo;
            float centro = canal(gP, c);
            float sw = 0.0;
            float swv = 0.0;
            for (int j = ini; j <= n; j += passo) {
                float q = canal(int2(clamp(gP.x + j, 0, gT.x - 1), gP.y), c);
                float d = centro - q;
                float w = peso(j, raio) / (mul(mul(d, d), K) + 1.0);
                sw += w;
                swv += mul(q, w);
            }
            __nv_out = gravarF(swv / sw);
            return __nv_out;
        }
        // ---- em y, a nitidez de cada nível e a soma (`SharpenPixWorldMixer`), sempre contra a fonte
        float A = canal(gP, c);
        float acc = A;
        float nr = ruido();
        for (int i = 0; i < 4; i++) {
            if (!passeLigado(i)) continue;
            float B = i == 0 ? bilateralY(h0, raioDoPasse(0), K) : (i == 1 ? bilateralY(h1, raioDoPasse(1), K)
                    : (i == 2 ? bilateralY(h2, raioDoPasse(2), K) : bilateralY(h3, raioDoPasse(3), K)));
            float S = nitidez(A, B, tresA(i), nr);
            acc = i == 0 ? S : fixa(S - A) + acc;      // só o passe 0 começa do zero (o laço marca "já passou um")
        }
        __nv_out = gravarF(acc);
        return __nv_out;
    }

    float Kg = limiar(fx16(u.gritSensitivity));
    float raioG = fx16(u.gritRadius) * eng.acEscalaDePixel;
    if (eng.acPass < 18) {
        // ---- o Reduce Grit em x, sobre o resultado sintonizado
        if (!u.reduceGrit) { __nv_out = float4(0.0); return __nv_out; }
        int c = eng.acPass - 15;
        int n = meia(raioG);
        int passo = passoDaJanela(n);
        int ini = -(n / passo) * passo;
        float centro = sintonizado(gP)[c];
        float sw = 0.0;
        float swv = 0.0;
        for (int j = ini; j <= n; j += passo) {
            float q = sintonizado(int2(clamp(gP.x + j, 0, gT.x - 1), gP.y))[c];
            float d = centro - q;
            float w = peso(j, raioG) / (mul(mul(d, d), Kg) + 1.0);
            sw += w;
            swv += mul(q, w);
        }
        __nv_out = gravarF(swv / sw);
        return __nv_out;
    }

    // ---- a saída
    float4 s = inputImg.read(uint2(gP), uint(0));
    float3 B = u.reduceGrit ? float3(bilateralY(h0, raioG, Kg), bilateralY(h1, raioG, Kg), bilateralY(h2, raioG, Kg))
                        : sintonizado(gP);
    int3 o = int3(floor(fixa3(clamp(B, 0.0, 1.0) * 255.0) + 0.5));
    float mx = pct(u.mixWithOriginal);
    if (mx != 0.0) {
        int b = 256 - int(floor(mx * 256.0 + 0.5));
        int3 f = int3(s.rgb * 255.0 + 0.5);
        int3 dif = (o - f) * b;
        o = (f + int3(floor(float3(dif) / 256.0))) & 255;
    }
    __nv_out = float4(float3(o) / 255.0, s.a);
    return __nv_out;
}
