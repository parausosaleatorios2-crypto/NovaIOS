// ---------------------------------------------------------------------------
// Definir matte
// origem : assets/effects/set-matte.xml
// id     : nova.effect.setmatte
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct set_matteParams {
    int matteChannel;
    int invertMatte;
    int combineWithOriginal;
    int premultiplyMatte;
};

// --- funcoes auxiliares do efeito
float valorDoMatte(float4 m) {
    if (u.matteChannel == 0) return m.a;

    float3 c = u.premultiplyMatte ? m.rgb * m.a : m.rgb;

    if (u.matteChannel == 1) return dot(c, float3(0.299, 0.587, 0.114));
    if (u.matteChannel == 2) return c.r;
    if (u.matteChannel == 3) return c.g;
    if (u.matteChannel == 4) return c.b;

    float maior = max(max(c.r, c.g), c.b);
    float menor = min(min(c.r, c.g), c.b);
    float luz = (maior + menor) * 0.5;
    if (u.matteChannel == 5) return luz;

    float croma = maior - menor;
    if (u.matteChannel == 6) {
        // Saturação do HSL: zero no cinza, e a mesma fórmula nos dois lados
        // do meio, para branco e preto puros não dividirem por zero.
        if (croma <= 0.0) return 0.0;
        return croma / max(1.0 - abs(2.0 * luz - 1.0), 1e-4);
    }

    // Matiz, de 0 a 1 dando a volta no círculo de cor.
    if (croma <= 0.0) return 0.0;
    float h;
    if (maior == c.r) h = __nv_mod((c.g - c.b) / croma, 6.0);
    else if (maior == c.g) h = (c.b - c.r) / croma + 2.0;
    else h = (c.r - c.g) / croma + 4.0;
    return h / 6.0;
}

fragment float4 fx_set_matte(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant set_matteParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> matteImg [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float matte = clamp(valorDoMatte(matteImg.sample(__nv_smp, in.acScreenNorm)), 0.0, 1.0);
    if (u.invertMatte) matte = 1.0 - matte;

    float alfa = u.combineWithOriginal ? camada.a * matte : matte;
    __nv_out = float4(camada.rgb, alfa);
    return __nv_out;
}
