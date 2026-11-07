// ---------------------------------------------------------------------------
// Radial Blur (AE)
// origem : assets/effects/ae-radial-blur.xml
// id     : nova.effect.aeradialblur
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_radial_blurParams {
    float amount;
    float2 center;
    int tipo;
    int qualidade;
    float seed;
};

// --- funcoes auxiliares do efeito
const int BLOCO = 32;
const int MEIO = 128;    // o nível do meio do estado (passe 1); o de cima (passe 0) é 512 ou 1024

/** O gerador do plugin: 48271 · (x mod 44488) + 3399 · (x div 44488), em 32 bits; zero vira 2³¹ − 1. */
uint sorteio(uint x) {
    uint r = (x % 44488u) * 48271u + (x / 44488u) * 3399u;
    return r == 0u ? 0x7fffffffu : r;
}

/**
 * O centro do plugin em ponto fixo 16.16: (c / n, truncado) · (n − 2). Aqui `c` já vem dividido
 * por n (o ponto do app é de 0 a 1).
 */
int centroFixo(float c, int n) {
    return (c < 0.0 ? -1 : 1) * int(abs(c) * 65536.0) * (n - 2);
}

/**
 * O preparo do plugin: 32 sorteios a partir da semente, cada um um tremor de 0 a 15 para o raio. Devolve o
 * estado depois dos 32 e põe em [tremor] o do sorteio [qual].
 */
uint preparo(uint semente, int qual, out int tremor) {
    tremor = 0;
    uint st = semente;
    for (int k = 0; k < 32; k++) {
        st = sorteio(st);
        if (k == qual) tremor = int((st >> 18) & 15u);
    }
    return st;
}

/** O estado do gerador antes do primeiro pixel da linha `y`. */
uint estadoDaLinha(int y, int W, uint depoisDoPreparo) {
    uint a = sorteio(uint(W * y));
    uint b = sorteio((a >> 7) & 0x7fffu);
    return ((b >> 7) & 0x7fffu) * depoisDoPreparo;
}

/** O estado guardado em (b, y): 24 bits no texel b, 8 no b + 1. */
uint lerEstado(sampler2D buf, int b, int y) {
    int3 lo = int3(buf.read(uint2(int2(b, y)), uint(0)).rgb * 255.0 + 0.5);
    int hi = int(buf.read(uint2(int2(b + 1, y)), uint(0)).r * 255.0 + 0.5);
    return uint(lo.r) | (uint(lo.g) << 8) | (uint(lo.b) << 16) | (uint(hi) << 24);
}

/** O texel b (os 24 bits de baixo) ou o b + 1 (os 8 de cima) do estado [e]. */
float4 gravarEstado(uint e, bool primeiro) {
    return primeiro
        ? float4(float(e & 255u), float((e >> 8) & 255u), float((e >> 16) & 255u), 255.0) / 255.0
        : float4(float(e >> 24), 0.0, 0.0, 255.0) / 255.0;
}

/** Um texel da fonte em bytes, com a cor PRÉ-MULTIPLICADA (é assim que o AE entrega ao efeito). */
int4 ler(int2 p) {
    int4 c = int4(inputImg.read(uint2(p), uint(0)) * 255.0 + 0.5);
    return int4((c.rgb * c.a + 127) / 255, c.a);
}

