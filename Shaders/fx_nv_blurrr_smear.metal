// ---------------------------------------------------------------------------
// Desfoque Arrastar (Blurrr)
// origem : assets/effects/nv-blurrr-smear.xml
// id     : nova.effect.blurrr.smear
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_smearParams {
    float comprimento;
    float angle;
    float samples;
    float falloff;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;

fragment float4 fx_nv_blurrr_smear(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_smearParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 o = inputImg.sample(__nv_smp, in.acScreenNorm);
    if (u.comprimento <= 0.0) { __nv_out = o; return __nv_out; }
    int n = clamp(int(u.samples), 4, 48);
    float a = u.angle * PI / 180.0;
    float2 d = float2(cos(a), sin(a));
    d.x /= max(eng.acAspect, 1e-4);

    float4 soma = float4(0.0);
    float peso = 0.0;
    for (int i = 0; i <= 48; i++) {
        if (i > n) break;
        float t = float(i) / float(n);
        float w = pow(1.0 - t, u.falloff);
        float2 uv = in.acScreenNorm - d * u.comprimento * t;
        soma += inputImg.sample(__nv_smp, uv) * w;
        peso += w;
    }
    __nv_out = soma / max(peso, 1e-4);
    return __nv_out;
}
