// ---------------------------------------------------------------------------
// Effect Gaussian Blur Auto (NV)
// origem : assets/effects/nv-nodevideo-effect-gaussian-blur-auto.xml
// id     : nv.effect.nodevideo-effect-gaussian-blur-auto
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct nv_nodevideo_effect_gaussian_blur_autoParams { int __vazio; };

fragment float4 fx_nv_nodevideo_effect_gaussian_blur_auto(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant nv_nodevideo_effect_gaussian_blur_autoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    __nv_out = inputImg.sample(__nv_smp, in.acScreenNorm.xy);
    return __nv_out;
    return __nv_out;
}
