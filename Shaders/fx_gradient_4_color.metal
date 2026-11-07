// ---------------------------------------------------------------------------
// Gradiente de 4 cores
// origem : assets/effects/gradient-4-color.xml
// id     : nova.effect.gradient4color
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gradient_4_colorParams {
    float2 point1;
    float4 color1;
    float2 point2;
    float4 color2;
    float2 point3;
    float4 color3;
    float2 point4;
    float4 color4;
    float sharpness;
    float scatter;
};

// --- funcoes auxiliares do efeito
static float hash21(float2 p) {
    p = fract(p * float2(127.1, 311.7));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

fragment float4 fx_gradient_4_color(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gradient_4_colorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 uv = in.acScreenNorm * float2(eng.acAspect, 1.0);

    float2 p1 = u.point1 * float2(eng.acAspect, 1.0);
    float2 p2 = u.point2 * float2(eng.acAspect, 1.0);
    float2 p3 = u.point3 * float2(eng.acAspect, 1.0);
    float2 p4 = u.point4 * float2(eng.acAspect, 1.0);

    // A faixa 1..8 é onde a transição continua macia (não vira um recorte
    // duro cedo demais), mas ainda dá pra sentir cada ponto dominando perto
    // de si quando `u.sharpness` sobe.
    float power = mix(1.0, 8.0, u.sharpness);

    float w1 = 1.0 / pow(max(distance(uv, p1), 0.0001), power);
    float w2 = 1.0 / pow(max(distance(uv, p2), 0.0001), power);
    float w3 = 1.0 / pow(max(distance(uv, p3), 0.0001), power);
    float w4 = 1.0 / pow(max(distance(uv, p4), 0.0001), power);
    float total = w1 + w2 + w3 + w4;

    float3 mixed = (u.color1.rgb * w1 + u.color2.rgb * w2 + u.color3.rgb * w3 + u.color4.rgb * w4) / total;

    // Mesmo espalhamento de `gradient-ramp.xml`: um ruído minúsculo antes de
    // arredondar quebra o banding de 8 bits num degradê suave.
    if (u.scatter > 0.0) {
        mixed += (hash21(in.acScreenNorm * eng.acResolution) - 0.5) * u.scatter;
    }
    mixed = clamp(mixed, 0.0, 1.0);

    __nv_out = float4(mixed, original.a);
    return __nv_out;
}
