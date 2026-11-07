// ---------------------------------------------------------------------------
// Vinheta
// origem : assets/effects/vignette.xml
// id     : nova.effect.vignette
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct vignetteParams {
    float2 center;
    float radius;
    float softness;
    float amount;
    float4 tint;
};

fragment float4 fx_vignette(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant vignetteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // A correção por eng.acAspect é o que impede a vinheta de virar uma elipse
    // achatada num projeto 16:9. Sem ela, o círculo só fica redondo em
    // composição quadrada.
    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0) * 2.0;
    float dist = length(offset);

    float mask = 1.0 - smoothstep(u.radius, u.radius + u.softness, dist);
    float factor = mix(1.0, mask, u.amount);

    // Mistura em direção à cor escolhida, não multiplica. Assim dá para fazer
    // vinheta branca, azulada ou o que for — não só preta.
    __nv_out = float4(mix(u.tint.rgb, color.rgb, factor), color.a);
    return __nv_out;
}
