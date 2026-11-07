// ---------------------------------------------------------------------------
// S_Glow
// origem : assets/effects/sapphire-glow.xml
// id     : nova.effect.sglow
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_glowParams {
    float brightness;
    float4 color;
    float threshold;
    float4 thresholdAddColor;
    float glowWidth;
    float widthX;
    float widthY;
    float widthRed;
    float widthGreen;
    float widthBlue;
    int subpixel;
    int show;
    int combine;
    int edgeMode;
    float affectAlpha;
    float glowFromAlpha;
    float glowUnderSource;
    float sourceOpacity;
};

// --- funcoes auxiliares do efeito
const float RAIO_MAX = 240.0;         // o maior raio de uma caixa (largura de um canal até ~720 px)

/**
 * A luz num buffer de 8 bits, como mantissa e expoente: a cauda do halo vale milésimos, e são seis passes em
 * fila — com 8 bits diretos o erro de cada um se somava. O maior canal fica entre 0,5 e 1 (guardado com raiz)
 * e o alfa leva a potência de dois.
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

/**
 * O limiar (medido): a cor pré-multiplicada vezes UM fator — a soma do que cada canal passa do limiar dele,
 * sobre a soma dos canais, com o (1 − limiar) que leva o branco de volta a 1. A cor somada ao limiar entra em
 * 8 bits, como no plugin.
 */
static float3 corDoLimiar(int2 p) {
    float4 t = inputImg.read(uint2(p), uint(0));
    float3 c = max(t.rgb * t.a, float3(0.0));
    return mix(c, float3(t.a), clamp(u.glowFromAlpha, 0.0, 1.0));
}
static float fatorDoLimiar(float3 c) {
    float soma = c.r + c.g + c.b;
    if (soma < 1e-6) return 0.0;
    float3 passa = max(c - (u.threshold + floor(u.thresholdAddColor.rgb * 255.0 + 0.5) / 255.0), float3(0.0));
    return (passa.r + passa.g + passa.b) / soma / max(1.0 - u.threshold, 1e-6);
}
static float3 limiar(int2 p) {
    float3 c = corDoLimiar(p);
    return c * fatorDoLimiar(c);
}

/**
 * (desempenho, 0.805.0) O fator do limiar é uma conta por pixel, mas a 1ª caixa o refazia em cada amostra (~90 por
 * pixel com a largura de fábrica: 28 dos 37 ms do passe na GPU do PC). O passe 0 o guarda inteiro — os 32 bits do
 * float nos 4 bytes do texel — e a caixa só multiplica a cor da fonte por ele: o mesmo número de antes.
 */
static float4 guardarFator(float f) {
    uint b = as_type<uint>(f);
    return float4(float(b & 255u), float((b >> 8u) & 255u), float((b >> 16u) & 255u), float(b >> 24u)) / 255.0;
}
static float3 limiarGuardado(int2 p) {
    uint4 b = uint4(gb.read(uint2(p), uint(0)) * 255.0 + 0.5);
    return corDoLimiar(p) * as_type<float>(b.r | (b.g << 8u) | (b.b << 16u) | (b.a << 24u));
}

/** Espelha o índice repetindo o pixel da borda (medido: o Reflect do plugin). */
static int espelhar(int i, int n) {
    int p = 2 * n;
    i = i - (i / p) * p; if (i < 0) i += p;
    return i < n ? i : p - 1 - i;
}

/**
 * O que o passe `passo` lê: a fonte com o limiar, ou o buffer do passe anterior. O espelho (com divisão inteira)
 * só para o tap que cai FORA da imagem: dentro, ele devolve o próprio índice (0.569.0: 72 → 44 ms na GPU do PC).
 */
static float3 ler(int passo, int2 p, int2 T) {
    bool fora = p.x < 0 || p.y < 0 || p.x >= T.x || p.y >= T.y;
    if (u.edgeMode == 1 && fora) p = int2(espelhar(p.x, T.x), espelhar(p.y, T.y));
    else if (p.x < 0 || p.y < 0 || p.x >= T.x || p.y >= T.y) return float3(0.0);
    if (passo == 0) return limiarGuardado(p);
    if ((passo & 1) == 1) return decodificar(ga.read(uint2(p), uint(0)));
    return decodificar(gb.read(uint2(p), uint(0)));
}

/**
 * Uma das três caixas (`qual` = 0, 1, 2) de um eixo. Medido: largura inteira W -> raios que somam W, o mais
 * parelhos possível; de W para W + 1 só a caixa (W mod 3) cresce, e a largura quebrada mistura as duas —
 * o que dá a caixa de raio r com mais uma ponta de peso menor.
 */
