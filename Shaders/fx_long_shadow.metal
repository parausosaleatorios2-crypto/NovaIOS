// ---------------------------------------------------------------------------
// Sombra longa
// origem : assets/effects/long-shadow.xml
// id     : nova.effect.longshadow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct long_shadowParams {
    float angle;
    float reach;
    float quality;
    float fade;
    float opacityF;
    float4 shadowColor;
};

// --- funcoes auxiliares do efeito
const int MAX_STEPS = 96;

fragment float4 fx_long_shadow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant long_shadowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    float rad = radians(u.angle);
    // Em pixels da COMPOSIÇÃO: `eng.acEscalaDePixel` converte para o buffer, e a prévia
    // reduzida (o Auto da tela, o play) fica do tamanho da exportação (0.516.0).
    float2 axis = float2(cos(rad), sin(rad)) * eng.acTexelSize * (u.reach * eng.acEscalaDePixel);
    int steps = clamp(int(u.quality + 0.5), 1, MAX_STEPS);

    float shadow = 0.0;
    for (int i = 1; i <= MAX_STEPS; i++) {
        if (i > steps) break;
        float t = float(i) / float(steps);
        float2 uv = in.acScreenNorm - axis * t;
        if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) continue;

        float hit = inputImg.sample(__nv_smp, uv).a;
        // O desvanecer é aplicado no PASSO, não no fim: assim a sombra perde
        // força conforme se afasta do objeto, em vez de clarear por igual.
        shadow = max(shadow, hit * mix(1.0, 1.0 - t, u.fade));
    }

    float4 thrown = float4(u.shadowColor.rgb, shadow * u.shadowColor.a * u.opacityF);

    // A camada por cima da sombra, com a fórmula de alpha reto. A sombra tem que
    // ficar ATRÁS: composta por cima, ela escureceria o próprio objeto.
    float outAlpha = color.a + thrown.a * (1.0 - color.a);
    float3 outColor = outAlpha > 0.0
        ? (color.rgb * color.a + thrown.rgb * thrown.a * (1.0 - color.a)) / outAlpha
        : float3(0.0);

    __nv_out = float4(outColor, outAlpha);
    return __nv_out;
}
