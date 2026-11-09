// ---------------------------------------------------------------------------
// S_EdgeRays (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-edge-rays.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_edge_raysParams {
    float2 center;
    float rayLength;
    float edgeThreshold;
    float brightness;
    float4 color;
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

fragment float4 fx_sapphire_edge_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_edge_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float4 src = inputImg.sample(__nv_smp, uv);
    float2 e = 1.5 / res;
    const int N = 48;
    float soma = 0.0, decai = 1.0;
    float2 passo = (u.center - uv) * u.rayLength / float(N);
    float2 p = uv;
    for (int i = 0; i < N; i++) {
        p += passo;
        float gx = sp_luma(inputImg.sample(__nv_smp, p + float2(e.x, 0)).rgb) - sp_luma(inputImg.sample(__nv_smp, p - float2(e.x, 0)).rgb);
        float gy = sp_luma(inputImg.sample(__nv_smp, p + float2(0, e.y)).rgb) - sp_luma(inputImg.sample(__nv_smp, p - float2(0, e.y)).rgb);
        soma += smoothstep(u.edgeThreshold, u.edgeThreshold + 0.2, length(float2(gx, gy))) * decai;
        decai *= 0.96;
    }
    float3 g = soma / float(N) * u.brightness * u.color.rgb;
    return float4(src.rgb + g, max(src.a, clamp(sp_luma(g), 0.0, 1.0)));
}
