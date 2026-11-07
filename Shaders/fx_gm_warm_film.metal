// ---------------------------------------------------------------------------
// Warm Film
// origem : assets/effects/gm-warm_film.xml
// id     : gm.custom.warm_film
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_warm_filmParams {
    float warmth;
    float lift;
    float contrast;
    float mixAmt;
};

fragment float4 fx_gm_warm_film(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_warm_filmParams&  u    [[buffer(1)]],
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
  float3 warm = float3(1.08, 1.00, 0.88);
  float3 g = c * mix(float3(1.0), warm, u.warmth);
  g = clamp((g - 0.5) * u.contrast + 0.5, 0.0, 1.0);
  g = g * g * (3.0 - 2.0 * g);
  g = g + u.lift * (1.0 - g);
  float3 col = mix(c, g, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
