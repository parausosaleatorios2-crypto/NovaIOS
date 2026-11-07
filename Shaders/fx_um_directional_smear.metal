// ---------------------------------------------------------------------------
// Rastro Direcional (Ultra Motion)
// origem : assets/effects/um-directional-smear.xml
// id     : nova.effect.ultramotion.directionalsmear
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_directional_smearParams {
    float len;
    float angle;
    float falloff;
    float samples;
};

fragment float4 fx_um_directional_smear(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_directional_smearParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.len <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float rad = radians(u.angle);
    float2 dir = float2(cos(rad), sin(rad));
    dir.x /= eng.acAspect;

    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float w = pow(1.0 - t, u.falloff);
        soma += inputImg.sample(__nv_smp, in.acScreenNorm - dir * u.len * t) * w;
        pesoTot += w;
    }
    __nv_out = soma / max(pesoTot, 1e-4);
    return __nv_out;
}
