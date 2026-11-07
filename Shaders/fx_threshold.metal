// ---------------------------------------------------------------------------
// Threshold
// origem : assets/effects/threshold.xml
// id     : nova.effect.threshold
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct thresholdParams {
    float level;
    float softness;
    float4 darkColor;
    float4 lightColor;
};

// --- funcoes auxiliares do efeito
// A luminância do Threshold do After Effects em 8 bits: 0,299 / 0,587 / 0,114 em ponto fixo de 15 bits.
static int luminanciaDoAe(int3 n) {
    return (9798 * n.r + 19235 * n.g + 3735 * n.b + 16384) >> 15;
}

fragment float4 fx_threshold(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant thresholdParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float mask;
    if (u.softness <= 0.0) {
        // O corte seco do AE, em NÍVEIS inteiros (0..255): branco quando a luminância passa do Level truncado.
        int3 n = int3(floor(clamp(color.rgb, 0.0, 1.0) * 255.0 + 0.5));
        float x = u.level * 255.0;
        // Level inteiro (o caso de quase sempre): não fica à mercê do arredondamento da conta acima na GPU.
        float perto = floor(x + 0.5);
        if (abs(x - perto) < 0.0001) x = perto;
        int limiar = x < 0.0 ? 0 : min(255, int(floor(x)) + 1);
        mask = luminanciaDoAe(n) >= limiar ? 1.0 : 0.0;
    } else {
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        mask = smoothstep(u.level - u.softness, u.level + u.softness, luma);
    }
    float3 result = mix(u.darkColor.rgb, u.lightColor.rgb, mask);

    __nv_out = float4(result, color.a);
    return __nv_out;
}
