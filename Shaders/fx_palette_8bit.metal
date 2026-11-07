// ---------------------------------------------------------------------------
// Paleta 8-bit
// origem : assets/effects/palette-8bit.xml
// id     : nova.effect.palette-8bit
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct palette_8bitParams {
    float cellSize;
    float levels;
    float dither;
    float saturation;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
static float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Matriz de Bayer 4×4 (valores 0..15 / 16): o dithering ordenado clássico. */
const float BAYER[16] = float[16](
     0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
    12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
     3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
    15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

static float bayerEm(int2 p) {
    int x = p.x - (p.x / 4) * 4;
    int y = p.y - (p.y / 4) * 4;
    return BAYER[y * 4 + x];
}

fragment float4 fx_palette_8bit(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant palette_8bitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float lado = max(u.cellSize, 1.0);

    // 1. Rasteriza em pixels grandes.
    float2 pixelado = floor(in.acScreenNorm * tam / lado) * lado / tam + (lado * 0.5) / tam;
    float4 original = inputImg.sample(__nv_smp, pixelado);

    // 2. Satura antes de quantizar (pra puxar as cores ao perfil retrô).
    float3 cinza = float3(luma(original.rgb));
    float3 saturada = mix(cinza, original.rgb, u.saturation);

    // 3. Dithering ordenado + quantização.
    int n = clamp(int(u.levels + 0.5), 2, 8);
    float passo = 1.0 / float(n - 1);
    int2 p = int2(in.acScreenNorm * tam / lado);
    float d = (bayerEm(p) - 0.5) * passo * u.dither;

    float3 quantizada = clamp(saturada + float3(d), 0.0, 1.0);
    quantizada = floor(quantizada * float(n - 1) + 0.5) / float(n - 1);

    __nv_out = float4(quantizada, original.a);
    return __nv_out;
}
