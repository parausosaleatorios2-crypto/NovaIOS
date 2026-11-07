// ---------------------------------------------------------------------------
// Nuvens
// origem : assets/effects/clouds.xml
// id     : nova.effect.clouds
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct cloudsParams {
    float coverage;
    float scale;
    float speed;
    float layers;
    float softness;
    float windAngle;
    float drift;
    float4 cloudColor;
    float4 skyColor;
    float lightAngle;
    float relief;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

static float hash(float2 p) {
    // Primos grandes e um seno: o gerador de ruído mais usado em shader. O que
    // importa dele é embaralhar bem pixels vizinhos, e isso ele faz.
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

/** Ruído de valor com interpolação suave — a base de tudo aqui. */
static float ruido(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 s = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

/**
 * Ruído somado em camadas.
 *
 * Cada camada anda numa velocidade própria (`float(i) * 0.37`), e é isso que
 * faz a nuvem se DEFORMAR enquanto anda em vez de deslizar inteira.
 */
static float nuvem(float2 p, float2 vento, int quantas) {
    float soma = 0.0;
    float peso = 0.0;
    float amplitude = 1.0;
    float frequencia = 1.0;

    for (int i = 0; i < 7; i++) {
        if (i >= quantas) break;
        float2 deslocada = p * frequencia + vento * (1.0 + float(i) * 0.37 * u.drift);
        soma += ruido(deslocada) * amplitude;
        peso += amplitude;
        amplitude *= 0.5;
        frequencia *= 2.0;
    }

    return soma / max(peso, 1e-4);
}

fragment float4 fx_clouds(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant cloudsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y) * u.scale;
    float anguloVento = u.windAngle * PI / 180.0;
    float2 vento = float2(cos(anguloVento), sin(anguloVento)) * eng.acTime * u.speed;

    int quantas = clamp(int(u.layers + 0.5), 1, 7);
    float n = nuvem(p, vento, quantas);

    // A cobertura é um CORTE, não um multiplicador: céu é ruído cortado, e é o
    // corte que separa "algumas nuvens" de "encoberto".
    float corte = 1.0 - u.coverage;
    float densidade = smoothstep(corte, corte + u.softness, n);

    // O volume sai do gradiente do próprio ruído: onde ele cresce na direção da
    // luz, a nuvem clareia. É o mesmo princípio do relevo, e é o que impede a
    // nuvem de parecer uma mancha chapada.
    float passo = 0.02 * u.scale;
    float dx = nuvem(p + float2(passo, 0.0), vento, quantas) - n;
    float dy = nuvem(p + float2(0.0, passo), vento, quantas) - n;

    float anguloLuz = u.lightAngle * PI / 180.0;
    float2 luz = float2(cos(anguloLuz), -sin(anguloLuz));
    float claro = dot(normalize(float2(dx, dy) + 1e-5), luz) * u.relief;

    float3 cor = clamp(u.cloudColor.rgb * (1.0 + claro), 0.0, 2.0);
    float alfa = densidade * u.cloudColor.a;

    // O fundo é opcional: com alfa zero nele, a nuvem sai sobre o que já estava,
    // que é o caso de fumaça por cima de um vídeo.
    float3 comFundo = mix(u.skyColor.rgb, cor, alfa);
    float alfaFinal = max(alfa, u.skyColor.a);

    float4 desenhado = float4(comFundo, alfaFinal);
    float saidaAlfa = desenhado.a + original.a * (1.0 - desenhado.a);
    float3 saidaCor = saidaAlfa > 0.0
        ? (desenhado.rgb * desenhado.a + original.rgb * original.a * (1.0 - desenhado.a)) / saidaAlfa
        : float3(0.0);

    __nv_out = float4(saidaCor, saidaAlfa);
    return __nv_out;
}
