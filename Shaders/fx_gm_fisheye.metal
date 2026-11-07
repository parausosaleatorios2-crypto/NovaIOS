// ---------------------------------------------------------------------------
// Fisheye
// origem : assets/effects/gm-fisheye.xml
// id     : gm.custom.fisheye
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_fisheyeParams {
    float strength;
    float scale;
    float mixAmt;
};

fragment float4 fx_gm_fisheye(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_fisheyeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float2 p = (uv - 0.5) * float2(ar, 1.0) * u.scale;
  float r2 = dot(p, p);
  p *= (1.0 + u.strength * r2 * u.mixAmt);
  uv = p / float2(ar, 1.0) + 0.5;
  __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
