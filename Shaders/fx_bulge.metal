// ---------------------------------------------------------------------------
// Esferizar
// origem : assets/effects/bulge.xml
// id     : nova.effect.bulge
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bulgeParams {
    float2 center;
    float radius;
    float strength;
};

fragment float4 fx_bulge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bulgeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A correção de proporção é o que mantém a lente REDONDA num projeto 16:9.
    // Sem ela o efeito vira uma elipse achatada.
    float2 p = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float dist = length(p);

    if (dist >= u.radius || u.radius <= 0.0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    float ratio = dist / u.radius;

    // A curva `pow` faz a distorção ser forte no centro e ir a zero na borda do
    // raio. Um fator linear deixaria uma emenda visível no limite do círculo.
    float factor = pow(ratio, 1.0 + u.strength);

    float2 warped = p * (factor / max(ratio, 0.0001));
    float2 uv = u.center + warped / float2(eng.acAspect, 1.0);

    __nv_out = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
    return __nv_out;
}
