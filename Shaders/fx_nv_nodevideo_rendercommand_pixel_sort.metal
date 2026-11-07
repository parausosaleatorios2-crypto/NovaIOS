// ---------------------------------------------------------------------------
// Classificação de pixels (NV)
// origem : assets/effects/nv-nodevideo-rendercommand-pixel-sort.xml
// id     : nv.effect.nodevideo-rendercommand-pixel-sort
// passes : 20
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_rendercommand_pixel_sortParams {
    float limiar;
    float angulo;
    int tipo;
    int aleatorio;
    float continuo;
};

// --- funcoes auxiliares do efeito
// ---- Passes (o <passes> tem 20) ----
const int MARGEM = 4;
const int P_GIRO = 0;      // giroRt: a camada girada
const int P_PONTEIROS = 1; // saltoA: os ponteiros de começo/fim (ou do próximo que entra)
const int P_SALTO = 2;     // 2..7: 6 saltos de ×4 (4⁶ = 4096), B ← A, A ← B...; o último fica em saltoA
const int P_FAIXAS = 8;    // saltoB: (começo, fim) de cada pixel
const int P_ORDEM = 9;     // 9: blocos de 8; 10..18: intercala 8+8 ... 2048+2048; saltoA ← giroRt, giroRt ← saltoA...
const int P_VOLTA = 19;    // lê giroRt
const int BLOCO = 8;

static float3 linear(float3 c) { return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(float3(0.04045), c)); }
static float3 srgb(float3 l) {
    l = clamp(l, 0.0, 1.0);
    return mix(l * 12.92, 1.055 * pow(l, float3(1.0 / 2.4)) - 0.055, step(float3(0.0031308), l));
}

static int2 tamCamada() { return int2(int(inputImg.get_width()), int(inputImg.get_height())); }
// O pixel do RT do Node na posição (x, y) da camada de pé, em bytes (0..255).
static float4 bytesDaCamada(int2 p) {
    int2 T = tamCamada();
    if (eng.acEntradaDePe != 1) p.y = T.y - 1 - p.y;
    float4 c = inputImg.read(uint2(p), uint(0));
    return floor(float4(srgb(linear(c.rgb) * c.a), c.a) * 255.0 + 0.5);
}

// ---- A geometria do giro (nv_cpu_eft_pixelsort) ----
float co, si;           // cos e sin do ângulo
float2 centro;            // (w/2, h/2)
int2 caixa;            // a caixa girada do Node: (int)(extensão + 4)
float2 centroG;           // o meio dela
bool deLado;            // a linha do Node corre na vertical do buffer
int2 L;                // elementos usados: (ao longo, através)
float2 f;                 // quanto o buffer encolhe a caixa (1 = pixel a pixel)
static void montarGiro() {
    int2 T = tamCamada();
    // O Node: sincos em double de ângulo × 0,017453291681077746 (o grau→radiano arredondado), então o cos de 270°
    // é −2,3e−7 e não zero — e o corte para baixo do bilinear perde um nível onde a conta cai logo abaixo do inteiro.
    // O float da GPU não chega a isso por cos(ângulo): o quadrante exato e o resto pequeno, que o float guarda.
    float q = floor(u.angulo / 90.0 + 0.5);
    float r = (u.angulo - 90.0 * q) * 0.017453291681077746 - 7.549789948768648e-8 * q;
    float c0 = cos(r), s0 = sin(r);
    int k = int(__nv_mod(q, 4.0));
    co = k == 0 ? c0 : (k == 1 ? -s0 : (k == 2 ? -c0 : s0));
    si = k == 0 ? s0 : (k == 1 ? c0 : (k == 2 ? -s0 : -c0));
    centro = float2(T) * 0.5;
    float2 x0 = float2(-centro.x, float(T.x - 1) - centro.x);
    float2 y0 = float2(-centro.y, float(T.y - 1) - centro.y);
    float xa = 1e9, xb = -1e9, ya = 1e9, yb = -1e9;
    for (int i = 0; i < 2; i++) for (int k = 0; k < 2; k++) {
        float gx = x0[i] * co - y0[k] * si, gy = x0[i] * si + y0[k] * co;
        xa = min(xa, gx); xb = max(xb, gx); ya = min(ya, gy); yb = max(yb, gy);
    }
    caixa = int2(int(xb - xa + 4.0), int(yb - ya + 4.0));
    centroG = float2(caixa) * 0.5;
    int2 B = T + 2 * MARGEM;
    bool cabe = caixa.x <= B.x && caixa.y <= B.y;
    bool cabeDeLado = caixa.x <= B.y && caixa.y <= B.x;
    if (cabe) deLado = false;
    else if (cabeDeLado) deLado = true;
    else deLado = max(float(caixa.x) / float(B.y), float(caixa.y) / float(B.x))
                < max(float(caixa.x) / float(B.x), float(caixa.y) / float(B.y));
    int2 cap = deLado ? B.yx : B;
    L = min(caixa, cap);
    f = float2(caixa) / float2(L);
}
static int2 texelDe(int a, int c) { return deLado ? int2(c, a) : int2(a, c); }
static void elementoDoTexel(int2 b, out int a, out int c) { a = deLado ? b.y : b.x; c = deLado ? b.x : b.y; }
// elemento (ao longo, através) → ponto da caixa girada do Node
static float2 pontoGirado(int a, int c) {
    return float2(L.x == caixa.x ? float(a) : (float(a) + 0.5) * f.x - 0.5,
                L.y == caixa.y ? float(c) : (float(c) + 0.5) * f.y - 0.5);
}

