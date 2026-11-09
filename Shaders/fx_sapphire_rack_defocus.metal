// ---------------------------------------------------------------------------
// S_RackDefocus (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-rack-defocus.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_rack_defocusParams {
    float amount;
    int shape;
    float bokehBrightness;
    float bokehThreshold;
    float aspect;
    float rotate;
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

fragment float4 fx_sapphire_rack_defocus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_rack_defocusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float r = max(u.amount, 0.0);
    if (r < 0.5) return inputImg.sample(__nv_smp, uv);
    float lados = u.shape == 1 ? 6.0 : 8.0;
    float4 soma = float4(0.0); float pesos = 0.0;
    const int N = 96;
    for (int i = 0; i < N; i++) {
        float t = (float(i) + 0.5) / float(N);
        float ang = float(i) * 2.39996323;
        float2 d = float2(cos(ang), sin(ang)) * sqrt(t);
        if (u.shape > 0) {
            float a = atan2(d.y, d.x), setor = 6.2831853 / lados;
            float m = fmod(a + 62.831853 + setor * 0.5, setor) - setor * 0.5;
            d *= cos(setor * 0.5) / max(cos(m), 0.5);
        }
        d = sp_rot(d, u.rotate * 0.0174533);
        d.x *= u.aspect;
        float4 c = inputImg.sample(__nv_smp, uv + d * r / res);
        float w = 1.0 + u.bokehBrightness * sp_brilho(c, u.bokehThreshold);
        soma += c * w; pesos += w;
    }
    return soma / pesos;
}
