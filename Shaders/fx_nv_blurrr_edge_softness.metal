// ---------------------------------------------------------------------------
// Suavizar Bordas (Blurrr)
// origem : assets/effects/nv-blurrr-edge-softness.xml
// id     : nova.effect.blurrr.edgesoftness
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_edge_softnessParams {
    float radius;
    float amount;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);

fragment float4 fx_nv_blurrr_edge_softness(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_edge_softnessParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = (eng.acPass == 0) ? inputImg.sample(__nv_smp, in.acScreenNorm) : hblur.sample(__nv_smp, in.acScreenNorm);
    if (u.radius <= 0.0 || u.amount <= 0.0) { __nv_out = cor; return __nv_out; }

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);

    float somaA = 0.0;
    float pesoTot = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i];
        float a = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u).a : hblur.sample(__nv_smp, u).a;
        somaA += a * WT[i];
        pesoTot += WT[i];
    }
    float alphaSoft = somaA / pesoTot;
    __nv_out = float4(cor.rgb, mix(cor.a, alphaSoft, u.amount));
    return __nv_out;
}
