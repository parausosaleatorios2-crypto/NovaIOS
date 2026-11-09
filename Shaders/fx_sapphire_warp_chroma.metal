// ---------------------------------------------------------------------------
// S_WarpChroma (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-warp-chroma.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_warp_chromaParams {
    float2 center;
    float amount;
    int mode;
    float samples;
    float saturation;
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

fragment float4 fx_sapphire_warp_chroma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_warp_chromaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    int n = clamp(int(u.samples), 3, 48);
    float2 dir;
    if (u.mode == 2) dir = float2(1.0, 0.0) * u.amount / res;
    else if (u.mode == 3) dir = float2(0.0, 1.0) * u.amount / res;
    else if (u.mode == 1) dir = (uv - u.center) * u.amount * 0.01;
    else dir = (uv - u.center) * length((uv - u.center) * res) / max(res.x, res.y) * u.amount * 0.02;
    float4 soma = float4(0.0); float3 pesos = float3(0.0);
    for (int i = 0; i < n; i++) {
        float t = float(i) / float(n - 1);
        float3 w = mix(float3(1.0 / 3.0), sp_espectro(t), u.saturation);
        float4 c = inputImg.sample(__nv_smp, uv - dir * (t - 0.5));
        soma.rgb += c.rgb * w; soma.a += c.a / float(n); pesos += w;
    }
    return float4(soma.rgb / max(pesos, float3(1e-4)), soma.a);
}
