// ---------------------------------------------------------------------------
// Temperatura de cor
// origem : assets/effects/color-temperature.xml
// id     : nova.effect.colortemp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct color_temperatureParams {
    float temperature;
    float tint;
    int keepLuma;
};

// --- funcoes auxiliares do efeito
static float3 paraLinear(float3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), step(0.04045, c));
}

static float3 paraSrgb(float3 c) {
    return mix(c * 12.92, 1.055 * pow(c, float3(1.0 / 2.4)) - 0.055, step(0.0031308, c));
}

// Rec. 709: os pesos com que o olho soma os três canais.
static float luma(float3 c) { return dot(c, float3(0.2126, 0.7152, 0.0722)); }

fragment float4 fx_color_temperature(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant color_temperatureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 luz = paraLinear(clamp(color.rgb, 0.0, 1.0));

    /*
     * Quente sobe o vermelho e baixa o azul; frio faz o contrário. O verde
     * fica de fora deste eixo — é ele o eixo do `u.tint`.
     *
     * Os multiplicadores eram 0,4/0,3 — pensados como CORREÇÃO de balanço de
     * branco (o uso mais comum: uma foto levemente amarelada). No máximo do
     * controle (±100%) isso dava um empurrão de só ±40% no ganho — fraco
     * demais para quem quer um visual de propósito, não um conserto sutil.
     * Relato do snow (25/09/2026): "eu jogo tudo pro lado pra ficar azul, e
     * ele fica um azul fraquinho, e aquele é o limite máximo". Com 1,4/1,0 o
     * canal oposto ao extremo escolhido chega a ZERO (`max(ganho, 0.0)` logo
     * abaixo já cobria esse caso) — um visual saturado de verdade no máximo,
     * e ainda proporcional para valores pequenos (a correção sutil de sempre
     * continua sutil perto de 0).
     */
    float t = clamp(u.temperature, -1.0, 1.0) * 1.4;
    float m = clamp(u.tint, -1.0, 1.0) * 1.0;

    float3 ganho = float3(
        1.0 + t,
        1.0 - m,
        1.0 - t
    );
    // O magenta é a ausência de verde: subir os dois extremos junto com a
    // queda do verde é o que mantém o resultado neutro em brilho.
    ganho.r += m * 0.5;
    ganho.b += m * 0.5;

    float3 antes = luz;
    luz *= max(ganho, float3(0.0));

    if (u.keepLuma) {
        float l0 = luma(antes);
        float l1 = luma(luz);
        if (l1 > 0.0001) luz *= l0 / l1;
    }

    __nv_out = float4(clamp(paraSrgb(max(luz, 0.0)), 0.0, 1.0), color.a);
    return __nv_out;
}
