// ---------------------------------------------------------------------------
// Unmult
// origem : assets/effects/unmult.xml
// id     : nova.effect.unmult
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct unmultParams {
    int alphaFrom;
    float gain;
    float blackClip;
    int recoverColor;
    int keepOriginalAlpha;
};

fragment float4 fx_unmult(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant unmultParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);

    // A cor que chega aqui é "reta" (não pré-multiplicada): é assim que o motor
    // guarda os buffers do encadeamento, e é o que o compositor espera de volta.
    // Ver a fórmula de composição em `drop-shadow.xml`, que faz a conta à mão.
    float3 cor = camada.rgb;

    float brilho;
    if (u.alphaFrom == 1) brilho = dot(cor, float3(0.299, 0.587, 0.114));
    else if (u.alphaFrom == 2) brilho = (cor.r + cor.g + cor.b) / 3.0;
    else brilho = max(max(cor.r, cor.g), cor.b);

    // O corte joga fora o pé escuro da imagem — ruído de sensor, cinza de
    // compressão — e reescala o resto, para o que sobrou não perder densidade.
    if (u.blackClip > 0.0) {
        brilho = (brilho - u.blackClip) / max(1.0 - u.blackClip, 1e-4);
    }

    float alfa = clamp(brilho * u.gain, 0.0, 1.0);
    if (u.keepOriginalAlpha) alfa *= camada.a;

    if (alfa < 1e-4) {
        __nv_out = float4(cor, 0.0);
        return __nv_out;
    }

    // Dividir pelo alfa devolve a cor à saturação cheia. É o que faz a conta
    // fechar: compor `cor/alfa` com esse alfa sobre o fundo dá
    // `fundo·(1-alfa) + cor`, o mesmo pixel que "Tela"/"Adição" mostrava.
    // Sem isso, o material fica com o alfa certo e a cor lavada.
    float3 saida = u.recoverColor ? min(cor / alfa, float3(1.0)) : cor;

    __nv_out = float4(saida, alfa);
    return __nv_out;
}
