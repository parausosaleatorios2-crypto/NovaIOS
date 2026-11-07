// ---------------------------------------------------------------------------
// Flares Arco-Íris (Ultra Motion)
// origem : assets/effects/um-rainbow-flares.xml
// id     : nova.effect.ultramotion.rainbowflares
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct um_rainbow_flaresParams {
    float2 source;
    float spacing;
    float size;
    float intensity;
};

// --- funcoes auxiliares do efeito
const int N_FLARES = 7;

float3 corDoDisco(int i) {
    if (i == 0) return float3(1.0, 0.0, 0.0);
    if (i == 1) return float3(1.0, 0.5, 0.0);
    if (i == 2) return float3(1.0, 1.0, 0.0);
    if (i == 3) return float3(0.0, 1.0, 0.2);
    if (i == 4) return float3(0.0, 0.7, 1.0);
    if (i == 5) return float3(0.3, 0.2, 1.0);
    return float3(0.8, 0.0, 1.0);
}

fragment float4 fx_um_rainbow_flares(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant um_rainbow_flaresParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
    float2 centro = float2(0.5);
    float2 dir = u.source - centro;
    float3 soma = float3(0.0);
    for (int i = 0; i < N_FLARES; i++) {
        float t = (float(i) + 1.0) / float(N_FLARES + 1);
        float2 pos = u.source - dir * (1.0 + t) * u.spacing * float(N_FLARES);
        float2 p = in.acScreenNorm - pos;
        p.x *= eng.acAspect;
        float d = length(p);
        float disco = smoothstep(u.size, 0.0, d);
        soma += corDoDisco(i) * disco;
    }
    __nv_out = float4(orig.rgb + soma * u.intensity, orig.a);
    return __nv_out;
}
