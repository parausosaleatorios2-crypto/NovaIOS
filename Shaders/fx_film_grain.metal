// ---------------------------------------------------------------------------
// Granulação
// origem : assets/effects/film-grain.xml
// id     : nova.effect.grain
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct film_grainParams {
    float amount;
    float size;
    float speed;
    int colored;
    float shadowBias;
};

// --- funcoes auxiliares do efeito
// Hash clássico de shader: barato, sem textura, e "aleatório o bastante".
// Não serve para criptografia; serve perfeitamente para grão de filme.
static float hash(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

fragment float4 fx_film_grain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant film_grainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);

    // Quantizar o tempo faz o grão "trocar" em degraus, como quadros de filme,
    // em vez de deslizar continuamente — que pareceria água, não película.
    float frame = floor(eng.acTime * u.speed);
    float2 cell = floor(in.acScreenNorm * eng.acResolution / max(u.size, 0.5));

    float3 noise;
    if (u.colored) {
        noise = float3(
            hash(cell + frame),
            hash(cell + frame + 37.0),
            hash(cell + frame + 91.0)
        );
    } else {
        noise = float3(hash(cell + frame));
    }
    noise = noise * 2.0 - 1.0;

    // Filme real granula mais na sombra que na luz. Sem esse viés, o grão fica
    // uniforme e denuncia que é digital.
    float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
    float weight = mix(1.0, 1.0 - luma, u.shadowBias);

    __nv_out = float4(clamp(color.rgb + noise * u.amount * weight, 0.0, 1.0), color.a);
    return __nv_out;
}
