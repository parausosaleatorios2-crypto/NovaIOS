// ---------------------------------------------------------------------------
// Pixelado Suave (Blurrr)
// origem : assets/effects/nv-blurrr-pixelate.xml
// id     : nova.effect.blurrr.pixelate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_blurrr_pixelateParams {
    float size;
    float softness;
};

fragment float4 fx_nv_blurrr_pixelate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_blurrr_pixelateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float2 res = float2(eng.acAspect, 1.0);
    float2 cell = float2(u.size) * eng.acTexelSize * eng.acEscalaDePixel;
    float2 q = floor(in.acScreenNorm / cell) * cell + cell * 0.5;

    float4 bloco = inputImg.sample(__nv_smp, q);
    float4 real  = inputImg.sample(__nv_smp, in.acScreenNorm);

    // suaviza misturando a cor do bloco com a original pela distância ao centro
    float2 f = fract(in.acScreenNorm / cell) - 0.5;
    float d = max(abs(f.x), abs(f.y));
    float k = smoothstep(0.5 - u.softness * 0.5, 0.5, d);
    __nv_out = mix(bloco, real, k * u.softness);
    return __nv_out;
}
