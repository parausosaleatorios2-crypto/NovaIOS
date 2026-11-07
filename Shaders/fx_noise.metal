// ---------------------------------------------------------------------------
// Ruído
// origem : assets/effects/noise.xml
// id     : nova.effect.noise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct noiseParams {
    float amount;
    int noiseType;
    int colorNoise;
    int clipping;
};

// --- funcoes auxiliares do efeito
// ==========================================================================
//  HASH SEM SENO (Dave Hoskins, licença MIT — https://www.shadertoy.com/view/4djSRW)
// ==========================================================================
//
//  O hash clássico `fract(sin(dot(p, k)) * 43758.5)` PARECE aleatório, mas as
//  linhas de valor constante do `dot(p, k)` são retas diagonais, e o
//  embaralhamento do `sin(...)*bignum` depende de precisão que se PERDE quando a
//  coordenada é grande — e `__nv_fragCoord.xy` chega aos milhares. O que sobra são
//  faixas diagonais atravessando a imagem: era o "ruído meio linha, estranho".
//
//  Este hash trabalha só com `fract` e multiplicações, misturando os três eixos
//  entre si. É estável em qualquer escala (não tem `sin`, não depende de
//  precisão de argumento grande) e devolve valores bem decorrelacionados —
//  inclusive entre canais, o que conserta também o ruído colorido.
float hash13(float3 p3) {
    p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
float3 hash33(float3 p3) {
    p3 = fract(p3 * float3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yxx) * p3.zyx);
}

/*
 * Irwin-Hall: a soma de N uniformes independentes se aproxima de uma normal (o
 * Teorema Central do Limite de livro-texto) — domínio público. Cada `hash33` dá
 * TRÊS uniformes independentes de uma vez; quatro chamadas com deslocamentos
 * bem separados dão, por canal, uma normal de desvio padrão 1. Sem `cos`, sem o
 * padrão diagonal que a combinação Box-Muller + hash de seno produzia.
 */
float3 gaussiano3(float3 seed) {
    float3 s = hash33(seed)
        + hash33(seed + float3(37.0, 91.0, 13.0))
        + hash33(seed + float3(113.0, 29.0, 197.0))
        + hash33(seed + float3(197.0, 151.0, 59.0));
    // Média 2, desvio padrão sqrt(4/12) ≈ 0,5774 — recentra e normaliza para
    // desvio padrão 1, como uma normal padrão de verdade.
    return (s - 2.0) / 0.5773502692;
}

float3 ruidoEm(float3 seed) {
    if (u.noiseType == 0) {
        // Uniforme, recentrado em [-1, 1]. Colorido = três canais independentes
        // de uma só chamada; mono = um canal repetido.
        float3 u = u.colorNoise ? hash33(seed) : float3(hash13(seed));
        return u * 2.0 - 1.0;
    }

    // Gaussiano: dividir por 3 deixa quase tudo dentro de [-1,1] (regra dos três
    // desvios), na mesma faixa do uniforme.
    float3 g = gaussiano3(seed);
    return (u.colorNoise ? g : float3(g.x)) / 3.0;
}

// Recorte suave: sem ele, o excesso além de [0,1] corta em degrau reto e vira
// flecos de preto/branco puro nas pontas de brilho e sombra. `tanh` centrado
// comprime esse excesso continuamente em vez de cortar — assintótico, nunca
// chega a bater 0 ou 1 de verdade.
float3 semRecorte(float3 x) {
    float3 centro = x - 0.5;
    return tanh(centro) * 0.5 + 0.5;
}

fragment float4 fx_noise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant noiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Um campo novo a cada quadro — como o Noise do After Effects, que reamostra
    // a cada quadro por padrão. O quadro entra como TERCEIRA dimensão do hash (e
    // não somado às coordenadas): assim cada quadro é um campo independente, em
    // vez de deslizar o mesmo padrão na diagonal a cada quadro.
    float quadro = floor(eng.acTime * 24.0);
    float3 ruido = ruidoEm(float3(__nv_fragCoord.xy, quadro));

    float3 resultado = original.rgb + ruido * u.amount;
    resultado = u.clipping ? clamp(resultado, 0.0, 1.0) : clamp(semRecorte(resultado), 0.0, 1.0);

    __nv_out = float4(resultado, original.a);
    return __nv_out;
}
