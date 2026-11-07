// ---------------------------------------------------------------------------
// Rampa de gradiente
// origem : assets/effects/gradient-ramp.xml
// id     : nova.effect.gradientramp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gradient_rampParams {
    int shape;
    float2 startPoint;
    float2 endPoint;
    float4 startColor;
    float4 endColor;
    float rampCurve;
    float scatter;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

fragment float4 fx_gradient_ramp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gradient_rampParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 uv = in.acScreenNorm * float2(eng.acAspect, 1.0);
    float2 from = u.startPoint * float2(eng.acAspect, 1.0);
    float2 to = u.endPoint * float2(eng.acAspect, 1.0);

    float t;
    if (u.shape == 1) {
        // Radial: a distância até o início, medida em "quantos raios".
        float radius = max(length(to - from), 0.0001);
        t = length(uv - from) / radius;
    } else if (u.shape == 2) {
        // Ângulo: uma volta completa em torno do início. Vira cone de cor.
        float2 axis = to - from;
        float base = __nv_atan(axis.y, axis.x);
        float here = __nv_atan(uv.y - from.y, uv.x - from.x);
        t = fract((here - base) / TAU);
    } else {
        float2 axis = to - from;
        float lengthSquared = max(dot(axis, axis), 0.0001);
        // Projeção do ponto sobre o eixo: dá exatamente "o quanto andei do
        // início para o fim", sem precisar de trigonometria.
        t = dot(uv - from, axis) / lengthSquared;
    }

    t = clamp(t, 0.0, 1.0);
    t = pow(t, max(u.rampCurve, 0.01));

    if (u.scatter > 0.0) {
        t = clamp(t + (hash21(in.acScreenNorm * eng.acResolution) - 0.5) * u.scatter, 0.0, 1.0);
    }

    float4 ramp = mix(u.startColor, u.endColor, t);
    __nv_out = float4(ramp.rgb, ramp.a * original.a);
    return __nv_out;
}
