// ---------------------------------------------------------------------------
// Perspective Warp
// origem : assets/effects/gm-perspective.xml
// id     : gm.custom.perspective
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_perspectiveParams {
    float tiltX;
    float tiltY;
    float zoom;
    float mixAmt;
};

fragment float4 fx_gm_perspective(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_perspectiveParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 p = (uv - 0.5) * 2.0;
  float w = 1.0 + u.tiltX * p.x * u.mixAmt + u.tiltY * p.y * u.mixAmt;
  p /= max(w, 0.1);
  p /= max(u.zoom, 0.05);
  float2 tuv = p * 0.5 + 0.5;
  float4 warped = inputImg.sample(__nv_smp, tuv);
  float4 orig = inputImg.sample(__nv_smp, uv);
  float inside = step(0.0, tuv.x) * step(tuv.x, 1.0) * step(0.0, tuv.y) * step(tuv.y, 1.0);
  __nv_out = mix(orig, warped * inside, u.mixAmt);
    return __nv_out;
}
