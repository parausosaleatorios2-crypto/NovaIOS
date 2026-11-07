// ---------------------------------------------------------------------------
// Colorizar
// origem : assets/effects/am-colorize.xml
// id     : nova.effect.am-colorize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_colorizeParams {
    float tint;
};

// --- funcoes auxiliares do efeito
// O croma (U, V) e a volta do YUV para o RGB, nos números do BT.601 (os mesmos do AM).
static float2 cromaDe(float3 c) {
    return float2(dot(c, float3(-0.14713, -0.28886, 0.436)),
                dot(c, float3(0.615, -0.51499, -0.10001)));
}

static float3 rgbDe(float y, float2 uv) {
    return float3(y + 1.13983 * uv.y,
                y - 0.39465 * uv.x - 0.58060 * uv.y,
                y + 2.03211 * uv.x);
}

// A cor pura do matiz (em voltas, 0..1) com brilho 0,5: a rampa de seis lados do HSV com saturação 1.
static float3 corDoMatiz(float voltas) {
    float3 rampa = abs(fract(float3(voltas) + float3(1.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
    return 0.5 * clamp(rampa - 1.0, 0.0, 1.0);
}

fragment float4 fx_am_colorize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_colorizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    float3 pre = camada.rgb * a;                                   // o AM trabalha pré-multiplicado
    float y = dot(pre, float3(0.299, 0.587, 0.114));
    float2 uv = mix(cromaDe(pre), cromaDe(corDoMatiz(u.tint.x / 360.0)), u.tint.y * a);
    float3 saida = clamp(rgbDe(y, uv), 0.0, 1.0);                  // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
