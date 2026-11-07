// ---------------------------------------------------------------------------
// S_DistortChroma
// origem : assets/effects/sapphire-distort-chroma.xml
// id     : nova.effect.sdistortchroma
// passes : 18
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_distort_chromaParams {
    float amount;
    float blurLens;
    float rotateWarpDir;
    float warpRed;
    float warpBlue;
    float steps;
    float4 color1;
    float4 color2;
    float4 color3;
    int whiteBalance;
    float amountRelX;
    float amountRelY;
    int wrapX;
    int wrapY;
    int useFilter;
};

// --- funcoes auxiliares do efeito
const int BLOCO = 16;                 // as somas prontas são de 16 pontos seguidos
const int NIVEIS = 4;
const int VOLTAS_MAX = 760;           // teto do laço de uma caixa (raio até 333 perto da borda)

/** Um número de 0 a 1 em quatro bytes (o gradiente do brilho é ampliado milhares de vezes: 8 bits não bastam). */
static float4 empacotar(float v) {
    v = clamp(v, 0.0, 0.99999994);
    float4 e = fract(v * float4(1.0, 255.0, 65025.0, 16581375.0));
    e -= e.yzww * float4(1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0, 0.0);
    return e;
}

static float desempacotar(float4 c) { return dot(c, float4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0)); }

static int espelhar(int i, int n) {
    // Dentro do quadro o espelho é o próprio índice: sem a divisão inteira, que em todo tap custava caro (0.569.0)
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static float larguraDoBorrao() { return max(u.blurLens, 0.0) * eng.acEscalaDePixel; }

/** Os números de uma das três caixas de um eixo (`qual` = 0, 1, 2) para a largura `w`: raio, peso de dentro e da ponta.
 *  O desfoque do Sapphire, medido no S_Glow: largura inteira W -> raios que somam W; de W para W + 1 só a caixa
 *  (W mod 3) cresce, e a largura quebrada mistura as duas. */
static float3 numerosDaCaixa(int qual, float w) {
    float a = floor(w), f = w - a;
    float r = floor((a + float(2 - qual)) / 3.0 + 1e-4);
    if (abs(a - 3.0 * floor(a / 3.0 + 1e-4) - float(qual)) > 0.5) f = 0.0;
    return float3(r, (1.0 - f) / (2.0 * r + 1.0) + f / (2.0 * r + 3.0), f / (2.0 * r + 3.0));
}

/** O brilho da lente num ponto da fonte: (5 R + 8 G + 3 B) / 16 da cor pré-multiplicada (medido). */
static float brilhoDaFonte(int2 p, int2 T) {
    float4 c = inputImg.read(uint2(int2(espelhar(p.x, T.x), espelhar(p.y, T.y))), uint(0));
    return dot(c.rgb * c.a, float3(0.3125, 0.5, 0.1875));
}

/** O brilho num dos dois buffers do vai e vem, com a borda espelhada. */
static float lerBrilho(bool doA, int2 p, int2 T) {
    p = int2(espelhar(p.x, T.x), espelhar(p.y, T.y));
    if (doA) return desempacotar(la.read(uint2(p), uint(0)));
    return desempacotar(lb.read(uint2(p), uint(0)));
}

/** O brilho borrado num ponto qualquer (pontos do buffer), bilinear; o resultado das seis caixas fica em `la`. */
static float brilhoBorrado(float2 pos, int2 T) {
    float2 c = pos - 0.5;
    int2 b = int2(floor(c));
    float2 t = c - float2(b);
    return mix(mix(lerBrilho(true, b, T), lerBrilho(true, b + int2(1, 0), T), t.x),
               mix(lerBrilho(true, b + int2(0, 1), T), lerBrilho(true, b + int2(1, 1), T), t.x), t.y);
}

/** O deslocamento em pontos do buffer (medido): 0,4 · L · (Blur Lens + L / 80) · Amount · gradiente, depois Rel e giro. */
static float2 campo(float2 pos, int2 T) {
    float L = float(T.x);
    float k = 0.4 * L * (larguraDoBorrao() + L / 80.0) * u.amount;
    float2 g = 0.5 * float2(brilhoBorrado(pos + float2(1.0, 0.0), T) - brilhoBorrado(pos - float2(1.0, 0.0), T),
                        brilhoBorrado(pos + float2(0.0, 1.0), T) - brilhoBorrado(pos - float2(0.0, 1.0), T));
    float2 d = g * k * float2(u.amountRelX, u.amountRelY);
    float a = radians(u.rotateWarpDir);
    return float2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a));
}

static int2 tamanhoDoNivel(int n) {
    if (n == 0) return int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (n == 1) return int2(int(m1.get_width()), int(m1.get_height()));
    if (n == 2) return int2(int(m2.get_width()), int(m2.get_height()));
    if (n == 3) return int2(int(m3.get_width()), int(m3.get_height()));
    return int2(int(m4.get_width()), int(m4.get_height()));
}

