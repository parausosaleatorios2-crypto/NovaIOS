// ---------------------------------------------------------------------------
// Faded Matte
// origem : assets/effects/gm-fade_matte.xml
// id     : gm.custom.fade_matte
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_fade_matteParams {
    float fade;
    float desat;
    float rolloff;
    float4 tint;
    float mixAmt;
};

fragment float4 fx_gm_fade_matte(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_fade_matteParams&  u    [[buffer(1)]],
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
  g = g * (1.0 - u.rolloff * smoothstep(0.6, 1.0, gmLum(g)));
  float3 col = mix(c, g, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
