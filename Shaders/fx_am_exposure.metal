// ---------------------------------------------------------------------------
// Exposição/gama
// origem : assets/effects/am-exposure.xml
// id     : nova.effect.am-exposure
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct am_exposureParams {
    float exposure;
    float gamma;
    float offset;
};

fragment float4 fx_am_exposure(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant am_exposureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 camada = inputImg.sample(__nv_smp, in.acScreenNorm);
    float a = camada.a;
    // A camada do AM chega pré-multiplicada EM 8 BITS: arredondada aqui do mesmo jeito (o premul do Android).
    float3 c = floor(camada.rgb * a * 255.0 + 0.5) / 255.0;
    c = c + float3(u.offset) * a;
    c = pow(max(c, float3(0.0)), float3(1.0 / u.gamma));               // base negativa: o NaN do AM grava 0
    c = c * pow(2.0, u.exposure);
    float3 saida = clamp(c, 0.0, 1.0);                             // o buffer de 8 bits do AM corta em 0 e 1
    __nv_out = a > 0.0 ? float4(min(saida / a, float3(1.0)), a) : float4(0.0);
    return __nv_out;
}
