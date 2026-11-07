// ---------------------------------------------------------------------------
// Neve Caindo (Ultra Motion)
// origem : assets/effects/um-snow-falling.xml
// id     : nova.effect.ultramotion.snowfalling
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_snow_fallingParams {
    float density;
    float speed;
    float wind;
    float size;
    float opacity;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

static float camadaDeNeve(float2 uv, float d, float s) {
    float2 g = uv * d;
    g.x += eng.acTime * u.wind * d * 0.5;
    g.y += eng.acTime * u.speed * d * 0.3;
    float2 cell = floor(g);
    float2 f = fract(g) - 0.5;
    float r = hash21(cell);
    float r2 = hash21(cell + 17.3);
    float2 pos = (float2(r, r2) - 0.5) * 0.7;
    float dist = length(f - pos);
    return smoothstep(0.35 * s, 0.0, dist) * (0.4 + r * 0.6);
}

fragment float4 fx_um_snow_falling(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_snow_fallingParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float n = 0.0;
    n += camadaDeNeve(in.acScreenNorm, u.density * 0.5, u.size * 1.4) * 0.5;
    n += camadaDeNeve(in.acScreenNorm, u.density,        u.size)        * 0.8;
    n += camadaDeNeve(in.acScreenNorm, u.density * 1.6,  u.size * 0.7)  * 1.0;
    n = clamp(n, 0.0, 1.0);
    __nv_out = float4(mix(orig.rgb, float3(1.0), n * u.opacity), max(orig.a, n * u.opacity));
    return __nv_out;
}
