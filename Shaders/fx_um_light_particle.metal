// ---------------------------------------------------------------------------
// Partículas de Luz (Ultra Motion)
// origem : assets/effects/um-light-particle.xml
// id     : nova.effect.ultramotion.lightparticle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_light_particleParams {
    float density;
    float size;
    float threshold;
    float speed;
    float4 tint;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

fragment float4 fx_um_light_particle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_light_particleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 g = in.acScreenNorm * u.density;
    float2 cell = floor(g);
    float2 f = fract(g) - 0.5;

    float r = hash21(cell);
    float r2 = hash21(cell + 13.7);
    float fase = r * 6.2831853;
    float piscar = 0.5 + 0.5 * sin(eng.acTime * u.speed + fase);
    float2 pos = (float2(r, r2) - 0.5) * 0.6;
    float d = length(f - pos);
    float ponto = smoothstep(0.32 * u.size, 0.0, d) * piscar;

    // só onde a camada já está brilhante
    float l = dot(orig.rgb, LUMA);
    float onde = smoothstep(u.threshold, u.threshold + 0.2, l);

    float3 cor = orig.rgb + u.tint.rgb * u.tint.a * ponto * onde * 1.5;
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
