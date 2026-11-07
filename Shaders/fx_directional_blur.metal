// ---------------------------------------------------------------------------
// Desfoque direcional
// origem : assets/effects/directional-blur.xml
// id     : nova.effect.directionalblur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct directional_blurParams {
    float angle;
    float reach;
    float quality;
    int trail;
};

// --- funcoes auxiliares do efeito
const int MAX_TAPS = 48;

fragment float4 fx_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant directional_blurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float rad = radians(u.angle);
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 stride = float2(cos(rad), sin(rad)) * (u.reach * eng.acEscalaDePixel) * eng.acTexelSize;

    int taps = clamp(int(u.quality + 0.5), 1, MAX_TAPS);
    if (taps == 1 || u.reach <= 0.0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    float4 total = float4(0.0);
    for (int i = 0; i < MAX_TAPS; i++) {
        if (i >= taps) break;
        float t = float(i) / float(taps - 1);
        // Centrado borra dos dois lados (parece fora de foco em movimento);
        // rastro puxa só para trás (parece velocidade com direção).
        float offset = u.trail ? -t : (t - 0.5);
        total += inputImg.sample(__nv_smp, clamp(in.acScreenNorm + stride * offset, 0.0, 1.0));
    }

    __nv_out = total / float(taps);
    return __nv_out;
}
