// ---------------------------------------------------------------------------
// Faíscas (Ultra Motion)
// origem : assets/effects/um-sparkle.xml
// id     : nova.effect.ultramotion.sparkle
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_sparkleParams {
    float density;
    float size;
    float speed;
    float threshold;
    float4 tint;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

float cruz(float2 p, float r) {
    float h = smoothstep(r, 0.0, abs(p.y)) * smoothstep(r * 3.0, 0.0, abs(p.x));
    float v = smoothstep(r, 0.0, abs(p.x)) * smoothstep(r * 3.0, 0.0, abs(p.y));
    return max(h, v);
}

fragment float4 fx_um_sparkle(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_sparkleParams&  u    [[buffer(1)]],
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
    float fase = r * 6.2831853;
    float pisc = pow(max(sin(eng.acTime * u.speed + fase), 0.0), 3.0);

    float l = dot(orig.rgb, LUMA);
    float onde = smoothstep(u.threshold, u.threshold + 0.2, l);

    float estrela = cruz(f, 0.09 * u.size) * pisc * onde;
    __nv_out = float4(orig.rgb + u.tint.rgb * u.tint.a * estrela * 2.0, orig.a);
    return __nv_out;
}
