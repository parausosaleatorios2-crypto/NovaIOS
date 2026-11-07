// ---------------------------------------------------------------------------
// Desfoque Zoom Cromático (Blurrr)
// origem : assets/effects/nv-blurrr-zoom-chroma.xml
// id     : nova.effect.blurrr.zoomchroma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_zoom_chromaParams {
    float strength;
    float chroma;
    float samples;
    float2 center;
};

// --- funcoes auxiliares do efeito
static float amostraCanal(float2 uv, float2 c, float esc, int canal, int n) {
    float soma = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float2 p = mix(uv, c, t * esc);
        soma += inputImg.sample(__nv_smp, p)[canal];
    }
    return soma / float(n + 1);
}

fragment float4 fx_nv_blurrr_zoom_chroma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_zoom_chromaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.strength <= 0.0) { __nv_out = original; return __nv_out; }

    int n = clamp(int(u.samples), 4, 48);
    float escR = u.strength * (1.0 + u.chroma);
    float escG = u.strength;
    float escB = u.strength * (1.0 - u.chroma);

    float r = amostraCanal(in.acScreenNorm, u.center, escR, 0, n);
    float g = amostraCanal(in.acScreenNorm, u.center, escG, 1, n);
    float b = amostraCanal(in.acScreenNorm, u.center, escB, 2, n);

    __nv_out = float4(r, g, b, original.a);
    return __nv_out;
}
