// ---------------------------------------------------------------------------
// Copiar fundo (Nova, até a 0.651)
// origem : assets/effects/copy-background.xml
// id     : nova.effect.copybackground
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct copy_backgroundParams {
    float fill;
};

fragment float4 fx_copy_background(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant copy_backgroundParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> fundoImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    // O fundo está na TELA e a camada não: sem a ponte, mover a camada faz o
    // efeito copiar o pedaço errado da cena. Ver `eng.acTela` no prelúdio.
    float4 fundo = fundoImg.sample(__nv_smp, __nv_acTela(in.acScreenNorm));

    // O formato vem da camada; a cor, do fundo. Onde o fundo é transparente
    // (camada mais de baixo sobre fundo vazio), não há o que copiar.
    float formato = mix(camada.a, 1.0, clamp(u.fill, 0.0, 1.0));
    __nv_out = float4(fundo.rgb, formato * fundo.a);
    return __nv_out;
}
