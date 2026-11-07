// ---------------------------------------------------------------------------
// Feixe de energia
// origem : assets/effects/energy-beam.xml
// id     : nova.effect.energybeam
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct energy_beamParams {
    float2 fromAt;
    float2 toAt;
    float thickness;
    float4 beamColor;
    float glow;
    float core;
    float tipGlow;
    float pulse;
    float pulseSpeed;
    float wobble;
    float grow;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_energy_beam(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant energy_beamParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float2 origem = float2(u.fromAt.x * eng.acAspect, u.fromAt.y);
    float2 destinoTotal = float2(u.toAt.x * eng.acAspect, u.toAt.y);

    // "Quanto já saiu" encurta o feixe a partir da origem. Com keyframe, é o
    // sabre de luz sendo ligado — e sai de graça, sem máscara animada.
    float2 destino = mix(origem, destinoTotal, clamp(u.grow, 0.0, 1.0));

    float2 eixo = destino - origem;
    float comprimento = length(eixo);
    if (comprimento < 1e-4) {
        __nv_out = original;
        return __nv_out;
    }

    float2 direcao = eixo / comprimento;
    float2 perpendicular = float2(-direcao.y, direcao.x);
    float2 rel = p - origem;

    float ao = dot(rel, direcao);          // ao longo do feixe
    float t = clamp(ao / comprimento, 0.0, 1.0);
    float trav = dot(rel, perpendicular);  // atravessado

    // Ondulação: o eixo do feixe serpenteia enquanto anda. Some com u.wobble 0.
    trav -= sin(t * 14.0 - eng.acTime * u.pulseSpeed * 1.7) * u.wobble * 0.02;

    // A distância usada nas quatro camadas é a mesma — o que muda é a largura
    // de cada uma. Fora do trecho do feixe, a distância vira a distância até a
    // PONTA, e é isso que arredonda os extremos em vez de cortá-los reto.
    float fora = max(max(-ao, ao - comprimento), 0.0);
    float d = length(float2(fora, trav));

    float esp = u.thickness * 0.006;

    float nucleo = (1.0 - smoothstep(0.0, esp * 0.55, d)) * u.core;
    float corpo = 1.0 - smoothstep(0.0, esp, d);
    float halo = exp(-d / max(esp * 6.0, 1e-5)) * u.glow;

    // As pontas ganham um brilho extra: é onde a energia "entra" e "sai", e sem
    // isso o feixe parece um tubo de neon apagado nas extremidades.
    float naPonta = exp(-length(p - origem) / max(esp * 4.0, 1e-5)) +
                    exp(-length(p - destino) / max(esp * 4.0, 1e-5));
    float pontas = naPonta * u.tipGlow;

    // O pulso ANDA pelo comprimento: `t` entra na fase, e é isso que faz a
    // energia parecer correr pelo feixe em vez de o feixe inteiro piscar.
    float onda = 1.0 + u.pulse * 0.6 * sin(t * 12.0 - eng.acTime * u.pulseSpeed * PI);

    float3 cor = u.beamColor.rgb * (corpo + halo + pontas) * onda + float3(1.0) * nucleo;
    float alfa = clamp(max(max(nucleo, corpo), max(halo, pontas) * 0.7), 0.0, 1.0) *
        u.beamColor.a * clamp(onda, 0.0, 2.0);

    float4 desenhado = float4(cor, clamp(alfa, 0.0, 1.0));
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
