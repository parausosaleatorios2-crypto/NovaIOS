// ---------------------------------------------------------------------------
// S_JpegDamage (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-jpeg-damage.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_jpeg_damageParams {
    float blockSize;
    float quality;
    float chromaBlur;
    float flicker;
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

fragment float4 fx_sapphire_jpeg_damage(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_jpeg_damageParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float s = max(u.blockSize, 2.0);
    float2 cel = (floor(uv * res / s) + 0.5) * s / res;
    float2 celC = (floor(uv * res / (s * u.chromaBlur)) + 0.5) * s * u.chromaBlur / res;
    float4 c = inputImg.sample(__nv_smp, uv);
    float4 med = inputImg.sample(__nv_smp, cel);
    float4 cro = inputImg.sample(__nv_smp, celC);
    float niveis = mix(3.0, 48.0, u.quality);
    float tempo = floor(eng.acTime * 12.0);
    float fl = 1.0 + (sp_hash(floor(uv * res / s) + tempo) - 0.5) * u.flicker;
    float y = sp_luma(mix(med.rgb, c.rgb, u.quality * 0.6));
    y = floor(y * niveis * fl + 0.5) / niveis;
    float3 ch = cro.rgb - sp_luma(cro.rgb);
    ch = floor(ch * niveis * 0.5 + 0.5) / (niveis * 0.5);
    return float4(clamp(y + ch, 0.0, 1.0) * c.a, c.a);
}
