// ---------------------------------------------------------------------------
// RGB Split
// origem : assets/effects/gm-rgb_split.xml
// id     : gm.custom.rgb_split
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_rgb_splitParams {
    float amount;
    float angle;
    float radial;
    float mixAmt;
};

fragment float4 fx_gm_rgb_split(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_rgb_splitParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float rad = radians(u.angle);
  float2 dir = float2(cos(rad), sin(rad));
  float2 rdir = normalize(uv - 0.5 + 1e-5);
  dir = normalize(mix(dir, rdir, u.radial) + 1e-5);
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = src.a;
  float amt = u.amount * u.mixAmt;
  float r = inputImg.sample(__nv_smp, uv + dir * amt).r;
  float g = src.g;
  float b = inputImg.sample(__nv_smp, uv - dir * amt).b;
  __nv_out = float4(r, g, b, a);
    return __nv_out;
}
