// ---------------------------------------------------------------------------
// Puxada de Foco (Blurrr)
// origem : assets/effects/nv-blurrr-focus-pull.xml
// id     : nova.effect.blurrr.focuspull
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_focus_pullParams {
    float radius;
    float sharpArea;
    float falloff;
    float2 center;
};

// --- funcoes auxiliares do efeito
const int N = 9;
const float OFF[9] = float[9](-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0);
const float WT[9]  = float[9](0.028,0.065,0.121,0.175,0.198,0.175,0.121,0.065,0.028);

static float fora(float2 uv) {
    float2 p = uv - u.center; p.x *= eng.acAspect;
    float r = length(p);
    return smoothstep(u.sharpArea, u.sharpArea + u.falloff, r);
}

fragment float4 fx_nv_blurrr_focus_pull(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_focus_pullParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float k = fora(in.acScreenNorm);
    float raio = u.radius * k;
    if (raio <= 0.0 && eng.acPass == 1) { __nv_out = original; return __nv_out; }

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (raio * eng.acEscalaDePixel);
    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        soma += ((eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv)) * WT[i];
    }
    if (eng.acPass == 0) { __nv_out = soma; }
    else { __nv_out = mix(original, soma, k); }
    return __nv_out;
}
