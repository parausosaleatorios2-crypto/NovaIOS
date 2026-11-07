// ---------------------------------------------------------------------------
// Sepia Tone
// origem : assets/effects/gm-sepia.xml
// id     : gm.custom.sepia
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_sepiaParams {
    float amount;
    float warmth;
    float mixAmt;
};

fragment float4 fx_gm_sepia(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_sepiaParams&  u    [[buffer(1)]],
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
  float3 warm = float3(1.07, 0.94, 0.74);
  float3 cool = float3(0.90, 0.93, 1.00);
  float3 sep = float3(l) * mix(cool, warm, u.warmth);
  sep.r *= 1.0 + 0.10 * u.warmth;
  sep.b *= 1.0 - 0.10 * u.warmth;
  float3 col = mix(c, clamp(sep, 0.0, 1.0), u.amount * u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
