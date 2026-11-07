// ---------------------------------------------------------------------------
// Fogo
// origem : assets/effects/fire.xml
// id     : nova.effect.fire
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct fireParams {
    float height;
    float speed;
    float scale;
    float detail;
    float intensity;
    float seed;
};

// --- funcoes auxiliares do efeito
const int MAXIMO_DE_OITAVAS = 7;

float hash2(float2 c) {
    c += float2(float(u.seed) * 13.7);
    return fract(sin(dot(c, float2(127.1, 311.7))) * 43758.5453);
}

/** Ruído suave 2D (valor nos cantos + smoothstep nos dois eixos). */
float ruido2(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 s = f * f * (3.0 - 2.0 * f);
    float a = hash2(i);
    float b = hash2(i + float2(1.0, 0.0));
    float c = hash2(i + float2(0.0, 1.0));
    float d = hash2(i + float2(1.0, 1.0));
    return mix(mix(a, b, s.x), mix(c, d, s.x), s.y);
}

/** FBM: soma de oitavas, amplitude cai pela metade, frequência dobra. */
float fbm(float2 p, int oitavas) {
    float soma = 0.0;
    float amp = 0.5;
    float peso = 0.0;
    for (int i = 0; i < MAXIMO_DE_OITAVAS; i++) {
        if (i >= oitavas) break;
        soma += ruido2(p) * amp;
        peso += amp;
        p *= 2.0;
        amp *= 0.5;
    }
    return soma / max(peso, 1e-4);
}

/** Rampa de cor do fogo: do vermelho escuro à ponta branca. */
float3 rampa(float x) {
    x = clamp(x, 0.0, 1.0);
    float3 c;
    if (x < 0.25)      c = mix(float3(0.0), float3(0.6, 0.0, 0.0), x / 0.25);
    else if (x < 0.5)  c = mix(float3(0.6, 0.0, 0.0), float3(1.0, 0.3, 0.0), (x - 0.25) / 0.25);
    else if (x < 0.75) c = mix(float3(1.0, 0.3, 0.0), float3(1.0, 0.9, 0.2), (x - 0.5) / 0.25);
    else               c = mix(float3(1.0, 0.9, 0.2), float3(1.0), (x - 0.75) / 0.25);
    return c;
}

fragment float4 fx_fire(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant fireParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 p = float2(in.acScreenNorm.x * eng.acAspect, in.acScreenNorm.y) * u.scale;
    // O ruído escorre pra cima no tempo — é o que vira "chama subindo".
    p.y -= eng.acTime * u.speed;

    int oit = clamp(int(u.detail + 0.5), 1, MAXIMO_DE_OITAVAS);
    float n = fbm(p, oit);

    // Máscara vertical: 1 na base, 0 no topo; `u.height` escala.
    float mascara = smoothstep(0.0, max(u.height, 1e-4), 1.0 - in.acScreenNorm.y);

    // Combina o ruído com a máscara: o produto é a quantidade de fogo no pixel.
    float quanto = n * mascara;
    quanto = clamp(quanto * u.intensity * 1.6, 0.0, 1.5);

    float3 corDoFogo = rampa(quanto);
    float alfaDoFogo = clamp(quanto, 0.0, 1.0);

    // Mistura por SCREEN (fogo é luz, não tinta por cima).
    float3 cor = 1.0 - (1.0 - original.rgb) * (1.0 - corDoFogo);
    cor = mix(original.rgb, cor, alfaDoFogo);
    float alfa = max(original.a, alfaDoFogo);

    __nv_out = float4(cor, alfa);
    return __nv_out;
}
