// ---------------------------------------------------------------------------
// S_Glint (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-glint.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_glintParams {
    float threshold;
    float brightness;
    float rays;
    float length;
    float rotate;
    float4 color;
    float twinkle;
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

fragment float4 fx_sapphire_glint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_glintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float4 src = inputImg.sample(__nv_smp, uv);
    int raios = clamp(int(u.rays), 2, 16);
    float3 soma = float3(0.0);
    const int PASSOS = 24;
    for (int r = 0; r < 16; r++) {
        if (r >= raios) break;
        float a = u.rotate * 0.0174533 + 6.2831853 * float(r) / float(raios);
        float2 d = float2(cos(a), sin(a)) * u.length / res;
        for (int k = 1; k <= PASSOS; k++) {
            float t = float(k) / float(PASSOS);
            float4 c = inputImg.sample(__nv_smp, uv - d * t);
            float q = (1.0 - t); q *= q;
            soma += c.rgb * sp_brilho(c, u.threshold) * q;
        }
    }
    float tw = 1.0 - u.twinkle * (0.5 + 0.5 * sin(eng.acTime * 9.0 + sp_hash(floor(uv * 40.0)) * 6.28));
    float3 g = soma / float(PASSOS) * u.brightness * u.color.rgb * tw;
    return float4(src.rgb + g, max(src.a, clamp(sp_luma(g), 0.0, 1.0)));
}
