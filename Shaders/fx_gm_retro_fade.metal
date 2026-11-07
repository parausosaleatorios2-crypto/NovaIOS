// ---------------------------------------------------------------------------
// Retro Fade
// origem : assets/effects/gm-retro_fade.xml
// id     : gm.custom.retro_fade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_retro_fadeParams {
    float fade;
    float desat;
    float vignette;
    float4 tint;
    float mixAmt;
};

fragment float4 fx_gm_retro_fade(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_retro_fadeParams&  u    [[buffer(1)]],
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
  float3 g = mix(c, float3(gmLum(c)), u.desat);
  g = mix(g, u.tint.rgb, u.fade);
  g *= mix(1.0, 0.65, u.fade);
  float d = length((uv - 0.5) * float2(1.4, 1.0));
  g *= 1.0 - u.vignette * smoothstep(0.3, 0.85, d);
  float3 col = mix(c, g, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
