// ---------------------------------------------------------------------------
// Caleidoscópio
// origem : assets/effects/kaleidoscope.xml
// id     : nova.effect.kaleidoscope
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct kaleidoscopeParams {
    float2 center;
    float sides;
    float spin;
    float zoom;
    float amount;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_kaleidoscope(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant kaleidoscopeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);

    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);
    float radius = length(offset) / max(u.zoom, 0.01);
    float angle = __nv_atan(offset.y, offset.x) + radians(u.spin);

    float segment = TAU / max(u.sides, 2.0);
    angle = __nv_mod(angle, segment);
    // Dobra a fatia ao meio. É este `abs` que faz o desenho espelhar em vez de
    // apenas se repetir — sem ele o resultado é um ventilador, não um
    // caleidoscópio.
    angle = abs(angle - segment * 0.5);

    float2 warped = float2(cos(angle), sin(angle)) * radius;
    float2 sampleUv = warped / float2(eng.acAspect, 1.0) + u.center;
    sampleUv = clamp(sampleUv, 0.0, 1.0);

    __nv_out = mix(original, inputImg.sample(__nv_smp, sampleUv), u.amount);
    return __nv_out;
}
