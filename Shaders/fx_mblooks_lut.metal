// ---------------------------------------------------------------------------
// Looks: LUT
// origem : assets/effects/mblooks-lut.xml
// id     : nova.effect.mblooks.lut
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
#include "NovaLut.h"
using namespace metal;

struct mblooks_lutParams {
    float4 lut;
    float menu;
    float strength;
};

fragment float4 fx_mblooks_lut(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant mblooks_lutParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture3d<float> lutTex [[texture(1)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

    float4 c = inputImg.sample(__nv_smp, in.acScreenNorm);
    // LUT do Magic Bullet Looks com forca ajustavel (0-100).
    __nv_out = float4(mix(c.rgb, nova_lut3d(lutTex, c.rgb), clamp(u.strength / 100.0, 0.0, 1.0)), c.a);
    return __nv_out;
}
