// ---------------------------------------------------------------------------
// Desfoque Tilt-Shift (Blurrr)
// origem : assets/effects/nv-blurrr-tilt.xml
// id     : nova.effect.blurrr.tilt
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_tiltParams {
    float radius;
    float bandCenter;
    float bandWidth;
    float falloff;
    float angle;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265;
const int N = 9;
const float OFF[9] = float[9](-4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0);
const float WT[9]  = float[9](0.028, 0.065, 0.121, 0.175, 0.198, 0.175, 0.121, 0.065, 0.028);

static float mascaraFoco(float2 uv) {
    float a = u.angle * PI / 180.0;
    float2 n = float2(-sin(a), cos(a));
    float d = abs(dot(uv - float2(0.5, u.bandCenter), n));
    float meiaFaixa = u.bandWidth * 0.5;
    return smoothstep(meiaFaixa, meiaFaixa + u.falloff, d);
}

fragment float4 fx_nv_blurrr_tilt(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_tiltParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 original = inputImg.sample(__nv_smp, in.acScreenNorm);
    float fora = mascaraFoco(in.acScreenNorm);
    float raio = u.radius * fora;
    if (raio <= 0.0 && eng.acPass == 1) { __nv_out = original; return __nv_out; }

    float2 direction = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = direction * eng.acTexelSize * (raio * eng.acEscalaDePixel);

    float4 soma = float4(0.0);
    for (int i = 0; i < N; i++) {
        float2 uv = in.acScreenNorm + passo * OFF[i];
        float4 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, uv) : hblur.sample(__nv_smp, uv);
        soma += c * WT[i];
    }

    if (eng.acPass == 0) {
        __nv_out = soma;
    } else {
        __nv_out = mix(original, soma, clamp(fora, 0.0, 1.0));
    }
    return __nv_out;
}
