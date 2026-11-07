// ---------------------------------------------------------------------------
// Mirror Split
// origem : assets/effects/gm-mirror_split.xml
// id     : gm.custom.mirror_split
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_mirror_splitParams {
    int mode;
    float seam;
    float feather;
    float mixAmt;
};

fragment float4 fx_gm_mirror_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_mirror_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 m = uv;
  if (u.mode <= 0)      m.x = mix(uv.x, u.seam - abs(uv.x - u.seam), step(u.seam, uv.x));
  else if (u.mode <= 1) m.x = mix(u.seam + abs(uv.x - u.seam), uv.x, step(u.seam, uv.x));
  else if (u.mode <= 2) m.y = mix(uv.y, u.seam - abs(uv.y - u.seam), step(u.seam, uv.y));
  else                m.y = mix(u.seam + abs(uv.y - u.seam), uv.y, step(u.seam, uv.y));
  float4 a = inputImg.sample(__nv_smp, uv);
  float4 b = inputImg.sample(__nv_smp, m);
  float edge = smoothstep(0.0, u.feather + 1e-5, abs((u.mode <= 1 ? uv.x : uv.y) - u.seam));
  __nv_out = mix(a, b, edge * u.mixAmt);
    return __nv_out;
}