// ---- As chaves (pixelSortRow e os comparadores), nos bytes ÷ 255 ----
static float fmodC(float x, float y) { return x - y * trunc(x / y); }
static float chave(float3 c) {
    int t = int(u.tipo);
    if (t == 0) return (c.r + c.g + c.b) / 3.0;
    float mx = max(max(c.r, c.g), c.b), mn = min(min(c.r, c.g), c.b), d = mx - mn;
    if (t == 3) return mx;
    if (t == 4) return mn;
    if (t == 2) return d > 0.0 && mx > 0.0 ? d / mx : 0.0;
    if (d <= 0.0) return 0.0;
    float h;
    if (mx == c.r) h = fmodC((c.g - c.b) / d, 6.0) * 60.0;
    else if (mx == c.g) h = ((c.b - c.r) / d + 2.0) * 60.0;
    else h = ((c.r - c.g) / d + 4.0) * 60.0;
    if (h < 0.0) h += 360.0;
    return h / 360.0;
}
static bool entra(float4 bytes) { return bytes.a / 255.0 > 0.001 && chave(bytes.rgb / 255.0) >= u.limiar; }

// ---- Os ponteiros: dois índices de 16 bits por texel ----
static float4 guardar(int p, int q) { return float4(float(p / 256), float(p % 256), float(q / 256), float(q % 256)) / 255.0; }
static int2 ler(sampler2D s, int a, int c) {
    int4 v = int4(s.read(uint2(texelDe(a, c)), uint(0)) * 255.0 + 0.5);
    return int2(v.x * 256 + v.y, v.z * 256 + v.w);
}

// Os sorteios (o rand() do Node): hash da linha, do índice e do quadro.
static uint hash3(uint3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return v.x ^ v.y ^ v.z;
}
static float sorteio(int linha, int i, int qual, float a, float b) {
    uint quadro = uint(int(floor(eng.acTime * 1000.0 + 0.5)));
    float u = float(hash3(uint3(uint(linha), uint(i) * 4u + uint(qual), quadro)) >> 8u) / 16777216.0;
    return a + u * (b - a);
}
static bool continua(int linha, int i) { return u.continuo * 100.0 >= sorteio(linha, i, 2, 0.0, 100.0); }

static float4 passeGiro(int2 b) {
    int a, c;
    elementoDoTexel(b, a, c);
    if (a >= L.x || c >= L.y) return float4(0.0);
    float2 g = pontoGirado(a, c) - centroG;
    float2 s = float2(g.x * co + g.y * si, g.y * co - g.x * si) + centro;
    int2 i = int2(s);                   // fcvtzs: corta para o zero
    int2 T = tamCamada();
    if (s.x <= -1.0 || s.y <= -1.0 || i.x < 0 || i.y < 0 || i.x >= T.x - 1 || i.y >= T.y - 1) return float4(0.0);
    float2 fr = s - float2(i);
    float4 v = mix(mix(bytesDaCamada(i), bytesDaCamada(i + int2(1, 0)), fr.x),
                 mix(bytesDaCamada(i + int2(0, 1)), bytesDaCamada(i + int2(1, 1)), fr.x), fr.y);
    return clamp(floor(v + 1e-4), 0.0, 255.0) / 255.0;
}

