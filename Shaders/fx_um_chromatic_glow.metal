// ---------------------------------------------------------------------------
// Brilho Cromático (Ultra Motion)
// origem : assets/effects/um-chromatic-glow.xml
// id     : nova.effect.ultramotion.chromaticglow
// passes : 2
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_chromatic_glowParams {
    float radius;
    float threshold;
    float intensity;
    float spread;
};

// --- funcoes auxiliares do efeito
const int N = 11;
const float OFF[11] = float[11](-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0);
const float WT[11]  = float[11](0.027,0.065,0.121,0.175,0.198,0.198,0.198,0.175,0.121,0.065,0.027);
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

float3 varrer(float2 uv, float2 d, float r, int canal, sampler2D s) {
    float2 passo = d * eng.acTexelSize * (r * eng.acEscalaDePixel);
    float3 soma = float3(0.0);
    float pt = 0.0;
    for (int i = 0; i < N; i++) {
        float2 u = uv + passo * OFF[i];
        float3 c = s.sample(__nv_smp, u).rgb;
        float g = smoothstep(u.threshold, u.threshold + 0.2, dot(c, LUMA));
        soma[canal] += c[canal] * g * WT[i];
        pt += WT[i];
    }
    return soma / pt;
}

fragment float4 fx_um_chromatic_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_chromatic_glowParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> hblur [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    if (eng.acPass == 0) {
        float2 d = float2(1.0, 0.0);
        float3 col = float3(0.0);
        col.r = varrer(in.acScreenNorm, d, u.radius * (1.0 + u.spread), 0, inputImg).r;
        col.g = varrer(in.acScreenNorm, d, u.radius,                  1, inputImg).g;
        col.b = varrer(in.acScreenNorm, d, u.radius * (1.0 - 0.5 * u.spread), 2, inputImg).b;
        __nv_out = float4(col, 1.0);
    } else {
        float2 d = float2(0.0, 1.0);
        float3 col = float3(0.0);
        col.r = varrer(in.acScreenNorm, d, u.radius * (1.0 + u.spread), 0, hblur).r;
        col.g = varrer(in.acScreenNorm, d, u.radius,                  1, hblur).g;
        col.b = varrer(in.acScreenNorm, d, u.radius * (1.0 - 0.5 * u.spread), 2, hblur).b;
        float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
        __nv_out = float4(orig.rgb + col * u.intensity, orig.a);
    }
    return __nv_out;
}
