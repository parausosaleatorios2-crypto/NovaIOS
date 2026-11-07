// ---------------------------------------------------------------------------
// Vibrance (AE)
// origem : assets/effects/ae-vibrance.xml
// id     : nova.effect.aevibrance
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_vibranceParams {
    float vibrance;
    float saturation;
};

// --- funcoes auxiliares do efeito
// Os valores de Vibrance que têm tabela, em ordem; o 0 (índice 12) é a própria cor e não ocupa linha.
const int N_VALORES = 23;
const int INDICE_DO_ZERO = 12;
const float VALORES[23] = float[23](-100.0, -90.0, -80.0, -70.0, -60.0, -50.0, -40.0, -30.0, -20.0, -10.0, -5.0, -2.0, 0.0,
                                    10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0);

// A LUT 33³ do atlas: 33 ladrilhos 33×33 lado a lado (x = b·33 + r, y = linha0 + g).
static float3 lut(float3 c, float linha0) {
    float2 tam = float2(int2(int(atlas.get_width()), int(atlas.get_height())));
    float3 p = clamp(c, 0.0, 1.0) * 32.0;
    float b0 = floor(p.b);
    float b1 = min(b0 + 1.0, 32.0);
    float t = p.b - b0;
    float v = (linha0 + p.g + 0.5) / tam.y;
    float3 a = atlas.sample(__nv_smp, float2((b0 * 33.0 + p.r + 0.5) / tam.x, v)).rgb;
    float3 d = atlas.sample(__nv_smp, float2((b1 * 33.0 + p.r + 0.5) / tam.x, v)).rgb;
    return mix(a, d, t);
}

/** A resposta medida no valor de índice `i` da lista. */
static float3 medido(float3 c, int i) {
    if (i == INDICE_DO_ZERO) return c;
    return lut(c, 33.0 * float(i < INDICE_DO_ZERO ? i : i - 1));
}

static float3 paraLuz(float3 c) { return mix(pow((c + 0.055) / 1.055, float3(2.4)), c / 12.92, float3(lessThanEqual(c, float3(0.04045)))); }
static float3 paraTela(float3 l) { return mix(1.055 * pow(max(l, float3(0.0)), float3(1.0 / 2.4)) - 0.055, l * 12.92, float3(lessThanEqual(l, float3(0.0031308)))); }

fragment float4 fx_ae_vibrance(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_vibranceParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> atlas [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 fonte = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    float3 c = fonte.rgb;

    // Vibrance: mistura linear entre as duas tabelas vizinhas do valor.
    float v = clamp(u.vibrance, -100.0, 100.0);
    if (v != 0.0) {
        int i = 0;
        for (int k = 0; k < N_VALORES - 1; k++) { if (v >= VALORES[k]) i = k; }
        i = min(i, N_VALORES - 2);
        float t = (v - VALORES[i]) / (VALORES[i + 1] - VALORES[i]);
        c = mix(medido(c, i), medido(c, i + 1), t);
    }

    // Saturation (medido, exato): em luz linear, em volta da luminância com os pesos do ProPhoto.
    if (u.saturation != 0.0) {
        float3 l = paraLuz(c);
        float y = dot(l, float3(0.2880, 0.7119, 0.0001));
        c = clamp(paraTela(clamp(y + (l - y) * (1.0 + clamp(u.saturation, -100.0, 100.0) / 100.0), 0.0, 1.0)), 0.0, 1.0);
    }

    __nv_out = float4(c, fonte.a);
    return __nv_out;
}
