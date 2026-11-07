// ---------------------------------------------------------------------------
// Infravermelho
// origem : assets/effects/infrared.xml
// id     : nova.effect.infrared
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct infraredParams {
    float contrast;
    float bias;
    float strength;
    float saturation;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Rampa "inferno" aproximada em 5 pontos: preto-azul-roxo-vermelho-amarelo-branco. */
float3 rampaTermica(float t) {
    t = clamp(t, 0.0, 1.0);
    float3 c;
    if (t < 0.2)      c = mix(float3(0.0),              float3(0.1, 0.0, 0.5),  t / 0.2);
    else if (t < 0.4) c = mix(float3(0.1, 0.0, 0.5),    float3(0.6, 0.0, 0.5),  (t - 0.2) / 0.2);
    else if (t < 0.6) c = mix(float3(0.6, 0.0, 0.5),    float3(1.0, 0.2, 0.0),  (t - 0.4) / 0.2);
    else if (t < 0.8) c = mix(float3(1.0, 0.2, 0.0),    float3(1.0, 0.85, 0.0), (t - 0.6) / 0.2);
    else              c = mix(float3(1.0, 0.85, 0.0),   float3(1.0),            (t - 0.8) / 0.2);
    return c;
}

fragment float4 fx_infrared(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant infraredParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Temperatura é luma com contraste e viés aplicados.
    float T = luma(original.rgb);
    T = (T - 0.5) * u.contrast + 0.5 + u.bias;

    float3 termica = rampaTermica(T);

    // Saturação da rampa: mistura entre o cinza perceptual da rampa e ela mesma.
    float cinzaDaRampa = luma(termica);
    termica = mix(float3(cinzaDaRampa), termica, u.saturation);

    float3 cor = mix(original.rgb, termica, u.strength);
    __nv_out = float4(cor, original.a);
    return __nv_out;
}
