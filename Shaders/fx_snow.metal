// ---------------------------------------------------------------------------
// Neve
// origem : assets/effects/snow.xml
// id     : nova.effect.snow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct snowParams {
    float density;
    float speed;
    float size;
    float wind;
    float layers;
    float4 flakeColor;
    float seed;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_CAMADAS = 5;

static float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

/**
 * O brilho do floco numa camada: 1 passe pelo grid dessa camada.
 * Cada célula tem UM floco, cujo lugar na célula é fixo (hash) e cujo Y
 * cai com o tempo, voltando ao topo ao sair.
 */
static float neveDaCamada(float2 uv, float t, float densidadeDaCamada, float velocidadeDaCamada, float tamanhoDaCamada) {
    float2 grade = float2(densidadeDaCamada, densidadeDaCamada);
    float2 escalado = uv * grade;
    float2 i = floor(escalado);
    float2 f = fract(escalado);

    float xDoFloco = hash2(i + 0.1);
    float yFase = hash2(i + 0.3);
    float tamDoFloco = mix(0.25, 1.0, hash2(i + 0.7));

    // Y cai no tempo, começa em uma fase diferente para cada célula; vento desloca x.
    float y = fract(yFase + t * velocidadeDaCamada);
    float x = fract(xDoFloco + t * u.wind);

    float2 pontoDoFloco = float2(x, 1.0 - y);
    float2 dentroDaCelula = (f - pontoDoFloco);
    float d = length(dentroDaCelula);

    float raio = tamanhoDaCamada * tamDoFloco * 0.3;
    float floco = 1.0 - smoothstep(0.0, raio, d);
    return floco;
}

fragment float4 fx_snow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant snowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    int n = clamp(int(u.layers + 0.5), 1, MAXIMO_DE_CAMADAS);
    float acumulado = 0.0;

    for (int k = 0; k < MAXIMO_DE_CAMADAS; k++) {
        if (k >= n) break;
        float profundidade = (float(k) + 1.0) / float(n);           // 1/n a 1: 1 = frente
        float dens = u.density * (0.5 + 0.5 * profundidade);
        float vel = u.speed * (0.6 + profundidade);
        float tam = u.size * profundidade;
        acumulado = max(acumulado, neveDaCamada(in.acScreenNorm, eng.acTime, dens, vel, tam) * profundidade);
    }

    float alfaFloco = clamp(acumulado, 0.0, 1.0) * u.flakeColor.a;

    float3 cor = mix(original.rgb, u.flakeColor.rgb, alfaFloco);
    float alfa = max(original.a, alfaFloco);

    __nv_out = float4(cor, alfa);
    return __nv_out;
}
