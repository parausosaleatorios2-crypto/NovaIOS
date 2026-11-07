// ---------------------------------------------------------------------------
// Desfoque Perda de Foco (Blurrr)
// origem : assets/effects/nv-blurrr-defocus.xml
// id     : nova.effect.blurrr.defocus
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_defocusParams {
    float radius;
    float highlight;
    float threshold;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_nv_blurrr_defocus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_defocusParams&  u    [[buffer(1)]],
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
    float pesoTot = 0.0;
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
        if (eng.acPass == 0) {
            float luz = dot(c.rgb, LUMA);
            float k = smoothstep(u.threshold, u.threshold + 0.2, luz);
            c.rgb *= (1.0 + u.highlight * k);
        }
        soma += c * WT[i];
        pesoTot += WT[i];
    }
    __nv_out = soma / pesoTot;
    return __nv_out;
}
