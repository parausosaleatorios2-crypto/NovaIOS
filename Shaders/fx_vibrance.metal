// ---------------------------------------------------------------------------
// Vibração
// origem : assets/effects/vibrance.xml
// id     : nova.effect.vibrance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct vibranceParams {
    float vibranceF;
    float saturationF;
    float skinProtect;
};

fragment float4 fx_vibrance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant vibranceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float maxC = max(color.r, max(color.g, color.b));
    float minC = min(color.r, min(color.g, color.b));
    float currentSaturation = maxC - minC;

    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));

    // Quanto mais saturado já está, menos recebe. É a definição de vibração.
    float weight = (1.0 - currentSaturation) * u.vibranceF;

    // Tons de pele ficam em torno do laranja. Sem esta proteção, aumentar a
    // vibração de um retrato deixa a pessoa cor de tijolo — e é a reclamação
    // número um de quem usa saturação sem pensar.
    if (u.skinProtect > 0.0 && color.r > color.g && color.g > color.b) {
        float skinness = clamp((color.r - color.b) * 2.0, 0.0, 1.0);
        weight *= 1.0 - skinness * u.skinProtect;
    }

    float3 result = mix(float3(luma), color.rgb, 1.0 + weight);
    result = mix(float3(dot(result, float3(0.299, 0.587, 0.114))), result, 1.0 + u.saturationF);

    __nv_out = float4(clamp(result, 0.0, 1.0), color.a);
    return __nv_out;
}
