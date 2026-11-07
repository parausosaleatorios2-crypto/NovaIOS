// ---------------------------------------------------------------------------
// Desfoque gaussiano
// origem : assets/effects/gaussian-blur.xml
// id     : nova.effect.gaussianblur
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gaussian_blurParams {
    float radius;
    float iterations;
};

// --- funcoes auxiliares do efeito
// Gaussiana de 9 amostras fundida em 5 leituras bilineares (truque bilinear):
// cada par de amostras adjacentes vira uma única leitura no ponto que reproduz
// a mesma média ponderada pela interpolação bilinear da GPU — ~44% menos leituras
// por passe, mesma "suavidade" de gaussiana.
// offsets = média ponderada dos pares adjacentes; weights = soma dos pares.
const int   SAMPLE_COUNT = 5;
const float OFFSETS[5] = float[5](-3.2307692308, -1.3846153846, 0.0, 1.3846153846, 3.2307692308);
const float WEIGHTS[5] = float[5](0.0702702703, 0.3162162162, 0.2270270270, 0.3162162162, 0.0702702703);

fragment float4 fx_gaussian_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gaussian_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.radius <= 0.0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    // O passe 0 caminha em X, o passe 1 em Y. Um shader, duas direções.
    //
    // Cuidado com nomes aqui: `sample` é palavra RESERVADA no GLSL ES 3.00 e
    // `step` é uma função nativa. Usar qualquer um dos dois como variável dá
    // erro de compilação (ou, pior, sombreia a função nativa sem avisar).
    float2 direction = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 stepUv = direction * eng.acTexelSize * (u.radius * eng.acEscalaDePixel / 4.0);

    float4 sum = float4(0.0);
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        // O passe 1 lê o buffer que o passe 0 escreveu, não a entrada original.
        float2 uv = in.acScreenNorm + stepUv * OFFSETS[i];
        float4 texel = (eng.acPass == 0)
            ? inputImg.sample(__nv_smp, uv)
            : hblur.sample(__nv_smp, uv);
        sum += texel * WEIGHTS[i];
    }

    __nv_out = sum;
    return __nv_out;
}
