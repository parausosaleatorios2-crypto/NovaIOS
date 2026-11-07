// ---------------------------------------------------------------------------
// Plasma Field
// origem : assets/effects/gm-plasma.xml
// id     : gm.custom.plasma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_plasmaParams {
    float scale;
    float speed;
    float4 colorA;
    float4 colorB;
    float amount;
    float mixAmt;
};

fragment float4 fx_gm_plasma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_plasmaParams&  u    [[buffer(1)]],
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
  float t = eng.acTime * u.speed;
  float2 p = uv * u.scale;
  float v = sin(p.x + t) + sin(p.y * 1.3 - t * 0.8) + sin((p.x + p.y) * 0.7 + t * 1.2)
          + sin(length(p - u.scale * 0.5) * 2.0 - t * 2.0);
  v = v * 0.125 + 0.5;
  float3 pl = mix(u.colorA.rgb, u.colorB.rgb, clamp(v, 0.0, 1.0));
  float3 col = mix(c, pl, u.amount * u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
