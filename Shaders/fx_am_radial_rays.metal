// ---------------------------------------------------------------------------
// Raios radiais
// origem : assets/effects/am-radial-rays.xml
// id     : nova.effect.am-radial-rays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_radial_raysParams {
    float2 position;
    float pointCount;
    float rayWidth;
    float angle;
    float4 color;
    float alpha;
    int blendMode;
    float innerRadius;
    float outerRadius;
    float feather;
    float radialFeather;
    float bendStrength;
    float bendFrequency;
    float bendPhase;
};

// --- funcoes auxiliares do efeito
#define PI 3.1415926536

static float4 preMultiplicada(float4 c) { return float4(c.rgb * c.a, c.a); }

// A volta da `eng.acCamadaParaTela`: UV da tela → UV do buffer da camada.
static float2 naCamada(float2 t) {
    float3 c = __nv_inverse(eng.acCamadaParaTela) * float3(t, 1.0);
    return c.xy / c.z;
}

// A função do AM, linha por linha.
static float rays(float2 st, float pixelSize, float u.feather, float width, float count, float u.innerRadius, float u.outerRadius,
           float u.radialFeather, float u.bendStrength, float u.bendFrequency, float u.bendPhase, float u.angle) {
    float r = length(st);
    float theta = (__nv_atan(st.x, st.y) + u.angle) / (2.0 * PI);
    theta += sin(r * u.bendFrequency + u.bendPhase) * u.bendStrength;
    float sweep = 1. / count;
    float t = __nv_mod(theta, sweep) / sweep;
    float h = u.feather / 2. * pixelSize / r;
    float halfWidth = width / 2.;
    float low = smoothstep(0.5 - halfWidth - h, 0.5 - halfWidth + h, t);
    float high = smoothstep(0.5 + halfWidth + h, 0.5 + halfWidth - h, t);
    float rf = u.radialFeather / 2. * pixelSize;
    float inside = smoothstep(u.innerRadius - rf, u.innerRadius + rf, r);
    float outside = smoothstep(u.outerRadius + rf, u.outerRadius - rf, r);
    return low * high * inside * outside;
}

fragment float4 fx_am_radial_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_radial_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 texColor = preMultiplicada(inputImg.sample(__nv_smp, in.acScreenNorm));

    // O `in.acLayerNorm` do AM: o retângulo do conteúdo de 0 a 1, com o Y para CIMA (a matriz dele inverte o Y da tela;
    // o buffer de camada do Nova cresce para baixo). A mesma ponte do Túnel (AM).
    float2 conteudo = max(eng.acTamanhoDaCamada, float2(1e-6));
    float2 st = 0.5 + (naCamada(__nv_acTela(in.acScreenNorm)) - 0.5) * eng.acTamanhoDaTela / conteudo;
    st.y = 1.0 - st.y;

    // Daqui em diante, o `main` do AM.
    st.y = 1. - st.y;
    st -= 0.5;
    st.x *= conteudo.x / conteudo.y;
    float pixelSize = 1. / length(eng.acTamanhoDaTela);

    float p = rays(st - u.position / 1000.0, pixelSize, u.feather, u.rayWidth, u.pointCount, u.innerRadius, u.outerRadius,
                   u.radialFeather, u.bendStrength / 10., u.bendFrequency, u.bendPhase, u.angle / 57.2958);

    float4 adjColor = float4(u.color.rgb, 1.0) * p;

    float4 result;
    if (texColor.a <= 0.0) {
        // Lá, 0 ÷ 0 = NaN nos dois modos que dividem pelo alfa, e o pixel sai vazio; no Normal, a camada (vazia).
        result = float4(0.0);
    } else if (u.blendMode == 1) {
        result = float4((texColor.rgb / texColor.a) * adjColor.rgb, 1.0) * texColor.a;
    } else if (u.blendMode == 2) {
        result = float4(1. - ((1. - (texColor.rgb / texColor.a)) * (1. - adjColor.rgb)), 1.0) * texColor.a;
    } else {
        result = adjColor * texColor.a;
        result = texColor * (1. - result.a) + result;
    }
    float4 c = mix(texColor, result, u.alpha);
    __nv_out = c.a > 0.0 ? float4(min(c.rgb / c.a, float3(1.0)), c.a) : float4(0.0);
    return __nv_out;
}
