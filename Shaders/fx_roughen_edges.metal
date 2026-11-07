// ---------------------------------------------------------------------------
// Bordas rasgadas
// origem : assets/effects/roughen-edges.xml
// id     : nova.effect.roughenedges
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct roughen_edgesParams {
    float border;
    float scale;
    float octaves;
    float sharpness;
    float evolution;
};

// --- funcoes auxiliares do efeito
const int MAX_OCTAVES = 8;

float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float valueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    float2 w = f * f * (3.0 - 2.0 * f);
    float a = hash21(cell);
    float b = hash21(cell + float2(1.0, 0.0));
    float c = hash21(cell + float2(0.0, 1.0));
    float d = hash21(cell + float2(1.0, 1.0));
    return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

float fbm(float2 p, int levels) {
    float sum = 0.0;
    float amplitude = 1.0;
    float norm = 0.0;
    for (int i = 0; i < MAX_OCTAVES; i++) {
        if (i >= levels) break;
        sum += valueNoise(p) * amplitude;
        norm += amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return sum / max(norm, 0.0001);
}

fragment float4 fx_roughen_edges(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant roughen_edgesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int levels = clamp(int(u.octaves + 0.5), 1, MAX_OCTAVES);

    float2 p = in.acScreenNorm * float2(eng.acAspect, 1.0) / max(u.scale, 0.01) * 12.0 + float2(u.evolution);
    float2 shift = float2(
        fbm(p, levels) - 0.5,
        fbm(p + float2(19.3, 7.7), levels) - 0.5
    ) * u.border * eng.acEscalaDePixel * eng.acTexelSize * 2.0;

    // Empurrar a amostragem e depois cortar o alfa de novo é o que rasga a
    // borda. No meio da camada o alfa já é 1, então o empurrão não aparece — o
    // efeito se concentra sozinho onde existe transição.
    float4 color = inputImg.sample(__nv_smp, clamp(in.acScreenNorm + shift, 0.0, 1.0));
    float alpha = smoothstep(0.5 - u.sharpness, 0.5 + u.sharpness, color.a);

    __nv_out = float4(color.rgb, alpha);
    return __nv_out;
}
