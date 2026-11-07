// ---------------------------------------------------------------------------
// Teal and Orange
// origem : assets/effects/gm-teal_orange.xml
// id     : gm.custom.teal_orange
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_teal_orangeParams {
    float strength;
    float balance;
    float protectSkin;
    float mixAmt;
};

fragment float4 fx_gm_teal_orange(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_teal_orangeParams&  u    [[buffer(1)]],
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
  float sh = 1.0 - smoothstep(0.0, 0.55, l);
  float hi = smoothstep(0.42, 1.0, l);
  float3 teal   = float3(0.05, 0.42, 0.46);
  float3 orange = float3(1.00, 0.58, 0.20);
  float3 g = c;
  g = mix(g, g * (teal * 2.1 + 0.30), sh * u.strength * (1.0 - u.balance * 0.5));
  g = mix(g, g * (orange * 1.7 + 0.18), hi * u.strength * (0.55 + u.balance * 0.6));
  float skin = smoothstep(0.15, 0.55, c.r) * (1.0 - smoothstep(0.55, 0.85, c.b));
  g = mix(g, c, skin * u.protectSkin);
  float3 col = mix(c, clamp(g, 0.0, 1.0), u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
