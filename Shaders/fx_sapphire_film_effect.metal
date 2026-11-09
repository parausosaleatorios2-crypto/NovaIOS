// ---------------------------------------------------------------------------
// S_FilmEffect (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-film-effect.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_film_effectParams {
    float grain;
    float grainSize;
    float halation;
    float vignette;
    float flicker;
    float scratches;
    float4 tint;
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

fragment float4 fx_sapphire_film_effect(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_film_effectParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float4 src = inputImg.sample(__nv_smp, uv);
    float3 c = src.rgb;
    // halacao: o vermelho das luzes vaza em volta
    float3 h = float3(0.0);
    for (int i = 0; i < 16; i++) {
        float ang = float(i) * 2.39996323, t = sqrt((float(i) + 0.5) / 16.0);
        float4 s = inputImg.sample(__nv_smp, uv + float2(cos(ang), sin(ang)) * t * 18.0 / res);
        h += s.rgb * sp_brilho(s, 0.6);
    }
    c += h / 16.0 * float3(1.0, 0.35, 0.15) * u.halation;
    float tq = floor(eng.acTime * 24.0);
    c *= 1.0 + (sp_hash(float2(tq, 3.7)) - 0.5) * u.flicker;
    float g = sp_hash(floor(uv * res / u.grainSize) + tq * 7.31) - 0.5;
    c += g * u.grain * 0.35;
    float2 v = (uv - 0.5) * float2(res.x / res.y, 1.0);
    c *= 1.0 - u.vignette * smoothstep(0.35, 1.1, length(v));
    float xs = sp_hash(float2(tq, 1.1));
    if (xs < u.scratches) {
        float pos = sp_hash(float2(tq, 2.2));
        c = mix(c, float3(0.9), (1.0 - smoothstep(0.0, 1.5 / res.x, abs(uv.x - pos))) * 0.6);
    }
    c *= mix(float3(1.0), u.tint.rgb, 0.6);
    return float4(clamp(c, 0.0, 1.0) * (src.a > 0.0 ? 1.0 : 0.0), src.a);
}
