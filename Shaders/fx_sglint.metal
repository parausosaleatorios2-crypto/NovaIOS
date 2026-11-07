// ---------------------------------------------------------------------------
// S_Glint
// origem : assets/effects/sglint.xml
// id     : nova.effect.sglint
// passes : 43
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sglintParams {
    float brightness;
    float hueShift;
    float4 scaleColors;
    float brightnessX;
    float brightnessY;
    float brightnessDiag1;
    float brightnessDiag2;
    float threshold;
    float4 thresholdAddColor;
    float thresholdBlur;
    float size;
    float sizeX;
    float sizeY;
    float sizeDiag1;
    float sizeDiag2;
    float sizeRed;
    float sizeGreen;
    float sizeBlue;
    float blurGlint;
    float affectAlpha;
    int glintFromAlpha;
    int glintUnderSource;
    float sourceOpacity;
};

// --- funcoes auxiliares do efeito
const int TOQUES = 16;                       // amostras do pente de cada caixa

float4 pre(float4 c) { return float4(c.rgb * c.a, c.a); }
float4 fonte(float2 uv) { return pre(inputImg.sample(__nv_smp, uv)); }

/** Gaussiano de um eixo. `de`: 0 = a fonte, 1 = bh, 2 = gl. */
float4 ler(int de, float2 q) { return de == 0 ? fonte(q) : de == 1 ? bh.sample(__nv_smp, q) : gl.sample(__nv_smp, q); }
float4 gauss(int de, float2 eixo, float sigma) {
    float2 uv = in.acScreenNorm;
    if (sigma < 0.05) return ler(de, uv);
    float passo = max(1.0, ceil(3.0 * sigma / 20.0));
    float4 soma = float4(0.0);
    float pesos = 0.0;
    for (int n = -20; n <= 20; n++) {
        float d = float(n) * passo;
        if (abs(d) > 3.0 * sigma + 0.5) continue;
        float w = exp(-0.5 * d * d / (sigma * sigma));
        soma += w * ler(de, clamp(uv + eixo * d * eng.acTexelSize, 0.0, 1.0));
        pesos += w;
    }
    return soma / max(pesos, 1e-6);
}

float sigmaDoLimiar() { return 0.42 * u.thresholdBlur * eng.acEscalaDePixel; }
float sigmaDoGlint() { return 0.4 * u.blurGlint * eng.acEscalaDePixel; }

/**
 * Hue Shift (medido num raio branco com 0,25 e 0,5): gira o matiz como no HSV e devolve o brilho
 * que a cor tinha — o brilho da Sapphire, 5/16·R + 8/16·G + 3/16·B.
 */
