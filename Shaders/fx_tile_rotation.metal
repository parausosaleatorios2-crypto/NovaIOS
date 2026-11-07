// ---------------------------------------------------------------------------
// Ladrilho com rotação
// origem : assets/effects/tile-rotation.xml
// id     : nova.effect.tilerotation
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tile_rotationParams {
    float countX;
    float countY;
    float rotationAmount;
    float offsetAmount;
    float scaleAmount;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash(float2 p, float semente) {
    return fract(sin(dot(p, float2(127.1, 311.7)) + semente * 43.71) * 43758.5453);
}

fragment float4 fx_tile_rotation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tile_rotationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 counts = float2(max(u.countX, 1.0), max(u.countY, 1.0));
    float2 grid = in.acScreenNorm * counts;
    float2 cell = floor(grid);
    float2 local = fract(grid) - 0.5; // -0.5..0.5, centralizado na própria célula

    float anguloAleatorio = (hash(cell, u.seed) - 0.5) * 2.0 * radians(u.rotationAmount);
    float2 deslocAleatorio = float2(
        hash(cell + float2(17.0, 0.0), u.seed) - 0.5,
        hash(cell + float2(0.0, 29.0), u.seed) - 0.5
    ) * u.offsetAmount;
    float escalaAleatoria = 1.0 + (hash(cell + float2(41.0, 5.0), u.seed) - 0.5) * 2.0 * u.scaleAmount;

    // A volta: desfaz o giro e a escala DESTA célula, pra achar de onde a
    // amostra deveria vir na imagem original.
    float c = cos(-anguloAleatorio);
    float s = sin(-anguloAleatorio);
    float2 local2 = float2x2(c, -s, s, c) * (local / max(escalaAleatoria, 0.05)) - deslocAleatorio;

    float2 uv = (cell + local2 + 0.5) / counts;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        __nv_out = float4(0.0);
        return __nv_out;
    }

    __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
