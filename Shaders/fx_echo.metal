// ---------------------------------------------------------------------------
// Eco (rastro)
// origem : assets/effects/echo.xml
// id     : nova.effect.echo
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct echoParams {
    float count;
    float gap;
    float decay;
    int mode;
    float4 tint;
    float scatter;
};

// --- funcoes auxiliares do efeito
static float2 paraUv(float2 v) { return float2(v.x / max(eng.acAspect, 1e-4), v.y); }

static float4 sobre(float4 baixo, float4 cima) {
    float a = cima.a + baixo.a * (1.0 - cima.a);
    if (a <= 0.0) return float4(0.0);
    return float4((cima.rgb * cima.a + baixo.rgb * baixo.a * (1.0 - cima.a)) / a, a);
}

/**
 * Junta um rastro ao que já está montado.
 *
 * O deslocamento existe para o caso em que a camada está PARADA: sem ele, cinco
 * cópias no mesmo lugar não aparecem, e o efeito parece desligado. Um empurrão
 * pequeno por rastro já mostra a escada.
 */
static float4 juntar(float4 acumulado, float4 rastro, float peso) {
    if (rastro.a <= 0.0 || peso <= 0.0) return acumulado;

    float3 corRastro = mix(rastro.rgb, u.tint.rgb, u.tint.a);
    float4 pintado = float4(corRastro, rastro.a * peso);

    if (u.mode == 1) {
        // Somar luz: o rastro ACENDE o que já está lá. É o que se quer em
        // fogo, faísca e texto brilhante.
        return float4(acumulado.rgb + pintado.rgb * pintado.a,
                    max(acumulado.a, pintado.a));
    }
    if (u.mode == 2) {
        // Mais claro: fica o maior dos dois, canal a canal. Não estoura o
        // branco como a soma, e mantém a silhueta limpa.
        return float4(max(acumulado.rgb, pintado.rgb),
                    max(acumulado.a, pintado.a));
    }
    // Por trás: o rastro aparece ONDE a camada atual não está. É o padrão
    // porque é o que preserva a imagem de agora intacta.
    return sobre(pintado, acumulado);
}

fragment float4 fx_echo(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant echoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> eco1 [[texture(1)]],
    texture2d<float> eco2 [[texture(2)]],
    texture2d<float> eco3 [[texture(3)]],
    texture2d<float> eco4 [[texture(4)]],
    texture2d<float> eco5 [[texture(5)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 agora = inputImg.sample(__nv_smp, in.acScreenNorm);

    int quantos = clamp(int(u.count + 0.5), 0, 5);
    if (quantos == 0) {
        __nv_out = agora;
        return __nv_out;
    }

    // Começa do rastro mais VELHO e vai chegando no atual: assim o mais novo
    // fica por cima, que é a ordem natural de um rastro.
    float4 montado = float4(0.0);

    for (int i = 5; i >= 1; i--) {
        if (i > quantos) continue;

        float2 desvio = paraUv(float2(u.scatter * float(i), 0.0));
        float2 uv = in.acScreenNorm - desvio;

        float4 rastro;
        if (i == 1) rastro = eco1.sample(__nv_smp, uv);
        else if (i == 2) rastro = eco2.sample(__nv_smp, uv);
        else if (i == 3) rastro = eco3.sample(__nv_smp, uv);
        else if (i == 4) rastro = eco4.sample(__nv_smp, uv);
        else rastro = eco5.sample(__nv_smp, uv);

        montado = juntar(montado, rastro, pow(max(u.decay, 0.001), float(i)));
    }

    // O quadro de agora entra por último, sempre inteiro: o rastro é o que
    // acompanha, não o que substitui.
    if (u.mode == 1) {
        __nv_out = float4(montado.rgb * (1.0 - agora.a) + agora.rgb * agora.a,
                         max(montado.a, agora.a));
    } else {
        __nv_out = sobre(montado, agora);
    }
    return __nv_out;
}
