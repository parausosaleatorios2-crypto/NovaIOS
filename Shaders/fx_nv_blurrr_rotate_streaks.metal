// ---------------------------------------------------------------------------
// Rastro Giratório (Blurrr)
// origem : assets/effects/nv-blurrr-rotate-streaks.xml
// id     : nova.effect.blurrr.rotatestreaks
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_rotate_streaksParams {
    float angle;
    float samples;
    float2 center;
};

fragment float4 fx_nv_blurrr_rotate_streaks(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_rotate_streaksParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (abs(u.angle) < 0.01) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float rad = radians(u.angle);

    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;

    float4 soma = float4(0.0);
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = (float(i) / float(n) - 0.5) * rad;
        float c = cos(t), s = sin(t);
        float2 q = float2(p.x * c - p.y * s, p.x * s + p.y * c);
        q.x /= eng.acAspect;
        soma += inputImg.sample(__nv_smp, q + u.center);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