static bool entraEm(int a, int c) { return entra(floor(giroRt.read(uint2(texelDe(a, c)), uint(0)) * 255.0 + 0.5)); }

static float4 passePonteiros(int2 b) {
    int a, c;
    elementoDoTexel(b, a, c);
    if (a >= L.x || c >= L.y) return guardar(a, a);
    int ultimo = L.x - 1;
    bool q = entraEm(a, c);
    if (u.aleatorio) return guardar(a, q || a == ultimo ? a : a + 1);   // o próximo que entra
    int p = q && a > 0 && entraEm(a - 1, c) ? a - 1 : a;
    int n = q && a < ultimo && entraEm(a + 1, c) ? a + 1 : a;
    return guardar(p, n);
}

// p ← p(p(p(p))): o alcance vezes 4 a cada passe
static float4 passeSalto(int2 b, sampler2D de) {
    int a, c;
    elementoDoTexel(b, a, c);
    if (a >= L.x || c >= L.y) return guardar(a, a);
    int2 p = ler(de, a, c);
    for (int k = 0; k < 3; k++) p = int2(ler(de, p.x, c).x, ler(de, p.y, c).y);
    return guardar(p.x, p.y);
}

static float4 passeFaixas(int2 b) {
    int a, c;
    elementoDoTexel(b, a, c);
    if (a >= L.x || c >= L.y) return guardar(a, a);
    int ultimo = L.x - 1;
    if (!u.aleatorio) {
        if (a == ultimo || !entraEm(a, c)) return guardar(a, a);
        int2 p = ler(saltoA, a, c);
        int fim = min(p.y, ultimo - 1);
        if (fim <= p.x || !continua(c, p.x)) return guardar(a, a);
        return guardar(p.x, fim);
    }
    // Aleatório: a corrente de faixas desde o começo da linha
    int r = 0;
    for (int k = 0; k < 1024; k++) {
        if (r > ultimo) break;
        int ini = ler(saltoA, r, c).y;
        if (ini > a || !entraEm(ini, c)) break;
        float comp = float(caixa.x) * 0.01 + floor(sorteio(c, k, 1, 1.0, 100.0));
        int fim = min(ultimo, int(float(ini) + comp / f.x));
        if (a <= fim) return fim > ini && continua(c, k) ? guardar(ini, fim) : guardar(a, a);
        r = fim + 2;
    }
    return guardar(a, a);
}

// ---- A ordenação de cada faixa, no lugar: blocos de 8 e intercalações (estável; empate fica na ordem) ----
static float chaveEm(sampler2D de, int ini, int i, int c) {
    return chave(floor(de.read(uint2(texelDe(ini + i, c)), uint(0)).rgb * 255.0 + 0.5) / 255.0);
}
static float4 passeBloco(int2 b, sampler2D de) {
    int a, c;
    elementoDoTexel(b, a, c);
    float4 meu = de.read(uint2(b), uint(0));
    if (a >= L.x || c >= L.y) return meu;
    int2 fx = ler(saltoB, a, c);
    int n = fx.y - fx.x + 1;
    if (n <= 1) return meu;
    int i = a - fx.x, b0 = i / BLOCO * BLOCO, cnt = min(BLOCO, n - b0), r = i - b0;
    float k[BLOCO];
    for (int j = 0; j < BLOCO; j++) if (j < cnt) k[j] = chaveEm(de, fx.x, b0 + j, c);
    // o elemento cuja posição na ordem é r
    for (int j = 0; j < BLOCO; j++) {
        if (j >= cnt) break;
        int pos = 0;
        for (int l = 0; l < BLOCO; l++) if (l < cnt && (k[l] < k[j] || (k[l] == k[j] && l < j))) pos++;
        if (pos == r) return float4(de.read(uint2(texelDe(fx.x + b0 + j, c)), uint(0)).rgb, meu.a);
    }
    return meu;
}
// intercala as metades ordenadas de cada bloco de 2m: a posição k sai da busca binária (merge path)
static float4 passeJuntar(int2 b, int m, sampler2D de) {
    int a, c;
    elementoDoTexel(b, a, c);
    float4 meu = de.read(uint2(b), uint(0));
    if (a >= L.x || c >= L.y) return meu;
    int2 fx = ler(saltoB, a, c);
    int n = fx.y - fx.x + 1;
    if (n <= m) return meu;
    int i = a - fx.x, b0 = i / (2 * m) * (2 * m);
    int la = min(m, n - b0), lb = clamp(n - b0 - m, 0, m), k = i - b0;
    if (lb == 0) return meu;
    int A = fx.x + b0, B = A + m;
    int lo = max(0, k - lb), hi = min(k, la);
    for (int it = 0; it < 13; it++) {
        if (lo >= hi) break;
        int mid = (lo + hi) / 2;
        if (chaveEm(de, A, mid, c) <= chaveEm(de, B, k - mid - 1, c)) lo = mid + 1; else hi = mid;
    }
    int ia = lo, ib = k - lo;
    bool daA = ia < la && (ib >= lb || chaveEm(de, A, ia, c) <= chaveEm(de, B, ib, c));
    return float4(de.read(uint2(texelDe(daA ? A + ia : B + ib, c)), uint(0)).rgb, meu.a);  // só o RGB anda
}

