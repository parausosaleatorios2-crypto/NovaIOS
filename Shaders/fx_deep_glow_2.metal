// ---------------------------------------------------------------------------
// Deep Glow 2 (iOS)
// origem : Resources/effects/deep-glow-2.xml (base: deep-glow-ae)
// id     : nova.effect.deepglow2
// passes : 24
// Escrito a mao a partir de fx_deep_glow_2.metal (passe final novo)
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct deep_glow_2Params {
    float radius;
    float exposure;
    float threshold;
    float thresholdSmooth;
    float sourceOpacity;
    int unmult;
    float4 tintColor;
    float tint;
    float glowSaturation;
    float chromatic;
    int blendMode;
    float rolloff;
    int dither;
};

// --- funcoes auxiliares do efeito
const int NIVEIS = 6;                 // medido: seis níveis, cada um com metade do alcance do anterior
const int DEGRAUS = 5;                // a pirâmide vai até 1/32
const float SIGMA = 0.24494897;       // do shader do plugin: sqrt(0,06) da meia largura do nível
const float GAMA = 2.2222222;
const int MEIA_MAX = 24;              // o desfoque soma até 49 pontos por passe

static float3 paraLuz(float3 g) { return pow(max(g, float3(0.0)), float3(GAMA)); }
static float3 paraGama(float3 l) { return pow(max(l, float3(0.0)), float3(1.0 / GAMA)); }

/**
 * A luz num buffer de 8 bits: o halo de um ponto pequeno vale 0,0001 ou menos, e 8 bits (mesmo com gama) não
 * guardam isso. Vai então como mantissa e expoente: o maior canal fica entre 0,5 e 1 (guardado com raiz, para
 * render mais) e o alfa leva a potência de dois — o erro é sempre uma fração do valor, claro ou escuro.
 */
static float4 codificar(float3 l) {
    l = max(l, float3(0.0));
    float m = max(l.r, max(l.g, l.b));
    if (m < 1e-9) return float4(0.0);
    float e = clamp(ceil(log2(m)), -30.0, 2.0);
    return float4(sqrt(min(l / exp2(e), float3(1.0))), (e + 32.0) / 255.0);
}

static float3 decodificar(float4 t) {
    if (t.a <= 0.0) return float3(0.0);
    return t.rgb * t.rgb * exp2(floor(t.a * 255.0 + 0.5) - 32.0);
}

/** A luz da fonte num pixel: pré-multiplicada, com o limiar do plugin (canal a canal), em linear, presa em 1. */
static float3 entrada(int2 p) {
    float4 t = inputImg.read(uint2(p), uint(0));
    float3 c = max(t.rgb * t.a, float3(0.0));
    float lim = u.threshold / 100.0;
    if (lim > 0.0) {
        float3 abaixo = (c / lim) * c * (u.thresholdSmooth / 100.0);
        c = mix(c, abaixo, float3(lessThan(c, float3(lim))));
    }
    return min(paraLuz(c), float3(1.0));
}

