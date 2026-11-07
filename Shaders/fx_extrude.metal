// ---------------------------------------------------------------------------
// Extrusão 2.5D
// origem : assets/effects/extrude.xml
// id     : nova.effect.extrude
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct extrudeParams {
    float depth;
    int mode;
    float angle;
    float2 vanish;
    int sideMode;
    float4 sideColor;
    float4 sideColor2;
    float darken;
    float lightAmount;
    float lightAngle;
    float quality;
    int hideFace;
};

// --- funcoes auxiliares do efeito
const int MAX_STEPS = 128;

// Pixels de uma composição de 1080 de lado curto. Ver o cabeçalho.
static float escalaDePixel() {
    return min(eng.acResolution.x, eng.acResolution.y) / 1080.0;
}

// Onde, na camada, está o pedaço que aparece em `uv` quando a cópia está a
// profundidade `t` (0 = a frente, 1 = o fundo).
//
// Reta: a cópia do fundo está DESLOCADA para o lado da direção, então o pedaço
// que cai em `uv` vem de mais para trás dessa direção.
// Perspectiva: a cópia do fundo está ENCOLHIDA em direção ao ponto de fuga, e o
// pedaço que cai em `uv` vem de mais longe dele. A divisão é a inversa do
// encolhimento — e o piso de 0,05 impede o fundo de fugir para o infinito.
static float2 origemNoFundo(float2 uv, float t, float2 deslocamento, float afunilamento) {
    if (u.mode == 0) return uv - deslocamento * t;
    return u.vanish + (uv - u.vanish) / max(1.0 - afunilamento * t, 0.05);
}

static float3 corDoLado(float3 daCamada, float t) {
    if (u.sideMode == 1) return u.sideColor.rgb;
    if (u.sideMode == 2) return mix(u.sideColor.rgb, u.sideColor2.rgb, t);
    return daCamada;
}

// Para onde a borda aponta, em `uv`: o gradiente do alfa, virado do avesso.
// O alfa CRESCE para dentro da peça, então o gradiente aponta para dentro e a
// normal de fora é o oposto dele. Sem borda ali, não há normal.
static float2 normalDaBorda(float2 uv) {
    float raio = max(1.5 * escalaDePixel(), 1.0);
    float2 ex = float2(raio * eng.acTexelSize.x, 0.0);
    float2 ey = float2(0.0, raio * eng.acTexelSize.y);
    float2 gradiente = float2(
        inputImg.sample(__nv_smp, uv + ex).a - inputImg.sample(__nv_smp, uv - ex).a,
        inputImg.sample(__nv_smp, uv + ey).a - inputImg.sample(__nv_smp, uv - ey).a
    );
    float tamanho = length(gradiente);
    return tamanho > 0.001 ? -gradiente / tamanho : float2(0.0);
}

fragment float4 fx_extrude(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant extrudeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float4 frente = inputImg.sample(__nv_smp, uv);

    float escala = escalaDePixel();
    float profundidadePx = u.depth * escala;

    // No tipo perspectiva a "profundidade" vira quanto o fundo encolhe:
    // 100 px valem 10 %, e o teto de 90 % deixa sempre um fundo para ver.
    float afunilamento = clamp(u.depth / 1000.0, 0.0, 0.9);

    // Quanto a cópia mais funda anda, em pixels: é o que decide o número de
    // passos. No perspectiva, o canto da tela é o que mais anda.
    float alcancePx = (u.mode == 0)
        ? profundidadePx
        : afunilamento * 0.5 * max(eng.acResolution.x, eng.acResolution.y);

    if (alcancePx < 0.5) {
        __nv_out = u.hideFace ? float4(0.0) : frente;
        return __nv_out;
    }

    float rad = radians(u.angle);
    float2 deslocamento = float2(cos(rad), sin(rad)) * profundidadePx * eng.acTexelSize;

    // Um passo a cada ~1,25 px, entre 8 e o teto do usuário. Menos que isso
    // deixa buraco em traço fino; mais que isso é leitura à toa.
    int passos = clamp(int(alcancePx * 0.8), 8, min(int(u.quality + 0.5), MAX_STEPS));

    // Cor PRÉ-MULTIPLICADA, acumulada de frente para trás.
    float4 lados = float4(0.0);
    bool achou = false;
    float2 pontoDaBorda = uv;

    for (int i = 1; i <= MAX_STEPS; i++) {
        if (i > passos) break;
        float t = float(i) / float(passos);

        float2 origem = origemNoFundo(uv, t, deslocamento, afunilamento);
        if (origem.x < 0.0 || origem.x > 1.0 || origem.y < 0.0 || origem.y > 1.0) continue;

        float4 leitura = inputImg.sample(__nv_smp, origem);
        if (leitura.a < 0.004) continue;

        // A profundidade escurece a cópia inteira; a luz (abaixo) escurece por
        // direção. São duas coisas diferentes e se multiplicam.
        float3 cor = corDoLado(leitura.rgb, t) * mix(1.0, 1.0 - u.darken, t);
        lados += (1.0 - lados.a) * float4(cor * leitura.a, leitura.a);

        // O primeiro ponto realmente dentro da peça é o que toca a borda: é
        // dali que sai a normal, uma vez só por pixel.
        if (!achou && leitura.a > 0.3) {
            achou = true;
            pontoDaBorda = origem;
        }

        // Opaco: o resto está tapado. É aqui que o custo de um lado cai para
        // uma leitura.
        if (lados.a > 0.995) break;
    }

    if (achou && u.lightAmount > 0.0) {
        float luzRad = radians(u.lightAngle);
        float2 paraALuz = float2(cos(luzRad), sin(luzRad));
        float aceso = 0.5 + 0.5 * dot(normalDaBorda(pontoDaBorda), paraALuz);
        // Do lado apagado (1 − quantidade) ao aceso (1, a cor como ela é): a
        // luz só ESCURECE. Clarear além da cor da própria camada estouraria o
        // branco de um texto branco e apagaria o degradê dos lados.
        lados.rgb *= mix(1.0 - u.lightAmount, 1.0, aceso);
    }

    // A frente por cima dos lados, em alfa reto.
    float alfaDaFrente = u.hideFace ? 0.0 : frente.a;
    float alfa = alfaDaFrente + lados.a * (1.0 - alfaDaFrente);
    float3 rgb = alfa > 0.0001
        ? (frente.rgb * alfaDaFrente + lados.rgb * (1.0 - alfaDaFrente)) / alfa
        : float3(0.0);

    __nv_out = float4(clamp(rgb, 0.0, 1.0), clamp(alfa, 0.0, 1.0));
    return __nv_out;
}
