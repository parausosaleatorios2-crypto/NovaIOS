// ---------------------------------------------------------------------------
// Inverter
// origem : assets/effects/invert.xml
// id     : nova.effect.invert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct invertParams {
    int space;
};

// --- funcoes auxiliares do efeito
static float3 toHsv(float3 c) {
    float maxC = max(c.r, max(c.g, c.b));
    float minC = min(c.r, min(c.g, c.b));
    float span = maxC - minC;

    float hue = 0.0;
    if (span > 0.00001) {
        if (maxC == c.r) {
            hue = __nv_mod((c.g - c.b) / span, 6.0);
        } else if (maxC == c.g) {
            hue = (c.b - c.r) / span + 2.0;
        } else {
            hue = (c.r - c.g) / span + 4.0;
        }
        hue /= 6.0;
    }
    return float3(hue, maxC > 0.0 ? span / maxC : 0.0, maxC);
}

static float3 toRgb(float3 hsv) {
    float3 k = __nv_mod(hsv.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0);
    float3 base = clamp(min(k, 4.0 - k), 0.0, 1.0);
    return hsv.z * mix(float3(1.0), base, hsv.y);
}

fragment float4 fx_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 flipped = color;

    if (u.space == 1) {
        flipped.r = 1.0 - color.r;
    } else if (u.space == 2) {
        flipped.g = 1.0 - color.g;
    } else if (u.space == 3) {
        flipped.b = 1.0 - color.b;
    } else if (u.space == 4) {
        flipped.a = 1.0 - color.a;
    } else if (u.space == 5) {
        // Inverte só o brilho e devolve a cor original em cima: o azul continua
        // azul, mas o que era escuro fica claro.
        float3 hsv = toHsv(color.rgb);
        hsv.z = 1.0 - hsv.z;
        flipped.rgb = toRgb(hsv);
    } else if (u.space == 6) {
        float3 hsv = toHsv(color.rgb);
        hsv.x = fract(hsv.x + 0.5);
        flipped.rgb = toRgb(hsv);
    } else {
        flipped.rgb = 1.0 - color.rgb;
    }

    __nv_out = flipped;
    return __nv_out;
}
