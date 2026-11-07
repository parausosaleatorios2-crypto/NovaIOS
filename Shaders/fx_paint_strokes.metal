// ---------------------------------------------------------------------------
// Pinceladas
// origem : assets/effects/paint-strokes.xml
// id     : nova.effect.paint-strokes
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct paint_strokesParams {
    float strokeLength;
    float angleJitter;
    float strength;
    float detail;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_AMOSTRAS = 16;

/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float hash1(float2 c) {
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 fx_paint_strokes(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant paint_strokesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float2 px = 1.0 / tam;

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Gradiente da luma por diferenças centrais: ∂L/∂x = (L(x+1) - L(x-1)) / 2.
    float lx = luma(inputImg.sample(__nv_smp, in.acScreenNorm + float2(px.x, 0.0)).rgb)
             - luma(inputImg.sample(__nv_smp, in.acScreenNorm - float2(px.x, 0.0)).rgb);
    float ly = luma(inputImg.sample(__nv_smp, in.acScreenNorm + float2(0.0, px.y)).rgb)
             - luma(inputImg.sample(__nv_smp, in.acScreenNorm - float2(0.0, px.y)).rgb);

    // Tangente = perpendicular ao gradiente. Uma área lisa (gradiente ~0) ganha uma
    // direção padrão (horizontal) para o traço não desaparecer.
    float2 tangente = float2(-ly, lx);
    float magnitude = length(tangente);
    tangente = magnitude > 1e-4 ? tangente / magnitude : float2(1.0, 0.0);

    // Ruído por pixel: rotaciona o traço u.angleJitter graus para cada lado.
    float semente = hash1(floor(in.acScreenNorm * tam / max(u.strokeLength, 1.0)));
    float giro = radians((semente * 2.0 - 1.0) * u.angleJitter);
    float cosG = cos(giro);
    float sinG = sin(giro);
    float2 t = float2(tangente.x * cosG - tangente.y * sinG, tangente.x * sinG + tangente.y * cosG);

    int n = clamp(int(u.detail + 0.5), 2, MAXIMO_DE_AMOSTRAS);
    int metade = n / 2;

    // Média ao longo da tangente — isso é o "borrão direcional" que pinta o traço.
    float3 soma = float3(0.0);
    float peso = 0.0;
    for (int i = -MAXIMO_DE_AMOSTRAS / 2; i <= MAXIMO_DE_AMOSTRAS / 2; i++) {
        if (i < -metade || i > metade) continue;
        float f = float(i) / float(metade);
        float2 deslocamento = t * f * u.strokeLength * px;
        float3 c = inputImg.sample(__nv_smp, in.acScreenNorm + deslocamento).rgb;
        // Peso triangular: as pontas pesam menos, o miolo do traço mais.
        float w = 1.0 - abs(f);
        soma += c * w;
        peso += w;
    }
    float3 pintado = soma / max(peso, 1e-4);

    float3 cor = mix(original.rgb, pintado, u.strength);
    __nv_out = float4(cor, original.a);
    return __nv_out;
}
