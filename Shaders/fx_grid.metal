// ---------------------------------------------------------------------------
// Grade
// origem : assets/effects/grid.xml
// id     : nova.effect.grid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gridParams {
    int gridOnly;
    float2 origin;
    float cells;
    float thickness;
    float subdivisions;
    float subOpacity;
    float4 lineColor;
};

// --- funcoes auxiliares do efeito
/**
 * A cobertura de uma linha de grade com `divisions` divisões.
 *
 * `fwidth` mede quanto a coordenada muda de um pixel para o vizinho. Dividir a
 * espessura por ele é o que faz a linha ter a MESMA grossura na tela em qualquer
 * densidade e em qualquer zoom — sem isso, uma grade fina desaparece num
 * aparelho de tela densa.
 */
float gridLines(float2 uv, float divisions, float width) {
    float2 scaled = uv * divisions;
    float2 distanceToLine = abs(fract(scaled) - 0.5) / max(fwidth(scaled), 0.0001);
    float nearest = min(distanceToLine.x, distanceToLine.y);
    return 1.0 - smoothstep(0.0, width, nearest);
}

fragment float4 fx_grid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gridParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 uv = (in.acScreenNorm - u.origin) * float2(eng.acAspect, 1.0);
    float divisions = max(u.cells, 1.0);

    float major = gridLines(uv, divisions, u.thickness);

    float minor = 0.0;
    int subs = clamp(int(u.subdivisions + 0.5), 0, 8);
    if (subs > 0) {
        minor = gridLines(uv, divisions * float(subs + 1), u.thickness * 0.6) * u.subOpacity;
    }

    float coverage = max(major, minor) * u.lineColor.a;
    float4 drawn = float4(u.lineColor.rgb, coverage);

    // O que está POR BAIXO da grade: a camada, ou nada. Com `u.gridOnly` a camada
    // é descartada e as linhas saem sobre transparência.
    float4 under = u.gridOnly ? float4(0.0) : original;

    // Composto sobre o que está por baixo, não misturado com ele: a grade é uma
    // coisa desenhada POR CIMA, e onde não há linha o que estava tem que continuar.
    float outAlpha = drawn.a + under.a * (1.0 - drawn.a);
    float3 outColor = outAlpha > 0.0
        ? (drawn.rgb * drawn.a + under.rgb * under.a * (1.0 - drawn.a)) / outAlpha
        : float3(0.0);

    __nv_out = float4(outColor, outAlpha);
    return __nv_out;
}
