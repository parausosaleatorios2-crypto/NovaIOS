// ---------------------------------------------------------------------------
// S_Aurora (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-aurora.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_auroraParams {
    float4 color1;
    float4 color2;
    float intensity;
    float height;
    float speed;
    float scale;
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

fragment float4 fx_sapphire_aurora(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_auroraParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float4 src = inputImg.sample(__nv_smp, uv);
    float t = eng.acTime * u.speed;
    float3 acum = float3(0.0);
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float x = uv.x * 3.0 * u.scale + fi * 0.7;
        float onda = u.height + 0.08 * sin(x * 1.3 + t + fi) + 0.05 * (sp_ruido(float2(x * 2.0, t * 0.5 + fi)) - 0.5);
        float y = uv.y - onda + fi * 0.03;
        float faixa = exp(-max(y, 0.0) * 9.0) * smoothstep(-0.02, 0.01, y);
        float cortina = 0.5 + 0.5 * sp_ruido(float2(x * 8.0, t * 2.0 + fi * 3.0));
        acum += mix(u.color1.rgb, u.color2.rgb, fi / 5.0) * faixa * cortina;
    }
    float3 g = acum / 6.0 * u.intensity * 2.0;
    return float4(src.rgb + g, max(src.a, clamp(sp_luma(g), 0.0, 1.0)));
}
