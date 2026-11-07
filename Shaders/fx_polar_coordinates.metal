// ---------------------------------------------------------------------------
// Coordenadas polares
// origem : assets/effects/polar-coordinates.xml
// id     : nova.effect.polarcoordinates
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct polar_coordinatesParams {
    int direction;
    float2 center;
    float amount;
    float spin;
    float zoom;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_polar_coordinates(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant polar_coordinatesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 offset = (uv - u.center) * float2(eng.acAspect, 1.0) / max(u.zoom, 0.01);

    float2 warped;
    if (u.direction == 1) {
        // Polar para retangular: X vira ângulo, Y vira raio. Um retângulo
        // desenhado assim se abre em leque.
        float angle = (uv.x - 0.5) * TAU + radians(u.spin);
        float radius = uv.y * 0.5;
        warped = float2(cos(angle), sin(angle)) * radius / float2(eng.acAspect, 1.0) + u.center;
    } else {
        // Retangular para polar: o ângulo em volta do centro vira a coluna, e a
        // distância vira a linha. A borda de baixo da imagem fecha o círculo.
        float angle = __nv_atan(offset.y, offset.x) + radians(u.spin);
        float radius = length(offset) * 2.0;
        warped = float2(fract(angle / TAU + 0.5), clamp(radius, 0.0, 1.0));
    }

    float4 twisted = inputImg.sample(__nv_smp, clamp(warped, 0.0, 1.0));
    __nv_out = mix(inputImg.sample(__nv_smp, uv), twisted, u.amount);
    return __nv_out;
}
