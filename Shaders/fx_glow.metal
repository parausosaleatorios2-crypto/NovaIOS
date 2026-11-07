// ---------------------------------------------------------------------------
// Brilho
// origem : assets/effects/glow.xml
// id     : nova.effect.glow
// passes : 4
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct glowParams {
    float threshold;
    float radius;
    float intensity;
    float4 tint;
};

// --- funcoes auxiliares do efeito
const int TAPS = 9;
const float WEIGHTS[9] = float[9](
    0.0162162162, 0.0540540541, 0.1216216216, 0.1945945946,
    0.2270270270,
    0.1945945946, 0.1216216216, 0.0540540541, 0.0162162162
);

float4 blurPass(sampler2D tex, float2 direction) {
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 stepUv = direction * eng.acTexelSize * (u.radius * eng.acEscalaDePixel / 4.0);
    float4 sum = float4(0.0);
    for (int i = 0; i < TAPS; i++) {
        float offset = float(i - TAPS / 2);
        sum += tex.sample(__nv_smp, in.acScreenNorm + stepUv * offset) * WEIGHTS[i];
    }
    return sum;
}

fragment float4 fx_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> bright [[texture(1)]],
    texture2d<float> blurH [[texture(2)]],
    texture2d<float> blurV [[texture(3)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        // Reescala o que sobrou acima do limiar para 0..1, senão um limiar alto
        // deixaria o brilho quase invisível.
        // Pesado pelo alfa: a cor do motor é reta, e o pixel transparente de um PNG recortado ainda guarda a cor
        // do fundo apagado — sem isto ela acendia o brilho (o mesmo do Deep Glow, 23/10/2026).
        float excess = max(luma - u.threshold, 0.0) / max(1.0 - u.threshold, 0.001) * color.a;
        __nv_out = float4(color.rgb * excess, excess);
        return __nv_out;
    }

    if (eng.acPass == 1) {
        __nv_out = blurPass(bright, float2(1.0, 0.0));
        return __nv_out;
    }

    if (eng.acPass == 2) {
        __nv_out = blurPass(blurH, float2(0.0, 1.0));
        return __nv_out;
    }

    float4 base = inputImg.sample(__nv_smp, in.acScreenNorm);
    float4 light = blurV.sample(__nv_smp, in.acScreenNorm);

    // Soma (linear dodge) e não mistura: luz se ACUMULA. Misturar deixaria a
    // imagem de baixo mais fraca, que é o oposto do que brilho faz.
    float3 luz = clamp(light.rgb * u.tint.rgb * u.intensity, 0.0, 1.0);
    float3 rgb = clamp(base.rgb + light.rgb * u.tint.rgb * u.intensity, 0.0, 1.0);

    // O alpha também cresce, senão o brilho não vaza para fora da silhueta da
    // camada — e vazar para fora é justamente a graça. Fora dela é SÓ a luz (não a cor escondida do pixel
    // transparente), e o alfa é screen(alfa da camada, maior canal da luz), como o Unmult do Deep Glow do AE.
    // Sobre a camada opaca, nada muda.
    float alpha = 1.0 - (1.0 - base.a) * (1.0 - max(luz.r, max(luz.g, luz.b)));
    float3 pre = rgb * base.a + luz * (1.0 - base.a);

    __nv_out = alpha > 0.0 ? float4(min(pre / alpha, float3(1.0)), alpha) : float4(0.0);
    return __nv_out;
}
