// ---------------------------------------------------------------------------
// Curvas
// origem : assets/effects/curves.xml
// id     : nova.effect.curves
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct curvesParams {
    float4 curve;
    int keepLuma;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

/**
 * Uma entrada da tabela.
 *
 * O `0.5/256` é o centro do texel: sem ele, um valor que caia exatamente na
 * fronteira entre duas entradas pega a vizinha errada — e no degradê isso
 * aparece como uma listra deslocada de uma entrada inteira.
 */
static float consultar(float valor, int canal) {
    float x = clamp(valor, 0.0, 1.0) * (255.0 / 256.0) + (0.5 / 256.0);
    float4 tabela = u.curve.sample(__nv_smp, float2(x, 0.5));
    return canal == 0 ? tabela.r : (canal == 1 ? tabela.g : tabela.b);
}

fragment float4 fx_curves(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant curvesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);

    float3 ajustada = float3(
        consultar(cor.r, 0),
        consultar(cor.g, 1),
        consultar(cor.b, 2)
    );

    // Manter o brilho: aplica a curva só no MATIZ, devolvendo a luminância
    // original. É como se faz correção de cor sem mexer na exposição — muda a
    // temperatura da imagem sem clarear nem escurecer nada.
    if (u.keepLuma) {
        float antes = dot(cor.rgb, LUMA);
        float depois = dot(ajustada, LUMA);
        ajustada *= antes / max(depois, 1e-3);
    }

    __nv_out = float4(clamp(ajustada, 0.0, 1.0), cor.a);
    return __nv_out;
}
