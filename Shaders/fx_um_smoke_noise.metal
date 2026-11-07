// ---------------------------------------------------------------------------
// Fumaça Procedural (Ultra Motion)
// origem : assets/effects/um-smoke-noise.xml
// id     : nova.effect.ultramotion.smokenoise
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_smoke_noiseParams {
    float scale;
    float speed;
    float density;
    float4 tint;
};

// --- funcoes auxiliares do efeito
float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float ruido(float2 p) {
    float2 i = floor(p), f = fract(p);
    float a = hash21(i), b = hash21(i + float2(1,0));
    float c = hash21(i + float2(0,1)), d = hash21(i + float2(1,1));
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(float2 p) {
    float v = 0.0; float a = 0.5;
    for (int i = 0; i < 5; i++) { v += a * ruido(p); p *= 2.0; a *= 0.5; }
    return v;
}

fragment float4 fx_um_smoke_noise(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_smoke_noiseParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 p = in.acScreenNorm * u.scale + float2(-eng.acTime * u.speed * 0.3, -eng.acTime * u.speed);
    float n = fbm(p);
    float alfa = clamp(n * u.density, 0.0, 1.0);
    float3 cor = mix(orig.rgb, u.tint.rgb, alfa * u.tint.a);
    __nv_out = float4(cor, orig.a);
    return __nv_out;
}
