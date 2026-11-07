// ---------------------------------------------------------------------------
// Repetir
// origem : assets/effects/tile.xml
// id     : nova.effect.tile
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tileParams {
    float countX;
    float countY;
    int mirrored;
    float offsetX;
    float scroll;
};

fragment float4 fx_tile(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tileParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 counts = float2(max(u.countX, 1.0), max(u.countY, 1.0));
    float2 grid = in.acScreenNorm * counts;

    // Rolagem ligada ao tempo: padrão animado sem precisar de keyframe.
    grid.x += eng.acTime * u.scroll;

    float2 cell = floor(grid);

    // Deslocar as linhas ímpares transforma uma grade quadriculada num padrão
    // de tijolos. É a diferença entre "repetido" e "padrão".
    if (__nv_mod(cell.y, 2.0) > 0.5) {
        grid.x += u.offsetX;
        cell = floor(grid);
    }

    float2 uv = fract(grid);

    // Espelhar as células alternadas faz as bordas casarem: sem isso, a emenda
    // entre um ladrilho e o vizinho aparece como um corte duro.
    if (u.mirrored) {
        if (__nv_mod(cell.x, 2.0) > 0.5) uv.x = 1.0 - uv.x;
        if (__nv_mod(cell.y, 2.0) > 0.5) uv.y = 1.0 - uv.y;
    }

    __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
