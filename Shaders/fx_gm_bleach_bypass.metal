// ---------------------------------------------------------------------------
// Bleach Bypass
// origem : assets/effects/gm-bleach_bypass.xml
// id     : gm.custom.bleach_bypass
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_bleach_bypassParams {
    float desat;
    float contrast;
    float lift;
    float mixAmt;
};

fragment float4 fx_gm_bleach_bypass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_bleach_bypassParams&  u    [[buffer(1)]],
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
  float3 base = mix(c, float3(l), u.desat);
  float3 bc = clamp((base - 0.5) * u.contrast + 0.5 + u.lift, 0.0, 1.0);
  bc = bc * bc * (3.0 - 2.0 * bc);            // soft S-curve
  float3 col = mix(c, bc, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
