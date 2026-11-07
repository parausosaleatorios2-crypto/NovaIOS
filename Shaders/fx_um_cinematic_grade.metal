// ---------------------------------------------------------------------------
// Gradação Cinema (Ultra Motion)
// origem : assets/effects/um-cinematic-grade.xml
// id     : nova.effect.ultramotion.cinematicgrade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_cinematic_gradeParams {
    float strength;
    float contrast;
    float sat;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);
const float3 TEAL = float3(0.18, 0.55, 0.60);
const float3 LARANJA = float3(1.0, 0.55, 0.20);

fragment float4 fx_um_cinematic_grade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_cinematic_gradeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    float l = dot(c.rgb, LUMA);
    // Contraste em torno de 0.5
    l = clamp((l - 0.5) * u.contrast + 0.5, 0.0, 1.0);

    float3 cor = mix(TEAL, LARANJA, l);
    float3 grad = mix(float3(l), cor, 0.35 * u.strength);

    // Saturação local
    float lg = dot(grad, LUMA);
    grad = mix(float3(lg), grad, u.sat);

    __nv_out = float4(mix(c.rgb, grad, u.strength), c.a);
    return __nv_out;
}