static float4 bytesGirados(int a, int c) { return floor(giroRt.read(uint2(texelDe(a, c)), uint(0)) * 255.0 + 0.5); }
static float4 passeVolta() {
    int2 T = tamCamada();
    float2 q = eng.acEntradaDePe == 1 ? in.acScreenNorm : float2(in.acScreenNorm.x, 1.0 - in.acScreenNorm.y);
    int2 p = int2(min(floor(q * float2(T)), float2(T) - 1.0));
    float2 d = float2(p) - centro;
    float2 g = float2(d.x * co - d.y * si, d.x * si + d.y * co) + centroG;
    int2 gi = int2(g);
    float4 v;
    if (g.x <= -1.0 || g.y <= -1.0 || gi.x < 0 || gi.y < 0 || gi.x >= caixa.x - 1 || gi.y >= caixa.y - 1) {
        v = bytesDaCamada(p);
    } else {
        // no elemento do buffer (pixel a pixel, ou encolhido)
        float2 u = float2(L.x == caixa.x ? g.x : (g.x + 0.5) / f.x - 0.5, L.y == caixa.y ? g.y : (g.y + 0.5) / f.y - 0.5);
        u = clamp(u, float2(0.0), float2(L - 1));
        int2 e = int2(u);
        int2 e1 = min(e + 1, L - 1);
        float2 fr = u - float2(e);
        v = mix(mix(bytesGirados(e.x, e.y), bytesGirados(e1.x, e.y), fr.x),
                mix(bytesGirados(e.x, e1.y), bytesGirados(e1.x, e1.y), fr.x), fr.y);
        v = clamp(floor(v + 1e-4), 0.0, 255.0);
    }
    v /= 255.0;
    return v.a > 0.0 ? float4(srgb(min(linear(v.rgb) / v.a, float3(1.0))), v.a) : float4(0.0);
}

fragment float4 fx_nv_nodevideo_rendercommand_pixel_sort(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_rendercommand_pixel_sortParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> giroRt [[texture(1)]],
    texture2d<float> saltoA [[texture(2)]],
    texture2d<float> saltoB [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    montarGiro();
    int2 b = int2(__nv_fragCoord.xy);
    if (eng.acPass == P_GIRO) { __nv_out = passeGiro(b); return __nv_out; }
    if (eng.acPass == P_PONTEIROS) { __nv_out = passePonteiros(b); return __nv_out; }
    if (eng.acPass < P_FAIXAS) {
        int k = eng.acPass - P_SALTO;
        __nv_out = k % 2 == 0 ? passeSalto(b, saltoA) : passeSalto(b, saltoB);
        return __nv_out;
    }
    if (eng.acPass == P_FAIXAS) { __nv_out = passeFaixas(b); return __nv_out; }
    if (eng.acPass == P_ORDEM) { __nv_out = passeBloco(b, giroRt); return __nv_out; }
    if (eng.acPass < P_VOLTA) {
        int k = eng.acPass - P_ORDEM, m = BLOCO << (k - 1);
        __nv_out = k % 2 == 0 ? passeJuntar(b, m, giroRt) : passeJuntar(b, m, saltoA);
        return __nv_out;
    }
    __nv_out = passeVolta();
    return __nv_out;
}
