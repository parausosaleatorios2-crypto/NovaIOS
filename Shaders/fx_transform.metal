// ---------------------------------------------------------------------------
// Transformar (Transform)
// origem : assets/effects/transform.xml
// id     : nova.effect.transform
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct transformParams {
    float2 anchorPoint;
    float2 position;
    int uniformScale;
    float scaleHeight;
    float scaleWidth;
    float skew;
    float skewAxis;
    float rotation;
    float opacity;
    int useCompShutter;
    float shutterAngle;
    int sampling;
};

// --- funcoes auxiliares do efeito
static float4 premult(float4 c) { return float4(c.rgb * c.a, c.a); }

static float4 depremult(float4 c) {
    return c.a > 0.0 ? float4(c.rgb / c.a, c.a) : float4(0.0);
}

// O Motion Tile que rodou logo antes na cadeia (camada de ajuste), dado pelo host: fora da imagem, em vez de
// transparente, a continuação do ladrilho. Ver `LadrilhoDeMovimento.uniformsDaContinuacao`.
uniform int   mtAtivo;     // 1: o efeito logo antes é o Motion Tile
uniform float2  mtCentro;    // Tile Center, como o shader dele recebeu
uniform float2  mtTam;       // Tile Width/Height, em fração da camada
uniform float2  mtSaida;     // Output Width/Height, em fração da camada
uniform int   mtEspelhar;  // Mirror Edges
uniform float mtFase;      // Phase, em voltas
uniform int   mtFaseH;     // Horizontal Phase Shift

static bool impar(float k) { return __nv_mod(k, 2.0) == 1.0; }

/** A fração `f` do ladrilho, posta no ladrilho `k`: espelhada nos ímpares com o Mirror Edges. */
static float noLadrilho(float f, float k) { return (mtEspelhar == 1 && impar(k)) ? 1.0 - f : f; }

/**
 * Num eixo: `x` (px da camada) levado ao mesmo ponto do desenho num ladrilho que caia dentro de [0, n). `kDe` sai
 * com o ladrilho de `x`, `kPara` com o de destino. O ladrilho maior que a camada pode não ter o ponto: a borda.
 */
static float dobrarNoEixo(float x, float org, float t, float n, out float kDe, out float kPara) {
    float u = (x - org) / t;
    kDe = floor(u);
    float f = noLadrilho(u - kDe, kDe);
    float k0 = floor(-org / t);
    for (int i = 0; i < 3; i++) {
        float k = k0 + float(i);
        float y = org + (k + noLadrilho(f, k)) * t;
        if (y >= 0.0 && y < n) { kPara = k; return y; }
    }
    kPara = kDe;
    return clamp(x, 0.0, n - 0.5);
}

/** O deslocamento da Phase no ladrilho `k` (só os ímpares andam), no outro eixo. */
static float faseDe(float k, float t) { return impar(k) ? mtFase * t : 0.0; }

/** O pixel `c`, fora da imagem, na continuação do ladrilho; (-1, -1) = fora da saída do Motion Tile. */
static int2 continuarLadrilho(int2 c, int2 tam) {
    // A camada dentro do buffer, como o `motion-tile.xml` a mede.
    float2 T = float2(tam);
    float2 n = clamp(floor(max(eng.acCamada, float2(0.001)) * T + 0.5), float2(1.0), T);
    float2 inicio = floor((T - n) * 0.5);
    float2 x = float2(c) + 0.5 - inicio;
    if (any(greaterThan(abs(x / n - 0.5), mtSaida * 0.5))) return int2(-1);

    float2 t = max(mtTam * n, float2(1e-3));
    float2 org = mtCentro * n - t * 0.5;
    float2 y = x;
    float kDe = 0.0;
    float kPara = 0.0;
    if (mtFaseH == 0) {
        // A Phase desce as colunas ímpares: trocar de coluna troca o deslocamento em y.
        if (x.x < 0.0 || x.x >= n.x) {
            y.x = dobrarNoEixo(x.x, org.x, t.x, n.x, kDe, kPara);
            y.y += faseDe(kPara, t.y) - faseDe(kDe, t.y);
        }
        if (y.y < 0.0 || y.y >= n.y) y.y = dobrarNoEixo(y.y, org.y, t.y, n.y, kDe, kPara);
    } else {
        if (x.y < 0.0 || x.y >= n.y) {
            y.y = dobrarNoEixo(x.y, org.y, t.y, n.y, kDe, kPara);
            y.x += faseDe(kPara, t.x) - faseDe(kDe, t.x);
        }
        if (y.x < 0.0 || y.x >= n.x) y.x = dobrarNoEixo(y.x, org.x, t.x, n.x, kDe, kPara);
    }
    return clamp(int2(floor(y + inicio)), int2(0), tam - 1);
}

/** Um pixel da entrada, pré-multiplicado. Fora da imagem, transparente (ou o ladrilho que continua). */
static float4 pixelDe(int2 c, int2 tam) {
    if (c.x < 0 || c.y < 0 || c.x >= tam.x || c.y >= tam.y) {
        if (mtAtivo != 1) return float4(0.0);
        c = continuarLadrilho(c, tam);
        if (c.x < 0) return float4(0.0);
    }
    return premult(inputImg.read(uint2(c), uint(0)));
}

