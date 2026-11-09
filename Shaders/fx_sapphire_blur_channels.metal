// ---------------------------------------------------------------------------
// S_BlurChannels (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-blur-channels.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_blur_channelsParams {
    float blurRed;
    float blurGreen;
    float blurBlue;
    float blurAlpha;
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

fragment float4 fx_sapphire_blur_channels(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_blur_channelsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float4 raios = float4(u.blurRed, u.blurGreen, u.blurBlue, u.blurAlpha);
    float4 soma = float4(0.0);
    const int N = 40;
    for (int i = 0; i < N; i++) {
        float t = (float(i) + 0.5) / float(N);
        float ang = float(i) * 2.39996323;
        float2 d = float2(cos(ang), sin(ang)) * sqrt(t) / res;
        soma.r += inputImg.sample(__nv_smp, uv + d * raios.r).r;
        soma.g += inputImg.sample(__nv_smp, uv + d * raios.g).g;
        soma.b += inputImg.sample(__nv_smp, uv + d * raios.b).b;
        soma.a += inputImg.sample(__nv_smp, uv + d * raios.a).a;
    }
    return soma / float(N);
}
