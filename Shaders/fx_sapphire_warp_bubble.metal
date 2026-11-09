// ---------------------------------------------------------------------------
// S_WarpBubble (estilo Sapphire, NovaEditor iOS)
// origem : Resources/effects/sapphire-warp-bubble.xml
// Escrito a mao (gerado por gerar_sapphire.py); a ordem dos campos e a do XML.
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sapphire_warp_bubbleParams {
    float amplitude;
    float frequency;
    float frequencyRelX;
    float octaves;
    float seed;
    float rotateWarpDir;
    float shiftStartX;
    float shiftStartY;
    float shiftSpeedX;
    float shiftSpeedY;
    float zDist;
    int wrapX;
    int wrapY;
    int useFilter;
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

fragment float4 fx_sapphire_warp_bubble(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sapphire_warp_bubbleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float2 uv = in.acScreenNorm;
    float2 res = max(eng.acScreenSize, float2(1.0));
    float2 pp = uv * res + float2(u.shiftStartX, u.shiftStartY) + float2(u.shiftSpeedX, u.shiftSpeedY) * eng.acTime;
    float f = max(u.frequency, 0.01) / max(res.x, 1.0) * 4.0;
    float2 p = pp * float2(f * u.frequencyRelX, f) / max(u.zDist, 0.001) + u.seed * 13.7;
    float2 d = float2(0.0); float amp = 1.0, tot = 0.0;
    for (int o = 0; o < 10; o++) {
        if (o >= int(u.octaves)) break;
        d += amp * float2(sp_ruido(p), sp_ruido(p + float2(31.7, 11.3)));
        tot += amp; amp *= 0.5; p *= 2.0;
    }
    d = sp_rot(d / tot - 0.5, u.rotateWarpDir * 0.0174533);
    float2 q = uv + d * u.amplitude * 2.0 * res.x / max(u.frequency, 0.01) / res;
    if (u.wrapX == 1) q.x = fract(q.x); else if (u.wrapX == 2) q.x = abs(fract(q.x * 0.5) * 2.0 - 1.0);
    if (u.wrapY == 1) q.y = fract(q.y); else if (u.wrapY == 2) q.y = abs(fract(q.y * 0.5) * 2.0 - 1.0);
    if (u.wrapX == 0 && (q.x < 0.0 || q.x > 1.0)) return float4(0.0);
    if (u.wrapY == 0 && (q.y < 0.0 || q.y > 1.0)) return float4(0.0);
    return inputImg.sample(__nv_smp, q);
}
