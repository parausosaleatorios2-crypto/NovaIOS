// ---------------------------------------------------------------------------
// Brilho interno
// origem : assets/effects/inner-glow.xml
// id     : nova.effect.innerglow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct inner_glowParams {
    float4 glowColor;
    float size;
    float intensity;
    float inset;
    int blend;
};

// --- funcoes auxiliares do efeito
const int AMOSTRAS = 12;
const float DOURADO = 2.39996323; // o ângulo áureo, em radianos

fragment float4 fx_inner_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant inner_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Fora do desenho não há dentro: pixel transparente sai como está, e é isso
    // que mantém o efeito colado na silhueta em vez de virar um borrão
    // retangular.
    if (color.a <= 0.002) {
        __nv_out = color;
        return __nv_out;
    }

    float raio = max(u.size, 0.001);
    float somaAlfa = 0.0;

    for (int i = 0; i < AMOSTRAS; i++) {
        float t = (float(i) + 0.5) / float(AMOSTRAS);
        float angulo = float(i) * DOURADO;
        // `sqrt(t)` espalha as amostras por ÁREA e não por raio: sem ele, a
        // espiral fica densa no centro e rala na borda, e o degradê sai com
        // anéis visíveis.
        float r = raio * sqrt(t);

        float2 passo = float2(cos(angulo), sin(angulo)) * r;
        passo.x /= max(eng.acAspect, 0.0001); // o raio é em unidades de altura

        somaAlfa += inputImg.sample(__nv_smp, in.acScreenNorm + passo).a;
    }

    float vizinhanca = somaAlfa / float(AMOSTRAS);

    // 1 no miolo do desenho, 0 encostando na borda → invertido vira "quanto
    // perto da borda estou".
    float perto = 1.0 - vizinhanca;
    perto = clamp((perto - u.inset * 0.5) / max(1.0 - u.inset * 0.5, 0.001), 0.0, 1.0);

    // A curva ao quadrado concentra a luz junto da borda. Linear dá uma
    // iluminação chapada que parece erro de opacidade.
    float luz = perto * perto * u.intensity * u.glowColor.a;
    luz *= color.a; // e ela nunca escapa da silhueta

    float3 rgb = color.rgb;
    if (u.blend == 0) {
        rgb += u.glowColor.rgb * luz;
    } else if (u.blend == 1) {
        rgb = mix(rgb, u.glowColor.rgb, clamp(luz, 0.0, 1.0));
    } else {
        rgb *= mix(float3(1.0), u.glowColor.rgb, clamp(luz, 0.0, 1.0));
    }

    __nv_out = float4(clamp(rgb, 0.0, 1.0), color.a);
    return __nv_out;
}
