// ---------------------------------------------------------------------------
// BCC Cross Glitch
// origem : assets/effects/bcc-cross-glitch.xml
// id     : nova.effect.bcccrossglitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bcc_cross_glitchParams {
    float progress;
    float colorShift;
    float horizontalShift;
    float scanLines;
    float blocky;
    float pixelate;
    float noiseAmount;
    float speed;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash1(float n) {
    return fract(sin(n * 12.9898 + u.seed * 7.1) * 43758.5453);
}

float hash2(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233)) + u.seed * 7.1) * 43758.5453);
}

/** O tempo quantizado dá o "degrau" do glitch: cada tick, uma nova composição de saltos. */
float tickDoGlitch() {
    return floor(eng.acTime * max(u.speed, 0.01));
}

fragment float4 fx_bcc_cross_glitch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bcc_cross_glitchParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    // Progress 0 devolve a camada como está, igual ao AE.
    float p = clamp(u.progress * 0.01, 0.0, 1.0);
    if (p <= 0.0) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    float tick = tickDoGlitch();
    float2 uv = in.acScreenNorm;

    // -------------------------------------------------- 1. fatias horizontais
    // Quantas fatias: proporcional ao Horizontal Shift (um glitch com shift zero é só a aberração cromática).
    float rows = mix(12.0, 80.0, u.horizontalShift * 0.01);
    float row = floor(uv.y * rows);
    float semenduraDaLinha = hash1(row * 1.7 + tick * 17.3);
    float densidade = 0.25 + 0.5 * (u.horizontalShift * 0.01);
    float ativaLinha = step(1.0 - densidade, semenduraDaLinha);
    float saltoLinha = (hash1(semenduraDaLinha * 7.13) - 0.5) * (u.horizontalShift * 0.01) * 0.2 * ativaLinha * p;
    uv.x += saltoLinha;

    // -------------------------------------------------- 2. blocos quadrados
    float ladoBloco = mix(0.0, 0.08, u.blocky * 0.01);
    if (ladoBloco > 0.001) {
        float2 bloco = floor(uv / ladoBloco);
        float ativaBloco = step(0.75 - 0.25 * (u.blocky * 0.01), hash2(bloco + tick));
        float2 saltoBloco = (float2(hash2(bloco + 1.3), hash2(bloco + 2.7)) - 0.5) * ladoBloco * 2.0 * ativaBloco * p;
        uv += saltoBloco;
    }

    // -------------------------------------------------- 3. u.pixelate
    float px = mix(0.0, 60.0, u.pixelate * 0.01) * p;
    if (px > 0.5) {
        float2 grade = max(float2(1.0), eng.acTamanhoDaTela / px);
        uv = (floor(uv * grade) + 0.5) / grade;
    }

    uv = clamp(uv, 0.0, 1.0);

    // -------------------------------------------------- 4. separação de canais
    float split = (u.colorShift * 0.01) * 0.012 * p;
    float4 r = inputImg.sample(__nv_smp, clamp(uv + float2(split, 0.0), 0.0, 1.0));
    float4 g = inputImg.sample(__nv_smp, uv);
    float4 b = inputImg.sample(__nv_smp, clamp(uv - float2(split, 0.0), 0.0, 1.0));
    float4 cor = float4(r.r, g.g, b.b, g.a);

    // -------------------------------------------------- 5. scan lines (listras horizontais escuras)
    if (u.scanLines > 0.0) {
        float faixas = max(eng.acTamanhoDaTela.y * 0.5, 60.0);
        float onda = 0.5 + 0.5 * cos(uv.y * faixas * 6.28318530718);
        float forca = (u.scanLines * 0.01) * 0.7 * p;
        cor.rgb *= mix(1.0, onda, forca);
    }

    // -------------------------------------------------- 6. ruído aditivo
    if (u.noiseAmount > 0.0) {
        float ruido = hash2(__nv_fragCoord.xy + tick * 101.0) - 0.5;
        cor.rgb = clamp(cor.rgb + ruido * (u.noiseAmount * 0.01) * 0.5 * p, 0.0, 1.0);
    }

    __nv_out = cor;
    return __nv_out;
}
