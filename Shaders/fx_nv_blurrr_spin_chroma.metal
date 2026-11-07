// ---------------------------------------------------------------------------
// Desfoque Giro Cromático (Blurrr)
// origem : assets/effects/nv-blurrr-spin-chroma.xml
// id     : nova.effect.blurrr.spinchroma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_spin_chromaParams {
    float angle;
    float chroma;
    float samples;
    float2 center;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

float canal(float2 uv, float2 c, float ang, int k, int n) {
    float2 p = uv - c; p.x *= eng.acAspect;
    float r = length(p);
    float a0 = __nv_atan(p.y, p.x);
    float s = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = (float(i)/float(n) - 0.5) * ang * PI / 180.0;
        float2 q = float2(cos(a0 + t), sin(a0 + t)) * r;
        q.x /= eng.acAspect;
        s += inputImg.sample(__nv_smp, c + q).rgb[k];
    }
    return s / float(n + 1);
}

fragment float4 fx_nv_blurrr_spin_chroma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_spin_chromaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 o = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.angle <= 0.0) { __nv_out = o; return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float r = canal(in.acScreenNorm, u.center, u.angle * (1.0 + u.chroma * 0.1), 0, n);
    float g = canal(in.acScreenNorm, u.center, u.angle,                           1, n);
    float b = canal(in.acScreenNorm, u.center, u.angle * (1.0 - u.chroma * 0.1), 2, n);
    __nv_out = float4(r, g, b, o.a);
    return __nv_out;
}
