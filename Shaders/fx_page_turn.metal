// ---------------------------------------------------------------------------
// Virar página
// origem : assets/effects/page-turn.xml
// id     : nova.effect.pageturn
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct page_turnParams {
    float completion;
    int corner;
    float curlCurve;
    float shadowAmount;
    float feather;
    int invertWipe;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

/**
 * Reconstrói a UV de outra posição `posAlvo` (0..1) ao longo do MESMO eixo
 * da dobra, mantendo a coordenada perpendicular de `centred` — "andar" na
 * imagem sem sair da faixa em que o pixel de tela já está. Usado para o
 * verso espelhado do papel (ver o cabeçalho do arquivo).
 */
float2 uvEm(float posAlvo, float2 centred, float2 axis, float2 perp, float perpComp, float support) {
    float along2 = posAlvo * 2.0 * support - support;
    float2 centred2 = along2 * axis + perpComp * perp;
    return clamp(centred2 / float2(eng.acAspect, 1.0) + 0.5, 0.0, 1.0);
}

fragment float4 fx_page_turn(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant page_turnParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv0 = in.acScreenNorm;

    // O eixo aponta DA quina escolhida PARA a oposta — a direção em que o
    // rolo cresce.
    float2 axis;
    if (u.corner == 0) axis = normalize(float2(-1.0, -1.0));
    else if (u.corner == 1) axis = normalize(float2(1.0, -1.0));
    else if (u.corner == 2) axis = normalize(float2(-1.0, 1.0));
    else axis = normalize(float2(1.0, 1.0));
    float2 perp = float2(-axis.y, axis.x);

    float2 centred = (uv0 - 0.5) * float2(eng.acAspect, 1.0);

    // Mesma projeção aspect-corrigida da Cortina linear: sem normalizar pelo
    // alcance na direção do eixo, a mesma porcentagem andaria mais rápido na
    // diagonal que na horizontal.
    float support = max(0.5 * (eng.acAspect * abs(axis.x) + abs(axis.y)), 1e-4);
    float along = dot(centred, axis);
    float perpComp = dot(centred, perp);
    float p = (along + support) / (2.0 * support);

    float completion01 = u.invertWipe ? (1.0 - u.completion * 0.01) : (u.completion * 0.01);
    float R = max(u.curlCurve, 0.005);

    // Varre de fora do quadro (nada enrolado) a bem depois da quina oposta
    // (nada sobra) — ver o comentário do cabeçalho.
    float foldPos = -R * (PI * 0.5) + completion01 * (1.0 + R * PI);
    float dist = p - foldPos;

    float soft = max(u.feather, 0.0005);

    /*
     * AS TRÊS CORES POSSÍVEIS, SEMPRE CALCULADAS — e misturadas por peso no
     * final, em vez de um `if`/`return` por região. Um `if` cortaria na
     * hora: bem na borda do rolo, um lado desenharia "rolo, quase
     * transparente" e o outro "página, com sombra cheia" — duas contas
     * diferentes que não têm por que bater exatamente, e a costura aparece
     * como uma linha. Misturando os três pesos (que somam 1 fora da faixa
     * de suavização), a borda do rolo se funde na sombra da página do jeito
     * que a PRÓPRIA sombra já foi pensada para encontrar: sem covarde.
     */

    // ---- Ainda achatada, com a sombra do rolo se aproximando. ----
    float4 frente = inputImg.sample(__nv_smp, uv0);
    const float FAIXA_DE_SOMBRA = 0.06;
    float sombraT = clamp((dist - R) / FAIXA_DE_SOMBRA, 0.0, 1.0);
    float sombra = 1.0 - u.shadowAmount * (1.0 - sombraT);
    float4 corFrente = float4(frente.rgb * sombra, frente.a);

    // ---- Em cima do rolo: sempre o lado mais perto da câmera, que é o
    // VERSO (ver a conta no cabeçalho). `rim` é 1 na borda externa do rolo
    // (o ponto mais alto, quase de perfil) e 0 na dobra (o verso virado
    // cheio para a câmera, mais fundo na sombra própria). ----
    float distC = clamp(dist, 0.0, R);
    float theta = PI - asin(clamp(distC / R, 0.0, 1.0));
    float rim = sin(theta);

    float pBack = foldPos - distC;
    float2 uvBack = uvEm(clamp(pBack, 0.0, 1.0), centred, axis, perp, perpComp, support);
    float3 verso = inputImg.sample(__nv_smp, uvBack).rgb;
    // Verso de papel: mais pálido e escuro que a tinta da frente, com uma
    // aresta clara (`rim`) onde a luz pega o papel quase de perfil.
    float3 versoPintado = mix(float3(0.08), verso * 0.4 + 0.06, 0.85);
    float brilho = mix(0.4, 1.0, rim);
    float4 corRolo = float4(versoPintado * brilho, 1.0);

    // ---- Já virou de vez: nada — o compositor mostra o que está atrás. ----
    float4 corVazio = float4(0.0);

    // Os três pesos, em ordem crescente de `dist`: vazio → rolo → frente.
    // Ascendente dos dois lados de propósito (ver o comentário acima sobre
    // `smoothstep` com limites invertidos).
    float wFrente = smoothstep(R - soft, R + soft, dist);
    float wVazio = 1.0 - smoothstep(-soft, soft, dist);
    float wRolo = max(1.0 - wFrente - wVazio, 0.0);

    __nv_out = corVazio * wVazio + corRolo * wRolo + corFrente * wFrente;
    return __nv_out;
}
