// ---------------------------------------------------------------------------
// Aparar recorte
// origem : assets/effects/choker.xml
// id     : nova.effect.choker
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct chokerParams {
    float amount;
    float quality;
    float softness;
};

// --- funcoes auxiliares do efeito
const int MAX_SAMPLES = 32;
const float TAU = 6.28318530718;

fragment float4 fx_choker(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant chokerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    if (u.amount == 0.0) {
        __nv_out = color;
        return __nv_out;
    }

    int samples = clamp(int(u.quality + 0.5), 4, MAX_SAMPLES);
    float radius = abs(u.amount);
    bool spreading = u.amount > 0.0;

    float extreme = color.a;
    float3 carried = color.rgb;

    for (int i = 0; i < MAX_SAMPLES; i++) {
        if (i >= samples) break;
        float angle = float(i) / float(samples) * TAU;
        // Em pixels da COMPOSIÇÃO (`eng.acEscalaDePixel`): a prévia reduzida fica do tamanho da exportação (0.516.0).
        float2 uv = in.acScreenNorm + float2(cos(angle), sin(angle)) * (radius * eng.acEscalaDePixel) * eng.acTexelSize;
        float4 texel = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));

        if (spreading) {
            if (texel.a > extreme) {
                extreme = texel.a;
                carried = texel.rgb;
            }
        } else {
            extreme = min(extreme, texel.a);
        }
    }

    float alpha = extreme;
    if (u.softness > 0.0) {
        alpha = smoothstep(0.5 - u.softness, 0.5 + u.softness, alpha);
    }

    // Ao aparar, a cor não muda: só some alfa. Ao espalhar, a cor vem da
    // amostra vencedora, senão a borda nova nasceria preta.
    __nv_out = float4(spreading ? carried : color.rgb, alpha);
    return __nv_out;
}
