// ---------------------------------------------------------------------------
// Repetir em grade
// origem : assets/effects/repeat-grid.xml
// id     : nova.effect.repeat-grid
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct repeat_gridParams {
    float columns;
    float rows;
    float cellScale;
    float gap;
    float fade;
    float phase;
};

fragment float4 fx_repeat_grid(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant repeat_gridParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float colsF = max(float(int(u.columns + 0.5)), 1.0);
    float rowsF = max(float(int(u.rows + 0.5)), 1.0);
    float2 grade = float2(colsF, rowsF);

    // O pixel vira "coordenada de célula + fração dentro dela".
    float2 escalado = in.acScreenNorm * grade;
    float2 celula = floor(escalado);
    float2 dentro = fract(escalado);

    // O `u.gap` encolhe o UV útil da célula; o resto vira transparente (margem).
    float margem = clamp(u.gap * 0.5, -0.4, 0.4);
    float2 util = (dentro - margem) / max(1.0 - 2.0 * margem, 1e-4);
    if (any(lessThan(util, float2(0.0))) || any(greaterThan(util, float2(1.0)))) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    // Reescala em volta do meio da célula para `u.cellScale`.
    float2 uvNaCamada = (util - 0.5) / max(u.cellScale, 1e-4) + 0.5;
    if (any(lessThan(uvNaCamada, float2(0.0))) || any(greaterThan(uvNaCamada, float2(1.0)))) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    // Defasagem: cada célula puxa um instante diferente do conteúdo (preview estático
    // ignora `eng.acTime`, mas na timeline isso dá a onda clássica de grade animada).
    // Aqui só altera a opacidade pelo tempo, já que o conteúdo é UMA textura.
    float d = (celula.x + celula.y * colsF) / max(colsF * rowsF, 1.0);
    float fasador = 0.5 + 0.5 * cos(6.2831853 * (eng.acTime / max(u.phase, 1e-3) - d));
    float opacidadeDaFase = u.phase > 1e-3 ? mix(0.4, 1.0, fasador) : 1.0;

    // Esmaecer do centro para o canto: índice normalizado da célula.
    float2 centroCelula = (celula + 0.5) / grade - 0.5;
    float distanciaAoCentro = length(centroCelula) / 0.7071;
    float opacidadeDoFade = mix(1.0, 1.0 - clamp(distanciaAoCentro, 0.0, 1.0), u.fade);

    float4 c = inputImg.sample(__nv_smp, uvNaCamada);
    c *= opacidadeDaFase * opacidadeDoFade;

    __nv_out = c;
    return __nv_out;
}
