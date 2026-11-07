// ---------------------------------------------------------------------------
// Aberração Cromática Forte
// origem : assets/effects/nv-um-chromatic-aberration-strong.xml
// id     : nova.effect.um-chromatic-aberration-strong
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_um_chromatic_aberration_strongParams {
    float strength;
    float2 center;
    float samples;
};

fragment float4 fx_nv_um_chromatic_aberration_strong(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_um_chromatic_aberration_strongParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 uv = in.acScreenNorm;
    float2 d = uv - u.center;
    float dist = length(d);
    float2 dir = dist > 0.0001 ? d / dist : float2(0.0);

    int N = int(u.samples);
    float3 acc = float3(0.0);
    float a = 0.0;
    for (int i = 0; i < 16; i++) {
        if (i >= N) break;
        float t = float(i) / float(N - 1);
        float offR = u.strength * dist * (0.6 + 0.4 * t);
        float offG = u.strength * dist * 0.5 * t;
        float offB = -u.strength * dist * (0.6 + 0.4 * t);
        float4 cr = inputImg.sample(__nv_smp, uv + dir * offR);
        float4 cg = inputImg.sample(__nv_smp, uv + dir * offG);
        float4 cb = inputImg.sample(__nv_smp, uv + dir * offB);
        acc += float3(cr.r, cg.g, cb.b);
        a += cg.a;
    }
    __nv_out = float4(acc / float(N), a / float(N));
    return __nv_out;
}
