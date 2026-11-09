// ---------------------------------------------------------------------------
// S_Glare (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-glare.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_glareParams {
    float threshold;
    float brightness;
    float size;
    float rotate;
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

fragment float4 fx_sapphire_glare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_glareParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float4 src = inputImg.sample(__nv_smp, uv);
    float3 soma = float3(0.0);
    for (int r = 0; r < 4; r++) {
        float a = u.rotate * 0.0174533 + 1.5707963 * float(r);
        float2 d = float2(cos(a), sin(a)) * u.size / res;
        for (int k = 1; k <= 20; k++) {
            float t = float(k) / 20.0;
            float4 c = inputImg.sample(__nv_smp, uv - d * t);
            soma += c.rgb * sp_brilho(c, u.threshold) * (1.0 - t) * (1.0 - t);
        }
    }
    float3 halo = float3(0.0);
    for (int i = 0; i < 24; i++) {
        float ang = float(i) * 2.39996323, t = sqrt((float(i) + 0.5) / 24.0);
        float4 c = inputImg.sample(__nv_smp, uv + float2(cos(ang), sin(ang)) * t * u.size * 0.3 / res);
        halo += c.rgb * sp_brilho(c, u.threshold);
    }
    float3 g = (soma / 20.0 + halo / 24.0) * u.brightness * u.color.rgb;
    return float4(src.rgb + g, max(src.a, clamp(sp_luma(g), 0.0, 1.0)));
}
