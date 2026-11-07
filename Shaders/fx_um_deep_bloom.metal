// ---------------------------------------------------------------------------
// Brilho Profundo (Ultra Motion)
// origem : assets/effects/um-deep-bloom.xml
// id     : nova.effect.ultramotion.deepbloom
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_deep_bloomParams {
    float radius;
    float threshold;
    float smoothness;
    float gain;
};

// --- funcoes auxiliares do efeito
const int N = 13;
const float OFF[13] = float[13](-6.0,-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0,6.0);
const float WT[13]  = float[13](0.010,0.025,0.058,0.107,0.158,0.183,0.198,0.183,0.158,0.107,0.058,0.025,0.010);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_deep_bloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_deep_bloomParams&  u    [[buffer(1)]],
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
            float k = smoothstep(u.threshold, u.threshold + u.smoothness, l);
            c *= k * k;
        }
        soma += c * WT[i];
        pt += WT[i];
    }
    float3 bloom = soma / pt;
    if (eng.acPass == 0) { __nv_out = float4(bloom, 1.0); return __nv_out; }

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    // Screen blend
    float3 res = 1.0 - (1.0 - orig.rgb) * (1.0 - bloom * u.gain);
    __nv_out = float4(res, orig.a);
    return __nv_out;
}
