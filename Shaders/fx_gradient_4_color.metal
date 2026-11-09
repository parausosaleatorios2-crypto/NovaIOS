// ---------------------------------------------------------------------------
// Gradiente de 4 cores
// origem : assets/effects/gradient-4-color.xml
// id     : nova.effect.gradient4color
// passes : 1
// Escrito a mao (base do glsl2msl.py + mesclagem e opacidade do iOS)
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gradient_4_colorParams {
    float2 point1;
    float4 color1;
    float2 point2;
    float4 color2;
    float2 point3;
    float4 color3;
    float2 point4;
    float4 color4;
    float sharpness;
    float scatter;
    float opacity;
    int blendingMode;
};

static float g4_lum(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }
static float3 g4_clip(float3 c) {
    float l = g4_lum(c), n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + (c - l) * l / max(l - n, 1e-6);
    if (x > 1.0) c = l + (c - l) * (1.0 - l) / max(x - l, 1e-6);
    return c;
}
static float3 g4_comLum(float3 c, float l) { return g4_clip(c + (l - g4_lum(c))); }
static float g4_sat(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }
static float3 g4_comSat(float3 c, float s) {
    float n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    return x > n ? (c - n) * s / (x - n) : float3(0.0);
}
// m: 1 Normal, 2 Add, 3 Multiply, 4 Screen, 5 Overlay, 6 Soft Light, 7 Hard Light,
// 8 Color Dodge, 9 Color Burn, 10 Darken, 11 Lighten, 12 Difference, 13 Exclusion,
// 14 Hue, 15 Saturation, 16 Color, 17 Luminosity
static float3 g4_misturar(int m, float3 b, float3 s) {
    switch (m) {
    case 2: return min(b + s, 1.0);
    case 3: return b * s;
    case 4: return 1.0 - (1.0 - b) * (1.0 - s);
    case 5: return select(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, b < 0.5);
    case 6: {
        float3 d = select(sqrt(b), ((16.0 * b - 12.0) * b + 4.0) * b, b <= 0.25);
        return select(b + (2.0 * s - 1.0) * (d - b), b - (1.0 - 2.0 * s) * b * (1.0 - b), s <= 0.5);
    }
    case 7: return select(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, s < 0.5);
    case 8: return select(min(1.0, b / max(1.0 - s, 1e-6)), float3(1.0), s >= 1.0);
    case 9: return select(1.0 - min(1.0, (1.0 - b) / max(s, 1e-6)), float3(0.0), s <= 0.0);
    case 10: return min(b, s);
    case 11: return max(b, s);
    case 12: return abs(b - s);
    case 13: return b + s - 2.0 * b * s;
    case 14: return g4_comLum(g4_comSat(s, g4_sat(b)), g4_lum(b));
    case 15: return g4_comLum(g4_comSat(b, g4_sat(s)), g4_lum(b));
    case 16: return g4_comLum(s, g4_lum(b));
    case 17: return g4_comLum(b, g4_lum(s));
    default: return s;
    }
}

// --- funcoes auxiliares do efeito
static float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

fragment float4 fx_gradient_4_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gradient_4_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 uv = in.acScreenNorm * float2(eng.acAspect, 1.0);

    float2 p1 = u.point1 * float2(eng.acAspect, 1.0);
    float2 p2 = u.point2 * float2(eng.acAspect, 1.0);
    float2 p3 = u.point3 * float2(eng.acAspect, 1.0);
    float2 p4 = u.point4 * float2(eng.acAspect, 1.0);

    // A faixa 1..8 é onde a transição continua macia (não vira um recorte
    // duro cedo demais), mas ainda dá pra sentir cada ponto dominando perto
    // de si quando `u.sharpness` sobe.
    float power = mix(1.0, 8.0, u.sharpness);

    float w1 = 1.0 / pow(max(distance(uv, p1), 0.0001), power);
    float w2 = 1.0 / pow(max(distance(uv, p2), 0.0001), power);
    float w3 = 1.0 / pow(max(distance(uv, p3), 0.0001), power);
    float w4 = 1.0 / pow(max(distance(uv, p4), 0.0001), power);
    float total = w1 + w2 + w3 + w4;

    float3 mixed = (u.color1.rgb * w1 + u.color2.rgb * w2 + u.color3.rgb * w3 + u.color4.rgb * w4) / total;

    // Mesmo espalhamento de `gradient-ramp.xml`: um ruído minúsculo antes de
    // arredondar quebra o banding de 8 bits num degradê suave.
    if (u.scatter > 0.0) {
        mixed += (hash21(in.acScreenNorm * eng.acResolution) - 0.5) * u.scatter;
    }
    mixed = clamp(mixed, 0.0, 1.0);

    // Mesclagem com a camada ("Nenhuma" = so o degrade, como antes).
    float op = clamp(u.opacity, 0.0, 100.0) / 100.0;
    if (u.blendingMode <= 0) {
        __nv_out = float4(mix(original.rgb, mixed, op), original.a);
    } else {
        float3 base = original.a > 0.0001 ? original.rgb / original.a : float3(0.0);
        float3 r = clamp(g4_misturar(u.blendingMode, base, mixed), 0.0, 1.0);
        __nv_out = float4(mix(base, r, op) * original.a, original.a);
    }
    return __nv_out;
}
