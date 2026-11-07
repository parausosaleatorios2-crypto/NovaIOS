// ---------------------------------------------------------------------------
// Cortina linear
// origem : assets/effects/linear-wipe.xml
// id     : nova.effect.linearwipe
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct linear_wipeParams {
    float completion;
    float angle;
    float feather;
    int invertWipe;
};

fragment float4 fx_linear_wipe(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant linear_wipeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float rad = radians(u.angle);
    float2 axis = float2(cos(rad), sin(rad));
    float2 centred = (in.acScreenNorm - 0.5) * float2(eng.acAspect, 1.0);

    // O alcance do retângulo naquela direção. Sem normalizar por ele, a mesma
    // porcentagem revelaria mais na diagonal que na horizontal — e a cortina
    // pareceria acelerar sozinha ao girar o ângulo.
    float support = max(0.5 * (eng.acAspect * abs(axis.x) + abs(axis.y)), 0.0001);
    float position = (dot(centred, axis) + support) / (2.0 * support);

    float cut = u.completion * 0.01;
    float soft = max(u.feather, 0.0005);
    float mask = smoothstep(cut - soft, cut + soft, position);

    if (u.invertWipe) mask = 1.0 - mask;

    __nv_out = float4(color.rgb, color.a * mask);
    return __nv_out;
}
