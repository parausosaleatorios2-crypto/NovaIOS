// ---------------------------------------------------------------------------
// Invert (AE)
// origem : assets/effects/ae-invert.xml
// id     : nova.effect.aeinvert
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_invertParams {
    int channel;
    float blendWithOriginal;
};

// --- funcoes auxiliares do efeito
static float matizDe(float3 c, float mx, float d) {
    if (d < 1e-9) return 0.0;
    float h = mx == c.r ? __nv_mod((c.g - c.b) / d, 6.0) : (mx == c.g ? (c.b - c.r) / d + 2.0 : (c.r - c.g) / d + 4.0);
    return h / 6.0;
}

static float canalDoHls(float p, float q, float t) {
    t = fract(t);
    if (t < 1.0 / 6.0) return p + (q - p) * 6.0 * t;
    if (t < 0.5) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6.0;
    return p;
}

/** Matiz, claridade e CROMA (maior − menor canal) de volta para RGB. */
static float3 deHlc(float h, float l, float d) {
    float q = l + 0.5 * d, p = l - 0.5 * d;
    return float3(canalDoHls(p, q, h + 1.0 / 3.0), canalDoHls(p, q, h), canalDoHls(p, q, h - 1.0 / 3.0));
}

fragment float4 fx_ae_invert(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_invertParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 c = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float4 o = c;
    int k = u.channel;
    if (k == 0 || k == 8) o.rgb = 1.0 - c.rgb;
    else if (k == 1) o.r = 1.0 - c.r;
    else if (k == 2) o.g = 1.0 - c.g;
    else if (k == 3) o.b = 1.0 - c.b;
    else if (k >= 4 && k <= 7) {
        float mx = max(c.r, max(c.g, c.b)), mn = min(c.r, min(c.g, c.b));
        float d = mx - mn, l = 0.5 * (mx + mn), h = matizDe(c.rgb, mx, d);
        if (k == 4 || k == 5) h = fract(0.5 - h);
        if (k == 4 || k == 6) l = 1.0 - l;
        float teto = 1.0 - abs(2.0 * l - 1.0);
        d = min((k == 4 || k == 7) ? 1.0 - d : d, teto);
        o.rgb = deHlc(h, l, d);
    }
    else if (k == 9) o.rgb = c.rgb + (1.0 - 2.0 * dot(c.rgb, float3(0.299, 0.587, 0.114)));
    else if (k == 10) o.rgb = float3(dot(c.rgb, float3(-0.13937, 0.52492, 0.61442)), dot(c.rgb, float3(0.32419, 0.85063, -0.17484)), dot(c.rgb, float3(1.31888, -0.60762, 0.28872)));
    else if (k == 11) o.rgb = float3(dot(c.rgb, float3(0.73735, 0.64906, -0.38643)), dot(c.rgb, float3(0.27379, 0.32335, 0.40283)), dot(c.rgb, float3(-0.72089, 1.78160, -0.06072)));
    else o.a = 1.0 - c.a;
    o = clamp(o, 0.0, 1.0);
    __nv_out = mix(o, c, clamp(u.blendWithOriginal / 100.0, 0.0, 1.0));
    return __nv_out;
}
