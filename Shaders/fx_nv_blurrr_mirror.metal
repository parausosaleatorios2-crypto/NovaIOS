// ---------------------------------------------------------------------------
// Desfoque Espelho (Blurrr)
// origem : assets/effects/nv-blurrr-mirror.xml
// id     : nova.effect.blurrr.mirror
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_mirrorParams {
    float axis;
    float mixAmount;
    float blurRadius;
    float center;
};

// --- funcoes auxiliares do efeito
const int N = 7;
const float OFF[7] = float[7](-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0);
const float WT[7]  = float[7](0.071, 0.131, 0.190, 0.216, 0.190, 0.131, 0.071);

static float2 espelhar(float2 uv) {
    int a = int(u.axis);
    if (a == 0) return float2(2.0 * u.center - uv.x, uv.y);
    if (a == 1) return float2(uv.x, 2.0 * u.center - uv.y);
    if (a == 2) return 2.0 * float2(u.center) - uv;
    return float2(2.0 * u.center - uv.x, 2.0 * u.center - uv.y);
}

fragment float4 fx_nv_blurrr_mirror(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_mirrorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 direction = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = direction * eng.acTexelSize * (u.blurRadius * eng.acEscalaDePixel);

    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
        soma += c * WT[i];
    }

    if (eng.acPass == 0) {
        __nv_out = soma;
        return __nv_out;
    }

    float4 espelhado = hblur.sample(__nv_smp, espelhar(in.acScreenNorm));
    float4 direto    = soma;
    __nv_out = mix(direto, espelhado, u.mixAmount);
    return __nv_out;
}
