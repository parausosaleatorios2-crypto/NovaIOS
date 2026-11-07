// ---------------------------------------------------------------------------
// Campo de Estrelas (Ultra Motion)
// origem : assets/effects/um-starfield.xml
// id     : nova.effect.ultramotion.starfield
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_starfieldParams {
    float density;
    float speed;
    float intensity;
    int onDark;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

static float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

static float camada(float2 uv, float d, float velo) {
    float2 g = uv * d + float2(eng.acTime * velo, 0.0);
    float2 cell = floor(g);
    float2 f = fract(g) - 0.5;
    float r = hash21(cell);
    float r2 = hash21(cell + 31.1);
    if (r < 0.9) return 0.0;
    float2 pos = (float2(r, r2) - 0.5) * 0.4;
    float dist = length(f - pos);
    return smoothstep(0.18, 0.0, dist) * (0.5 + r2 * 0.5);
}

fragment float4 fx_um_starfield(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_starfieldParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float n = 0.0;
    n += camada(in.acScreenNorm, u.density * 0.5, u.speed * 0.4) * 0.6;
    n += camada(in.acScreenNorm, u.density,       u.speed)       * 1.0;
    n += camada(in.acScreenNorm, u.density * 1.8, u.speed * 1.8) * 0.4;
    float l = dot(orig.rgb, LUMA);
    float peso = u.onDark ? (1.0 - smoothstep(0.2, 0.6, l)) : 1.0;
    __nv_out = float4(orig.rgb + float3(n * u.intensity * peso), orig.a);
    return __nv_out;
}