/** Bilinear à mão: 4 leituras. `pos` em pixels. */
static float4 lerBilinear(float2 pos, int2 tam) {
    float2 p = pos - 0.5;
    float2 base = floor(p);
    float2 f = p - base;
    int2 i = int2(base);
    float4 a = pixelDe(i, tam);
    float4 b = pixelDe(i + int2(1, 0), tam);
    float4 c = pixelDe(i + int2(0, 1), tam);
    float4 d = pixelDe(i + int2(1, 1), tam);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

/** Pesos de Catmull-Rom para os quatro vizinhos (-1, 0, 1, 2) a uma distância t. */
static float4 pesosCubicos(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return float4(
        -0.5 * t3 + t2 - 0.5 * t,
         1.5 * t3 - 2.5 * t2 + 1.0,
        -1.5 * t3 + 2.0 * t2 + 0.5 * t,
         0.5 * t3 - 0.5 * t2
    );
}

/** Bicúbico (Catmull-Rom) à mão: 16 leituras. */
static float4 lerBicubico(float2 pos, int2 tam) {
    float2 p = pos - 0.5;
    float2 base = floor(p);
    float2 f = p - base;
    int2 i = int2(base);
    float4 wx = pesosCubicos(f.x);
    float4 wy = pesosCubicos(f.y);

    float4 soma = float4(0.0);
    for (int y = 0; y < 4; y++) {
        float4 linha = float4(0.0);
        for (int x = 0; x < 4; x++) {
            linha += pixelDe(i + int2(x - 1, y - 1), tam) * wx[x];
        }
        soma += linha * wy[y];
    }
    // O lóbulo negativo do filtro pode passar de 0..1 perto de uma borda dura.
    soma.a = clamp(soma.a, 0.0, 1.0);
    soma.rgb = clamp(soma.rgb, float3(0.0), float3(soma.a));
    return soma;
}

/** Gira `v` no sentido HORÁRIO da tela (o eixo y cresce para baixo). */
static float2 girar(float2 v, float angulo) {
    float c = cos(angulo);
    float s = sin(angulo);
    return float2(c * v.x - s * v.y, s * v.x + c * v.y);
}

/**
 * De que ponto da ENTRADA vem o pixel `p` da saída.
 *
 * É a inversa de: saída = pos + inclinação(giro(escala(entrada - âncora))).
 * Medido no After Effects: a inclinação soma tan(Skew) · x ao y, no referencial
 * girado pelo Skew Axis, e é aplicada por FORA do giro; desfazê-la é o
 * cisalhamento oposto, no mesmo referencial, antes de desfazer o giro.
 */
static float2 origemDe(float2 p, float2 ancora, float2 pos, float2 escala, float inclina, float eixo, float giro) {
    float2 v = p - pos;
    v = girar(v, eixo);
    v.y -= tan(inclina) * v.x;
    v = girar(v, -eixo);
    v = girar(v, -giro);
    v /= escala;
    return v + ancora;
}

fragment float4 fx_transform(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant transformParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float2 tamF = float2(tam);
    float2 p = in.acScreenNorm * tamF;

    // Bicúbico custa 16 leituras por imagem: com o obturador ligado, menos imagens.
    bool bicubico = u.sampling == 1;
    int n = bicubico ? min(eng.acAmostras, 6) : eng.acAmostras;
    n = max(n, 1);

    float4 soma = float4(0.0);
    for (int i = 0; i < 16; i++) {
        if (i >= n) break;

        // Onde no obturador esta imagem cai: o meio de cada fatia.
        float f = (float(i) + 0.5) / float(n);

        float2 ancora = mix(u.anchorPoint, anchorPointFim, f) * tamF;
        float2 pos = mix(u.position, positionFim, f) * tamF;

        float altura = mix(u.scaleHeight, scaleHeightFim, f);
        float largura = mix(u.scaleWidth, scaleWidthFim, f);
        float2 escala = u.uniformScale ? float2(altura) : float2(largura, altura);

        // Escala zero some com a imagem, e dividir por ela daria infinito.
        if (abs(escala.x) < 1e-4 || abs(escala.y) < 1e-4) continue;

        float inclina = radians(clamp(mix(u.skew, skewFim, f), -85.0, 85.0));
        float eixo = radians(mix(u.skewAxis, skewAxisFim, f));
        float giro = radians(mix(u.rotation, rotationFim, f));
        float opaco = clamp(mix(u.opacity, opacityFim, f), 0.0, 1.0);

        float2 q = origemDe(p, ancora, pos, escala, inclina, eixo, giro);
        float4 c = bicubico ? lerBicubico(q, tam) : lerBilinear(q, tam);

        // Opacidade em cor pré-multiplicada: escala cor e alfa juntos.
        soma += c * opaco;
    }

    __nv_out = depremult(soma / float(n));
    return __nv_out;
}
