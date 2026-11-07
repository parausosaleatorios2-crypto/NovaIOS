// ---------------------------------------------------------------------------
// Cortina radial
// origem : assets/effects/radial-wipe.xml
// id     : nova.effect.radialwipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct radial_wipeParams {
    float completion;
    float2 center;
    float startAngle;
    int direction;
    float feather;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_radial_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant radial_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    // O -90° põe o zero no topo, como num relógio. Sem isso a varredura
    // começaria na direita, que não é onde ninguém espera.
    float angle = __nv_atan(offset.y, offset.x) - radians(u.startAngle) + TAU * 0.25;

    float position = fract(angle / TAU);
    if (u.direction == 1) {
        position = 1.0 - position;
    } else if (u.direction == 2) {
        // Abre para os dois lados ao mesmo tempo: a mesma fração de cada lado.
        position = abs(position * 2.0 - 1.0);
    }

    float cut = u.completion * 0.01;
    float soft = max(u.feather, 0.0005);
    float mask = smoothstep(cut - soft, cut + soft, position);

    __nv_out = float4(color.rgb, color.a * mask);
    return __nv_out;
}
