// ---------------------------------------------------------------------------
// Efeito Vertigo (Ultra Motion)
// origem : assets/effects/um-dolly-zoom.xml
// id     : nova.effect.ultramotion.dollyzoom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_dolly_zoomParams {
    float depth;
    float focus;
    float samples;
    float2 center;
};

fragment float4 fx_um_dolly_zoom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_dolly_zoomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int n = clamp(int(u.samples), 4, 32);
    float2 p = in.acScreenNorm - u.center;
    p.x *= eng.acAspect;
    float d = length(p);
    float peso = smoothstep(u.focus, u.focus + 0.3, d);
    if (peso <= 0.0 || abs(u.depth) < 1e-4) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }

    float4 soma = float4(0.0);
    for (int i = 0; i <= 32; i++) {
        if (i > n) break;
        float t = float(i) / float(n) - 0.5;
        float escala = 1.0 + u.depth * peso * t;
        float2 q = p / escala;
        q.x /= eng.acAspect;
        soma += inputImg.sample(__nv_smp, q + u.center);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