fragment float4 fx_ae_radial_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_radial_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> estado [[texture(1)]],
    texture2d<float> estadoLongo [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int W = T.x, H = T.y;
    int2 px = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    uint semente = uint(clamp(u.seed, 0.0, 10000.0) + 0.5);
    int aF = int(floor(u.amount * 65536.0 + 0.5));
    int aI = aF >> 16;
    int tremor;

    if (eng.acPass <= 2) {
        // O estado antes do pixel `b` de cada linha, em três níveis: o passe 0 desde o começo da linha (b múltiplo de
        // 512, ou 1024 numa camada larga: a melhor divisão medida), o 1 desde o do 0 (b múltiplo de 128) e o 2 desde
        // o do 1 (b múltiplo de 32). Com a parte inteira do Amount em 0 ninguém o lê (ver abaixo).
        int topo = W > 2048 ? 1024 : 512;
        int lado = eng.acPass == 0 ? topo : eng.acPass == 1 ? MEIO : BLOCO;
        int b = (px.x / lado) * lado;
        if (px.x > b + 1 || aI == 0) { __nv_out = float4(0.0, 0.0, 0.0, 1.0); return __nv_out; }
        int acima = eng.acPass == 1 ? topo : MEIO;
        int de = (b / acima) * acima;
        uint e;
        if (eng.acPass > 0 && de + 1 < W) {
            e = eng.acPass == 1 ? lerEstado(estado, de, px.y) : lerEstado(estadoLongo, de, px.y);
        } else {
            e = estadoDaLinha(px.y, W, preparo(semente, -1, tremor));
            de = 0;
        }
        for (int i = de; i < b; i++) e = sorteio(e);
        __nv_out = gravarEstado(e, px.x == b);
        return __nv_out;
    }

    // ---- Amount inteiro 0: o giro (Spin) e o zoom (Zoom) valem 0 em toda a tabela, então as n amostras caem no
    // próprio pixel (preso à leitura que para em n − 2), de fração zero: a soma de n leituras iguais / n é ela. ----
    if (aI == 0) {
        int4 r = ler(clamp(px, int2(0), max(T - 2, int2(0))));
        __nv_out = r.a > 0 ? float4(min(float3(r.rgb) / float(r.a), 1.0), float(r.a) / 255.0) : float4(0.0);
        return __nv_out;
    }

    // O preparo do plugin, com o tremor deste pixel.
    uint depoisDoPreparo = preparo(semente, (int(semente) + W * px.y + px.x + 1) & 31, tremor);

    // ---- a fase deste pixel: do bloco gravado, mais um passo por pixel ----
    int b = (px.x / BLOCO) * BLOCO;
    if (b + 1 >= W && b >= BLOCO) b -= BLOCO;
    uint e;
    if (b + 1 < W) {
        e = lerEstado(estado, b, px.y);
    } else {
        e = estadoDaLinha(px.y, W, depoisDoPreparo);
        b = 0;
    }
    for (int i = b; i <= px.x; i++) e = sorteio(e);
    int fase = int((e >> 7) & 0x3ffu);

    // ---- o centro e o raio ----
    int cxF = centroFixo(u.center.x, W), cyF = centroFixo(u.center.y, H);
    int cxi = cxF >> 16, cyi = cyF >> 16;
    float dx = float((cxF - (px.x << 16)) >> 16), dy = float((cyF - (px.y << 16)) >> 16);
    int limite = int(sqrt(float(W * W + H * H)) * 4.0) - 2;
    float raio = length(float2(float((cxF >> 14) - 4 * px.x), float((cyF >> 14) - 4 * px.y)));
    int idx = min(int(raio + 0.5) + tremor, limite);

    // ---- quantas amostras ----
    // Na prévia em movimento (`eng.acRascunho`, play/arraste), o Low do próprio plugin: até 16 amostras em vez de 255.
    bool alta = u.qualidade == 1 && eng.acRascunho == 0;
    int n;
    if (u.tipo == 0) {
        n = (idx * aI) >> 8;
    } else {
        // |FixMul(idx, 1 + m) − FixMul(idx, 1 − m)|, com m = (Amount / 200) / 2 em ponto fixo
        uint p = uint(idx) * uint((aF / 200) >> 1);
        int d = int(p >> 16) + int((p + 65535u) >> 16);
        n = alta ? d >> 2 : d >> 3;
    }
    n = clamp(n, 4, alta ? 255 : 16);
    int passo = 1024 / n;

    // ---- a soma ----
    int4 soma = int4(0);
    int xMax = (W - 2) << 16, yMax = (H - 2) << 16;
    for (int k = 0; k < n; k++) {
        int t = (fase + k * passo) & 1023;
        float X, Y;
        if (u.tipo == 0) {
            float ang = float(aI * (t - 512)) / -58368.0;
            float sn = sin(ang), cs = cos(ang);
            X = (float(cxi) - (cs * dx - sn * dy)) * 65536.0;
            Y = (float(cyi) - (cs * dy + sn * dx)) * 65536.0;
        } else {
            float z = float(aI * (t - 512)) / 204800.0 + 1.0;
            X = (float(cxi) - z * dx) * 65536.0;
            Y = (float(cyi) - z * dy) * 65536.0;
        }
        int xf = clamp(int(X), 0, max(xMax, 0)), yf = clamp(int(Y), 0, max(yMax, 0));
        int2 i = int2(xf >> 16, yf >> 16);
        int fx = 32 - ((xf & 0xffff) >> 11), fy = 32 - ((yf & 0xffff) >> 11);
        int4 p00 = ler(i), p01 = ler(i + int2(1, 0)), p10 = ler(i + int2(0, 1)), p11 = ler(i + int2(1, 1));
        int4 topo = ((p00 * fx + 16) >> 5) - ((p01 * fx + 16) >> 5) + p01;
        int4 base = ((p10 * fx + 16) >> 5) - ((p11 * fx + 16) >> 5) + p11;
        soma += ((topo * fy + 16) >> 5) - ((base * fy + 16) >> 5) + base;
    }
    int4 r = min(soma / n, int4(255));
    // de volta à cor reta
    __nv_out = r.a > 0 ? float4(min(float3(r.rgb) / float(r.a), 1.0), float(r.a) / 255.0) : float4(0.0);
    return __nv_out;
}
