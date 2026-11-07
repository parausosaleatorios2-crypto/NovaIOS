// ---------------------------------------------------------------------------
// Desfoque Radial Cromático (Blurrr)
// origem : assets/effects/nv-blurrr-radial-chroma.xml
// id     : nova.effect.blurrr.radialchroma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_radial_chromaParams {
    float strength;
    float chroma;
    float samples;
    float2 center;
};

// --- funcoes auxiliares do efeito
static float canal(float2 uv, float2 c, float esc, int k, int n) {
    float s = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = (float(i)/float(n) - 0.5) * esc;
        float2 dir = normalize(uv - c + float2(1e-5));
        float2 perp = float2(-dir.y, dir.x);
        s += inputImg.sample(__nv_smp, uv + perp * t).rgb[k];
    }
    return s / float(n + 1);
}

fragment float4 fx_nv_blurrr_radial_chroma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_radial_chromaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 o = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.strength <= 0.0) { __nv_out = o; return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float r = canal(in.acScreenNorm, u.center, u.strength * (1.0 + u.chroma), 0, n);
    float g = canal(in.acScreenNorm, u.center, u.strength,                    1, n);
    float b = canal(in.acScreenNorm, u.center, u.strength * (1.0 - u.chroma), 2, n);
    __nv_out = float4(r, g, b, o.a);
    return __nv_out;
}
