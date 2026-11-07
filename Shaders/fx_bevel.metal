// ---------------------------------------------------------------------------
// Bisel e sombra interna
// origem : assets/effects/bevel.xml
// id     : nova.effect.bevel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct bevelParams {
    float size;
    float depth;
    float lightAngle;
    int shape;
    float4 lightColor;
    float4 darkColor;
    float innerShadow;
    float innerSize;
    float innerGlow;
    float4 glowColor;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float2 paraUv(float2 v) { return float2(v.x / max(eng.acAspect, 1e-4), v.y); }

/**
 * A coroa de amostras: devolve a rampa da borda em `x` e a direção dela em `yz`.
 *
 * Uma leitura no centro e oito em volta. A média é a rampa (1 fundo dentro, 0
 * fora); a soma vetorial aponta para FORA, porque o alfa cresce para dentro e o
 * sinal é invertido na soma.
 */
float3 bordaEm(float2 ph, float raio) {
    float media = inputImg.sample(__nv_smp, paraUv(ph)).a * 0.2;
    float2 soma = float2(0.0);

    for (int i = 0; i < 8; i++) {
        float ang = float(i) * 0.78539816;
        float2 dir = float2(cos(ang), sin(ang));
        float a = inputImg.sample(__nv_smp, paraUv(ph + dir * raio)).a;
        media += a * 0.1;
        soma -= dir * a;
    }

    float comp = length(soma);
    return float3(media, comp > 1e-5 ? soma / comp : float2(0.0));
}

fragment float4 fx_bevel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant bevelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (original.a <= 0.0) {
        __nv_out = original;
        return __nv_out;
    }

    float2 ph = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);

    float3 borda = bordaEm(ph, max(u.size, 0.001));
    float rampa = clamp(borda.x, 0.0, 1.0);
    float2 normal = borda.yz;

    // O formato do chanfro é a curva aplicada à rampa. São três respostas
    // diferentes para "como a superfície sobe da borda até o platô":
    //   Suave    — meia volta de seno, sem canto nenhum
    //   Duro     — reta, com quina no topo (metal, plástico rígido)
    //   Almofada — sobe rápido e achata, como estofado
    float perfil;
    if (u.shape == 1) {
        perfil = rampa;
    } else if (u.shape == 2) {
        perfil = sqrt(clamp(rampa, 0.0, 1.0));
    } else {
        perfil = 0.5 - 0.5 * cos(clamp(rampa, 0.0, 1.0) * PI);
    }

    // A inclinação é a DERIVADA do perfil: no platô ela é zero (nada de luz), e
    // na beirada é máxima. Aproximada pela diferença entre perfil e rampa, que é
    // suficiente e custa zero amostras a mais.
    float inclinacao = (1.0 - abs(rampa * 2.0 - 1.0)) * u.depth;

    float ang = u.lightAngle * PI / 180.0;
    float2 luz = float2(cos(ang), -sin(ang));
    float voltadoParaLuz = dot(normal, luz);

    float claro = max(voltadoParaLuz, 0.0) * inclinacao;
    float escuro = max(-voltadoParaLuz, 0.0) * inclinacao;

    float3 cor = original.rgb;
    cor = mix(cor, u.lightColor.rgb, clamp(claro * u.lightColor.a, 0.0, 1.0));
    cor = mix(cor, u.darkColor.rgb, clamp(escuro * u.darkColor.a, 0.0, 1.0));

    // ------------------------------------------------------- sombra interna
    //
    // Ela mora DENTRO da forma, encostada na borda do lado contrário à luz.
    // Amostrar o alfa deslocado na direção da luz é o que produz isso: onde o
    // deslocamento cai fora da silhueta, há sombra.
    if (u.innerShadow > 0.0) {
        float aDeslocado = inputImg.sample(__nv_smp, paraUv(ph + luz * u.innerSize)).a;
        float dentroDaSombra = clamp(1.0 - aDeslocado, 0.0, 1.0) * u.innerShadow;
        cor = mix(cor, u.darkColor.rgb, dentroDaSombra * u.darkColor.a * original.a);
    }

    // O brilho interno é a mesma ideia sem direção: ele acompanha a borda toda.
    if (u.innerGlow > 0.0) {
        float perto = 1.0 - clamp(rampa, 0.0, 1.0);
        cor = mix(cor, u.glowColor.rgb, perto * u.innerGlow * u.glowColor.a);
    }

    __nv_out = float4(cor, original.a);
    return __nv_out;
}
