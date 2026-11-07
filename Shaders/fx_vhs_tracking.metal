// ---------------------------------------------------------------------------
// Tracking VHS
// origem : assets/effects/vhs-tracking.xml
// id     : nova.effect.vhs-tracking
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct vhs_trackingParams {
    float bandHeight;
    float speed;
    float displaceAmount;
    float noiseAmount;
    float softEdges;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 fx_vhs_tracking(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant vhs_trackingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // A faixa sobe pela tela ao longo do tempo (fract mantém dentro de [0, 1]).
    float centroDaFaixa = fract(1.0 - eng.acTime * u.speed);

    // Distância do pixel à faixa, em y.
    float d = abs(in.acScreenNorm.y - centroDaFaixa);

    // Está dentro da faixa? (com transição suave nas bordas)
    float meiaAltura = u.bandHeight * 0.5;
    float suavidade = meiaAltura * max(u.softEdges, 1e-4);
    float dentro = 1.0 - smoothstep(meiaAltura - suavidade, meiaAltura + suavidade, d);

    // Deslocamento horizontal da faixa (modulado por seno pra "enrolar").
    float onda = sin(in.acScreenNorm.y * 60.0 - eng.acTime * 20.0);
    float dx = u.displaceAmount * dentro * onda;

    float2 uv = in.acScreenNorm + float2(dx, 0.0);
    float4 cor = inputImg.sample(__nv_smp, uv);

    // Chuveiro sobreposto só na faixa.
    float ruido = hash2(in.acScreenNorm * 800.0 + float2(eng.acTime * 90.0)) - 0.5;
    cor.rgb += float3(ruido) * u.noiseAmount * dentro;

    cor.rgb = clamp(cor.rgb, 0.0, 1.0);
    __nv_out = cor;
    return __nv_out;
}
