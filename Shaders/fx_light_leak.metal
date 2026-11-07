// ---------------------------------------------------------------------------
// Vazamento de luz
// origem : assets/effects/light-leak.xml
// id     : nova.effect.light-leak
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct light_leakParams {
    float2 sourceAt;
    float4 leakColor;
    float intensity;
    float spread;
    float breathe;
    float speed;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash1(float x) {
    return fract(sin(x * 127.1 + float(u.seed) * 13.7) * 43758.5453);
}

/** Ruído suave 1D (interpolação smoothstep entre hashes). */
float ruido1(float x) {
    float i = floor(x);
    float f = fract(x);
    float s = f * f * (3.0 - 2.0 * f);
    return mix(hash1(i), hash1(i + 1.0), s);
}

fragment float4 fx_light_leak(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant light_leakParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // A fonte "respira" andando devagar num círculo pequeno.
    float t = eng.acTime * u.speed;
    float2 andanca = float2(ruido1(t * 0.37 + 1.3) - 0.5, ruido1(t * 0.41 + 7.7) - 0.5);
    float2 fonte = u.sourceAt + andanca * 0.08;
    fonte = float2(fonte.x * eng.acAspect, fonte.y);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float d = length(p - fonte);

    // Gradiente radial exponencial: luz forte perto, desvanece longe.
    float gradiente = exp(-d / max(u.spread, 1e-4));

    // Respirar: a intensidade oscila devagar.
    float pulsacao = mix(1.0, 0.5 + 0.5 * ruido1(t * 0.9 + 2.7), u.breathe);

    float forca = gradiente * u.intensity * pulsacao * u.leakColor.a;

    float3 luz = u.leakColor.rgb * forca;

    // Mistura por SCREEN: 1 − (1−orig)(1−luz). Luz nunca escurece pixel claro.
    float3 cor = 1.0 - (1.0 - original.rgb) * (1.0 - luz);
    cor = mix(original.rgb, cor, clamp(forca, 0.0, 1.0));

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
