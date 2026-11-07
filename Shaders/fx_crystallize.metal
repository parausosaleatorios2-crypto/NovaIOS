// ---------------------------------------------------------------------------
// Cristalizar
// origem : assets/effects/crystallize.xml
// id     : nova.effect.crystallize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct crystallizeParams {
    float cellSize;
    float irregularity;
    float edgeWidth;
    float4 edgeColor;
};

// --- funcoes auxiliares do efeito
static float2 hash22(float2 p) {
    float n = sin(dot(p, float2(41.0, 289.0)));
    return fract(float2(262144.0, 32768.0) * n);
}

fragment float4 fx_crystallize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant crystallizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 scaled = in.acScreenNorm * eng.acResolution / (max(u.cellSize, 1.0) * eng.acEscalaDePixel);
    float2 cell = floor(scaled);
    float2 local = fract(scaled);

    float2 bestOffset = float2(0.0);
    float bestDistance = 8.0;
    float secondDistance = 8.0;

    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            float2 neighbour = float2(float(x), float(y));
            // Semente no meio da casa quando a irregularidade é 0 — e aí o
            // resultado degenera exatamente numa grade quadrada, o que é uma
            // saída útil e não um defeito.
            float2 seed = neighbour + mix(float2(0.5), hash22(cell + neighbour), u.irregularity);
            float d = length(seed - local);
            if (d < bestDistance) {
                secondDistance = bestDistance;
                bestDistance = d;
                bestOffset = seed;
            } else if (d < secondDistance) {
                secondDistance = d;
            }
        }
    }

    // A cor da célula vem do CENTRO dela, não do pixel atual: é isso que faz a
    // célula inteira ficar de uma cor só.
    float2 centreUv = (cell + bestOffset) * (max(u.cellSize, 1.0) * eng.acEscalaDePixel) / eng.acResolution;
    float4 crystal = inputImg.sample(__nv_smp, clamp(centreUv, 0.0, 1.0));

    if (u.edgeWidth > 0.0) {
        // A diferença entre a menor e a segunda menor distância é pequena
        // exatamente na fronteira entre duas células — é o jeito clássico de
        // achar a borda de um Voronoi sem calcular geometria nenhuma.
        float border = smoothstep(0.0, u.edgeWidth, secondDistance - bestDistance);
        crystal.rgb = mix(u.edgeColor.rgb, crystal.rgb, border);
    }

    __nv_out = crystal;
    return __nv_out;
}
