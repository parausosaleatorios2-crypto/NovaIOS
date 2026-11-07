// ---------------------------------------------------------------------------
// Movimento (Blurrr)
// origem : assets/effects/nv-blurrr-movement.xml
// id     : nova.effect.blurrr.movement
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_movementParams {
    float trailLen;
    float angle;
    float samples;
};

fragment float4 fx_nv_blurrr_movement(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_movementParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.trailLen <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float rad = radians(u.angle);
    float2 dir = float2(cos(rad), sin(rad));
    dir.x /= eng.acAspect;

    float4 soma = float4(0.0);
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        soma += inputImg.sample(__nv_smp, in.acScreenNorm + dir * u.trailLen * t);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
