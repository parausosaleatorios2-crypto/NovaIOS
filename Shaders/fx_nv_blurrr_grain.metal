// ---------------------------------------------------------------------------
// Grão + Desfoque (Blurrr)
// origem : assets/effects/nv-blurrr-grain.xml
// id     : nova.effect.blurrr.grain
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_grainParams {
    float radius;
    float grain;
    float speed;
};

// --- funcoes auxiliares do efeito
const int N = 7;
const float OFF[7] = float[7](-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0);
const float WT[7]  = float[7](0.071,0.131,0.190,0.216,0.190,0.131,0.071);

static float hash(float2 p) { return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453); }

fragment float4 fx_nv_blurrr_grain(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_grainParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);
    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        soma += ((eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv)) * WT[i];
    }
    if (eng.acPass == 0) { __nv_out = soma; return __nv_out; }

    float g = (hash(in.acScreenNorm * 1024.0 + float2(eng.acTime * u.speed * 37.0)) - 0.5) * 2.0 * u.grain;
    __nv_out = float4(soma.rgb + g, soma.a);
    return __nv_out;
}
