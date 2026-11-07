// ---------------------------------------------------------------------------
// Directional Blur
// origem : assets/effects/gm-directional_blur.xml
// id     : gm.custom.directional_blur
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_directional_blurParams {
    float angle;
    float amount;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 12;

fragment float4 fx_gm_directional_blur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_directional_blurParams&  u    [[buffer(1)]],
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
  float4 sum = float4(0.0);
  for (int i = 0; i < TAPS; i++){
    float t = (float(i) / float(TAPS - 1) - 0.5) * u.amount * u.mixAmt;
    sum += inputImg.sample(__nv_smp, uv + dir * t);
  }
  __nv_out = sum / float(TAPS);
    return __nv_out;
}
