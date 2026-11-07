// ---------------------------------------------------------------------------
// Brilho Onírico (Ultra Motion)
// origem : assets/effects/um-dream-bloom.xml
// id     : nova.effect.ultramotion.dreambloom
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_dream_bloomParams {
    float radius;
    float intensity;
    float desat;
    float threshold;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_dream_bloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_dream_bloomParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 d = (eng.acPass == 0) ? float2(1.0, 0.0) : float2(0.0, 1.0);
    float2 passo = d * eng.acTexelSize * (u.radius * eng.acEscalaDePixel);
    float3 soma = float3(0.0);
    float pt = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = in.acScreenNorm + passo * OFF[i];
        float3 c = (eng.acPass == 0) ? inputImg.sample(__nv_smp, u).rgb : hblur.sample(__nv_smp, u).rgb;
        if (eng.acPass == 0) {
            float l = dot(c, LUMA);
            float k = smoothstep(u.threshold, u.threshold + 0.2, l);
            c *= k;
        }
        soma += c * WT[i];
        pt += WT[i];
    }
    float3 bloom = soma / pt;
    if (eng.acPass == 0) { __nv_out = float4(bloom, 1.0); return __nv_out; }

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float3 somado = orig.rgb + bloom * u.intensity;
    float l = dot(somado, LUMA);
    somado = mix(somado, float3(l), u.desat);
    __nv_out = float4(somado, orig.a);
    return __nv_out;
}
