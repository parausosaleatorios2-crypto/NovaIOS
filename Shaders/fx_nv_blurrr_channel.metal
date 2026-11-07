// ---------------------------------------------------------------------------
// Desfoque por Canal (Blurrr)
// origem : assets/effects/nv-blurrr-channel.xml
// id     : nova.effect.blurrr.channel
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_channelParams {
    float red;
    float green;
    float blue;
    float alpha;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);

float4 gaussCanal(float2 uv, float2 d, float raio) {
    if (raio <= 0.0) {
        return (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
    }
    float2 passo = d * eng.acTexelSize * (raio * eng.acEscalaDePixel);
    float4 soma = float4(0.0);
    float pesoTot = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = uv + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u) : hblur.sample(__nv_smp, u);
        soma += c * WT[i];
        pesoTot += WT[i];
    }
    return soma / pesoTot;
}

fragment float4 fx_nv_blurrr_channel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_channelParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float4 r = gaussCanal(in.acScreenNorm, d, u.red);
    float4 g = gaussCanal(in.acScreenNorm, d, u.green);
    float4 b = gaussCanal(in.acScreenNorm, d, u.blue);
    float4 a = gaussCanal(in.acScreenNorm, d, u.alpha);
    __nv_out = float4(r.r, g.g, b.b, a.a);
    return __nv_out;
}