/** Um ponto do nível `n` da pirâmide da fonte, pré-multiplicado, com o Wrap. */
static float4 pontoDoNivel(int n, int2 p, int2 Tn) {
    bool fora = false;
    if (u.wrapX == 1) { p.x = p.x - (p.x / Tn.x) * Tn.x; if (p.x < 0) p.x += Tn.x; }
    else if (u.wrapX == 2) p.x = espelhar(p.x, Tn.x);
    else if (p.x < 0 || p.x >= Tn.x) fora = true;
    if (u.wrapY == 1) { p.y = p.y - (p.y / Tn.y) * Tn.y; if (p.y < 0) p.y += Tn.y; }
    else if (u.wrapY == 2) p.y = espelhar(p.y, Tn.y);
    else if (p.y < 0 || p.y >= Tn.y) fora = true;
    if (fora) return float4(0.0);
    if (n == 0) { float4 c = inputImg.read(uint2(p), uint(0)); return float4(c.rgb * c.a, c.a); }
    if (n == 1) return m1.read(uint2(p), uint(0));
    if (n == 2) return m2.read(uint2(p), uint(0));
    if (n == 3) return m3.read(uint2(p), uint(0));
    return m4.read(uint2(p), uint(0));
}

/** A fonte lida em `pos` (pontos do buffer cheio) no nível `n`, bilinear. */
static float4 lerNivel(int n, float2 pos, int2 T) {
    int2 Tn = tamanhoDoNivel(n);
    float2 c = pos * float2(Tn) / float2(T) - 0.5;
    int2 b = int2(floor(c));
    float2 t = c - float2(b);
    return mix(mix(pontoDoNivel(n, b, Tn), pontoDoNivel(n, b + int2(1, 0), Tn), t.x),
               mix(pontoDoNivel(n, b + int2(0, 1), Tn), pontoDoNivel(n, b + int2(1, 1), Tn), t.x), t.y);
}

static float4 lerFonte(float2 pos, float nivel, int2 T) {
    if (nivel <= 0.001) return lerNivel(0, pos, T);
    float n0 = min(floor(nivel), float(NIVEIS - 1));
    return mix(lerNivel(int(n0), pos, T), lerNivel(int(n0) + 1, pos, T), clamp(nivel - n0, 0.0, 1.0));
}

/** As três tendas do espectro em `s` (0 = ponta do Warp Blue, 1 = ponta do Warp Red): (Color1, Color2, Color3). */
static float3 tendas(float s) {
    float b = clamp(1.0 - 2.0 * s, 0.0, 1.0), r = clamp(2.0 * s - 1.0, 0.0, 1.0);
    float3 e = float3(r, 0.5 * (1.0 - b - r), b);          // medido: a do meio vale metade
    return sqrt(e / (e.x + e.y + e.z));
}

