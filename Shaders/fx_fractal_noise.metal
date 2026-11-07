// ---------------------------------------------------------------------------
// Ruído fractal
// origem : assets/effects/fractal-noise.xml
// id     : nova.effect.fractalnoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct fractal_noiseParams {
    float size;
    float octaves;
    float roughness;
    float evolution;
    float speed;
    float contrast;
    float brightness;
    int invertNoise;
    int ridged;
    float4 lowColor;
    float4 highColor;
};

// --- funcoes auxiliares do efeito
const int MAX_OCTAVES = 8;

// Hash sem textura: barato e igual em qualquer GPU. Uma tabela de permutação
// daria ruído de qualidade melhor, mas custaria uma textura extra por efeito.
static float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 cell = floor(p);
    float2 f = fract(p);
    // Suavização com curva S: sem ela as células do ruído aparecem como
    // losangos, porque a interpolação linear tem quina na fronteira.
    float2 w = f * f * (3.0 - 2.0 * f);

    float a = hash21(cell);
    float b = hash21(cell + float2(1.0, 0.0));
    float c = hash21(cell + float2(0.0, 1.0));
    float d = hash21(cell + float2(1.0, 1.0));

    return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

static float fbm(float2 p, int levels, float gain) {
    float sum = 0.0;
    float amplitude = 1.0;
    float norm = 0.0;

    for (int i = 0; i < MAX_OCTAVES; i++) {
        if (i >= levels) break;
        float n = valueNoise(p);
        if (u.ridged) {
            // Dobrar o ruído em torno do meio cria cristas afiadas em vez de
            // manchas macias. É o que dá cara de fumaça e de fogo.
            n = 1.0 - abs(n * 2.0 - 1.0);
        }
        sum += n * amplitude;
        norm += amplitude;
        p *= 2.0;
        amplitude *= gain;
    }

    return sum / max(norm, 0.0001);
}

fragment float4 fx_fractal_noise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant fractal_noiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = in.acScreenNorm * float2(eng.acAspect, 1.0) / max(u.size, 0.01) * 4.0;
    p += float2(u.evolution + eng.acTime * u.speed, u.evolution * 0.7);

    float n = fbm(p, clamp(int(u.octaves + 0.5), 1, MAX_OCTAVES), u.roughness);

    if (u.invertNoise) n = 1.0 - n;
    n = clamp((n - 0.5) * u.contrast + 0.5 + u.brightness, 0.0, 1.0);

    float3 tinted = mix(u.lowColor.rgb, u.highColor.rgb, n);
    float alpha = mix(u.lowColor.a, u.highColor.a, n);

    // O gerador respeita o alfa da camada: aplicado num sólido ele preenche
    // tudo, aplicado num texto ele preenche só as letras.
    __nv_out = float4(tinted, alpha * original.a);
    return __nv_out;
}
