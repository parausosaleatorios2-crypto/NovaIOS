// ---------------------------------------------------------------------------
// BCC Rays Textured
// origem : assets/effects/bcc-rays-textured.xml
// id     : nova.effect.bccraystextured
// passes : 5
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_rays_texturedParams {
    float2 lightSource;
    float intensity;
    float rayLength;
    int look;
    float extendRays;
    float contractRays;
    float holdoutRadius;
    int textureMode;
    float textureAmount;
    float textureScale;
    float textureBias;
    float flowRate;
    float flowDirection;
    float morphStart;
    float morphRate;
    float textureRadius;
    float textureFalloff;
    int rayTexture;
    float shimmerIntensity;
    float shimmerDetail;
    int colorMode;
    float4 color1;
    float4 color2;
    float4 color3;
    float4 color4;
    float4 color5;
    float4 color6;
    int applyMode;
    float sourceOpacity;
    float lightOpacity;
    float mixOriginal;
};

// --- funcoes auxiliares do efeito
const float GRAU = 0.017453292;            // π/180 em float, como o plugin
const int MEIA_VOLTA = 0x1680000;          // 360° · 65536

// ---- a camada do AE no buffer (como no CC Light Burst) -------------------------------------------
int2 gBuf, gInicio;
int W, H;
bool dePe;
float Lx, Ly;                               // a luz em px da camada, na orientação da imagem (linha 0 = topo)

static void preparar() {
    gBuf = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 tam = clamp(int2(floor(eng.acCamada * float2(gBuf) + 0.5)), int2(1), gBuf);
    gInicio = (gBuf - tam) / 2;
    W = tam.x; H = tam.y;
    dePe = eng.acEntradaDePe == 1;
    float2 cb = __nv_acPontoNoBuffer(u.lightSource) * float2(gBuf) - float2(gInicio);
    if (dePe) cb.y = float(H) - cb.y;
    Lx = cb.x; Ly = cb.y;
}
static int2 noBuffer(int x, int y) { return gInicio + int2(x, dePe ? H - 1 - y : y); }

