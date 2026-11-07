// ---------------------------------------------------------------------------
// Bulge and Pinch
// origem : assets/effects/gm-bulge.xml
// id     : gm.custom.bulge
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_bulgeParams {
    float centerX;
    float centerY;
    float radius;
    float amount;
    float mixAmt;
};

fragment float4 fx_gm_bulge(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_bulgeParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float2 p = (uv - float2(u.centerX, u.centerY)) * float2(ar, 1.0);
  float r = length(p);
  float t = clamp(r / max(u.radius, 1e-4), 0.0, 1.0);
  float f = 1.0 - u.amount * (1.0 - t * t) * u.mixAmt;
  float2 q = p * f;
  uv = q / float2(ar, 1.0) + float2(u.centerX, u.centerY);
  __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
