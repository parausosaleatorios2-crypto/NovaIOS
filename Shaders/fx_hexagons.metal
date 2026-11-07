// ---------------------------------------------------------------------------
// Hexágonos
// origem : assets/effects/hexagons.xml
// id     : nova.effect.hexagons
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct hexagonsParams {
    float cellSize;
    float rotation;
    float edgeWidth;
    float4 edgeColor;
};

// --- funcoes auxiliares do efeito
const float SQRT3 = 1.7320508;

fragment float4 fx_hexagons(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant hexagonsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float size = max(u.cellSize, 2.0) * eng.acEscalaDePixel;
    float2 metade = eng.acResolution * 0.5;

    float ang = radians(u.rotation);
    float2x2 turn = float2x2(cos(ang), -sin(ang), sin(ang), cos(ang));
    float2 p = turn * (in.acScreenNorm * eng.acResolution - metade) + metade;

    // Duas grades retangulares simples, uma deslocada meia célula da outra
    // nos dois eixos — a união das duas É uma grade hexagonal.
    float2 s = float2(size, size * SQRT3);
    float2 candidateA = (floor(p / s) + 0.5) * s;
    float2 q = p - s * 0.5;
    float2 candidateB = (floor(q / s) + 0.5) * s + s * 0.5;

    float dA = length(p - candidateA);
    float dB = length(p - candidateB);
    float2 center = dA < dB ? candidateA : candidateB;
    float bestDist = min(dA, dB);
    float secondDist = max(dA, dB);

    // Desgira o centro achado pra amostrar no lugar certo da imagem original.
    float2x2 turnBack = float2x2(cos(-ang), -sin(-ang), sin(-ang), cos(-ang));
    float2 centerScreen = turnBack * (center - metade) + metade;
    float4 hex = inputImg.sample(__nv_smp, clamp(centerScreen / eng.acResolution, 0.0, 1.0));

    if (u.edgeWidth > 0.0) {
        float border = smoothstep(0.0, max(u.edgeWidth, 0.001) * size, secondDist - bestDist);
        hex.rgb = mix(u.edgeColor.rgb, hex.rgb, border);
    }

    __nv_out = hex;
    return __nv_out;
}
