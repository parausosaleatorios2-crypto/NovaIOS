// ---------------------------------------------------------------------------
// 4-Color Gradient (AE)
// origem : assets/effects/ae-4-color-gradient.xml
// id     : nova.effect.ae4colorgradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_4_color_gradientParams {
    float2 point1;
    float4 color1;
    float2 point2;
    float4 color2;
    float2 point3;
    float4 color3;
    float2 point4;
    float4 color4;
    float blend;
    float jitter;
    float opacity;
    int blendingMode;
};

// --- funcoes auxiliares do efeito
static float lum(float3 c) { return dot(c, float3(0.299, 0.587, 0.114)); }      // medido (0,30 / 0,59 / 0,11 erra 0,3 nível)

static float3 prenderCor(float3 c) {
    float l = lum(c), n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    if (n < 0.0) c = l + (c - l) * l / max(l - n, 1e-9);
    if (x > 1.0) c = l + (c - l) * (1.0 - l) / max(x - l, 1e-9);
    return c;
}

static float3 comLum(float3 c, float l) { return prenderCor(c + (l - lum(c))); }

static float sat(float3 c) { return max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b)); }

static float3 comSat(float3 c, float s) {
    float n = min(c.r, min(c.g, c.b)), x = max(c.r, max(c.g, c.b));
    return x > n ? (c - n) * s / (x - n) : float3(0.0);
}

static float3 luzSuave(float3 b, float3 s) {
    float3 d = mix(sqrt(b), ((16.0 * b - 12.0) * b + 4.0) * b, float3(lessThanEqual(b, float3(0.25))));
    return mix(b + (2.0 * s - 1.0) * (d - b), b - (1.0 - 2.0 * s) * b * (1.0 - b), float3(lessThanEqual(s, float3(0.5))));
}

static float3 subexpor(float3 b, float3 s) {          // Color Dodge
    return mix(min(float3(1.0), b / max(1.0 - s, float3(1e-9))), float3(1.0), float3(greaterThanEqual(s, float3(1.0))));
}

static float3 superexpor(float3 b, float3 s) {        // Color Burn
    return mix(1.0 - min(float3(1.0), (1.0 - b) / max(s, float3(1e-9))), float3(0.0), float3(lessThanEqual(s, float3(0.0))));
}

/** O resultado do modo `m` com as duas cores retas (b: a fonte, s: o gradiente). */
static float3 misturar(int m, float3 b, float3 s) {
    if (m == 3) return b * s;
    if (m == 4) return 1.0 - (1.0 - b) * (1.0 - s);
    if (m == 5) return mix(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, float3(lessThan(b, float3(0.5))));
    if (m == 6) return luzSuave(b, s);
    if (m == 7) return mix(1.0 - 2.0 * (1.0 - b) * (1.0 - s), 2.0 * b * s, float3(lessThan(s, float3(0.5))));
    if (m == 10) return min(b, s);
    if (m == 11) return max(b, s);
    if (m == 13) return b + s - 2.0 * b * s;
    if (m == 14) return comLum(comSat(s, sat(b)), lum(b));
    if (m == 15) return comLum(comSat(b, sat(s)), lum(b));
    if (m == 16) return comLum(s, lum(b));
    if (m == 17) return comLum(b, lum(s));
    return s;
}

static float sorteio(float2 p, float k) {
    float3 q = fract(float3(p.xyx) * float3(0.1031, 0.1030, 0.0973) + k);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

fragment float4 fx_ae_4_color_gradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_4_color_gradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    int2 pi = int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0));
    float4 fonte = inputImg.read(uint2(pi), uint(0));

    // Medido: peso = 1 / (distância² + Blend²), em px da composição, do canto do pixel.
    float2 p = float2(pi) / eng.acEscalaDePixel;
    float2 lado = float2(T) / eng.acEscalaDePixel;
    float b2 = u.blend * u.blend;
    float2 d1 = p - u.point1 * lado, d2 = p - u.point2 * lado, d3 = p - u.point3 * lado, d4 = p - u.point4 * lado;
    float w1 = 1.0 / (dot(d1, d1) + b2), w2 = 1.0 / (dot(d2, d2) + b2), w3 = 1.0 / (dot(d3, d3) + b2), w4 = 1.0 / (dot(d4, d4) + b2);
    float3 g = (u.color1.rgb * w1 + u.color2.rgb * w2 + u.color3.rgb * w3 + u.color4.rgb * w4) / (w1 + w2 + w3 + w4);

    // Medido: ruído uniforme de ± Jitter/100 níveis em cada canal.
    if (u.jitter > 0.0) {
        float3 r = float3(sorteio(float2(pi), 0.11), sorteio(float2(pi), 0.37), sorteio(float2(pi), 0.73)) * 2.0 - 1.0;
        g = clamp(g + r * (u.jitter / 100.0) / 255.0, 0.0, 1.0);
    }

    // O gradiente é uma camada com o alfa da fonte · Opacity (em passos de 1/256), posta sobre a fonte.
    float q = floor(clamp(u.opacity, 0.0, 100.0) * 2.56 + 1e-4) / 256.0;
    float ab = fonte.a, ag = ab * q;
    float3 cb = fonte.rgb, pb = cb * ab, ps = g * ag;
    float uni = ab + ag - ab * ag;
    int m = u.blendingMode;

    float3 cor;
    float alfa = uni;
    if (m == 0) { cor = ps; alfa = ag; }                                             // None: substitui a fonte
    else if (m == 2) cor = min(pb + ps, float3(uni));                                  // Add, Color Dodge e Difference: nas pré-multiplicadas
    else if (m == 8) cor = min(subexpor(pb, ps), float3(uni));
    else if (m == 12) cor = abs(pb - ps);
    else if (m == 9) cor = ab * superexpor(cb, 1.0 - (1.0 - g) * q) + (1.0 - ab) * ps;   // Color Burn: a Opacity clareia o gradiente
    else cor = (1.0 - ag) * pb + (1.0 - ab) * ps + ab * ag * clamp(misturar(m, cb, g), 0.0, 1.0);

    __nv_out = alfa > 0.0 ? float4(clamp(cor / alfa, 0.0, 1.0), alfa) : float4(0.0);
    return __nv_out;
}
