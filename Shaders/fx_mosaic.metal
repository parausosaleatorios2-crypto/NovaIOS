// ---------------------------------------------------------------------------
// Mosaico
// origem : assets/effects/mosaic.xml
// id     : nova.effect.mosaic
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct mosaicParams {
    float horizontalBlocks;
    float verticalBlocks;
    int sharpColors;
    int squareBlocks;
};

// --- funcoes auxiliares do efeito
static float4 preMultiplicar(float4 c) {
    return float4(c.rgb * c.a, c.a);
}

/** A primeira descida: a média de 2×2 pixels da imagem, texel a texel. */
static float4 descerDaImagem() {
    int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 base = int2(floor(in.acScreenNorm * float2(tam) - 0.5));
    float4 s = float4(0.0);
    for (int j = 0; j < 2; j++) {
        for (int i = 0; i < 2; i++) {
            int2 t = clamp(base + int2(i, j), int2(0), tam - 1);
            s += preMultiplicar(inputImg.read(uint2(t), uint(0)));
        }
    }
    return s * 0.25;
}

/** As outras: uma leitura bilinear no canto entre quatro texels é a média deles. */
static float4 descer(sampler2D origem) {
    return origem.sample(__nv_smp, in.acScreenNorm);
}

static float2 contagem() {
    float h = max(floor(u.horizontalBlocks + 0.5), 1.0);
    float v = u.squareBlocks
        ? max(floor(h / max(eng.acAspect, 0.0001) + 0.5), 1.0)
        : max(floor(u.verticalBlocks + 0.5), 1.0);
    return float2(h, v);
}

static float4 lerNivel(int n, float2 uv) {
    if (n <= 0) return preMultiplicar(inputImg.sample(__nv_smp, uv));
    if (n == 1) return p1.sample(__nv_smp, uv);
    if (n == 2) return p2.sample(__nv_smp, uv);
    if (n == 3) return p3.sample(__nv_smp, uv);
    if (n == 4) return p4.sample(__nv_smp, uv);
    if (n == 5) return p5.sample(__nv_smp, uv);
    if (n == 6) return p6.sample(__nv_smp, uv);
    return p7.sample(__nv_smp, uv);
}

/** A cor (pré-multiplicada) do bloco de índice `bloco`. */
static float4 corDoBloco(float2 bloco, float2 blocos) {
    float2 lado = 1.0 / blocos;
    float2 inicio = bloco * lado;
    if (u.sharpColors) {
        // O pixel do centro da região, sem mistura com o vizinho.
        int2 tam = int2(int(inputImg.get_width()), int(inputImg.get_height()));
        int2 t = clamp(int2(floor((inicio + lado * 0.5) * float2(tam))), int2(0), tam - 1);
        return preMultiplicar(inputImg.read(uint2(t), uint(0)));
    }
    // O nível em que um texel tem ~1/4 do lado maior do bloco.
    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float px = max(lado.x * tam.x, lado.y * tam.y);
    int n = int(clamp(floor(log2(max(px * 0.25, 1.0))), 0.0, 7.0));
    float4 s = float4(0.0);
    for (int j = 0; j < 4; j++) {
        for (int i = 0; i < 4; i++) {
            s += lerNivel(n, inicio + lado * (float2(float(i), float(j)) + 0.5) * 0.25);
        }
    }
    return s * 0.0625;
}

fragment float4 fx_mosaic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mosaicParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> p1 [[texture(1)]],
    texture2d<float> p2 [[texture(2)]],
    texture2d<float> p3 [[texture(3)]],
    texture2d<float> p4 [[texture(4)]],
    texture2d<float> p5 [[texture(5)]],
    texture2d<float> p6 [[texture(6)]],
    texture2d<float> p7 [[texture(7)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) { __nv_out = descerDaImagem(); return __nv_out; }
    if (eng.acPass == 1) { __nv_out = descer(p1); return __nv_out; }
    if (eng.acPass == 2) { __nv_out = descer(p2); return __nv_out; }
    if (eng.acPass == 3) { __nv_out = descer(p3); return __nv_out; }
    if (eng.acPass == 4) { __nv_out = descer(p4); return __nv_out; }
    if (eng.acPass == 5) { __nv_out = descer(p5); return __nv_out; }
    if (eng.acPass == 6) { __nv_out = descer(p6); return __nv_out; }

    float2 blocos = contagem();
    float2 f = in.acScreenNorm * blocos;          // onde o pixel está, em blocos
    float2 meioPixel = 0.5 * blocos * eng.acTexelSize;
    float2 ultimo = blocos - 1.0;
    float4 cor;

    if (meioPixel.x < 0.5 && meioPixel.y < 0.5) {
        // A borda suavizada: o pixel que cai em cima da divisa entre dois
        // blocos leva cada um na proporção do que cobre. `b0` é o bloco da
        // ponta esquerda/de cima do pixel; `w`, quanto dele passa para o próximo.
        float2 b0 = clamp(floor(f - meioPixel), float2(0.0), ultimo);
        float2 w = clamp((f + meioPixel - (b0 + 1.0)) / (2.0 * meioPixel), 0.0, 1.0);
        float2 b1 = min(b0 + 1.0, ultimo);
        if (b1.x == b0.x) w.x = 0.0;
        if (b1.y == b0.y) w.y = 0.0;
        cor = corDoBloco(b0, blocos);
        if (w.x > 0.0 || w.y > 0.0) {
            float4 dx = w.x > 0.0 ? corDoBloco(float2(b1.x, b0.y), blocos) : cor;
            float4 dy = w.y > 0.0 ? corDoBloco(float2(b0.x, b1.y), blocos) : cor;
            float4 dxy = (w.x > 0.0 && w.y > 0.0) ? corDoBloco(b1, blocos) : (w.x > 0.0 ? dx : dy);
            cor = mix(mix(cor, dx, w.x), mix(dy, dxy, w.x), w.y);
        }
    } else {
        // Bloco menor que um pixel: não há borda para suavizar.
        cor = corDoBloco(clamp(floor(f), float2(0.0), ultimo), blocos);
    }
    __nv_out = float4(cor.a > 0.0001 ? cor.rgb / cor.a : float3(0.0), cor.a);
    return __nv_out;
}
