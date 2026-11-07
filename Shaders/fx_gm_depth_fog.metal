// ---------------------------------------------------------------------------
// Depth Fog
// origem : assets/effects/gm-depth_fog.xml
// id     : gm.custom.depth_fog
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_depth_fogParams {
    int mode;
    float4 fogColor;
    float density;
    float near;
    float mixAmt;
};

fragment float4 fx_gm_depth_fog(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_depth_fogParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = max(src.a, 1e-4);
  float3 c = src.rgb / a;
  float d;
  if (u.mode <= 0) d = 1.0 - gmLum(c);
  else if (u.mode <= 1) d = 1.0 - uv.y;
  else d = length(uv - 0.5) * 2.0;
  float f = clamp((d - u.near) * u.density, 0.0, 1.0) * u.mixAmt;
  float3 col = mix(c, u.fogColor.rgb, f);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
