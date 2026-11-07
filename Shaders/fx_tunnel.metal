// ---------------------------------------------------------------------------
// Túnel
// origem : assets/effects/tunnel.xml
// id     : nova.effect.tunnel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct tunnelParams {
    float2 center;
    float repeats;
    float travelSpeed;
    float travel;
    float spin;
};

// --- funcoes auxiliares do efeito
const float TAU = 6.28318530718;

fragment float4 fx_tunnel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant tunnelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 offset = (in.acScreenNorm - u.center) * float2(eng.acAspect, 1.0);

    float angle = __nv_atan(offset.y, offset.x) + radians(u.spin);
    float radius = max(length(offset), 0.0001);

    // O inverso do raio é o que faz o centro "sumir pra dentro" — perto
    // dele, uma variação minúscula de raio já vale uma volta inteira na
    // repetição, e é isso que lê como profundidade correndo.
    float depth = u.repeats / radius - (eng.acTime * u.travelSpeed + u.travel);

    float2 tunnelUv = float2(fract(angle / TAU + 0.5), fract(depth));
    __nv_out = inputImg.sample(__nv_smp, tunnelUv);
    return __nv_out;
}
