// ---------------------------------------------------------------------------
// Sombras e luzes
// origem : assets/effects/shadow-highlight.xml
// id     : nova.effect.shadowhighlight
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct shadow_highlightParams {
    float shadows;
    float highlights;
};

// --- funcoes auxiliares do efeito
const float FIM_DA_SOMBRA = 0.4;
const float COMECO_DA_LUZ = 0.6;

fragment float4 fx_shadow_highlight(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant shadow_highlightParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));

    // Duas máscaras suaves, uma para cada ponta. `smoothstep` em vez de corte
    // seco: um limite duro deixaria uma linha visível atravessando o degradê da
    // imagem, exatamente onde a máscara termina.
    float shadowMask = 1.0 - smoothstep(0.0, FIM_DA_SOMBRA, luma);
    float highlightMask = smoothstep(COMECO_DA_LUZ, 1.0, luma);

    float3 result = color.rgb;
    // Levantar sombra puxando para o branco na proporção que falta: assim o
    // ajuste não pode estourar, porque ele nunca passa de 1.
    result += u.shadows * shadowMask * (1.0 - result) * 0.9;
    result -= u.highlights * highlightMask * result * 0.6;

    __nv_out = float4(clamp(result, 0.0, 1.0), color.a);
    return __nv_out;
}