/** Espelha o índice na borda (medido: a borda do plugin é espelhada). */
static int espelhar(int i, int n) {
    // Dentro do quadro o espelho é o próprio índice: sem a divisão inteira, que em todo tap custava caro (0.569.0)
    if (i >= 0 && i < n) return i;
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

static int2 tamanhoDe(int d) {
    if (d == 0) return int2(int(inputImg.get_width()), int(inputImg.get_height()));
    if (d == 1) return int2(int(p1.get_width()), int(p1.get_height()));
    if (d == 2) return int2(int(p2.get_width()), int(p2.get_height()));
    if (d == 3) return int2(int(p3.get_width()), int(p3.get_height()));
    if (d == 4) return int2(int(p4.get_width()), int(p4.get_height()));
    return int2(int(p5.get_width()), int(p5.get_height()));
}

/** Um ponto do degrau `d` da pirâmide (0 = a própria entrada), em luz. */
static float3 degrau(int d, int2 p) {
    int2 T = tamanhoDe(d);
    p = int2(espelhar(p.x, T.x), espelhar(p.y, T.y));
    if (d == 0) return entrada(p);
    if (d == 1) return decodificar(p1.read(uint2(p), uint(0)));
    if (d == 2) return decodificar(p2.read(uint2(p), uint(0)));
    if (d == 3) return decodificar(p3.read(uint2(p), uint(0)));
    if (d == 4) return decodificar(p4.read(uint2(p), uint(0)));
    return decodificar(p5.read(uint2(p), uint(0)));
}

/** O tamanho do buffer do desfoque horizontal do degrau `d` (o mesmo do degrau). */
static int2 tamanhoDoH(int d) {
    if (d == 0) return int2(int(tf.get_width()), int(tf.get_height()));
    if (d == 1) return int2(int(h1.get_width()), int(h1.get_height()));
    if (d == 2) return int2(int(h2.get_width()), int(h2.get_height()));
    if (d == 3) return int2(int(h3.get_width()), int(h3.get_height()));
    if (d == 4) return int2(int(h4.get_width()), int(h4.get_height()));
    return int2(int(h5.get_width()), int(h5.get_height()));
}

static float3 horizontal(int d, int2 p) {
    // No passe vertical o alvo é o próprio degrau (o motor não o entrega como textura): o tamanho vem do buffer do horizontal.
    int2 T = tamanhoDoH(d);
    p = int2(espelhar(p.x, T.x), espelhar(p.y, T.y));
    if (d == 0) return decodificar(tf.read(uint2(p), uint(0)));
    if (d == 1) return decodificar(h1.read(uint2(p), uint(0)));
    if (d == 2) return decodificar(h2.read(uint2(p), uint(0)));
    if (d == 3) return decodificar(h3.read(uint2(p), uint(0)));
    if (d == 4) return decodificar(h4.read(uint2(p), uint(0)));
    return decodificar(h5.read(uint2(p), uint(0)));
}

/** O degrau `d` lido num ponto qualquer da tela (uv), com interpolação bilinear feita em luz. */
static float3 degrauEm(int d, float2 uv) {
    float2 c = uv * float2(tamanhoDe(d)) - 0.5;
    int2 b = int2(floor(c));
    float2 f = c - float2(b);
    return mix(mix(degrau(d, b), degrau(d, b + int2(1, 0)), f.x), mix(degrau(d, b + int2(0, 1)), degrau(d, b + int2(1, 1)), f.x), f.y);
}

/** O sigma (em pixels do buffer cheio) do nível `k`: 0 é o mais largo. */
static float sigmaDoNivel(int k) {
    return SIGMA * u.radius * eng.acEscalaDePixel * 0.5 / exp2(float(k));
}

/** Em que degrau o nível mais largo é desfocado: aquele em que o sigma dele fica entre 1,5 e 3 pontos. */
static int degrauDoMaior() {
    float s = sigmaDoNivel(0);
    if (s < 3.0) return 0;
    return clamp(int(floor(log2(s / 1.5))), 0, DEGRAUS);
}

/** Um passe do desfoque gaussiano no degrau `d`, com `sigma` em pontos desse degrau. */
static float3 desfocar(int d, int2 p, float sigma, bool vertical) {
    int meia = min(int(ceil(sigma * 3.0)), MEIA_MAX);
    // Centro (i = 0, w = 1.0).
    float3 soma = vertical ? horizontal(d, p) : degrau(d, p);
    float pesos = 1.0;
    // Pesos incrementais: um único exp() por passada em vez de um por amostra.
    // w_i = w_{i-1} · rk, com rk crescendo por r²: i=1→r, i=2→r⁴, i=3→r⁹, ...
    float r  = exp(-0.5 / (sigma * sigma));
    float r2 = r * r;
    float rk = r;   // r^(2i-1) para i=1
    float w  = 1.0;
    for (int i = 1; i <= MEIA_MAX; i++) {
        if (i > meia) break;
        w  *= rk;
        rk *= r2;
        int2 qP = p + (vertical ? int2(0,  i) : int2( i, 0));
        int2 qM = p + (vertical ? int2(0, -i) : int2(-i, 0));
        soma  += w * ((vertical ? horizontal(d, qP) : degrau(d, qP))
                    + (vertical ? horizontal(d, qM) : degrau(d, qM)));
        pesos += 2.0 * w;
    }
    return soma / pesos;
}

/**
 * O sigma, em pontos do degrau `d`, que falta aplicar para o nível `k`: a própria pirâmide já
 * desfocou um pouco (cada descida de 2 x 2 soma 1/12 de ponto² de variância).
 */
static float sigmaNoDegrau(int k, int d, int2 T) {
    float ponto = float(int2(int(inputImg.get_width()), int(inputImg.get_height())).x) / float(T.x);
    float s = sigmaDoNivel(k) / ponto;
    float jaFeito = d == 0 ? 0.0 : (1.0 - exp2(-2.0 * float(d))) / 12.0;
    return sqrt(max(s * s - jaFeito, 0.01));
}

fragment float4 fx_deep_glow_2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant deep_glow_2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> p1 [[texture(1)]],
    texture2d<float> p2 [[texture(2)]],
    texture2d<float> p3 [[texture(3)]],
    texture2d<float> p4 [[texture(4)]],
    texture2d<float> p5 [[texture(5)]],
    texture2d<float> h1 [[texture(6)]],
    texture2d<float> h2 [[texture(7)]],
    texture2d<float> h3 [[texture(8)]],
    texture2d<float> h4 [[texture(9)]],
    texture2d<float> h5 [[texture(10)]],
    texture2d<float> tf [[texture(11)]],
    texture2d<float> ja [[texture(12)]],
    texture2d<float> jb [[texture(13)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int m0 = degrauDoMaior();

    // ---- 0..4: a pirâmide ----
    if (eng.acPass < 5) {
        int d = eng.acPass + 1;
        if (d > m0) { __nv_out = float4(0.0); return __nv_out; }
        // A média da ÁREA que este ponto cobre no degrau de cima. Os buffers não têm exatamente a metade um do
        // outro (o lado é arredondado para baixo): com dois pontos por eixo, uma linha inteira ficava de fora.
        int2 Tc = tamanhoDe(d - 1);
        float2 razao = float2(Tc) / eng.acResolution;
        float2 de = floor(in.acScreenNorm * eng.acResolution) * razao, ate = de + razao;
        int2 b = int2(floor(de));
        float3 l = float3(0.0);
        float area = 0.0;
        for (int j = 0; j < 4; j++) {
            float wy = min(float(b.y + j + 1), ate.y) - max(float(b.y + j), de.y);
            if (wy <= 0.0) continue;
            for (int i = 0; i < 4; i++) {
                float wx = min(float(b.x + i + 1), ate.x) - max(float(b.x + i), de.x);
                if (wx <= 0.0) continue;
                l += wx * wy * degrau(d - 1, b + int2(i, j));
                area += wx * wy;
            }
        }
        l /= max(area, 1e-6);
        __nv_out = codificar(l);
        return __nv_out;
    }

    // ---- 5..14: o nível de cada degrau (o degrau d recebe o nível m0 − d) ----
    if (eng.acPass < 15) {
        bool vertical = eng.acPass >= 10;
        int d = (vertical ? eng.acPass - 10 : eng.acPass - 5) + 1;
        if (d > m0) { __nv_out = float4(0.0); return __nv_out; }
        int2 T = vertical ? tamanhoDoH(d) : tamanhoDe(d);
        int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
        __nv_out = codificar(desfocar(d, p, sigmaNoDegrau(m0 - d, d, T), vertical));
        return __nv_out;
    }

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));

    // ---- 15..22: os níveis finos (de m0 em diante), na resolução cheia; menos de 1/4 de ponto de sigma não desfoca ----
    if (eng.acPass < 23) {
        int vaga = (eng.acPass - 15) / 2;
        bool vertical = ((eng.acPass - 15) & 1) == 1;
        int k = m0 + vaga;
        bool usa = k < NIVEIS && sigmaDoNivel(k) >= 0.25;
        if (!vertical) {
            __nv_out = usa ? codificar(desfocar(0, p, sigmaDoNivel(k), false)) : float4(0.0);
            return __nv_out;
        }
        // a junção até aqui (screen): quem escreve em `ja` lê `jb`, e vice-versa; a primeira começa do zero
        float3 antes = vaga == 0 ? float3(0.0) : decodificar((vaga & 1) == 1 ? ja.read(uint2(p), uint(0)) : jb.read(uint2(p), uint(0)));
        if (usa) antes = 1.0 - (1.0 - antes) * (1.0 - desfocar(0, p, sigmaDoNivel(k), true));
        __nv_out = codificar(antes);
        return __nv_out;
    }

    // ---- 23: junta os níveis; Tint, saturação, aberração cromática, altas e a mistura ----
    float3 falta = 1.0 - decodificar(jb.read(uint2(p), uint(0)));          // os níveis finos desfocados
    float3 e = entrada(p);
    for (int k = m0; k < NIVEIS; k++) {
        if (sigmaDoNivel(k) < 0.25) falta *= 1.0 - e;
    }
    // Aberração cromática: cada canal lê os níveis largos com o próprio zoom em volta do centro.
    float ca = clamp(u.chromatic, 0.0, 100.0) * 0.0006;
    float2 uv = in.acScreenNorm;
    float2 uvR = (uv - 0.5) * (1.0 - ca) + 0.5;
    float2 uvB = (uv - 0.5) * (1.0 + ca) + 0.5;
    for (int d = 1; d <= DEGRAUS; d++) {
        if (d <= m0) {
            if (ca > 0.0) {
                falta.r *= 1.0 - degrauEm(d, uvR).r;
                falta.g *= 1.0 - degrauEm(d, uv).g;
                falta.b *= 1.0 - degrauEm(d, uvB).b;
            } else {
                falta *= 1.0 - degrauEm(d, uv);
            }
        }
    }
    float3 linear = (1.0 - falta) * u.exposure;
    // Saturação e Tint do brilho, em luz.
    float lum = dot(linear, float3(0.2126, 0.7152, 0.0722));
    linear = max(mix(float3(lum), linear, u.glowSaturation / 100.0), 0.0);
    float tk = clamp(u.tint / 100.0, 0.0, 1.0);
    float3 tc = paraLuz(u.tintColor.rgb);
    linear = mix(linear, max(lum, max(linear.r, max(linear.g, linear.b))) * tc, tk);
    // Altas suaves: o corte em 1 vira um ombro.
    float ro = clamp(u.rolloff / 100.0, 0.0, 1.0);
    if (ro > 0.0) linear = mix(linear, 1.0 - exp(-linear * (1.0 + ro * 2.0)), ro);
    float3 luz = min(paraGama(linear), float3(1.0));
    if (u.dither != 0) {
        float rnd = fract(sin(dot(float2(p), float2(12.9898, 78.233))) * 43758.5453);
        luz = clamp(luz + (rnd - 0.5) / 255.0, 0.0, 1.0);
    }

    float4 fonte = inputImg.read(uint2(p), uint(0));
    float a = fonte.a * clamp(u.sourceOpacity / 100.0, 0.0, 1.0);
    float3 base = fonte.rgb * a;
    float3 cor;
    if (u.blendMode == 1)      cor = min(base + luz, 1.0);                 // Add
    else if (u.blendMode == 2) cor = mix(base, luz, max(luz.r, max(luz.g, luz.b))); // Normal (brilho por cima)
    else if (u.blendMode == 3) { cor = luz; a = 0.0; }                     // Só o brilho
    else                       cor = 1.0 - (1.0 - base) * (1.0 - luz);     // Screen (o do plugin)
    float mx = max(luz.r, max(luz.g, luz.b));
    float alfa = (u.unmult || u.blendMode == 3) ? 1.0 - (1.0 - a) * (1.0 - mx) : 1.0;
    __nv_out = alfa > 0.0 ? float4(min(cor / alfa, float3(1.0)), alfa) : float4(0.0);
    return __nv_out;
}
