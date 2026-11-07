// ---------------------------------------------------------------------------
// Raios de Deus (Ultra Motion)
// origem : assets/effects/um-god-rays.xml
// id     : nova.effect.ultramotion.godrays
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_god_raysParams {
    float density;
    float decay;
    float weight;
    float exposure;
    float threshold;
    float2 source;
};

// --- funcoes auxiliares do efeito
const float3 LUMA = float3(0.2126, 0.7152, 0.0722);

fragment float4 fx_um_god_rays(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_god_raysParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 delta = (in.acScreenNorm - u.source) / 64.0 * u.density;
    float2 uv = in.acScreenNorm;
    float illum = 1.0;
    float3 soma = float3(0.0);
    for (int i = 0; i < 64; i++) {
        uv -= delta;
        float3 c = inputImg.sample(__nv_smp, uv).rgb;
        float l = dot(c, LUMA);
        float k = smoothstep(u.threshold, u.threshold + 0.15, l);
        soma += c * k * illum * u.weight;
        illum *= u.decay;
    }
    __nv_out = float4(orig.rgb + soma * u.exposure, orig.a);
    return __nv_out;
}
