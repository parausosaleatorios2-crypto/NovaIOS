// ---------------------------------------------------------------------------
// Twirl (AE)
// origem : assets/effects/ae-twirl.xml
// id     : nova.effect.aetwirl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_twirlParams {
    float angle;
    float twirlRadius;
    float2 twirlCenter;
};

// --- funcoes auxiliares do efeito
// f(u), u de 0 a 1 em 64 passos — medida no After Effects (tools/twirl/benchmark/curva.py).
const float QUEDA[65] = float[65](
    1.000000, 0.999349, 0.997412, 0.994209, 0.989755, 0.984066, 0.977159, 0.969054,
    0.959776, 0.949355, 0.937826, 0.925225, 0.911598, 0.896989, 0.881447, 0.865025,
    0.847776, 0.829754, 0.811017, 0.791621, 0.771624, 0.751084, 0.730061, 0.708613,
    0.686799, 0.664680, 0.642312, 0.619756, 0.597068, 0.574305, 0.551522, 0.528773,
    0.506109, 0.483579, 0.461231, 0.439109, 0.417255, 0.395707, 0.374501, 0.353670,
    0.333244, 0.313252, 0.293718, 0.274664, 0.256111, 0.238076, 0.220574, 0.203619,
    0.187220, 0.171385, 0.156119, 0.141425, 0.127303, 0.113750, 0.100762, 0.088332,
    0.076454, 0.065120, 0.054322, 0.044053, 0.034302, 0.025055, 0.016290, 0.007964,
    0.000000);

/** f(u) pela tabela, com Catmull-Rom; antes de 0 a curva é espelhada, depois de 1 vale 0. */
static float queda(float u) {
    if (u >= 1.0) return 0.0;
    float x = max(u, 0.0) * 64.0;
    int i = min(int(floor(x)), 63);
    float t = x - float(i);
    float p1 = QUEDA[i], p2 = QUEDA[i + 1];
    float p0 = i == 0 ? QUEDA[1] : QUEDA[i - 1];
    float p3 = i == 63 ? 2.0 * QUEDA[64] - QUEDA[63] : QUEDA[i + 2];
    return 0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t);
}

/** A distância como o plugin a calcula: 1/16 de px, maior · hipotenusa(1, índice/256), com o índice cortado. */
static float distancia(float2 dd) {
    int a = abs(int(floor(dd.x * 16.0)));
    int b = abs(int(floor(dd.y * 16.0)));
    int maior = max(a, b), menor = min(a, b);
    if (maior == 0) return 0.0;
    if (maior >= 32768) return floor(length(float2(float(a), float(b))) + 0.5) / 16.0;
    float r = float((menor << 8) / maior) / 256.0;
    int hip = int(floor(16384.0 * sqrt(1.0 + r * r) + 0.5));
    return float((hip * maior) >> 14) / 16.0;
}

/** Um texel da imagem, pré-multiplicado; fora dela, transparente. */
static float4 texel(int2 p, int2 tamanho) {
    if (p.x < 0 || p.y < 0 || p.x >= tamanho.x || p.y >= tamanho.y) return float4(0.0);
    float4 c = inputImg.read(uint2(p), uint(0));
    return float4(c.rgb * c.a, c.a);
}

/** A média (pré-multiplicada) do retângulo [a, b] da imagem, em texels: exata até 12 texels de lado. */
static float4 media(float2 a, float2 b, int2 tamanho) {
    int2 de = int2(floor(a));
    int2 n = int2(floor(b)) - de + 1;
    float4 soma = float4(0.0);
    if (n.x <= 12 && n.y <= 12) {
        for (int j = 0; j < 12; j++) {
            if (j >= n.y) break;
            float py = float(de.y + j);
            float wy = max(min(py + 1.0, b.y) - max(py, a.y), 0.0);
            for (int i = 0; i < 12; i++) {
                if (i >= n.x) break;
                float px = float(de.x + i);
                float wx = max(min(px + 1.0, b.x) - max(px, a.x), 0.0);
                soma += texel(int2(de.x + i, de.y + j), tamanho) * (wx * wy);
            }
        }
        return soma / ((b.x - a.x) * (b.y - a.y));
    }
    // área grande: 12 x 12 amostras no meio de cada fatia
    for (int j = 0; j < 12; j++) {
        for (int i = 0; i < 12; i++) {
            float2 p = mix(a, b, (float2(float(i), float(j)) + 0.5) / 12.0);
            soma += texel(int2(floor(p)), tamanho);
        }
    }
    return soma / 144.0;
}

fragment float4 fx_ae_twirl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_twirlParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Tudo em px da COMPOSIÇÃO; a leitura volta para os texels do buffer no fim.
    float escala = eng.acEscalaDePixel;
    float2 tamanho = eng.acResolution / escala;
    // o centro chega como fração da camada: 200 px vira 199,99999, e isso também mudaria o degrau — volta para 1/1024 de px
    float2 centro = floor(u.twirlCenter * tamanho * 1024.0 + 0.5) / 1024.0;
    // o plugin conta em índices de pixel: o centro do pixel (i, j) é o ponto (i, j). O índice sai de `floor`, e não da
    // coordenada interpolada: a distância é cortada em 1/16 de px, e um erro de 0,00001 ali muda o degrau
    float2 dd = floor(in.acScreenNorm * eng.acResolution) / escala + (0.5 / escala - 0.5) - centro;

    float R = ceil(u.twirlRadius * 0.01 * length(tamanho) - 1.0e-4);
    float d = distancia(dd);
    float voltas = radians(u.angle);
    if (R <= 0.0 || d > R || voltas == 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }

    // a tabela do plugin anda de meio em meio px, e ele interpola só metade do caminho até a entrada seguinte
    float meio = floor(2.0 * d);
    float dq = (meio + 0.5 * (2.0 * d - meio)) * 0.5;
    float giro = -voltas * queda(dq / (0.875 * R));
    float c = cos(giro), s = sin(giro);
    float2 lido = float2(dd.x * c - dd.y * s, dd.y * c + dd.x * s) + centro + 0.5;

    float meiaLargura = min(0.5 * queda(abs(2.0 * d / R - 1.0)) * abs(voltas) + 0.5, 16.0);
    float4 m = media((lido - meiaLargura) * escala, (lido + meiaLargura) * escala, int2(eng.acResolution + 0.5));
    __nv_out = m.a > 0.0 ? float4(m.rgb / m.a, m.a) : float4(0.0);
    return __nv_out;
}
