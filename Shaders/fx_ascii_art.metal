// ---------------------------------------------------------------------------
// Arte ASCII
// origem : assets/effects/ascii-art.xml
// id     : nova.effect.ascii-art
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ascii_artParams {
    float cellSize;
    float levels;
    float4 inkColor;
    float4 bgColor;
    float useImageColor;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
static float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

fragment float4 fx_ascii_art(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ascii_artParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float lado = max(u.cellSize, 1.0);
    float2 grade = tam / lado;

    float2 escalado = in.acScreenNorm * grade;
    float2 i = floor(escalado);
    float2 f = fract(escalado) - 0.5;

    // Cor e luma do CENTRO da célula (1 lookup por célula).
    float2 uvDoCentro = (i + 0.5) / grade;
    float3 corDaImagem = inputImg.sample(__nv_smp, uvDoCentro).rgb;
    float L = luma(corDaImagem);

    // Quantiza a luma em `u.levels` patamares — o que vira a densidade do traço.
    int n = clamp(int(u.levels + 0.5), 2, 8);
    float Lq = floor(L * float(n)) / float(n - 1);
    Lq = clamp(Lq, 0.0, 1.0);

    // A marca: círculo cujo raio vem do Lq (claro = ponto grande, escuro = ponto pequeno).
    // Em Lq = 0 o círculo some; em Lq = 1 cobre quase a célula toda.
    float raio = Lq * 0.5;
    float d = length(f);
    float marca = 1.0 - smoothstep(raio - 0.05, raio + 0.05, d);

    float3 corDoTraco = mix(u.inkColor.rgb, corDaImagem, u.useImageColor);
    float4 fundo = float4(u.bgColor.rgb, u.bgColor.a);
    float4 traco = float4(corDoTraco, u.inkColor.a);

    float4 saida = mix(fundo, traco, marca);

    __nv_out = saida;
    return __nv_out;
}
