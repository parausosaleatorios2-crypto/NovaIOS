// ---------------------------------------------------------------------------
// Halação de Filme (Ultra Motion)
// origem : assets/effects/um-halation.xml
// id     : nova.effect.ultramotion.halation
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_halationParams {
    float radius;
    float threshold;
    float intensity;
    float4 tint;
};

// --- funcoes auxiliares do efeito
const int N = 9;
const float OFF[9] = float[9](-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0);
const float WT[9]  = float[9](0.028,0.070,0.133,0.196,0.228,0.196,0.133,0.070,0.028);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_halation(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_halationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);
    float soma = 0.0;
    float pt = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i];
        if (eng.acPass == 0) {
            float3 c = inputImg.sample(__nv_smp, u).rgb;
            float l = dot(c, LUMA);
            soma += smoothstep(u.threshold, u.threshold + 0.1, l) * WT[i];
        } else {
            soma += hblur.sample(__nv_smp, u).r * WT[i];
        }
        pt += WT[i];
    }
    float halo = soma / pt;
    if (eng.acPass == 0) { __nv_out = float4(halo, 0.0, 0.0, 1.0); return __nv_out; }
    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    __nv_out = float4(orig.rgb + u.tint.rgb * u.tint.a * halo * u.intensity, orig.a);
    return __nv_out;
}
