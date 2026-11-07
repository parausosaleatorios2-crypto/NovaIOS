// ---------------------------------------------------------------------------
// Sombra projetada
// origem : assets/effects/drop-shadow.xml
// id     : nova.effect.dropshadow
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct drop_shadowParams {
    float reach;
    float angle;
    float softness;
    float opacity;
    float4 shadowColor;
    int shadowOnly;
};

// --- funcoes auxiliares do efeito
// Gaussiana de 9 amostras fundida em 5 leituras bilineares — ~44% menos leituras por passe.
const int TAPS = 5;
const float TAP_OFFSETS[5] = float[5](-3.2307692308, -1.3846153846, 0.0, 1.3846153846, 3.2307692308);
const float WEIGHTS[5] = float[5](0.0702702703, 0.3162162162, 0.2270270270, 0.3162162162, 0.0702702703);

static float4 blurPass(sampler2D tex, float2 direction) {
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 stepUv = direction * eng.acTexelSize * max(u.softness * eng.acEscalaDePixel / 4.0, 0.001);
    float4 sum = float4(0.0);
    for (int i = 0; i < TAPS; i++) {
        sum += tex.sample(__nv_smp, in.acScreenNorm + stepUv * TAP_OFFSETS[i]) * WEIGHTS[i];
    }
    return sum;
}

fragment float4 fx_drop_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant drop_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> shadowMask [[texture(1)]],
    texture2d<float> blurH [[texture(2)]],
    texture2d<float> blurV [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float rad = radians(u.angle);
        float2 offset = float2(cos(rad), sin(rad)) * (u.reach * eng.acEscalaDePixel) * eng.acTexelSize;

        // Amostra DESLOCADA: a sombra é a silhueta deslocada no sentido oposto
        // ao da luz.
        float silhouette = inputImg.sample(__nv_smp, in.acScreenNorm - offset).a;
        __nv_out = float4(u.shadowColor.rgb, silhouette * u.opacity * u.shadowColor.a);
        return __nv_out;
    }

    if (eng.acPass == 1) {
        __nv_out = blurPass(shadowMask, float2(1.0, 0.0));
        return __nv_out;
    }

    if (eng.acPass == 2) {
        __nv_out = blurPass(blurH, float2(0.0, 1.0));
        return __nv_out;
    }

    float4 shadow = blurV.sample(__nv_smp, in.acScreenNorm);

    // Só a sombra: ela inteira, inclusive a parte que ficaria escondida embaixo
    // da camada. É o que o After Effects faz, e é o que se quer ao usar a sombra
    // em outro lugar — um recorte no formato da camada seria outro efeito.
    //
    // O texel já sai pronto: o passe 0 pinta TODO pixel com a cor da sombra
    // (só o alfa varia), então o borrão mistura cores iguais e a cor continua
    // reta, sem escurecer na borda.
    if (u.shadowOnly) {
        __nv_out = shadow;
        return __nv_out;
    }

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Composição "source-over": a camada por cima da sombra. Mesma fórmula do
    // compositor de camadas do motor.
    float outAlpha = base.a + shadow.a * (1.0 - base.a);
    float3 outRgb = outAlpha > 0.0
        ? (base.rgb * base.a + shadow.rgb * shadow.a * (1.0 - base.a)) / outAlpha
        : float3(0.0);

    __nv_out = float4(outRgb, outAlpha);
    return __nv_out;
}
