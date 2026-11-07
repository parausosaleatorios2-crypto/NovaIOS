// ---------------------------------------------------------------------------
// Tint (AE)
// origem : assets/effects/ae-tint.xml
// id     : nova.effect.aetint
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_tintParams {
    float4 mapBlackTo;
    float4 mapWhiteTo;
    float amountToTint;
};

fragment float4 fx_ae_tint(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_tintParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 cor = inputImg.sample(__nv_smp, in.acScreenNorm);
    // medido: os pesos da luminância de lá
    float y = dot(cor.rgb, float3(0.299, 0.587, 0.114));
    float3 alvo = mix(u.mapBlackTo.rgb, u.mapWhiteTo.rgb, y);
    __nv_out = float4(mix(cor.rgb, alvo, clamp(u.amountToTint / 100.0, 0.0, 1.0)), cor.a);
    return __nv_out;
}
