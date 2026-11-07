// ---------------------------------------------------------------------------
// Painel de LED
// origem : assets/effects/dot-matrix.xml
// id     : nova.effect.dotmatrix
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct dot_matrixParams {
    float ledSize;
    float gap;
    int rgbSubpixels;
    int roundLeds;
    float glowF;
    float4 panelColor;
};

fragment float4 fx_dot_matrix(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant dot_matrixParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float size = max(u.ledSize, 2.0);
    float2 grid = eng.acResolution / size;
    float2 cell = floor(in.acScreenNorm * grid);
    float2 local = fract(in.acScreenNorm * grid);

    // A cor do LED vem do centro da célula: um LED tem uma cor só.
    float4 source = inputImg.sample(__nv_smp, clamp((cell + 0.5) / grid, 0.0, 1.0));

    float3 emitted = source.rgb;
    if (u.rgbSubpixels) {
        // Cada terço horizontal da célula acende um canal. É como um telão de
        // verdade funciona, e de longe o olho volta a somar as três cores.
        float third = floor(local.x * 3.0);
        float3 pick = float3(
            third < 0.5 ? 1.0 : 0.0,
            (third >= 0.5 && third < 1.5) ? 1.0 : 0.0,
            third >= 1.5 ? 1.0 : 0.0
        );
        emitted = source.rgb * pick * 3.0;
    }

    // O vão. `u.roundLeds` troca a distância de Chebyshev (quadrado) pela
    // euclidiana (círculo) — a mesma conta, outra norma.
    float2 fromCentre = abs(local - 0.5) * 2.0;
    float distanceToEdge = u.roundLeds ? length(fromCentre) : max(fromCentre.x, fromCentre.y);
    float lit = 1.0 - smoothstep(1.0 - u.gap - 0.08, 1.0 - u.gap, distanceToEdge);

    // Brilho estoura o vão: um LED muito aceso vaza para o vizinho, e sem isso
    // a imagem clara fica com a mesma cara da escura.
    float luma = dot(source.rgb, float3(0.299, 0.587, 0.114));
    lit = clamp(lit + luma * u.glowF * (1.0 - lit), 0.0, 1.0);

    float3 result = mix(u.panelColor.rgb, clamp(emitted, 0.0, 1.0), lit);
    __nv_out = float4(result, source.a);
    return __nv_out;
}
