// ---------------------------------------------------------------------------
// Twirl
// origem : assets/effects/gm-twirl.xml
// id     : gm.custom.twirl
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_twirlParams {
    float centerX;
    float centerY;
    float radius;
    float twist;
    float mixAmt;
};

fragment float4 fx_gm_twirl(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_twirlParams&  u    [[buffer(1)]],
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
  float ang = u.twist * (1.0 - smoothstep(0.0, u.radius, r)) * u.mixAmt;
  float s = sin(ang), c = cos(ang);
  float2 q = float2(p.x * c - p.y * s, p.x * s + p.y * c);
  uv = q / float2(ar, 1.0) + float2(u.centerX, u.centerY);
  __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