static float3 caixa(int passo, int2 p, int2 T, bool vertical, int qual) {
    float3 w = u.glowWidth * eng.acEscalaDePixel * float3(u.widthRed, u.widthGreen, u.widthBlue) * (vertical ? u.widthY : u.widthX);
    w = clamp(w, float3(0.0), float3(3.0 * RAIO_MAX));
    float3 a = u.subpixel ? floor(w) : floor(w + 0.5);
    float3 f = u.subpixel ? w - a : float3(0.0);
    float3 r = floor((a + float(2 - qual)) / 3.0 + 1e-4);
    float3 cresce = float3(equal(a - 3.0 * floor(a / 3.0 + 1e-4), float3(float(qual))));
    f *= cresce;
    float3 dentro = (1.0 - f) / (2.0 * r + 1.0) + f / (2.0 * r + 3.0);
    float3 ponta = f / (2.0 * r + 3.0);
    int alcance = int(max(r.r, max(r.g, r.b))) + 1;
    // Até o menor raio, todo canal está dentro da caixa: o peso é `dentro` (a conta de baixo daria o mesmo,
    // `dentro · 1 + ponta · 0`). A soma continua na MESMA ordem, de −alcance a +alcance: somar o miolo à parte
    // mudaria o arredondamento (0.569.0: 44 → 37 ms).
    int miolo = int(min(r.r, min(r.g, r.b)));
    float3 soma = float3(0.0);
    for (int i = -alcance; i <= alcance; i++) {
        float3 peso = dentro;
        if (i < -miolo || i > miolo) {
            float d = abs(float(i));
            float3 naCaixa = step(float3(d), r + 0.5);
            peso = dentro * naCaixa + ponta * (step(float3(d), r + 1.5) - naCaixa);
            if (peso.r + peso.g + peso.b <= 0.0) continue;
        }
        soma += peso * ler(passo, p + (vertical ? int2(0, i) : int2(i, 0)), T);
    }
    return soma;
}

fragment float4 fx_sapphire_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> ga [[texture(1)]],
    texture2d<float> gb [[texture(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 p = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));

    if (eng.acPass == 0) { __nv_out = guardarFator(fatorDoLimiar(corDoLimiar(p))); return __nv_out; }

    // ---- 1..6: as caixas ----
    int passo = eng.acPass - 1;
    if (passo < 6) {
        bool vertical = passo >= 3;
        __nv_out = codificar(caixa(passo, p, T, vertical, vertical ? passo - 3 : passo));
        return __nv_out;
    }

    if (u.show == 1) { __nv_out = float4(min(limiar(p), float3(1.0)), 1.0); return __nv_out; }

    // ---- 6: a luz e a mistura (da definição do efeito; conferido no AE) ----
    float3 luz = min(decodificar(gb.read(uint2(p), uint(0))) * u.brightness * u.color.rgb, float3(1.0));
    float aLuz = min(max(luz.r, max(luz.g, luz.b)) * u.affectAlpha, 1.0);
    float4 fonte = inputImg.read(uint2(p), uint(0));
    float q = clamp(u.sourceOpacity, 0.0, 1.0);
    float aF = fonte.a * q;
    float3 s = fonte.rgb * aF;

    float3 cor;
    float alfa = 1.0 - (1.0 - aLuz) * (1.0 - aF);
    if (u.combine == 0) { cor = luz * s; alfa = aLuz * aF; }
    else if (u.combine == 1) { cor = luz + s; alfa = min(aLuz + aF, 1.0); }
    else if (u.combine == 2) cor = 1.0 - (1.0 - luz) * (1.0 - s);
    else if (u.combine == 3) cor = abs(luz - s);
    else cor = mix(2.0 * luz * s, 1.0 - 2.0 * (1.0 - luz) * (1.0 - s), float3(greaterThanEqual(s, float3(0.5))));

    // Glow Under Source: a fonte por cima da luz
    float sob = clamp(u.glowUnderSource, 0.0, 1.0);
    cor = mix(cor, s + luz * (1.0 - aF), sob);
    alfa = mix(alfa, aF + aLuz * (1.0 - aF), sob);

    cor = clamp(cor, 0.0, 1.0);
    __nv_out = alfa > 0.0 ? float4(min(cor / alfa, float3(1.0)), alfa) : float4(0.0);
    return __nv_out;
}
