// ---------------------------------------------------------------------------
// Light Sweep
// origem : assets/effects/gm-light_sweep.xml
// id     : gm.custom.light_sweep
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_light_sweepParams {
    float position;
    float width;
    float angle;
    float intensity;
    float4 sweepColor;
    float mixAmt;
};

fragment float4 fx_gm_light_sweep(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_light_sweepParams&  u    [[buffer(1)]],
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
  float rad = radians(u.angle);
  float2 dir = float2(cos(rad), sin(rad));
  float d = dot(uv - 0.5, dir) + 0.5;
  float band = 1.0 - smoothstep(0.0, u.width, abs(d - u.position));
  band = band * band;
  float3 col = c + u.sweepColor.rgb * band * u.intensity * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
