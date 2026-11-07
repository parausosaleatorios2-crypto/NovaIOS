// ---------------------------------------------------------------------------
// Chromatic Aberration
// origem : assets/effects/gm-chromatic.xml
// id     : gm.custom.chromatic
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_chromaticParams {
    float amount;
    float falloff;
    float mixAmt;
};

fragment float4 fx_gm_chromatic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_chromaticParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 dir = uv - 0.5;
  float r = length(dir) * u.falloff;
  float2 o = dir * r * u.amount * u.mixAmt;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = src.a;
  float cr = inputImg.sample(__nv_smp, uv + o).r;
  float cg = src.g;
  float cb = inputImg.sample(__nv_smp, uv - o).b;
  __nv_out = float4(cr, cg, cb, a);
    return __nv_out;
}
