// ---------------------------------------------------------------------------
// Plasma
// origem : assets/effects/plasma.xml
// id     : nova.effect.plasma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct plasmaParams {
    float scale;
    float speed;
    float colorShift;
    float blend;
};

// --- funcoes auxiliares do efeito
const float3 DEFASAGEM = float3(0.0, 2.094395, 4.188790); // 0°, 120°, 240°

/** Arco-íris suave de três cossenos defasados. */
static float3 arcoIris(float fase) {
    return 0.5 + 0.5 * cos(6.2831853 * fase + DEFASAGEM);
}

fragment float4 fx_plasma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant plasmaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y) * u.scale;
    float t = eng.acTime * u.speed;

    // Quatro senos: horizontal, vertical, diagonal, radial.
    float campo = sin(p.x + t)
                + sin(p.y + t * 1.3)
                + sin((p.x + p.y) * 0.7 + t * 0.9)
                + sin(length(p - u.scale * 0.5) + t * 1.5);

    // Normaliza o campo de [-4, 4] pra [0, 1] e envia pra rampa.
    float fase = campo * 0.125 + 0.5 + u.colorShift;
    float3 plasma = arcoIris(fase);

    float3 cor = mix(original.rgb, plasma, u.blend);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
