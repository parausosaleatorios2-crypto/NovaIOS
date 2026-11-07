// ---------------------------------------------------------------------------
// Bevel Alpha (AE)
// origem : assets/effects/bevel-alpha.xml
// id     : nova.effect.aebevelalpha
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bevel_alphaParams {
    float edgeThickness;
    float lightAngle;
    float4 lightColor;
    float lightIntensity;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

// Converte da fase (x·aspect, y) de volta para UV (x, y).
static float2 paraUv(float2 v) { return float2(v.x / max(eng.acAspect, 1e-4), v.y); }

/**
 * Coroa de 8 amostras ao redor de `ph` no raio `raio` (em unidades de fase,
 * onde 1 = altura da imagem). Devolve (rampa, normal.x, normal.y):
 *   rampa  — 1 no interior plano, ~0 exatamente na borda, 0 fora
 *   normal — direção "para fora" da superfície do chanfro (normalizada)
 */
static float3 bordaEm(float2 ph, float raio) {
    float media = inputImg.sample(__nv_smp, paraUv(ph)).a * 0.2;
    float2 soma = float2(0.0);
    for (int i = 0; i < 8; i++) {
        float ang = float(i) * 0.78539816; // PI/4
        float2 dir = float2(cos(ang), sin(ang));
        float a = inputImg.sample(__nv_smp, paraUv(ph + dir * raio)).a;
        media += a * 0.1;
        soma -= dir * a;
    }
    float comp = length(soma);
    return float3(media, comp > 1e-5 ? soma / comp : float2(0.0));
}

fragment float4 fx_bevel_alpha(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bevel_alphaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (original.a <= 0.0) { __nv_out = original; return __nv_out; }

    float2 ph = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);

    // u.edgeThickness em pixels → raio em unidades de fase (1 = altura)
    float raio = max(u.edgeThickness, 0.5) * eng.acTexelSize.y;

    float3 borda = bordaEm(ph, raio);
    float rampa  = clamp(borda.x, 0.0, 1.0);
    float2  normal = borda.yz;

    // Inclinação triangular: 0 no platô e na borda dura, máximo na meia-borda.
    float inclinacao = (1.0 - abs(rampa * 2.0 - 1.0)) * u.lightIntensity;

    float ang = u.lightAngle * PI / 180.0;
    float2 luz = float2(cos(ang), -sin(ang));
    float voltado = dot(normal, luz);

    float claro  = clamp(max( voltado, 0.0) * inclinacao, 0.0, 1.0);
    float escuro = clamp(max(-voltado, 0.0) * inclinacao, 0.0, 1.0);

    float3 cor = original.rgb;
    cor = mix(cor, u.lightColor.rgb, claro);
    cor = mix(cor, float3(0.0),      escuro);

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
