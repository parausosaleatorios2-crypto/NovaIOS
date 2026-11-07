// ---------------------------------------------------------------------------
// Ondas de rádio
// origem : assets/effects/radio-waves.xml
// id     : nova.effect.radio-waves
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct radio_wavesParams {
    float2 centerAt;
    float count;
    float speed;
    float spacing;
    float thickness;
    float4 ringColor;
    float glow;
    float fade;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_ANEIS = 12;

/**
 * A cor acumulada no pixel pelos anéis vivos.
 *
 * Cada anel k nasce em `k * u.spacing`, vive `duracao` segundos e caminha com
 * `u.speed`. A idade no relógio deste quadro é `fract(.)`, o raio é
 * `idade * u.speed`, e o pixel pega o que estiver mais perto do seu raio.
 */

fragment float4 fx_radio_waves(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant radio_wavesParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = (in.acScreenNorm - u.centerAt) * float2(eng.acAspect, 1.0);
    float d = length(p);

    float duracao = u.spacing * float(u.count);

    int quantos = clamp(int(u.count + 0.5), 1, MAXIMO_DE_ANEIS);
    float melhorMiolo = 0.0;
    float melhorHalo = 0.0;

    for (int k = 0; k < MAXIMO_DE_ANEIS; k++) {
        if (k >= quantos) break;

        float fase = eng.acTime / max(duracao, 1e-4) + float(k) / float(quantos);
        float idade = fract(fase) * duracao;
        float raio = idade * u.speed;

        // O anel nasce fino, afina um pouco mais com a idade e some: o desvanecer
        // combina a idade (tempo de vida) com o raio (distância), que é o que dá
        // o ar de sinal se perdendo.
        float velhice = idade / max(duracao, 1e-4);
        float opacidade = pow(1.0 - clamp(velhice, 0.0, 1.0), max(u.fade, 1e-4));

        float esp = u.thickness * (1.0 - 0.4 * velhice);
        float distanciaAoAnel = abs(d - raio);

        float miolo = (1.0 - smoothstep(0.0, esp, distanciaAoAnel)) * opacidade;
        float halo = exp(-distanciaAoAnel / max(esp * 7.0, 1e-5)) * u.glow * opacidade;

        melhorMiolo = max(melhorMiolo, miolo);
        melhorHalo = max(melhorHalo, halo);
    }

    float3 cor = u.ringColor.rgb * (melhorMiolo + melhorHalo);
    float alfa = clamp(max(melhorMiolo, melhorHalo * 0.7), 0.0, 1.0) * u.ringColor.a;

    float4 desenhado = float4(cor, alfa);
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
