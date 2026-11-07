// ---------------------------------------------------------------------------
// Desfoque Caleidoscópio (Blurrr)
// origem : assets/effects/nv-blurrr-kaleido.xml
// id     : nova.effect.blurrr.kaleido
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_kaleidoParams {
    float slices;
    float rotation;
    float zoom;
    float softness;
    float2 center;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const float TAU = 6.28318530;

static float4 fatiar(float2 uv, float jitter) {
    float2 p = uv - u.center;
    p.x *= eng.acAspect;
    float r = length(p);
    float ang = __nv_atan(p.y, p.x) - u.rotation * PI / 180.0 + jitter;

    float setor = TAU / max(float(u.slices), 1.0);
    ang = __nv_mod(ang, setor);
    if (ang > setor * 0.5) ang = setor - ang;

    float2 q = float2(cos(ang), sin(ang)) * (r / max(u.zoom, 0.01));
    q.x /= eng.acAspect;
    return inputImg.sample(__nv_smp, q + u.center);
}

fragment float4 fx_nv_blurrr_kaleido(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_kaleidoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.softness <= 0.0) {
        __nv_out = fatiar(in.acScreenNorm, 0.0);
        return __nv_out;
    }

    const int N = 5;
    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float jitter = (float(i) / float(N - 1) - 0.5) * u.softness * TAU;
        soma += fatiar(in.acScreenNorm, jitter);
    }
    __nv_out = soma / float(N);
    return __nv_out;
}
