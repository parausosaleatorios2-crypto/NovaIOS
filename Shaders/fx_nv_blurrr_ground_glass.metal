// ---------------------------------------------------------------------------
// Vidro Jateado (Blurrr)
// origem : assets/effects/nv-blurrr-ground-glass.xml
// id     : nova.effect.blurrr.groundglass
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_ground_glassParams {
    float spread;
    float samples;
    float seed;
};

// --- funcoes auxiliares do efeito
float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

fragment float4 fx_nv_blurrr_ground_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_ground_glassParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int n = clamp(int(u.samples), 4, 24);
    float4 soma = float4(0.0);
    for (int i = 0; i <= 24; i++) {
        if (i > n) break;
        float fi = float(i) + u.seed * 11.0;
        float2 j = float2(
            hash21(in.acScreenNorm * eng.acResolution + float2(fi, 0.0)) - 0.5,
            hash21(in.acScreenNorm * eng.acResolution + float2(0.0, fi + 7.0)) - 0.5
        ) * u.spread;
        soma += inputImg.sample(__nv_smp, in.acScreenNorm + j);
    }
    __nv_out = soma / float(n + 1);
    return __nv_out;
}