fragment float4 fx_sapphire_distort_chroma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_distort_chromaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> la [[texture(1)]],
    texture2d<float> lb [[texture(2)]],
    texture2d<float> ls [[texture(3)]],
    texture2d<float> m1 [[texture(4)]],
    texture2d<float> m2 [[texture(5)]],
    texture2d<float> m3 [[texture(6)]],
    texture2d<float> m4 [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));

    // ---- 0: o brilho da lente ----
    if (eng.acPass == 0) { __nv_out = empacotar(brilhoDaFonte(p, T)); return __nv_out; }

    // ---- 1..12: as seis caixas. A caixa i lê `la` (i par) ou `lb` (i ímpar) e escreve no outro. ----
    if (eng.acPass <= 12) {
        int i = (eng.acPass - 1) / 2;
        bool doA = (i & 1) == 0, vertical = i >= 3;
        float3 nc = numerosDaCaixa(vertical ? i - 3 : i, larguraDoBorrao());
        int r = int(nc.x);
        int2 passo = vertical ? int2(0, 1) : int2(1, 0);
        int n = vertical ? T.y : T.x, x = vertical ? p.y : p.x;

        if (((eng.acPass - 1) & 1) == 0) {
            // a soma (guardada como média) dos BLOCO pontos a partir deste; só serve para caixa larga
            if (r < BLOCO) { __nv_out = float4(0.0); return __nv_out; }
            float s = 0.0;
            for (int k = 0; k < BLOCO; k++) s += lerBrilho(doA, p + passo * k, T);
            __nv_out = empacotar(s / float(BLOCO));
            return __nv_out;
        }

        // a caixa: blocos prontos onde cabem inteiros (dentro da imagem e do miolo da caixa), pontas ponto a ponto
        float soma = 0.0;
        int k = x - r - 1, fim = x + r + 1;
        for (int volta = 0; volta < VOLTAS_MAX; volta++) {
            if (k > fim) break;
            if (r >= BLOCO && k >= x - r && k + BLOCO - 1 <= x + r && k >= 0 && k + BLOCO - 1 < n) {
                int2 q = vertical ? int2(p.x, k) : int2(k, p.y);
                soma += nc.y * float(BLOCO) * desempacotar(ls.read(uint2(q), uint(0)));
                k += BLOCO;
            } else {
                float peso = abs(k - x) <= r ? nc.y : nc.z;
                if (peso > 0.0) soma += peso * lerBrilho(doA, vertical ? int2(p.x, k) : int2(k, p.y), T);
                k += 1;
            }
        }
        __nv_out = empacotar(soma);
        return __nv_out;
    }

    // ---- 13..16: a pirâmide da fonte (pré-multiplicada), só com o Filter ----
    if (eng.acPass <= 16) {
        if (!u.useFilter) { __nv_out = float4(0.0); return __nv_out; }
        int n = eng.acPass - 13;                                            // lê o nível n, escreve o n + 1
        int2 Tc = tamanhoDoNivel(n);
        float2 razao = float2(Tc) / eng.acResolution;
        float2 de = floor(in.acScreenNorm * eng.acResolution) * razao, ate = de + razao;
        int2 b = int2(floor(de));
        float4 soma = float4(0.0);
        float area = 0.0;
        for (int j = 0; j < 4; j++) {
            float wy = min(float(b.y + j + 1), ate.y) - max(float(b.y + j), de.y);
            if (wy <= 0.0) continue;
            for (int i = 0; i < 4; i++) {
                float wx = min(float(b.x + i + 1), ate.x) - max(float(b.x + i), de.x);
                if (wx <= 0.0) continue;
                int2 q = clamp(b + int2(i, j), int2(0), Tc - 1);
                float4 c;
                if (n == 0) { c = inputImg.read(uint2(q), uint(0)); c.rgb *= c.a; }
                else if (n == 1) c = m1.read(uint2(q), uint(0));
                else if (n == 2) c = m2.read(uint2(q), uint(0));
                else c = m3.read(uint2(q), uint(0));
                soma += wx * wy * c; area += wx * wy;
            }
        }
        __nv_out = soma / max(area, 1e-6);
        return __nv_out;
    }

    // ---- 17: o campo, o espectro e a leitura ----
    float2 pos = float2(p) + 0.5;
    float2 d = campo(pos, T);

    // O Filter (aproximado): o quanto a leitura encolhe a imagem, pelo jacobiano do campo.
    float2 dx = float2(0.0), dy = float2(0.0);
    if (u.useFilter) {
        dx = 0.5 * (campo(pos + float2(1.0, 0.0), T) - campo(pos - float2(1.0, 0.0), T));
        dy = 0.5 * (campo(pos + float2(0.0, 1.0), T) - campo(pos - float2(0.0, 1.0), T));
    }

    int n = int(clamp(floor(u.steps + 0.5), 3.0, 48.0));
    // na prévia em movimento (`eng.acRascunho`, play/arraste), no máximo 12 amostras do espectro
    if (eng.acRascunho == 1) n = min(n, 12);
    // a soma de cada tenda ao longo das amostras (medido: cada uma é dividida pela soma dela)
    float3 somaDasTendas = float3(0.0);
    for (int k = 0; k < n; k++) somaDasTendas += tendas(float(k) / float(n - 1));

    float3 cor = float3(0.0), somaDaCor = float3(0.0);
    float alfa = 0.0;
    for (int k = 0; k < n; k++) {
        float s = float(k) / float(n - 1);
        float3 w = tendas(s) / somaDasTendas;
        float3 tom = w.x * u.color1.rgb + w.y * u.color2.rgb + w.z * u.color3.rgb;
        float t = mix(u.warpBlue, u.warpRed, s);
        float nivel = 0.0;
        if (u.useFilter) {
            float det = abs((1.0 + t * dx.x) * (1.0 + t * dy.y) - (t * dx.y) * (t * dy.x));
            nivel = clamp(0.5 * log2(max(det, 1e-6)), 0.0, float(NIVEIS));
        }
        float4 a = lerFonte(pos + d * t, nivel, T);
        cor += a.rgb * tom; somaDaCor += tom; alfa += a.a;
    }
    if (u.whiteBalance) cor /= max(somaDaCor, float3(1e-6));
    alfa /= float(n);
    cor = clamp(cor, 0.0, 1.0);
    __nv_out = alfa > 0.0 ? float4(min(cor / alfa, float3(1.0)), min(alfa, 1.0)) : float4(0.0);
    return __nv_out;
}
