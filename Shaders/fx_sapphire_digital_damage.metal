// ---------------------------------------------------------------------------
// S_DigitalDamage (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-digital-damage.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_digital_damageParams {
    float amount;
    float blockSize;
    float speed;
    float shift;
    float colorSplit;
    float seed;
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

fragment float4 fx_sapphire_digital_damage(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_digital_damageParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float t = floor(eng.acTime * u.speed) + u.seed;
    float2 bloco = floor(uv * res / float2(u.blockSize * 3.0, u.blockSize));
    float h = sp_hash(bloco + t * 1.37);
    float on = step(1.0 - u.amount, h);
    float2 desl = float2((sp_hash(bloco + t) - 0.5) * u.shift, 0.0) * on / res;
    float linha = step(0.985 - u.amount * 0.05, sp_hash(float2(floor(uv.y * res.y * 0.5), t)));
    desl.x += linha * (sp_hash(float2(t, uv.y)) - 0.5) * u.shift * 0.5 / res.x;
    float split = u.colorSplit * on / res.x;
    float4 c;
    c.r = inputImg.sample(__nv_smp, uv + desl + float2(split, 0)).r;
    float4 m = inputImg.sample(__nv_smp, uv + desl);
    c.g = m.g; c.a = m.a;
    c.b = inputImg.sample(__nv_smp, uv + desl - float2(split, 0)).b;
    if (on > 0.5 && sp_hash(bloco + t * 3.1) > 0.8) c.rgb = float3(1.0) - c.rgb;     // blocos invertidos
    return c;
}
