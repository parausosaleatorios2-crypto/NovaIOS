// ---------------------------------------------------------------------------
// Posterizar
// origem : assets/effects/posterize.xml
// id     : nova.effect.posterize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct posterizeParams {
    float levels;
    int perChannel;
};

fragment float4 fx_posterize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant posterizeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 color = inputImg.sample(__nv_smp, in.acScreenNorm);
    float n = max(u.levels, 2.0);

    float3 quantized;
    if (u.perChannel) {
        // Quantiza R, G e B separadamente: gera cores novas na mistura, com
        // aquele visual de pôster serigrafado.
        quantized = floor(color.rgb * n) / (n - 1.0);
    } else {
        // Quantiza só o brilho e mantém o matiz: preserva a paleta original.
        float luma = dot(color.rgb, float3(0.299, 0.587, 0.114));
        float stepped = floor(luma * n) / (n - 1.0);
        quantized = luma > 0.0 ? color.rgb * (stepped / luma) : color.rgb;
    }

    __nv_out = float4(clamp(quantized, 0.0, 1.0), color.a);
    return __nv_out;
}
