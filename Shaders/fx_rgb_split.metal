// ---------------------------------------------------------------------------
// Separação RGB
// origem : assets/effects/rgb-split.xml
// id     : nova.effect.rgbsplit
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct rgb_splitParams {
    float amount;
    float angle;
    int radial;
};

fragment float4 fx_rgb_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant rgb_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 direction;

    if (u.radial) {
        // No modo u.radial o deslocamento aponta para fora do centro, o que imita
        // de verdade como uma lente real erra — o erro cresce nas bordas.
        float2 fromCenter = in.acScreenNorm - float2(0.5);
        direction = fromCenter * 2.0;
    } else {
        // Não chame a variável de `radians`: o nome sombrearia a função nativa
        // `radians()` já dentro do próprio inicializador, e não compila.
        float rad = radians(u.angle);
        direction = float2(cos(rad), sin(rad));
    }

    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 offset = direction * (u.amount * eng.acEscalaDePixel) * eng.acTexelSize;

    // Só o alpha do canal central importa: os outros dois já estão deslocados e
    // usar o alpha deles produziria franjas transparentes na borda da camada.
    float4 center = inputImg.sample(__nv_smp, in.acScreenNorm);
    float r = inputImg.sample(__nv_smp, in.acScreenNorm + offset).r;
    float b = inputImg.sample(__nv_smp, in.acScreenNorm - offset).b;

    __nv_out = float4(r, center.g, b, center.a);
    return __nv_out;
}
