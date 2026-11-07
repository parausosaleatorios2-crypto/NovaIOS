// ---------------------------------------------------------------------------
// Misturador de canais
// origem : assets/effects/channel-mixer.xml
// id     : nova.effect.channelmixer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct channel_mixerParams {
    float rr;
    float rg;
    float rb;
    float gr;
    float gg;
    float gb;
    float br;
    float bg;
    float bb;
    int monochrome;
    int preserveLuma;
};

// --- funcoes auxiliares do efeito
// Normaliza uma linha da matriz para somar 1. Soma zero (ou negativa) não tem
// normalização possível — nesse caso a linha passa como está, e o resultado
// escuro é o que a pessoa pediu.
static float3 normalizar(float3 linha, bool ligado) {
    if (!ligado) return linha;
    float soma = linha.r + linha.g + linha.b;
    return soma > 0.001 ? linha / soma : linha;
}

fragment float4 fx_channel_mixer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant channel_mixerParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 c = clamp(color.rgb, 0.0, 1.0);

    float3 linhaR = normalizar(float3(u.rr, u.rg, u.rb), u.preserveLuma);

    if (u.monochrome) {
        // No modo preto e branco a PRIMEIRA linha manda em tudo: é ela o
        // "filtro de vidro". Mexer em nove números para produzir um cinza seria
        // trabalho sem sentido — e é assim que o Photoshop também faz.
        float cinza = dot(c, linhaR);
        __nv_out = float4(float3(clamp(cinza, 0.0, 1.0)), color.a);
        return __nv_out;
    }

    float3 linhaG = normalizar(float3(u.gr, u.gg, u.gb), u.preserveLuma);
    float3 linhaB = normalizar(float3(u.br, u.bg, u.bb), u.preserveLuma);

    float3 saida = float3(dot(c, linhaR), dot(c, linhaG), dot(c, linhaB));
    __nv_out = float4(clamp(saida, 0.0, 1.0), color.a);
    return __nv_out;
}
