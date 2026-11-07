// ---------------------------------------------------------------------------
// Onda de choque
// origem : assets/effects/shock-wave.xml
// id     : nova.effect.shock-wave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shock_waveParams {
    float2 centerAt;
    float speed;
    float period;
    float ringWidth;
    float strength;
    float4 ringColor;
    float ringGlow;
};

fragment float4 fx_shock_wave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shock_waveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Idade do anel dentro do ciclo atual (0 = acabou de nascer, u.period = acabou).
    float idade = fract(eng.acTime / max(u.period, 1e-4)) * u.period;
    float raio = idade * u.speed;

    // Força decai linear com a idade: nasce forte, some no fim.
    float forcaDoPulso = 1.0 - clamp(idade / max(u.period, 1e-4), 0.0, 1.0);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float2 centro = float2(u.centerAt.x * eng.acAspect, u.centerAt.y);
    float2 delta = p - centro;
    float d = length(delta);
    float2 direcao = d > 1e-4 ? delta / d : float2(0.0);

    // Pulso: proximidade da distância ao raio. Gaussiano no desvio.
    float proximidade = exp(-pow((d - raio) / max(u.ringWidth, 1e-4), 2.0));
    float empurrar = proximidade * u.strength * forcaDoPulso;

    float2 uvAfastado = in.acScreenNorm + direcao * empurrar;
    float4 cor = inputImg.sample(__nv_smp, uvAfastado);

    // Pinta o anel visível por cima (opcional via u.ringColor.a).
    float desenhoDoAnel = exp(-pow((d - raio) / max(u.ringWidth * 0.5, 1e-4), 2.0)) * forcaDoPulso;
    float3 halo = u.ringColor.rgb * desenhoDoAnel * u.ringGlow * u.ringColor.a;
    cor.rgb = 1.0 - (1.0 - cor.rgb) * (1.0 - halo);

    __nv_out = cor;
    return __nv_out;
}
