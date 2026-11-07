// ---------------------------------------------------------------------------
// Chave de cor
// origem : assets/effects/color-key.xml
// id     : nova.effect.colorkey
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct color_keyParams {
    float4 keyColor;
    float colorTolerance;
    float edgeThin;
    float edgeFeather;
    int showMatte;
};

// --- funcoes auxiliares do efeito
const int MAX_AMOSTRAS = 64;
const float PI = 3.14159265359;

// 1 = fica, 0 = sai. A maior diferença entre os canais, em 0..255, contra a
// tolerância — com meio nível de rampa para a borda não serrilhar.
static float fica(float2 uv) {
    float3 c = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0)).rgb;
    float3 d = abs(c - u.keyColor.rgb) * 255.0;
    float dif = max(d.r, max(d.g, d.b));
    return smoothstep(u.colorTolerance - 0.5, u.colorTolerance + 0.5, dif);
}

// A fração de um disco de raio r que fica do lado opaco de uma borda reta,
// quando o centro está a uma distância d DENTRO do opaco (negativa = fora).
static float fracaoNoDisco(float d, float r) {
    float x = clamp(d / r, -1.0, 1.0);
    return 0.5 + (x * sqrt(1.0 - x * x) + asin(x)) / PI;
}

fragment float4 fx_color_key(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant color_keyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float afinar = u.edgeThin * eng.acEscalaDePixel;
    float rampa = max(u.edgeFeather * eng.acEscalaDePixel, 0.0);
    float raio = abs(afinar) + rampa;

    float alpha;
    if (raio < 0.5) {
        alpha = fica(in.acScreenNorm);
    } else {
        // O disco, em espiral de ângulo áureo: amostras espalhadas por igual.
        int n = clamp(int(raio * raio * 0.8), 12, MAX_AMOSTRAS);
        float soma = 0.0;
        for (int i = 0; i < MAX_AMOSTRAS; i++) {
            if (i >= n) break;
            float t = (float(i) + 0.5) / float(n);
            float r = sqrt(t) * raio;
            float a = float(i) * 2.39996323;
            soma += fica(in.acScreenNorm + float2(cos(a), sin(a)) * r * eng.acTexelSize);
        }
        float fracao = soma / float(n);
        // A borda nova fica a `afinar` px para DENTRO do que fica; a rampa tem
        // `rampa` px (meio pixel no mínimo, para não serrilhar).
        float meia = max(rampa, 1.0) * 0.5;
        float de = fracaoNoDisco(afinar - meia, raio);
        float ate = fracaoNoDisco(afinar + meia, raio);
        alpha = smoothstep(de, max(ate, de + 0.001), fracao);
    }

    if (u.showMatte) {
        __nv_out = float4(float3(alpha), 1.0);
        return __nv_out;
    }
    __nv_out = float4(color.rgb, color.a * alpha);
    return __nv_out;
}
