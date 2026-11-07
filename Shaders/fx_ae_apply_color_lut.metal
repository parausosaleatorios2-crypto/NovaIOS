// ---------------------------------------------------------------------------
// Apply Color LUT
// origem : assets/effects/ae-apply-color-lut.xml
// id     : nova.effect.aeapplycolorlut
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct ae_apply_color_lutParams {
    float4 lut;
};

fragment float4 fx_ae_apply_color_lut(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant ae_apply_color_lutParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    int2 T = int2(int(inputImg.get_width()), int(inputImg.get_height()));
    float4 fonte = inputImg.read(uint2(int2(min(floor(in.acScreenNorm * float2(T)), float2(T) - 1.0))), uint(0));
    __nv_out = float4(clamp(lutAplicar(fonte.rgb, true), 0.0, 1.0), fonte.a);
    return __nv_out;
}
