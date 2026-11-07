// ---------------------------------------------------------------------------
// Halftone
// origem : assets/effects/gm-halftone.xml
// id     : gm.custom.halftone
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_halftoneParams {
    float scale;
    float angle;
    float contrast;
    int mono;
    float mixAmt;
};

fragment float4 fx_gm_halftone(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_halftoneParams&  u    [[buffer(1)]],
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
  float3 base = u.mono ? float3(gmLum(c)) : c;
  base = clamp((base - 0.5) * u.contrast + 0.5, 0.0, 1.0);
  float rad = radians(u.angle);
  float2 rp = float2(uv.x * cos(rad) - uv.y * sin(rad), uv.x * sin(rad) + uv.y * cos(rad));
  float2 cell = fract(rp * u.scale) - 0.5;
  float d = length(cell);
  float3 dots;
  dots.r = step(d, sqrt(base.r) * 0.5);
  dots.g = step(d, sqrt(base.g) * 0.5);
  dots.b = step(d, sqrt(base.b) * 0.5);
  float3 col = mix(c, dots, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
