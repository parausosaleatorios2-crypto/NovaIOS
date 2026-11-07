// ---------------------------------------------------------------------------
// Raio
// origem : assets/effects/lightning.xml
// id     : nova.effect.lightning
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct lightningParams {
    float2 fromAt;
    float2 toAt;
    float thickness;
    float chaos;
    float detail;
    float branches;
    float speed;
    float seed;
    float4 boltColor;
    float glow;
    float flicker;
};

// --- funcoes auxiliares do efeito
float hash(float x) {
    return fract(sin(x * 127.1 + u.seed * 13.7) * 43758.5453);
}

/** Ruído de uma dimensão, suave: é ele que entorta a linha reta. */
float ruido1(float x) {
    float i = floor(x);
    float f = fract(x);
    float s = f * f * (3.0 - 2.0 * f);
    return mix(hash(i), hash(i + 1.0), s) * 2.0 - 1.0;
}

/**
 * Quanto o caminho se afasta da reta, na posição `t` (0 = origem, 1 = destino).
 *
 * O `sin(t * PI)` é o que prende as pontas: ele vale zero nos dois extremos e um
 * no meio. Sem isso, o raio sairia dos terminais e o efeito perderia o sentido.
 */
float desvio(float t, float semente, float tempo, int oitavas) {
    float soma = 0.0;
    float amplitude = 1.0;
    float frequencia = 3.0;
    float peso = 0.0;

    for (int i = 0; i < 6; i++) {
        if (i >= oitavas) break;
        soma += ruido1(t * frequencia + tempo + semente * 7.3) * amplitude;
        peso += amplitude;
        amplitude *= 0.55;
        frequencia *= 2.1;
    }

    return (soma / max(peso, 1e-4)) * sin(t * 3.14159265);
}

const int PASSOS = 20;

/** O trecho de um raio: o principal (0) vai de 0 a 1; o galho i nasce num ponto do principal e morre antes do fim. */
float2 trecho(int raio) {
    if (raio == 0) return float2(0.0, 1.0);
    float s = float(raio);
    float nasce = 0.15 + hash(s * 3.1) * 0.6;
    float morre = nasce + 0.15 + hash(s * 5.7) * 0.25;
    return float2(nasce, morre);
}

/** O desvio guardado pelo passe 0: o ponto i do raio. */
float desvioGuardado(int raio, int i) {
    uint4 b = uint4(desvios.read(uint2(int2(i, raio)), uint(0)) * 255.0 + 0.5);
    return as_type<float>(b.r | (b.g << 8) | (b.b << 16) | (b.a << 24));
}

/**
 * A distância do ponto até UM caminho (principal ou galho).
 *
 * O caminho é percorrido em passos; para cada passo, a distância até o segmento.
 * Vinte passos bastam porque o raio é fino: buracos entre os passos ficariam
 * menores que a espessura da linha.
 */
float distanciaAoRaio(float2 p, float2 origem, float2 destino, int raio,
                      float inicio, float fim, float forca) {
    float2 direcao = destino - origem;
    float comprimento = length(direcao);
    if (comprimento < 1e-4) return 1e9;

    float2 perpendicular = float2(-direcao.y, direcao.x) / comprimento;

    float menor = 1e9;
    float2 anterior = float2(0.0);

    for (int i = 0; i <= PASSOS; i++) {
        float t = mix(inicio, fim, float(i) / float(PASSOS));
        float2 atual = origem + direcao * t +
            perpendicular * desvioGuardado(raio, i) * u.chaos * forca * comprimento;

        if (i > 0) {
            float2 pa = p - anterior;
            float2 ba = atual - anterior;
            float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-8), 0.0, 1.0);
            menor = min(menor, length(pa - ba * h));
        }
        anterior = atual;
    }

    return menor;
}

fragment float4 fx_lightning(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant lightningParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> desvios [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float tempo = eng.acTime * u.speed;
    int oitavas = clamp(int(u.detail + 0.5), 1, 6);

    if (eng.acPass == 0) {
        // o desvio do ponto i (coluna) do raio (linha): os 4 bytes do float, para o passe 1 ler o mesmo número
        int2 o = int2(__nv_fragCoord.xy);
        float2 tr = trecho(o.y);
        float t = mix(tr.x, tr.y, float(o.x) / float(PASSOS));
        uint u = as_type<uint>(desvio(t, float(o.y), tempo, oitavas));
        __nv_out = float4(float(u & 255u), float((u >> 8) & 255u), float((u >> 16) & 255u), float(u >> 24)) / 255.0;
        return __nv_out;
    }

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y);
    float2 origem = float2(u.fromAt.x * eng.acAspect, u.fromAt.y);
    float2 destino = float2(u.toAt.x * eng.acAspect, u.toAt.y);

    float d = distanciaAoRaio(p, origem, destino, 0, 0.0, 1.0, 1.0);

    // Galhos: cada um nasce num ponto do caminho principal e morre antes do fim.
    // Eles usam a MESMA função, com semente e trecho diferentes — um galho é só
    // um raio menor.
    int quantos = clamp(int(u.branches + 0.5), 0, 5);
    for (int i = 1; i <= 5; i++) {
        if (i > quantos) break;
        float s = float(i);
        float2 tr = trecho(i);
        float fino = 0.45 + hash(s * 9.1) * 0.3;
        d = min(d, distanciaAoRaio(p, origem, destino, i, tr.x, tr.y, fino * 1.8));
    }

    float esp = u.thickness * 0.006;

    // Três faixas a partir da mesma distância: o miolo branco saturado, a cor no
    // meio e o halo largo. É a assinatura de luz forte numa câmera.
    float nucleo = 1.0 - smoothstep(0.0, esp, d);
    float corpo = 1.0 - smoothstep(0.0, esp * 2.5, d);
    float halo = exp(-d / max(esp * 9.0, 1e-5)) * u.glow;

    // A piscada usa ruído, e não um seno: descarga elétrica não tem ritmo.
    float pisca = 1.0 - u.flicker * (0.5 + 0.5 * ruido1(eng.acTime * 11.0));

    float3 cor = u.boltColor.rgb * (corpo + halo) + float3(1.0) * nucleo;
    float alfa = clamp(max(max(nucleo, corpo), halo * 0.6), 0.0, 1.0) * u.boltColor.a * pisca;

    float4 desenhado = float4(cor, alfa);
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
