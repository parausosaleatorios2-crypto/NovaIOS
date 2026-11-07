// ---------------------------------------------------------------------------
// Pontilhismo
// origem : assets/effects/pointillism.xml
// id     : nova.effect.pointillism
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct pointillismParams {
    float dotSize;
    float radius;
    float softness;
    float4 paperColor;
    float paperAlpha;
};

// --- funcoes auxiliares do efeito
/** Luminância ITU-R BT.709. */
float luma(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

fragment float4 fx_pointillism(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant pointillismParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 tam = float2(int2(int(inputImg.get_width()), int(inputImg.get_height())));
    float tamDaCelula = max(u.dotSize, 1.0);
    float2 grade = tam / tamDaCelula;

    float2 escalado = in.acScreenNorm * grade;
    float2 i = floor(escalado);
    float2 f = fract(escalado) - 0.5;

    // UV do centro da célula (lê a imagem UMA vez por célula, não por pixel).
    float2 uvDoCentro = (i + 0.5) / grade;
    float4 corDaCelula = inputImg.sample(__nv_smp, uvDoCentro);

    // O raio cresce com a luma: claro = ponto grande.
    float r = luma(corDaCelula.rgb) * u.radius * 0.5;

    // Desenha o ponto com anti-serrilhagem suave.
    float d = length(f);
    float ponto = 1.0 - smoothstep(r - max(u.softness * 0.25, 1e-4), r + max(u.softness * 0.25, 1e-4), d);

    // Fundo: papel com opacidade controlada; o original passa onde o papel não cobre.
    float4 fundo = mix(original, float4(u.paperColor.rgb, 1.0), u.paperAlpha * u.paperColor.a);

    float4 saida = mix(fundo, float4(corDaCelula.rgb, 1.0), ponto);

    __nv_out = saida;
    return __nv_out;
}
