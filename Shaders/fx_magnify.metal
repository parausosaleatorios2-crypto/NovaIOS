// ---------------------------------------------------------------------------
// Lupa
// origem : assets/effects/magnify.xml
// id     : nova.effect.magnify
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct magnifyParams {
    float2 center;
    float radius;
    float amount;
    float feather;
    float rim;
};

// --- funcoes auxiliares do efeito
// Distância medida em unidades de ALTURA. Sem multiplicar X pelo aspecto, a
// "lupa" sai oval em qualquer composição que não seja quadrada — e oval não
// parece lente, parece defeito.
float2 paraAltura(float2 uv) { return float2(uv.x * eng.acAspect, uv.y); }

fragment float4 fx_magnify(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant magnifyParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 p = paraAltura(in.acScreenNorm);
    float2 c = paraAltura(u.center);

    float d = distance(p, c);
    float raio = max(u.radius, 0.001);

    if (d > raio) {
        __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm);
        return __nv_out;
    }

    // `t` vai de 0 no centro a 1 na borda. A suavidade define a partir de onde
    // a ampliação começa a ceder.
    float t = d / raio;
    float inicio = 1.0 - clamp(u.feather, 0.0, 0.95);
    float queda = 1.0 - smoothstep(inicio, 1.0, t);

    float fator = mix(1.0, max(u.amount, 1.0), queda);

    // A amostra é puxada para o centro no espaço NORMAL (não no de altura),
    // senão a correção de aspecto entraria duas vezes e a imagem sairia
    // esticada dentro da lente.
    float2 uv = u.center + (in.acScreenNorm - u.center) / fator;

    float4 cor = inputImg.sample(__nv_smp, clamp(uv, float2(0.0), float2(1.0)));

    if (u.rim > 0.0) {
        // Duas linhas de luz: uma fina bem na borda (o canto do vidro) e um
        // brilho largo logo dentro dela (a espessura). Juntas dizem "isto é um
        // objeto", que é o que faz a lupa parecer pousada sobre a imagem em vez
        // de ser um buraco nela.
        float borda = smoothstep(0.86, 1.0, t) * (1.0 - smoothstep(0.995, 1.0, t));
        float luz = smoothstep(0.55, 0.9, t) * 0.35;
        cor.rgb += (borda * 0.8 + luz) * u.rim;

        // E uma sombra por fora do anel, que dá a espessura do vidro.
        float sombra = smoothstep(0.93, 1.0, t);
        cor.rgb *= 1.0 - sombra * u.rim * 0.25;
    }

    __nv_out = cor;
    return __nv_out;
}