float3 girarMatiz(float3 c, float voltas) {
    if (voltas == 0.0) return c;
    float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
    float d = mx - mn;
    if (d < 1e-6) return c;
    float h = mx == c.r ? (c.g - c.b) / d : mx == c.g ? 2.0 + (c.b - c.r) / d : 4.0 + (c.r - c.g) / d;
    h = fract(h / 6.0 + voltas);
    float3 puro = clamp(abs(__nv_mod(h * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    float3 r = mn + d * puro;
    const float3 PESO = float3(0.3125, 0.5, 0.1875);
    return r * dot(c, PESO) / max(dot(r, PESO), 1e-6);
}

/**
 * O que passa do limiar: (c − limiar − Threshold Add Color)/(1 − limiar) por canal (a cor SOBE o
 * limiar daquele canal: medido), devolvido com a COR da fonte — a soma dos três vezes a cor
 * dividida pela soma dela (medido na cartela, com Size 0).
 */
float3 limiar(float4 c) {
    float3 v = u.glintFromAlpha ? float3(c.a) : c.rgb;
    float3 t = max(v - u.threshold - u.thresholdAddColor.rgb, 0.0) / max(1.0 - u.threshold, 1e-4);
    float soma = v.r + v.g + v.b;
    float3 g = soma > 1e-5 ? v * (t.r + t.g + t.b) / soma : float3(0.0);
    return g * u.scaleColors.rgb;
}

// ---------------------------------------------------------------- os raios
// Medido (tools/sglint/benchmark): cada raio é a imagem do limiar borrada em UMA direção por TRÊS
// caixas seguidas de largura 2/3 do alcance — juntas dão uma B-spline quadrática de alcance ±Size —,
// a caixa nunca é mais larga do que a imagem, e o plugin corta o que sai da imagem ENTRE uma caixa e
// a outra (por isso o raio enfraquece perto da borda). Nas diagonais um lado fica LIVRE: na Diag1 o
// que sai pela direita continua valendo, na Diag2 o que sai por baixo (conferido lado por lado;
// erro de 0,05% contra 0,3–0,6% de qualquer outra combinação). Essa margem mora nos buffers `ua`/`ub`.
// Cada caixa aqui são dois passes: uma caixa pequena (largura s) e um pente de TOQUES amostras
// espaçadas de s.

/**
 * O brilho do raio `i`. Medido com um tamanho de direção por vez: esticar o raio NÃO o deixa mais
 * fraco — o pico fica onde estava e a energia cresce com o Size X / Y / Diag (as diagonais contam
 * a partir dos 0,75 de fábrica).
 */
float brilhoDe(int i) {
    float b = u.brightness * (i == 0 ? u.brightnessX : i == 1 ? u.brightnessY : i == 2 ? u.brightnessDiag1 : u.brightnessDiag2);
    return b * (i == 0 ? u.sizeX : i == 1 ? u.sizeY : i == 2 ? u.sizeDiag1 / 0.75 : u.sizeDiag2 / 0.75);
}
/** Pixels deste buffer por pixel da composição (os raios podem rodar em resolução reduzida). */
float escalaDoBuffer() { return eng.acEscalaDePixel * eng.acResolution.x / float(int2(int(inputImg.get_width()), int(inputImg.get_height())).x); }
int2 tamanho() { return int2(eng.acResolution + 0.5); }
int2 passoDe(int i) { return i == 0 ? int2(1, 0) : i == 1 ? int2(0, 1) : i == 2 ? int2(1, 1) : int2(1, -1); }
/** O espaçamento do pente, por canal, em PASSOS da direção (na diagonal um passo é √2 pixel: medido). */
float3 espacamento(int i) {
    float alcance = u.size * escalaDoBuffer() * (i == 0 ? u.sizeX : i == 1 ? u.sizeY : i == 2 ? u.sizeDiag1 : u.sizeDiag2);
    float teto = i == 0 ? eng.acResolution.x : eng.acResolution.y;
    return min(alcance * float3(u.sizeRed, u.sizeGreen, u.sizeBlue) * (2.0 / 3.0), teto) / float(TOQUES);
}

/**
 * Os buffers do motor têm 8 bits por canal, e um raio fraco passa por seis passes: guardado assim
 * ele perderia 10% (medido). Aqui os três canais vão com 10 bits cada (em raiz quadrada) nos 32
 * bits do pixel — por isso estes buffers são lidos com `texelFetch`, sem filtro.
 */
float4 empacotar(float3 v) {
    uint3 q = uint3(sqrt(clamp(v, 0.0, 1.0)) * 1023.0 + 0.5);
    uint bits = q.r | (q.g << 10) | (q.b << 20);
    return float4(float(bits & 255u), float((bits >> 8) & 255u), float((bits >> 16) & 255u), float((bits >> 24) & 255u)) / 255.0;
}
float3 desempacotar(float4 c) {
    uint4 b = uint4(c * 255.0 + 0.5);
    uint bits = b.r | (b.g << 8) | (b.b << 16) | (b.a << 24);
    float3 q = float3(float(bits & 1023u), float((bits >> 10) & 1023u), float((bits >> 20) & 1023u)) / 1023.0;
    return q * q;
}

/**
 * O estágio anterior na posição `p` (em pixels da imagem; a margem livre fica logo depois dela:
 * à direita na Diag1, embaixo na Diag2). Fora disso não há nada.
 */
float3 lerEstagio(int i, int estagio, int2 p) {
    int2 t = tamanho();
    bool dentro = p.x >= 0 && p.y >= 0 && p.x < t.x && p.y < t.y;
    if (estagio == 0) return dentro ? lim.read(uint2(p), uint(0)).rgb : float3(0.0);
    bool impar = estagio == 1 || estagio == 3 || estagio == 5;
    if (dentro) return desempacotar(impar ? ta.read(uint2(p), uint(0)) : tb.read(uint2(p), uint(0)));
    if (i == 2 && p.y >= 0 && p.y < t.y && p.x >= t.x && p.x < 2 * t.x) p.x -= t.x;
    else if (i == 3 && p.x >= 0 && p.x < t.x && p.y >= t.y && p.y < 2 * t.y) p.y -= t.y;
    else return float3(0.0);
    return desempacotar(impar ? ua.read(uint2(p), uint(0)) : ub.read(uint2(p), uint(0)));
}

/**
 * (desempenho, 0.805.0) Quantos passos da direção o raio já andou ao fim do `estagio`, no máximo: a caixa pequena lê
 * até ½·maior + 1, o pente até 7,5·maior + ½ (o toque mais longe), somados estágio a estágio. Na margem livre, o
 * pixel mais longe da imagem do que isso só soma zeros — o passe grava o zero direto, sem andar.
 */
int alcanceAte(int estagio, float3 s) {
    float maior = max(s.r, max(s.g, s.b));
    int caixas = estagio / 2 + 1;
    int pentes = (estagio + 1) / 2;
    // (+1 em cada termo: a folga do arredondamento do float)
    return caixas * (int(floor(0.5 * maior + 1.0)) + 1) + pentes * (int(floor(0.5 * float(TOQUES - 1) * maior + 0.5)) + 1);
}

/** Um dos seis passes de um raio: par = a caixa pequena; ímpar = o pente. `margem` = este buffer é o da margem livre. */
float3 passeDoRaio(int i, bool margem, int estagio) {
    int2 d = passoDe(i);
    int2 aqui = int2(floor(in.acScreenNorm * eng.acResolution));
    float3 s = espacamento(i);
    // (na margem, `aqui` = a distância até a imagem: o x além da borda direita na Diag1, o y além da de baixo na Diag2)
    if (margem && (i == 2 ? aqui.x : aqui.y) > alcanceAte(estagio, s) + 1) return float3(0.0);
    if (margem) aqui += i == 2 ? int2(tamanho().x, 0) : int2(0, tamanho().y);
    float3 soma = float3(0.0);
    if (estagio == 0 || estagio == 2 || estagio == 4) {
        float maior = max(s.r, max(s.g, s.b));
        float3 meia = 0.5 * max(s, 1.0);
        for (int k = -32; k <= 32; k++) {
            float x = float(k);
            if (abs(x) > 0.5 * maior + 1.0) continue;
            // quanto do pixel k cai dentro da caixa [−s/2, s/2] de cada canal
            float3 w = clamp(min(float3(x + 0.5), meia) - max(float3(x - 0.5), -meia), 0.0, 1.0);
            soma += w * lerEstagio(i, estagio, aqui + d * k);
        }
        return soma / max(s, 1.0);
    }
    for (int j = 0; j < TOQUES; j++) {
        float t = float(j) - 0.5 * float(TOQUES - 1);
        soma.r += lerEstagio(i, estagio, aqui + d * int(floor(t * s.r + 0.5))).r;
        soma.g += lerEstagio(i, estagio, aqui + d * int(floor(t * s.g + 0.5))).g;
        soma.b += lerEstagio(i, estagio, aqui + d * int(floor(t * s.b + 0.5))).b;
    }
    // (Com a caixa pequena os toques caem repetidos nos mesmos pixels: continua sendo a caixa certa,
    // e com Size 0 todos caem no próprio pixel — o raio é a imagem do limiar, como no plugin.)
    return soma / float(TOQUES);
}

/** O raio `i` pronto no pixel `p`. */
float3 raioPronto(int i, int2 p, int2 t) {
    float4 c = i == 0 ? rx.read(uint2(p), uint(0)) : i == 1 ? ry.read(uint2(p), uint(0)) : i == 2 ? rd1.read(uint2(p), uint(0)) : rd2.read(uint2(p), uint(0));
    return 4.0 * brilhoDe(i) * desempacotar(c);
}

/** Os quatro raios juntos em SCREEN (medido com Size 0: 1 − (1 − 4T)^4), no pixel `p` dos buffers dos raios. */
float3 glintEmTam(int2 p, int2 t) {
    p = clamp(p, int2(0), t - 1);
    float3 resto = float3(1.0);
    for (int i = 0; i < 4; i++) resto *= 1.0 - clamp(raioPronto(i, p, t), 0.0, 1.0);
    return 1.0 - resto;
}

fragment float4 fx_sglint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sglintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> bh [[texture(1)]],
    texture2d<float> bv [[texture(2)]],
    texture2d<float> lim [[texture(3)]],
    texture2d<float> ta [[texture(4)]],
    texture2d<float> tb [[texture(5)]],
    texture2d<float> ua [[texture(6)]],
    texture2d<float> ub [[texture(7)]],
    texture2d<float> rx [[texture(8)]],
    texture2d<float> ry [[texture(9)]],
    texture2d<float> rd1 [[texture(10)]],
    texture2d<float> rd2 [[texture(11)]],
    texture2d<float> gl [[texture(12)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    if (eng.acPass == 0) { __nv_out = gauss(0, float2(1.0, 0.0), sigmaDoLimiar()); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = gauss(1, float2(0.0, 1.0), sigmaDoLimiar()); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = float4(min(limiar(bv.sample(__nv_smp, uv)), 1.0), 1.0); return __nv_out; }
    if (eng.acPass >= 3 && eng.acPass <= 14) {
        int p = eng.acPass - 3;
        __nv_out = empacotar(passeDoRaio(p / 6, false, p - 6 * (p / 6)));
        return __nv_out;
    }
    if (eng.acPass >= 15 && eng.acPass <= 38) {
        int p = eng.acPass - 15;
        int q = p - 12 * (p / 12);
        // (a margem do último estágio não é lida por ninguém)
        __nv_out = q == 11 ? float4(0.0) : empacotar(passeDoRaio(2 + p / 12, q - 2 * (q / 2) == 1, q / 2));
        return __nv_out;
    }
    if (eng.acPass == 39) {
        // Os buffers dos raios podem ser menores do que a saída: interpolação bilinear à mão (eles não têm filtro).
        float2 t = float2(int2(int(rx.get_width()), int(rx.get_height())));
        float2 f = uv * t - 0.5;
        int2 i0 = int2(floor(f));
        float2 w = fract(f);
        // (dentro de glintEm, eng.acResolution é a deste passe; o tamanho dos raios vem de textureSize)
        float3 g = mix(mix(glintEmTam(i0, int2(t)), glintEmTam(i0 + int2(1, 0), int2(t)), w.x),
                     mix(glintEmTam(i0 + int2(0, 1), int2(t)), glintEmTam(i0 + int2(1, 1), int2(t)), w.x), w.y);
        __nv_out = float4(g, 1.0);
        return __nv_out;
    }
    if (eng.acPass == 40) { __nv_out = gauss(2, float2(1.0, 0.0), sigmaDoGlint()); return __nv_out; }
    if (eng.acPass == 41) { __nv_out = gauss(1, float2(0.0, 1.0), sigmaDoGlint()); return __nv_out; }

    float4 s = fonte(uv) * u.sourceOpacity;
    float3 g = girarMatiz(bv.sample(__nv_smp, uv).rgb, u.hueShift);
    float ga = clamp(max(g.r, max(g.g, g.b)) * u.affectAlpha, 0.0, 1.0);
    float4 c;
    if (u.glintUnderSource) c = float4(s.rgb + g * (1.0 - s.a), s.a + ga * (1.0 - s.a));
    else c = float4(1.0 - (1.0 - s.rgb) * (1.0 - g), 1.0 - (1.0 - s.a) * (1.0 - ga));
    c.rgb = min(c.rgb, 1.0);
    __nv_out = c.a > 1e-5 ? float4(min(c.rgb / c.a, 1.0), c.a) : float4(0.0);
    return __nv_out;
}
