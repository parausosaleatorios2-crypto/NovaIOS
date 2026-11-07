// ---------------------------------------------------------------------------
// Cold Steel
// origem : assets/effects/gm-cold_steel.xml
// id     : gm.custom.cold_steel
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_cold_steelParams {
    float coolness;
    float contrast;
    float shadowTint;
    float mixAmt;
};

fragment float4 fx_gm_cold_steel(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_cold_steelParams&  u    [[buffer(1)]],
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
  float l = gmLum(c);
  float3 cold = float3(0.86, 1.00, 1.14);
  float3 g = c * mix(float3(1.0), cold, u.coolness);
  float sh = 1.0 - smoothstep(0.0, 0.5, l);
  g = mix(g, g * float3(0.85, 0.98, 1.15), sh * u.shadowTint);
  g = clamp((g - 0.5) * u.contrast + 0.5, 0.0, 1.0);
  float3 col = mix(c, g, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
