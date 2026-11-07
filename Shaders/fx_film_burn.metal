// ---------------------------------------------------------------------------
// Queimadura de filme
// origem : assets/effects/film-burn.xml
// id     : nova.effect.film-burn
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct film_burnParams {
    float4 burnCore;
    float4 burnRing;
    float size;
    float intensity;
    float speed;
    float raggedness;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash1(float x) {
    return fract(sin(x * 127.1 + float(u.seed) * 13.7) * 43758.5453);
}

float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

float ruido2(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 s = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + float2(1.0, 0.0));
    float c = hash2(i + float2(0.0, 1.0));
    float d = hash2(i + float2(1.0, 1.0));
    return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

float fbm(float2 p) {
    float soma = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 4; i++) {
        soma += ruido2(p) * amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return soma;
}

fragment float4 fx_film_burn(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant film_burnParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // A queima anda de ponto em ponto — cada "estação" dura ~3 segundos.
    float estacao = floor(eng.acTime * u.speed * 0.3);
    float2 centro = float2(hash1(estacao + 1.3), hash1(estacao + 7.7));
    centro = float2(centro.x * eng.acAspect, centro.y);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);

    // Ruído distorce a borda: faz o círculo ter contorno irregular.
    float ruido = fbm(p * 8.0 + estacao * 13.0);
    float distorcao = (ruido - 0.5) * u.raggedness * u.size;

    float d = length(p - centro) + distorcao;

    // O miolo: tudo que está dentro do raio × 0.4.
    float miolo = 1.0 - smoothstep(u.size * 0.3, u.size * 0.5, d);
    // O anel: entre 0.4 e 1.0 do raio.
    float anel = (1.0 - smoothstep(u.size * 0.8, u.size * 1.1, d)) * smoothstep(u.size * 0.3, u.size * 0.6, d);

    // Fade na borda do take (o furo não cresce indefinidamente).
    float janela = 1.0 - smoothstep(u.size, u.size * 1.1, d);
    miolo *= janela;
    anel *= janela;

    float3 cor = original.rgb;
    // Anel: escurece pelo tom carbonizado.
    cor = mix(cor, u.burnRing.rgb, anel * u.burnRing.a * u.intensity * 0.8);
    // Miolo: adiciona luz amarela em screen (a brasa).
    float3 brasa = u.burnCore.rgb * miolo * u.intensity * u.burnCore.a;
    cor = 1.0 - (1.0 - cor) * (1.0 - brasa);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
