// ---------------------------------------------------------------------------
// Chuva
// origem : assets/effects/rain.xml
// id     : nova.effect.rain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct rainParams {
    float density;
    float speed;
    float streakLength;
    float wind;
    float thickness;
    float4 rainColor;
    float intensity;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

/** A distância de um ponto p ao segmento `a → b` (SDF 2D canônico). */
float distanciaAoSegmento(float2 p, float2 a, float2 b) {
    float2 pa = p - a;
    float2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-8), 0.0, 1.0);
    return length(pa - ba * h);
}

/** O traço de uma gota dentro de uma célula. Retorna a intensidade em `uvDaTela`. */
float gotaDaCelula(float2 celula, float2 uvDaTela, float t) {
    // Posição x da gota dentro da célula (hash estável).
    float xDaGota = hash2(celula + 0.1);
    float yFase = hash2(celula + 0.3);
    float tamanho = mix(0.5, 1.2, hash2(celula + 0.7));

    // Y cai no tempo, recomeça ao sair.
    float y = fract(yFase + t);
    float2 topoDaGota = float2(xDaGota, 1.0 - y);
    float2 baseDaGota = topoDaGota - float2(0.0, u.streakLength);

    // Vento inclina o segmento: gira em volta do topo.
    float a = radians(u.wind);
    float2 d = baseDaGota - topoDaGota;
    d = float2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a));
    baseDaGota = topoDaGota + d;

    float dist = distanciaAoSegmento(uvDaTela, topoDaGota, baseDaGota);
    float largura = 0.0015 * u.thickness * tamanho;
    return (1.0 - smoothstep(0.0, largura, dist)) * tamanho;
}

fragment float4 fx_rain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant rainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 grade = float2(u.density * 0.1, u.density * 0.3);
    float2 escalado = in.acScreenNorm * grade;
    float2 i = floor(escalado);
    float2 f = fract(escalado);
    float t = eng.acTime * u.speed;

    // Olha a célula atual + algumas vizinhas acima (o traço pode atravessar).
    float melhor = 0.0;
    for (int dy = 0; dy <= 2; dy++) {
        float2 celula = i + float2(0.0, float(dy));
        melhor = max(melhor, gotaDaCelula(celula, f - float2(0.0, float(dy)), t));
    }

    float alfa = clamp(melhor * u.intensity, 0.0, 1.0) * u.rainColor.a;

    float3 cor = mix(original.rgb, u.rainColor.rgb, alfa);
    float alfaFinal = max(original.a, alfa);

    __nv_out = float4(cor, alfaFinal);
    return __nv_out;
}
