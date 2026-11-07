// ---------------------------------------------------------------------------
// Reflexo de lente
// origem : assets/effects/lens-flare.xml
// id     : nova.effect.lens-flare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct lens_flareParams {
    float2 sourceAt;
    float brightness;
    float4 flareColor;
    float haloSize;
    float starPoints;
    float starLength;
    float starAngle;
    float ghostCount;
    float ghostSpread;
    float ghostSize;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_FANTASMAS = 8;

/** A paleta tingida de um fantasma k, rotacionando por hash: cada vidro tinge diferente. */
float3 corDoFantasma(int k, float3 base) {
    float h = fract(sin(float(k) * 12.9898) * 43758.5453);
    float3 roda = float3(
        sin(h * 6.2831 + 0.0),
        sin(h * 6.2831 + 2.094),
        sin(h * 6.2831 + 4.188)
    ) * 0.5 + 0.5;
    return mix(base, roda, 0.55);
}

fragment float4 fx_lens_flare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant lens_flareParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 centro = float2(0.5 * eng.acAspect, 0.5);
    float2 fonte = float2(u.sourceAt.x * eng.acAspect, u.sourceAt.y);
    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);

    float3 corAcumulada = float3(0.0);
    float alfaAcumulado = 0.0;

    // ================ Halo central: a luz espalhada em volta da fonte ================
    float d = length(p - fonte);
    float halo = exp(-d / max(u.haloSize * 0.3, 1e-4));
    float miolo = 1.0 - smoothstep(0.0, u.haloSize * 0.04, d);
    corAcumulada += u.flareColor.rgb * halo + float3(1.0) * miolo;
    alfaAcumulado = max(alfaAcumulado, max(miolo, halo * 0.8));

    // ================ Estrela: cos(n·θ), afinada e com alcance que cai suave =========
    if (u.starLength > 0.0) {
        float2 v = p - fonte;
        float theta = __nv_atan(v.y, v.x) + radians(u.starAngle);
        int pontas = clamp(int(u.starPoints + 0.5), 2, 12);
        float rosa = cos(float(pontas) * theta);
        rosa = pow(max(rosa, 0.0), 32.0);                 // afina a ponta
        float queda = exp(-d / max(u.starLength * 0.35, 1e-4));
        float raio = rosa * queda * 1.5;
        corAcumulada += u.flareColor.rgb * raio;
        alfaAcumulado = max(alfaAcumulado, raio);
    }

    // ================ Fantasmas: cópias alinhadas no eixo fonte↔centro ===============
    int quantos = clamp(int(u.ghostCount + 0.5), 0, MAXIMO_DE_FANTASMAS);
    for (int k = 0; k < MAXIMO_DE_FANTASMAS; k++) {
        if (k >= quantos) break;

        // Offsets negativos levam o fantasma pro outro lado do centro: é onde um reflexo de lente de verdade cai.
        float offset = -u.ghostSpread * (float(k) + 1.0) / float(max(quantos, 1));
        float2 ponto = mix(centro, fonte, 1.0 - offset);

        float dg = length(p - ponto);
        float raio = u.ghostSize * (0.6 + 0.6 * fract(sin(float(k) * 7.31) * 43758.5453));
        float disco = 1.0 - smoothstep(raio * 0.4, raio, dg);
        float brilhoDoFantasma = disco * (0.6 - 0.5 * float(k) / float(MAXIMO_DE_FANTASMAS));

        corAcumulada += corDoFantasma(k, u.flareColor.rgb) * brilhoDoFantasma;
        alfaAcumulado = max(alfaAcumulado, brilhoDoFantasma * 0.6);
    }

    corAcumulada *= u.brightness;
    float alfa = clamp(alfaAcumulado * u.brightness, 0.0, 1.0) * u.flareColor.a;

    float4 desenhado = float4(corAcumulada, alfa);
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
