// ---------------------------------------------------------------------------
// Chave por luminância
// origem : assets/effects/luma-key.xml
// id     : nova.effect.lumakey
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct luma_keyParams {
    int mode;
    float cut;
    float softness;
    float choke;
    float band;
};

// --- funcoes auxiliares do efeito
// Rec.709 — os mesmos pesos que a TV e o vídeo digital usam. Média simples dos
// canais pareceria errada: o olho enxerga o verde muito mais que o azul, e um
// céu azul apareceria escuro demais na máscara.
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_luma_key(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant luma_keyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    float luz = dot(cor.rgb, LUMA);

    // A rampa nunca é zero: com suavidade 0 a transição vira um degrau de um
    // tom, e degrau em máscara é serrilhado na borda.
    float rampa = max(u.softness, 0.004);
    float alfa = 1.0;

    if (u.mode == 0) {
        alfa = smoothstep(u.cut - rampa, u.cut + rampa, luz);
    } else if (u.mode == 1) {
        alfa = 1.0 - smoothstep(u.cut - rampa, u.cut + rampa, luz);
    } else {
        // Distância até o tom escolhido, em tons. Os dois últimos modos são o
        // mesmo cálculo, um invertido do outro.
        float dist = abs(luz - u.cut);
        float dentroDaFaixa = 1.0 - smoothstep(u.band * 0.5 - rampa, u.band * 0.5 + rampa, dist);
        alfa = u.mode == 2 ? 1.0 - dentroDaFaixa : dentroDaFaixa;
    }

    // Apertar/afrouxar: desloca o alfa já pronto. Feito DEPOIS da rampa de
    // propósito — mexer no limiar para o mesmo fim engoliria o meio-tom.
    alfa = clamp(alfa + u.choke, 0.0, 1.0);

    __nv_out = float4(cor.rgb, cor.a * alfa);
    return __nv_out;
}
