// ---------------------------------------------------------------------------
// Displacement Map (AE)
// origem : assets/effects/ae-displacement-map.xml
// id     : nova.effect.aedisplacementmap
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_displacement_mapParams {
    int useForHorizontal;
    float maxHorizontal;
    int useForVertical;
    float maxVertical;
    int mapBehavior;
    int wrapPixels;
    int expandOutput;
};

// --- funcoes auxiliares do efeito
// ============================================================ o float32 do AE (PF.dll)
// `um` vale 1, mas o compilador não sabe (vem de `eng.acIterationCount`, que é 1 neste efeito). (a·b)·um não se funde
// com a soma seguinte num fma: cada produto arredonda sozinho, como na SSE do AE.
float um;
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

/** a / b arredondado como no IEEE (b > 0): a divisão da GPU pode errar o último bit. */
float divisao(float a, float b) {
    if (a == 0.0) return 0.0;
    float s = a < 0.0 ? -1.0 : 1.0;
    a = abs(a);
    float q = a / b;
    float e = restoDaDivisao(a, b, q);
    for (int i = 0; i < 4; i++) {
        float q2 = as_type<float>(as_type<uint>(q) + (e > 0.0 ? 1u : 0xFFFFFFFFu));
        float e2 = restoDaDivisao(a, b, q2);
        if (abs(e2) < abs(e)) { q = q2; e = e2; } else break;
    }
    return s * q;
}

/** O valor do controle em 16.16, como o AE o entrega ao plugin (arredondado). Chega em float (13,7 vira
 *  13,69999981): volta ao decimal (até 4 casas) antes do 16.16. */
int fixo(float v) {
    float m = abs(v);
    float i = floor(m);
    float f = m - i;
    float l = floor(f * 10000.0 + 0.5);
    int r;
    if (abs(f * 10000.0 - l) < 0.002 && i < 32768.0) {
        int li = int(l);
        r = int(i) * 65536 + (2 * li * 4096 + 625) / 1250;
    } else {
        r = int(floor(m * 65536.0 + 0.5));
    }
    return v < 0.0 ? -r : r;
}

// ============================================================ a camada e o mapa
int W, H;                 // a camada do AE (px), dentro do buffer a partir de `inicio`
int2 inicio;
bool dePe;
bool mapaProprio;         // sem camada escolhida: o mapa é a própria camada (o padrão do AE)
int4 janela;             // o pedaço do mapa que chega ao efeito: [x0, x1) × [y0, y1), em px do mapa

/** Um pixel da camada (RGBA 0..255, cor reta) na orientação da IMAGEM (a linha 0 é o topo); fora, transparente. */
int4 daCamada(int x, int y) {
    if (x < 0 || y < 0 || x >= W || y >= H) return int4(0);
    int2 b = inicio + int2(x, dePe ? H - 1 - y : y);
    return int4(inputImg.read(uint2(b), uint(0)) * 255.0 + 0.5);
}

int4 doMapa(int x, int y) {
    if (x < janela.x || y < janela.y || x >= janela.z || y >= janela.w) return int4(0);
    if (mapaProprio) return daCamada(x, y);
    // o mapa de outra camada: a cena no tamanho do buffer, na mesma grade e orientação da entrada
    int2 tm = int2(int(mapImg.get_width()), int(mapImg.get_height()));
    if (x < 0 || y < 0 || x >= tm.x || y >= tm.y) return int4(0);
    return int4(mapImg.read(uint2(int2(x, dePe ? tm.y - 1 - y : y)), uint(0)) * 255.0 + 0.5);
}

int4 pixel(bool doMapa_, int x, int y) { return doMapa_ ? doMapa(x, y) : daCamada(x, y); }

/** O índice inteiro de uma posição 16.16 como o AE: (short)(X >> 16). */
int indice(int X) { return int(uint(X >> 16) << 16) >> 16; }

