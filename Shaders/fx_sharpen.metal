// ---------------------------------------------------------------------------
// Nitidez
// origem : assets/effects/sharpen.xml
// id     : nova.effect.sharpen
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct sharpenParams {
    float amount;
    float radius;
};

fragment float4 fx_sharpen(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant sharpenParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 offset = eng.acTexelSize * (u.radius * eng.acEscalaDePixel);
    float4 center = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Média dos quatro vizinhos = uma versão borrada barata da imagem.
    float3 blurred = (
        inputImg.sample(__nv_smp, in.acScreenNorm + float2( offset.x, 0.0)).rgb +
        inputImg.sample(__nv_smp, in.acScreenNorm + float2(-offset.x, 0.0)).rgb +
        inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.0,  offset.y)).rgb +
        inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.0, -offset.y)).rgb
    ) * 0.25;

    // "Unsharp mask": nitidez é a imagem MAIS a diferença entre ela e sua
    // versão borrada. Onde não há detalhe, a diferença é zero e nada muda —
    // por isso o efeito realça borda sem tocar em área lisa.
    float3 detail = center.rgb - blurred;
    __nv_out = float4(clamp(center.rgb + detail * u.amount, 0.0, 1.0), center.a);
    return __nv_out;
}
