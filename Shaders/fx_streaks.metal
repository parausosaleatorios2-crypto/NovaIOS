// ---------------------------------------------------------------------------
// Rastros
// origem : assets/effects/streaks.xml
// id     : nova.effect.streaks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct streaksParams {
    int mode;
    float2 center;
    float angle;
    float threshold;
    float strength;
    float quality;
    float intensity;
    float4 streakColor;
};

// --- funcoes auxiliares do efeito
const int MAX_SAMPLES = 48;

fragment float4 fx_streaks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant streaksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    int samples = clamp(int(u.quality + 0.5), 2, MAX_SAMPLES);

    float2 toCenter = in.acScreenNorm - u.center;
    float rad = radians(u.angle);
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 axis = float2(cos(rad), sin(rad)) * eng.acTexelSize * (u.strength * 700.0 * eng.acEscalaDePixel);

    float3 streak = float3(0.0);
    float weightSum = 0.0;

    for (int i = 0; i < MAX_SAMPLES; i++) {
        if (i >= samples) break;
        // Vai dos dois lados a partir do pixel: o rastro se estende pra
        // frente e pra trás no caminho, como o Risco anamórfico já faz.
        float t = (float(i) / float(samples - 1)) * 2.0 - 1.0;

        float2 uv;
        if (u.mode == 1) {
            // Giro: a amostra gira em torno do centro — mesma trajetória do
            // modo "Giro" de `radial-blur.xml`.
            float ang = u.strength * 1.5708 * t;
            float c = cos(ang);
            float s = sin(ang);
            uv = u.center + float2x2(c, -s, s, c) * toCenter;
        } else if (u.mode == 2) {
            // Zoom: a amostra anda na direção do centro (ou se afasta, do
            // lado negativo de t) — mesma trajetória do modo "Zoom".
            uv = u.center + toCenter * (1.0 - u.strength * t);
        } else {
            // Linear: acumula ao longo de um eixo fixo.
            uv = in.acScreenNorm + axis * t;
        }

        float4 texel = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
        float luma = dot(texel.rgb, float3(0.299, 0.587, 0.114)) * texel.a;
        float bright = smoothstep(u.threshold, min(u.threshold + 0.2, 1.0), luma);

        // Peso caindo com a distância: sem isso o rastro tem a mesma força
        // na ponta e no meio, e parece uma barra em vez de um brilho.
        float weight = 1.0 - abs(t);
        streak += texel.rgb * bright * weight;
        weightSum += weight;
    }

    streak *= u.intensity / max(weightSum, 0.0001);

    // Somado: luz se acumula por cima. Misturar deixaria a imagem lavada
    // em vez de acesa.
    float3 result = original.rgb + streak * u.streakColor.rgb * u.streakColor.a;
    __nv_out = float4(clamp(result, 0.0, 1.0), original.a);
    return __nv_out;
}
