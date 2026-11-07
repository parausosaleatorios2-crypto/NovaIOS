// ---------------------------------------------------------------------------
// Tingir sombras e luzes
// origem : assets/effects/split-tone.xml
// id     : nova.effect.split-tone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct split_toneParams {
    float4 shadowColor;
    float4 highlightColor;
    float shadowAmount;
    float highlightAmount;
    float balance;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

/** Soft-light (CSS/SVG definition): preserva contraste melhor que mix normal. */
float3 softLight(float3 baixa, float3 alta) {
    float3 d = mix(sqrt(baixa) * (2.0 * alta - 1.0) + 2.0 * baixa * (1.0 - alta),
                 2.0 * baixa * alta + baixa * baixa * (1.0 - 2.0 * alta),
                 step(alta, float3(0.5)));
    return d;
}

fragment float4 fx_split_tone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant split_toneParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float L = luma(original.rgb);

    // Forças: alta em sombras pra cor de sombra, alta em luzes pra cor de luz.
    float forcaSombra = (1.0 - smoothstep(0.0, u.balance, L)) * u.shadowAmount;
    float forcaLuz = smoothstep(u.balance, 1.0, L) * u.highlightAmount;

    // Cada ponta pinta por soft-light; a mistura entre elas é por força.
    float3 comSombra = softLight(original.rgb, u.shadowColor.rgb);
    float3 comLuz = softLight(original.rgb, u.highlightColor.rgb);

    float3 cor = original.rgb;
    cor = mix(cor, comSombra, forcaSombra * u.shadowColor.a);
    cor = mix(cor, comLuz, forcaLuz * u.highlightColor.a);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
