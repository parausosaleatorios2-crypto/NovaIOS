// ---------------------------------------------------------------------------
// Arco Elétrico (Ultra Motion)
// origem : assets/effects/um-electric-arc.xml
// id     : nova.effect.ultramotion.electricarc
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_electric_arcParams {
    float2 pointA;
    float2 pointB;
    float width;
    float jitter;
    float speed;
    float4 tint;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }

static float distReta(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h);
}

fragment float4 fx_um_electric_arc(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_electric_arcParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 A = u.pointA, B = u.pointB;
    float2 p = in.acScreenNorm;

    // t ao longo da linha
    float2 ba = B - A;
    float len2 = max(dot(ba, ba), 1e-6);
    float t = clamp(dot(p - A, ba) / len2, 0.0, 1.0);

    // o arco é a reta mais um deslocamento perpendicular barulhento
    float2 n = float2(-ba.y, ba.x) / sqrt(len2);
    float semente = floor(eng.acTime * u.speed);
    float ruido = 0.0;
    float amp = 1.0;
    for (int i = 0; i < 4; i++) {
        float f = pow(2.0, float(i)) * 6.0;
        ruido += (hash21(float2(floor(t * f), semente + float(i))) - 0.5) * amp;
        amp *= 0.5;
    }
    ruido *= u.jitter * (1.0 - abs(t - 0.5) * 2.0);
    float2 aoLongo = mix(A, B, t) + n * ruido;
    float d = length(p - aoLongo);

    float raio = smoothstep(u.width * 3.0, u.width, d);
    float glow = smoothstep(u.width * 15.0, u.width * 3.0, d) * 0.5;
    float3 cor = orig.rgb + u.tint.rgb * u.tint.a * (raio + glow);
    __nv_out = float4(cor, max(orig.a, (raio + glow) * u.tint.a));
    return __nv_out;
}
