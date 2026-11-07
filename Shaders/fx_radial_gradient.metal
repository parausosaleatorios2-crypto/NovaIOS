// ---------------------------------------------------------------------------
// Gradiente radial
// origem : assets/effects/radial-gradient.xml
// id     : nova.effect.radial-gradient
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct radial_gradientParams {
    float2 centerAt;
    float4 innerColor;
    float4 outerColor;
    float innerRadius;
    float outerRadius;
    float power;
    float aspectMix;
    float blend;
};

fragment float4 fx_radial_gradient(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant radial_gradientParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Dois modos: u.aspectMix = 0 usa coordenada corrigida (círculo real),
    // u.aspectMix = 1 usa UV crua (elipse que segue a forma da tela).
    float2 delta = in.acScreenNorm - u.centerAt;
    float2 corrigido = delta * float2(mix(eng.acAspect, 1.0, u.aspectMix), 1.0);
    float d = length(corrigido);

    // Normaliza entre raio interno e externo; eleva à curva escolhida.
    float t = smoothstep(u.innerRadius, max(u.outerRadius, u.innerRadius + 1e-4), d);
    t = pow(t, max(u.power, 1e-4));

    float4 gradiente = mix(u.innerColor, u.outerColor, t);

    // Mistura por opacidade (do u.blend) e alfa da cor do gradiente.
    float3 cor = mix(original.rgb, gradiente.rgb, u.blend * gradiente.a);
    float alfa = mix(original.a, max(original.a, gradiente.a), u.blend);

    __nv_out = float4(cor, alfa);
    return __nv_out;
}