// ---- ruído de gradiente 3D (o Shimmer, aproximado) ----------------------------------------------
static float3 hash3(float3 p) {
    p = float3(dot(p, float3(127.1, 311.7, 74.7)), dot(p, float3(269.5, 183.3, 246.1)), dot(p, float3(113.5, 271.9, 124.6)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
static float perlin3(float3 p) {
    float3 i = floor(p), f = fract(p);
    float3 u = f * f * (3.0 - 2.0 * f);
    float n000 = dot(hash3(i + float3(0, 0, 0)), f - float3(0, 0, 0));
    float n100 = dot(hash3(i + float3(1, 0, 0)), f - float3(1, 0, 0));
    float n010 = dot(hash3(i + float3(0, 1, 0)), f - float3(0, 1, 0));
    float n110 = dot(hash3(i + float3(1, 1, 0)), f - float3(1, 1, 0));
    float n001 = dot(hash3(i + float3(0, 0, 1)), f - float3(0, 0, 1));
    float n101 = dot(hash3(i + float3(1, 0, 1)), f - float3(1, 0, 1));
    float n011 = dot(hash3(i + float3(0, 1, 1)), f - float3(0, 1, 1));
    float n111 = dot(hash3(i + float3(1, 1, 1)), f - float3(1, 1, 1));
    return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
               mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// ---- a textura do BCC (o Noise Map), lida na DLL -------------------------------------------------
// FUN_18046dde0: o ruído de gradiente 3D global do Continuum (a tabela do FUN_18046d5a0: identidade de 0 a 256
// embaralhada por LCG com semente 1; 16 gradientes), conta por conta na ordem do asm (conferido 0 de 27 mil pontos
// contra a DLL chamada fora do AE: tools/bccraystextured/oraculo/ruido.py).
// A tabela e os gradientes NÃO são listas constantes: indexar 514 + 16 constantes levava 8 s para compilar na GPU
// do PC (1 s sem elas). A tabela sai do passe 0 (permBuf, 514×1): cada ponto refaz o LCG de trás para frente (o
// estado final 0x1EF6C426 e o inverso do multiplicador 0xEEB9EB65) seguindo onde o seu valor estava; P[256+i] =
// P[i mod 256], como a cópia do plugin (que sobrescreve o 256). Os gradientes são as 12 arestas + 4 repetidas.
static int permDoPasse(int i) {
    int pos = i & 255;
    uint s = 0x1EF6C426u;
    for (int k = 129; k >= 1; k--) {
        int idx = 256 - 2 * (k - 1), r = int((s >> 16) & 255u);
        if (pos == idx) pos = r; else if (pos == r) pos = idx;
        s = (s - 0x3039u) * 0xEEB9EB65u;
    }
    return pos;
}
static int PERM(int i) {
    int2 b = int2(floor(permBuf.read(uint2(int2(i, 0)), uint(0)).rg * 255.0 + 0.5));
    return b.x + (b.y << 8);
}
const float G7 = 0.70710677;               // 0x3F3504F3
static float3 gradBcc(int h) {
    if (h >= 12) return h == 12 ? float3(G7, G7, 0.0) : h == 13 ? float3(-G7, G7, 0.0) : h == 14 ? float3(0.0, -G7, G7) : float3(0.0, -G7, -G7);
    float s1 = (h & 1) != 0 ? -G7 : G7, s2 = (h & 2) != 0 ? -G7 : G7;
    return h < 4 ? float3(s1, s2, 0.0) : h < 8 ? float3(s1, 0.0, s2) : float3(0.0, s1, s2);
}
static int pisoBcc(float v) { return int(v >= 0.0 ? v : v - 1.0); }    // cvttss2si de (v < 0 ? v − 1 : v)
static float curvaBcc(float t) { return ((((t * 6.0) - 15.0) * t + 10.0) * t) * (t * t); }
static float cantoBcc(int h, int c, float gx, float gy, float gz) {
    float3 g = gradBcc((h + c) & 15);
    return (gy * g.y + gx * g.x) + gz * g.z;
}
static float ruidoBcc(float x, float y, float z) {
    int ix = pisoBcc(x), iy = pisoBcc(y), iz = pisoBcc(z);
    int X0 = (ix + 32) & 255, X1 = (X0 + 1) & 255, Y0 = (iy + 32) & 255, Y1 = (Y0 + 1) & 255;
    float fx = x - float(ix), fy = y - float(iy), fz = z - float(iz);
    float fx1 = fx - 1.0, fy1 = fy - 1.0, fz1 = fz - 1.0;
    float u = curvaBcc(fx), v = curvaBcc(fy), w = curvaBcc(fz);
    int a = PERM(X0), b = PERM(X1);
    int A0 = PERM(a + Y0), B0 = PERM(b + Y0), A1 = PERM(a + Y1), B1 = PERM(b + Y1);
    float n000 = cantoBcc(A0, iz, fx, fy, fz), n100 = cantoBcc(B0, iz, fx1, fy, fz);
    float nx00 = (n100 - n000) * u + n000;
    float n010 = cantoBcc(A1, iz, fx, fy1, fz), n110 = cantoBcc(B1, iz, fx1, fy1, fz);
    float nx10 = (n110 - n010) * u + n010;
    float nxy0 = (nx10 - nx00) * v + nx00;
    float n001 = cantoBcc(A0, iz + 1, fx, fy, fz1), n101 = cantoBcc(B0, iz + 1, fx1, fy, fz1);
    float nx01 = (n101 - n001) * u + n001;
    float n011 = cantoBcc(A1, iz + 1, fx, fy1, fz1), n111 = cantoBcc(B1, iz + 1, fx1, fy1, fz1);
    float nx11 = (n111 - n011) * u + n011;
    float nxy1 = (nx11 - nx01) * v + nx01;
    return ((nxy1 - nxy0) * w + nxy0) * 1.5;
}

// FUN_180d23c00 + FUN_180d23930 (1 oitava, tipo 1): a imagem da textura tem (W+1)×(H+1) pontos; x anda 1000/Scale
// na largura, y na mesma escala, o centro no meio. O Flow é ∫taxa·(cos θ, −sen θ)·0,05 e o Morph, início + 0,1·∫taxa
// (θ = 180° − Direction; ∫ em segundos — com os controles parados, taxa·t). Conferido 100% igual ao View do AE nos quadros
// 0 e 15. Valor = |ruído| preso em 1.
float gTb0, gTpx, gTpy, gTy0, gTo24, gTo28, gTz;
static void prepararTextura() {
    float S = max(u.textureScale, 1.0);
    float Wl = float(W + 1), Hl = float(H + 1);
    gTb0 = 1000.0 / S;                                  // 0xb0
    gTpx = gTb0 * (1.0 / Wl);                           // 0xa8
    float f9 = ((Hl / Wl) * 1000.0) / S;
    gTy0 = f9 * -0.5;                                   // 0xa0
    gTpy = f9 / Hl;                                     // 0xa4
    float m = 0.05 * u.flowRate * eng.acTime, a = (180.0 - u.flowDirection) * GRAU;   // θ = 180° − Direction (medido)
    gTo24 = m * cos(a); gTo28 = -m * sin(a);
    gTz = u.morphStart + 0.1 * u.morphRate * eng.acTime;
}
static float texturaBcc(int r, int c) {
    float n = ruidoBcc((gTb0 * -0.5 + float(c) * gTpx) + gTo28, (float(r) * gTpy + gTy0) - gTo24, gTz);
    return min(n <= 0.0 ? n * -1.0 : n, 1.0);
}
// o ponto (r, c) da imagem: do texBuf (os bits do float em RGBA8); a linha e a coluna a mais, na hora
static float pontoDaTextura(int r, int c) {
    if (r >= H || c >= W) return texturaBcc(r, c);
    uint4 b = uint4(floor(texBuf.read(uint2(noBuffer(c, r)), uint(0)) * 255.0 + 0.5));
    return as_type<float>(b.r | (b.g << 8) | (b.b << 16) | (b.a << 24));
}
// FUN_18069d160: bilinear em float; py, px em 24.8; fora da imagem os vizinhos viram a borda (0 ou H/W)
static float amostraTextura(int py, int px) {
    int r0 = py >> 8, c0 = px >> 8, r1 = r0 + 1, c1 = c0 + 1;
    if (r0 < 0 || r0 >= H) { r0 = r0 < 0 ? 0 : H; r1 = r0; }
    if (c0 < 0 || c0 >= W) { c0 = c0 < 0 ? 0 : W; c1 = c0; }
    float wr = float(py & 255) * 0.00390625, wc = float(px & 255) * 0.00390625;
    float a = ((1.0 - wc) * wr) * pontoDaTextura(r1, c0) + ((1.0 - wr) * (1.0 - wc)) * pontoDaTextura(r0, c0);
    float b = ((1.0 - wr) * wc) * pontoDaTextura(r0, c1) + (wc * wr) * pontoDaTextura(r1, c1);
    return a + b;
}
// a textura no k do raio (FUN_180e1d340): Amount·0,025, Bias·0,005, Radius e Falloff em % da largura
bool gTexOn;
float gTA, gTB, gTr1q, gTr2q, gTdif;
static void prepararTexturaNoRaio() {
    gTexOn = u.textureMode == 0 && u.textureAmount != 0.0;
    gTA = u.textureAmount * 0.025; gTB = u.textureBias * 0.005;
    float r1 = u.textureRadius * float(W) * 0.01, r2 = u.textureFalloff * float(W) * 0.01 + r1;
    gTr1q = r1 * r1; gTr2q = r2 * r2; gTdif = gTr2q - gTr1q;
}
static float texturaNoK(float k, float r2, int py, int px) {
    if (!gTexOn || r2 >= gTr2q) return k;
    float t = amostraTextura(py, px) - gTB;
    if (r2 > gTr1q) t *= (gTr2q - r2) / gTdif;
    float a = t * gTA;
    if (t > 0.0) return max(1.0 - max(1.0 - a, 0.0) * (1.0 - k), 0.0);
    return k * min(a + 1.0, 0.0);                   // é o que o plugin faz (minss com 0): k vai a zero
}

// ---- a luz em 16 bits -----------------------------------------------------------------------------
static uint luz(int y, int x) {
    if (x < 0 || y < 0 || x >= W || y >= H) return 0u;
    float4 t = luzBuf.read(uint2(noBuffer(x, y)), uint(0));
    return uint(floor(t.r * 255.0 + 0.5)) * 256u + uint(floor(t.g * 255.0 + 0.5));
}
// FUN_180e1f280: bilinear de 8 bits; py, px em 24.8
static uint amostra(int py, int px) {
    int y0 = py >> 8, x0 = px >> 8;
    uint fy = uint(py & 255), fx = uint(px & 255);
    uint i6 = luz(y0, x0), i5 = luz(y0, x0 + 1), i7 = luz(y0 + 1, x0), i8 = luz(y0 + 1, x0 + 1);
    return ((fx * i5 + (256u - fx) * i6) * (256u - fy) + ((256u - fx) * i7 + fx * i8) * fy) >> 16;
}

// ---- o atan2 inteiro do BCC (FUN_1803693a0, tabela de FUN_180369e70, divisão de FUN_180369330) -----
static int divA(int a, int b) {
    if (b < 0x4000) return (a << 16) / max(b, 1);
    if (b < 0x10000) return (a << 14) / ((b + 3) >> 2);
    if (b < 0x40000) return (a << 12) / ((b + 15) >> 4);
    return int(float(a) * 65536.0 / float(b));
}
static int tab(int i) { return int(__nv_atan(min(float(i) * 0.00390625, 1.0)) * 57.29578 * 65536.0 + 0.5); }
static int interp(int q, out bool ok) {
    int i = q >> 8, f = q & 255;
    ok = i >= 0 && i < 256;
    int i0 = clamp(i, 0, 255);
    int t0 = tab(i0);
    return (((tab(i0 + 1) - t0) * f) >> 8) + t0;
}
static int atan2Fixo(int p1, int p2) {
    int a1 = abs(p1), a2 = abs(p2);
    bool menor = a1 <= a2, ok;
    int t = menor ? interp(divA(a1, a2 + 1), ok) : interp(divA(a2, max(a1, 1)), ok);
    if (p1 >= 0 && p2 >= 0) return menor ? (ok ? t : 0) : (ok ? 0x5a0000 - t : 0x5a0000);
    if (p1 >= 0) return menor ? (ok ? 0xb40000 - t : 0xb40000) : (ok ? t + 0x5a0000 : 0x5a0000);
    if (p2 >= 0) return menor ? (ok ? -t : 0) : (ok ? t - 0x5a0000 : -0x5a0000);
    return menor ? (ok ? t - 0xb40000 : -0xb40000) : (ok ? -0x5a0000 - t : -0x5a0000);
}
static uint isqrtU(uint n) {
    uint s = uint(sqrt(float(n)));
    while (s > 0u && s * s > n) s--;
    while (s < 65535u && (s + 1u) * (s + 1u) <= n) s++;
    return s;
}

// ---- o Look (FUN_180d21ad0) e o coeficiente do raio -----------------------------------------------
float gExt, gHold, gP0, gP1, gRL2, gW2;
int gPot;
static void prepararLook() {
    float rl = max(u.rayLength, 0.0), e = 15.0, c = 0.0, h = 1.0;
    if (u.look == 1) { e = u.extendRays; c = u.contractRays; h = u.holdoutRadius; }
    else if (u.look == 2) { e = 100.0; c = 0.0; h = 1.0; }
    else if (u.look == 3) { e = rl; c = 7.0; h = 1.0; }
    else if (u.look == 4) { e = 100.0; c = 0.0; h = rl * -0.03; }
    else if (u.look == 5) { e = 100.0; float f8 = rl > 80.0 ? (rl - 80.0) * 0.3 : 0.0; c = rl > 150.0 ? (rl - 150.0) * 0.3 + f8 : f8; h = 1.0; }
    else if (u.look == 6) { e = 0.0; c = 25.0; h = 1.0; }
    else if (u.look == 7) { e = rl > 80.0 ? (rl - 80.0) * 0.7 : 0.0; c = 70.0 - rl * 0.4; h = 1.0; }
    else if (u.look == 8) { e = 0.0; c = 40.0; h = -4.5; }
    c = max(c, 0.0);
    float f = max(0.0, 30.0 - rl) / 30.0;
    float p4f = 880.0 * f * f * f + 120.0;          // 0x5e004f (0x5e0060 = 12, 0x5e006a = 30 na TexturedLight)
    float a184 = min(c * 0.3, 1000.0) * 0.001;      // 0x5e000d = Contract · 0,3
    float m = (1.0 - a184) * p4f * 0.001 + a184;    // 0x18c
    gP0 = 1.0 - a184; gP1 = 1.0 - m;
    gExt = e * 0.01;
    gHold = h * float(W) * 0.01;                    // o Holdout é % da largura
    gRL2 = rl * rl; gW2 = float(W) * float(W);
    gPot = max(int(floor(1.0 / max(eng.acEscalaDePixel, 1e-4) + 0.5)), 1);   // a prévia reduzida: k^n, como o BCC
    prepararTextura(); prepararTexturaNoRaio();
}
// FUN_180e1b8d0 (atenuação 0, holdout pela raiz: 0x5e006c = 1) e FUN_180e1d340 (0x5e006b = 1); py, px = o ponto
// do raio em 24.8 (onde a textura é lida)
static int coeficiente(int i, int v, int acc, int passo, int py, int px) {
    float r = float(i);
    float d = r - gHold;
    float f = (gHold != 0.0) ? (d >= 0.0 ? d * d : 0.0) : r * r;
    float x = (f * gRL2) / gW2;
    float k = min(1.0 - exp(-x * 0.008), 1.0);
    if (gExt != 0.0 && acc != v) {                  // FUN_180e1d660, modo 1
        float dl = float(v) * 3.0517578e-05 - float(acc) * 3.0517578e-05;
        if ((gExt > 0.0 && dl > 0.0) || (gExt < 0.0 && dl < 0.0)) k *= clamp(1.0 - dl * gExt, 0.0, 1.0);
    }
    k = min(texturaNoK(k, r * r, py, px), 1.0);
    float f6 = (gP0 - gP1) * k + gP1;
    int n = gPot * passo;
    if (n > 1 && f6 != 0.0) f6 = n == 2 ? f6 * f6 : (n == 3 ? f6 * f6 * f6 : (n == 4 ? (f6 * f6) * (f6 * f6) : pow(f6, float(n))));
    return int((1.0 - f6) * 65536.0 + 0.5);
}
// Um raio do mapa polar (FUN_180e1da20), da linha i0 (com o acumulado acc0 nela) até r1: o acumulado nas linhas r0
// e r1. Na linha i a posição é a da luz + i·passo, a mesma de marchar do centro.
static int2 raio(float ang, int i0, int acc0, int r0, int r1) {
    float s = sin(ang), c = cos(ang);
    int dy = int(s * 65536.0 + 0.5), dx = int(c * 65536.0 + 0.5);   // (int) trunca para o zero
    int y = int(Ly * 65536.0 + 0.5) + i0 * dy, x = int(Lx * 65536.0 + 0.5) + i0 * dx;
    int acc = acc0;
    int2 res = int2(acc);
    for (int i = i0 + 1; i <= r1; i++) {
        y += dy; x += dx;
        int v = int(amostra(y >> 8, x >> 8) >> 1);
        acc += ((v - acc) * (coeficiente(i, v, acc, 1, y >> 8, x >> 8) >> 1)) >> 15;
        if (i <= r0) res.x = acc;
        res.y = acc;
    }
    return res;
}
static int accDoCentro() {
    return min(int(amostra(int(Ly * 65536.0 + 0.5) >> 8, int(Lx * 65536.0 + 0.5) >> 8) >> 1), 0x8000);
}
static int numeroDeAngulos(int w) {                        // (uint)((double)W · 1,4): o 1,4 em double é um pouco menos
    int t = 14 * w, n = t / 10, p2 = 1;
    while (p2 <= n / 2) p2 *= 2;                    // a maior potência de 2 até n (findMSB é do ES 3.1)
    if (t % 10 == 0 && 4 * w > 5 * p2) n -= 1;
    return max(n, 1);
}

// ---- o tamanho do mapa e os pontos de controle ---------------------------------------------------
const int LADO_DOS_PONTOS = 1024;          // o pontosBuf (o passe que o escreve não pergunta o tamanho dele)
int gNa, gNr, gNc, gK;
float gPassoAng, gComeco;
static void prepararMapa() {
    gNa = numeroDeAngulos(W);
    gPassoAng = 360.0 / float(gNa); gComeco = gPassoAng * 0.5;
    float dmax = max(max(length(float2(Lx, Ly)), length(float2(Lx - float(W), Ly))),
                     max(length(float2(Ly - float(H), Lx)), length(float2(Ly - float(H), Lx - float(W)))));
    gNr = int(dmax) + (fract(dmax) != 0.0 ? 1 : 0) + 2;
    gNc = max(min((gNr + 31) / 32, LADO_DOS_PONTOS * LADO_DOS_PONTOS / gNa), 1);   // pontos por ângulo
    gK = (gNr + gNc - 1) / gNc;                                                    // linhas entre eles
}
static float anguloDaColuna(int c) { return (float(c) * gPassoAng + gComeco) * GRAU; }
// O acumulado do ângulo c na linha j·K (j ≥ 1), guardado pelo passe 1 em 16 bits (R e G).
static int ponto(int c, int j) {
    int i = c * gNc + j - 1;
    float4 t = pontosBuf.read(uint2(int2(i % LADO_DOS_PONTOS, i / LADO_DOS_PONTOS)), uint(0));
    return int(floor(t.r * 255.0 + 0.5)) * 256 + int(floor(t.g * 255.0 + 0.5));
}
// O raio do ângulo c nas linhas r0 e r1, a partir do ponto de controle de baixo.
static int2 raioDaColuna(int c, int r0, int r1) {
    int j = r0 / gK;
    return raio(anguloDaColuna(c), j * gK, j == 0 ? accDoCentro() : ponto(c, j), r0, r1);
}

// ---- o RGBMix do BCC (copiado do bcc-light-wrap.xml, medido 0 px lá) ---------------------------------------------------------------
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


static float3 colorir(float g) {
    float x = clamp(g, 0.0, 1.0) * 5.0;
    int i = int(min(floor(x), 4.0));
    float f = x - float(i);
    float3 c0 = i == 0 ? u.color1.rgb : i == 1 ? u.color2.rgb : i == 2 ? u.color3.rgb : i == 3 ? u.color4.rgb : u.color5.rgb;
    float3 c1 = i == 0 ? u.color2.rgb : i == 1 ? u.color3.rgb : i == 2 ? u.color4.rgb : i == 3 ? u.color5.rgb : u.color6.rgb;
    return mix(c0, c1, f);
}
static int4 bytes4(float4 c) { return int4(floor(c * 255.0 + 0.5)); }

fragment float4 fx_bcc_rays_textured(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_rays_texturedParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> permBuf [[texture(1)]],
    texture2d<float> luzBuf [[texture(2)]],
    texture2d<float> texBuf [[texture(3)]],
    texture2d<float> pontosBuf [[texture(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // 0. a tabela de permutação (514 pontos, valor até 256 em R e G)
    if (eng.acPass == 0) {
        int v = permDoPasse(int(__nv_fragCoord.x));
        __nv_out = float4(float(v & 255) / 255.0, float(v >> 8) / 255.0, 0.0, 1.0);
        return __nv_out;
    }
    preparar();

    // 3. os pontos de controle: um fragmento por (ângulo, j), marchando do centro até a linha j·K
    if (eng.acPass == 3) {
        int2 f = int2(__nv_fragCoord.xy);
        prepararLook(); prepararMapa();
        int i = f.y * LADO_DOS_PONTOS + f.x, c = i / gNc, j = i % gNc + 1;
        if (c >= gNa || j >= gNc) { __nv_out = float4(0.0); return __nv_out; }
        int m = raio(anguloDaColuna(c), 0, accDoCentro(), j * gK, j * gK).x;
        __nv_out = float4(float(m >> 8) / 255.0, float(m & 255) / 255.0, 0.0, 1.0);
        return __nv_out;
    }
    int2 t = min(int2(floor(in.acScreenNorm * float2(gBuf))), gBuf - int2(1));
    int2 q = t - gInicio;
    bool fora = any(lessThan(q, int2(0))) || any(greaterThanEqual(q, int2(W, H)));
    int x = q.x, y = dePe ? H - 1 - q.y : q.y;

    // 1. a luz: o Luma da camada pré-multiplicada em 8 bits · 256
    if (eng.acPass == 1) {
        if (fora) { __nv_out = float4(0.0); return __nv_out; }
        int4 s = bytes4(inputImg.read(uint2(t), uint(0)));
        int3 pm = int3(div255(s.r * s.a), div255(s.g * s.a), div255(s.b * s.a));
        int L16 = ((pm.r * 299 + pm.g * 587 + pm.b * 114 + 500) / 1000) * 256;
        __nv_out = float4(float(L16 >> 8) / 255.0, float(L16 & 255) / 255.0, 0.0, 1.0);
        return __nv_out;
    }
    // 2. a textura: o float do ponto (y, x) da imagem do BCC, em bytes
    if (eng.acPass == 2) {
        if (fora || u.textureMode == 2) { __nv_out = float4(0.0); return __nv_out; }
        prepararTextura();
        uint b = as_type<uint>(texturaBcc(y, x));
        __nv_out = float4(uint4(b & 255u, (b >> 8) & 255u, (b >> 16) & 255u, b >> 24)) / 255.0;
        return __nv_out;
    }

    float4 src = inputImg.read(uint2(t), uint(0));
    if (fora) { __nv_out = src; return __nv_out; }
    // View (FUN_18069dd10): a textura em cinza, int(t·255), opaca
    if (u.textureMode == 1) {
        prepararTextura();
        float tv = pontoDaTextura(y, x);
        __nv_out = float4(float3(float(clamp(int(tv * 255.0), 0, 255)) / 255.0), 1.0);
        return __nv_out;
    }
    prepararLook(); prepararMapa();

    // 2. o raio e o ângulo do pixel, como na volta do mapa (FUN_180e1cde0)
    int na = gNa, nr = gNr;
    float passoAng = gPassoAng, comeco = gComeco;
    int dxp = x * 256 - int(Lx * 256.0), dyp = y * 256 - int(Ly * 256.0);
    int ax = dxp >> 4, ay = dyp >> 4;
    int ri = int(isqrtU(uint(ax * ax) + uint(ay * ay))) * 16;
    int ang = atan2Fixo(dyp, dxp) - int(comeco * 65536.0 + 0.5);
    if (ang < 0) ang += MEIA_VOLTA;
    int ai = min((ang << 6) / int(round(passoAng * 16384.0)), na * 256);
    int r0 = min(ri >> 8, nr - 1), r1 = (ri >> 8) < nr ? (ri >> 8) + 1 : nr - 1, fr = ri & 255;
    int c0 = min(ai >> 8, na - 1), c1 = (ai >> 8) < na - 1 ? c0 + 1 : 0, fa = ai & 255;

    int2 m0 = raioDaColuna(c0, r0, r1), m1 = raioDaColuna(c1, r0, r1);
    uint ufa = uint(fa), ufr = uint(fr);
    uint v = (((256u - ufa) * uint(m0.y) + uint(m1.y) * ufa) * ufr + ((256u - ufa) * uint(m0.x) + uint(m1.x) * ufa) * (256u - ufr)) >> 16;
    // a cintilação (Shimmer): uma modulação por ângulo que anda (aproximada)
    float vf = float(v);
    if (u.rayTexture == 1) {
        float angf = __nv_atan(float(dyp), float(dxp));
        float mm = perlin3(float3(angf * (2.0 + u.shimmerDetail * 0.4), 0.0, eng.acTime * 0.5)) * 2.0;
        vf *= max(0.0, 1.0 + u.shimmerIntensity / 100.0 * mm);
    }
    int I = int(max(u.intensity, 0.0) * 0.01 * 256.0);
    float u = min(floor(vf * float(I) / 8192.0), 1024.0);
    float g = (u >= 1024.0 ? 255.0 : floor(u / 4.0)) / 255.0;     // o alfa da luz (8 bits)
    float gc = u / 1024.0;                                         // a luz de 10 bits do Colorize

    // 3. cor e composição (a cor sai da luz antes do Light Opacity)
    // Light Matte: a luz em cinza e opaca (o Light Opacity num matte não foi medido: entra no cinza)
    float3 cor = (u.colorMode == 1) ? float3(min(g * clamp(u.lightOpacity, 0.0, 100.0), 1.0)) : colorir(gc);
    float gl = (u.colorMode == 1) ? 1.0 : min(g * clamp(u.lightOpacity, 0.0, 100.0), 1.0);
    float3 srcP = src.rgb * src.a * u.sourceOpacity;
    float srcA = src.a * u.sourceOpacity;
    float3 luzP = cor * gl;
    float3 outP; float outA;
    if (u.applyMode == 0) {            // Behind: a camada por cima da luz
        outP = srcP + luzP * (1.0 - srcA); outA = srcA + gl * (1.0 - srcA);
    } else if (u.applyMode == 1) {     // None: só a luz
        outP = luzP; outA = gl;
    } else if (u.applyMode == 2) {     // In Front (o padrão): a luz por cima da camada
        outP = luzP + srcP * (1.0 - gl); outA = gl + srcA * (1.0 - gl);
    } else {                         // do Lighten ao 50 50 Mix: o RGBMix (1º operando a luz, 2º a camada)
        int4 X = int4(bytes4(float4(cor, 1.0)).rgb, int(floor(gl * 255.0 + 0.5)));
        int4 Y = bytes4(float4(src.rgb, srcA));
        bool pegaB;
        int3 cm = modo(u.applyMode - 3, X.rgb, Y.rgb, pegaB);
        int4 M = pegaB ? Y : int4(cm, X.a);
        float3 rgb = float3(compor(M, X, Y)) / 255.0;
        outA = gl + srcA * (1.0 - gl);              // não medido numa camada com transparência
        outP = rgb * outA;
    }
    float4 orig = float4(src.rgb * src.a, src.a);
    float4 res = mix(float4(outP, outA), orig, clamp(u.mixOriginal, 0.0, 1.0));
    __nv_out = res.a > 1e-6 ? float4(res.rgb / res.a, res.a) : float4(0.0);
    return __nv_out;
}