/**
 * O subpixel_sample de 8 bits do AE (PF_SubpixelSample_Straight, PF.dll), na ordem da SSE dele. Sem fração: o pixel.
 * Os quatro iguais: o pixel. Alfas iguais: cada canal (p3·w3 + p2·w2) + (p1·w1 + p0·w0) + 0,5. Senão: a cor pesada
 * pelo alfa, vezes 1/S, + 0,5; o alfa S + 0,5. Fora da imagem conta como zero.
 */
int4 amostraDoAe(bool doMapa_, int X, int Y) {
    int ix = indice(X), iy = indice(Y);
    int fx = X & 0xFFFF, fy = Y & 0xFFFF;
    int4 p0 = pixel(doMapa_, ix, iy);
    if (fx == 0 && fy == 0) return p0;
    int4 p1 = pixel(doMapa_, ix + 1, iy);
    int4 p2 = pixel(doMapa_, ix, iy + 1);
    int4 p3 = pixel(doMapa_, ix + 1, iy + 1);
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

/** A volta inteira (o resultado em [0, n)), sem o % do GLSL ES com negativo. */
int volta(int v, int n) {
    if (v < 0) v += n * ((n - 1 - v) / n);
    return v - n * (v / n);
}

/**
 * O bilinear do PRÓPRIO plugin, o do Wrap Pixels Around (Displacement.aex, 0x180002400): os índices dão a volta na
 * camada; pesos 16.16 cortados (o 00 é o resto); alfa = (Σ a·w + 0x8000) >> 16; cor = (Σ c·a·w + Σ a·w / 2) / Σ a·w.
 */
int4 amostraComVolta(int X, int Y) {
    int ix = volta(indice(X), W), iy = volta(indice(Y), H);
    int ix1 = ix + 1 == W ? 0 : ix + 1;
    int iy1 = iy + 1 == H ? 0 : iy + 1;
    int4 p0 = daCamada(ix, iy);
    uint fx = uint(X & 0xFFFF), fy = uint(Y & 0xFFFF);
    if (fx == 0u && fy == 0u) return p0;
    int4 p1 = daCamada(ix1, iy), p2 = daCamada(ix, iy1), p3 = daCamada(ix1, iy1);
    if (p0 == p1 && p1 == p2 && p2 == p3) return p0;
    uint w3 = (fx * fy) >> 16;
    uint w1 = ((65536u - fy) * fx) >> 16;
    uint w2 = ((65536u - fx) * fy) >> 16;
    uint w0 = 65536u - w2 - w1 - w3;
    uint a0 = uint(p0.a) * w0, a1 = uint(p1.a) * w1, a2 = uint(p2.a) * w2, a3 = uint(p3.a) * w3;
    uint S = a0 + a1 + a2 + a3;
    int alfa = int((S + 0x8000u) >> 16);
    if (alfa == 0) return int4(0);
    uint3 n = uint3(p0.rgb) * a0 + uint3(p1.rgb) * a1 + uint3(p2.rgb) * a2 + uint3(p3.rgb) * a3;
    uint3 c = (n + S / 2u) / S;
    return int4(int3(c), alfa);
}

// ============================================================ o valor do mapa

int div255(int v) { int t = v + 128; return ((t >> 8) + t) >> 8; }

/** A cor do mapa puxada para 128 pelo alfa (com alfa < 255), como o plugin. */
int4 para128(int4 p) {
    if (p.a == 255) return p;
    int4 q = p;
    for (int i = 0; i < 3; i++) {
        int c = p[i];
        q[i] = c >= 128 ? 128 + div255((c - 128) * p.a) : c + div255((255 - p.a) * (128 - c));
    }
    return q;
}

/** O Hue do AE (PF_Hue_Straight, PF.dll) em float32, passo a passo, ainda sem arredondar; −1 no cinza (dá 0). */
float matiz(int3 c) {
    float k = as_type<float>(0x3B808081u);            // (float)(1/255)
    float R = mul(float(c.r), k), G = mul(float(c.g), k), B = mul(float(c.b), k);
    float mx, mn;
    if (G > R) { mn = R; mx = G; } else { mx = R; mn = G; }
    if (B > mx) mx = B; else mn = min(B, mn);
    if (mx == mn) return -1.0;
    float d = fixa(mx - mn);
    float h;
    if (R == mx) h = divisao(fixa(G - B), d);
    else if (G == mx) h = fixa(divisao(fixa(B - R), d) + 2.0);
    else h = fixa(divisao(fixa(R - G), d) + 4.0);
    h = mul(h, 60.0);
    if (h < 0.0) h = fixa(h + 360.0);
    return divisao(mul(h, 255.0), 360.0);
}

/** O M_RoundDouble do U.dll do AE para x ≥ 0: trunc(x + 0,5) (sem somar em float, que arredondaria antes). Fica
 *  numa função à parte do matiz(): juntas, o compilador da AMD errou o resultado (conferido no PC). */
int arredonda(float x) {
    int i = int(x);
    if (x - float(i) >= 0.5) i++;
    return i;
}

/** O valor (0..255) que o canal escolhido dá; o Half é 127 no horizontal e 128 no vertical (é o plugin). */
int valorDoCanal(int4 q, int canal, bool horizontal) {
    int mx = max(max(q.r, q.g), q.b), mn = min(min(q.r, q.g), q.b);
    if (canal == 0) return q.r;
    if (canal == 1) return q.g;
    if (canal == 2) return q.b;
    if (canal == 3) return q.a;
    if (canal == 4) return (30 * q.r + 59 * q.g + 11 * q.b) / 100;
    if (canal == 5) { float h = matiz(q.rgb); return h < 0.0 ? 0 : arredonda(h); }
    if (canal == 6) return (mx + mn) / 2;
    if (canal == 7) { int s = mx + mn; return ((mx - mn) * (s <= 255 ? s : 510 - s)) / 255; }
    if (canal == 8) return 255;
    if (canal == 9) return horizontal ? 127 : 128;
    return 0;
}

/** O máximo de 8 bpc: (f + (f < 0 ? 127 : 0)) >> 7. */
int corte128(int f) { return f < 0 ? (f + 127) >> 7 : f >> 7; }

/** trunc(a·b / 65536) para o zero, com o produto em 64 bits (o sinal à parte; o resultado cabe em 32 bits). */
int mulDiv16(int a, int b) {
    bool neg = (a < 0) != (b < 0);
    uint x = uint(abs(a)), y = uint(abs(b));
    uint xl = x & 0xFFFFu, xh = x >> 16, yl = y & 0xFFFFu, yh = y >> 16;
    // a·b = hh·2³² + (lh + hl)·2¹⁶ + ll  ⇒  ⌊a·b / 2¹⁶⌋ = hh·2¹⁶ + lh + hl + ⌊ll / 2¹⁶⌋
    uint r = (xh * yh) * 65536u + xl * yh + xh * yl + ((xl * yl) >> 16);
    return neg ? -int(r) : int(r);
}

/** ⌊n / d⌋ com d > 0 (o / do GLSL ES com negativo é indefinido). */
int piso(int n, int d) { return n >= 0 ? n / d : -((-n + d - 1) / d); }
int teto(int n, int d) { return -piso(-n, d); }

fragment float4 fx_ae_displacement_map(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_displacement_mapParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> mapImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    um = float(min(eng.acIterationCount, 1));
    int2 buf = int2(eng.acResolution + 0.5);
    int2 aqui = int2(floor(in.acScreenNorm * eng.acResolution));
    // A camada do AE dentro do buffer (a mídia encaixada; texto, forma e sólido: a composição inteira): o efeito do AE
    // roda no tamanho DELA.
    int2 tam = clamp(int2(floor(eng.acCamada * float2(buf) + 0.5)), int2(1), buf);
    inicio = (buf - tam) / 2;
    W = tam.x; H = tam.y;
    // A conta é na orientação da IMAGEM (a linha 0 é o topo, como no plugin). Numa cena guardada de pé (camada de
    // ajuste, grupo solto) a linha 0 do buffer é a BASE.
    dePe = eng.acEntradaDePe == 1;
    int2 local = aqui - inicio;
    int x = local.x, y = dePe ? H - 1 - local.y : local.y;

    // o máximo em 16.16 (na prévia reduzida, × a escala e cortado, como o AE em resolução reduzida)
    float ds = eng.acEscalaDePixel > 0.0 ? eng.acEscalaDePixel : 1.0;
    int fh = fixo(u.maxHorizontal), fv = fixo(u.maxVertical);
    if (abs(ds - 1.0) > 1.0e-6) { fh = int(float(fh) * ds); fv = int(float(fv) * ds); }
    int eh = u.expandOutput ? abs(fh) >> 16 : 0;
    int ev = u.expandOutput ? abs(fv) >> 16 : 0;
    bool naCamada = x >= 0 && y >= 0 && x < W && y < H;
    if (x < -eh || y < -ev || x >= W + eh || y >= H + ev) {
        __nv_out = inputImg.read(uint2(aqui), uint(0));     // fora da saída do efeito: no AE não há camada aqui
        return __nv_out;
    }
    // Nenhum eixo lê o mapa (os dois em Full/Half/Off): o plugin nem pede o mapa e COPIA a camada.
    if (u.useForHorizontal >= 8 && u.useForVertical >= 8) {
        __nv_out = naCamada ? inputImg.read(uint2(aqui), uint(0)) : float4(0.0);
        return __nv_out;
    }

    mapaProprio = int2(int(mapImg.get_width()), int(mapImg.get_height())).x <= 1;
    int mapW = W, mapH = H;
    if (!mapaProprio) { int2 tm = int2(int(mapImg.get_width()), int(mapImg.get_height())); mapW = tm.x; mapH = tm.y; }
    int X16 = x * 65536, Y16 = y * 65536;
    int mx, my;
    if (u.mapBehavior == 2) {
        // Tile Map: escala 1, dá a volta no tamanho do mapa (o plugin subtrai/soma o tamanho até cair dentro)
        mx = volta(X16, mapW * 65536);
        my = volta(Y16, mapH * 65536);
        janela = int4(-eh, -ev, W + eh, H + ev);
    } else if (u.mapBehavior == 0) {
        // Center Map: rnd16(W/2 − mapW/2) = (W − mapW)·32768, exato; o pré-render pede ao mapa a janela da saída
        // deslocada por trunc(⌊mapW/2⌋ − W/2)
        mx = X16 - (W - mapW) * 32768;
        my = Y16 - (H - mapH) * 32768;
        int ox = int(float(2 * (mapW / 2) - W) * 0.5), oy = int(float(2 * (mapH / 2) - H) * 0.5);      // trunc para o zero
        janela = int4(ox - eh, oy - ev, ox + W + eh, oy + H + ev);
    } else {
        // Stretch Map to Fit: rnd16(mapW / W) (meio para cima: exato em inteiros); o deslocamento dá 0
        int sx16 = (mapW * 131072 + W) / (2 * W);
        int sy16 = (mapH * 131072 + H) / (2 * H);
        mx = mulDiv16(X16, sx16);
        my = mulDiv16(Y16, sy16);
        // o pré-render pede [⌊(l − W/2)·mapW/W + ⌊mapW/2⌋⌋, ⌈(r − W/2)·mapW/W + ⌊mapW/2⌋⌉)
        janela = int4(piso((-2 * eh - W) * mapW, 2 * W) + mapW / 2, piso((-2 * ev - H) * mapH, 2 * H) + mapH / 2,
                       teto((2 * (W + eh) - W) * mapW, 2 * W) + mapW / 2, teto((2 * (H + ev) - H) * mapH, 2 * H) + mapH / 2);
    }
    int4 q = para128(amostraDoAe(true, mx, my));
    int dh = (valorDoCanal(q, u.useForHorizontal, true) - 128) * corte128(fh);
    int dv = (valorDoCanal(q, u.useForVertical, false) - 128) * corte128(fv);
    int4 c = u.wrapPixels ? amostraComVolta(X16 + dh, Y16 + dv) : amostraDoAe(false, X16 + dh, Y16 + dv);
    __nv_out = float4(c) / 255.0;
    return __nv_out;
}
