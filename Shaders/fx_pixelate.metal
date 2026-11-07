// ---------------------------------------------------------------------------
// Pixelizar
// origem : assets/effects/pixelate.xml
// id     : nova.effect.pixelate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct pixelateParams {
    float size;
    int mode;
    float gap;
};

fragment float4 fx_pixelate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant pixelateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Tamanho do bloco em coordenada normalizada. Dividir a resolução pelo
    // tamanho e arredondar garante blocos de tamanho igual, sem uma fileira
    // torta na borda.
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 blocks = max(floor(eng.acResolution / (u.size * eng.acEscalaDePixel)), float2(1.0));
    float2 blockSize = 1.0 / blocks;

    float2 blockIndex = floor(in.acScreenNorm * blocks);
    float2 blockCenter = (blockIndex + 0.5) * blockSize;

    // Amostrar no CENTRO do bloco, não no canto: amostrar no canto desloca a
    // imagem inteira meio bloco para cima e para a esquerda.
    float4 color = inputImg.sample(__nv_smp, blockCenter);

    // Posição dentro do bloco, de -1 a 1, para desenhar a forma.
    float2 local = (fract(in.acScreenNorm * blocks) - 0.5) * 2.0;

    float mask = 1.0;
    float limit = 1.0 - u.gap;

    if (u.mode == 1) {
        mask = 1.0 - smoothstep(limit - 0.15, limit, length(local));
    } else if (u.mode == 2) {
        mask = 1.0 - smoothstep(limit - 0.15, limit, abs(local.x) + abs(local.y));
    } else if (u.gap > 0.0) {
        mask = 1.0 - smoothstep(limit - 0.05, limit, max(abs(local.x), abs(local.y)));
    }

    __nv_out = float4(color.rgb, color.a * mask);
    return __nv_out;
}
