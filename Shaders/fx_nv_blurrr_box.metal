// ---------------------------------------------------------------------------
// Desfoque Caixa (Blurrr)
// origem : assets/effects/nv-blurrr-box.xml
// id     : nova.effect.blurrr.box
// passes : 2  (iterativo)
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_boxParams {
    float radius;
    float iterations;
};

fragment float4 fx_nv_blurrr_box(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_boxParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (u.radius <= 0.0) { __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm); return __nv_out; }
    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);

    float4 soma = float4(0.0);
    const int K = 9;
    for (int i = -4; i <= 4; i++) {
        float2 uv = in.acScreenNorm + passo * float(i) / 4.0;
        soma += (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
    }
    __nv_out = soma / float(K);
    return __nv_out;
}
