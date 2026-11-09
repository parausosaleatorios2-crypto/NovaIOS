// ---------------------------------------------------------------------------
// S_Mosaic (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-mosaic.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_mosaicParams {
    float cellSize;
    int shape;
    float rotate;
    float edgeWidth;
    float4 edgeColor;
};

static float sp_luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }
static float sp_hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}
static float sp_ruido(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 w = f * f * (3.0 - 2.0 * f);
    float a = sp_hash(i), b = sp_hash(i + float2(1, 0));
    float c = sp_hash(i + float2(0, 1)), d = sp_hash(i + float2(1, 1));
    return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}
static float2 sp_rot(float2 p, float a) {
    float c = cos(a), s = sin(a);
    return float2(c * p.x - s * p.y, s * p.x + c * p.y);
}
static float3 sp_espectro(float t) {           // vermelho -> verde -> azul
    return clamp(float3(1.5 - 3.0 * t, 1.5 - abs(3.0 * t - 1.5), 3.0 * t - 1.5), 0.0, 1.0);
}
static float sp_brilho(float4 c, float limiar) {   // quanto passa do limiar
    float l = c.a > 0.0001 ? sp_luma(c.rgb / c.a) : 0.0;
    return smoothstep(limiar, min(limiar + 0.25, 1.0001), l);
}

fragment float4 fx_sapphire_mosaic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_mosaicParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float s = max(u.cellSize, 1.0);
    float2 p = sp_rot(uv * res - res * 0.5, -u.rotate * 0.0174533) / s;
    float2 cel, f;
    if (u.shape == 1) {
        float2 r = float2(1.0, 1.7320508);
        float2 a = fmod(p, r) - r * 0.5, b = fmod(p - r * 0.5, r) - r * 0.5;
        a = select(a, a + r, a < -r * 0.5); b = select(b, b + r, b < -r * 0.5);
        float2 g = dot(a, a) < dot(b, b) ? a : b;
        cel = p - g; f = g / r + 0.5;
    } else if (u.shape == 2) {
        float linha = floor(p.y);
        float2 q = float2(p.x + (fmod(linha, 2.0) == 0.0 ? 0.0 : 0.5), p.y);
        cel = floor(q) + 0.5 - float2(fmod(linha, 2.0) == 0.0 ? 0.0 : 0.5, 0.0); f = fract(q);
    } else {
        cel = floor(p) + 0.5; f = fract(p);
    }
    float2 q = (sp_rot(cel * s, u.rotate * 0.0174533) + res * 0.5) / res;
    float4 c = inputImg.sample(__nv_smp, clamp(q, 0.0, 1.0));
    float borda = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
    if (u.edgeWidth > 0.0 && borda < u.edgeWidth * 0.5) c.rgb = u.edgeColor.rgb * c.a;
    return c;
}
