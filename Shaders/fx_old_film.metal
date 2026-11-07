// ---------------------------------------------------------------------------
// Filme antigo
// origem : assets/effects/old-film.xml
// id     : nova.effect.old-film
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct old_filmParams {
    float sepiaMix;
    float grainStrength;
    float flickerStrength;
    float scratchCount;
    float scratchFreq;
    float seed;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_ARRANHOES = 12;

static float hash1(float x) {
    return fract(sin(x * 127.1 + float(u.seed) * 13.7) * 43758.5453);
}

static float hash2(float2 c) {
    return fract(sin(dot(c, float2(127.1, 311.7)) + float(u.seed) * 13.7) * 43758.5453);
}

/** A matriz clássica de sépia (Microsoft Office / IE "sepia" filter). */
static float3 sepia(float3 c) {
    float r = dot(c, float3(0.393, 0.769, 0.189));
    float g = dot(c, float3(0.349, 0.686, 0.168));
    float b = dot(c, float3(0.272, 0.534, 0.131));
    return float3(r, g, b);
}

fragment float4 fx_old_film(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant old_filmParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // 1. Sépia
    float3 cor = mix(original.rgb, sepia(original.rgb), u.sepiaMix);

    // 2. Grão: hash do pixel + tempo (o tempo faz o grão dançar).
    float grao = hash2(in.acScreenNorm * 1000.0 + float2(eng.acTime * 60.0)) - 0.5;
    cor += float3(grao) * u.grainStrength;

    // 3. Cintilação: brilho global oscila devagar.
    float bruxuleio = 1.0 + (hash1(floor(eng.acTime * 12.0)) - 0.5) * u.flickerStrength * 2.0;
    cor *= bruxuleio;

    // 4. Arranhões verticais: cada "quadro do projetor" (eng.acTime arredondado por u.scratchFreq)
    //    sorteia N posições; se o pixel está perto de alguma delas, risca.
    int n = clamp(int(u.scratchCount + 0.5), 0, MAXIMO_DE_ARRANHOES);
    float quadro = floor(eng.acTime * u.scratchFreq);
    float traco = 0.0;
    for (int k = 0; k < MAXIMO_DE_ARRANHOES; k++) {
        if (k >= n) break;
        float x = hash1(quadro * 97.0 + float(k) * 13.1);
        float largura = 0.0005 + 0.0015 * hash1(quadro * 7.0 + float(k) * 3.3);
        float distancia = abs(in.acScreenNorm.x - x);
        traco = max(traco, 1.0 - smoothstep(0.0, largura, distancia));
    }
    cor = mix(cor, float3(1.0), traco * 0.7);

    cor = clamp(cor, 0.0, 1.0);
    __nv_out = float4(cor, original.a);
    return __nv_out;
}
