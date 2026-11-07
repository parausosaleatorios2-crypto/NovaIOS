// ---------------------------------------------------------------------------
// Radial Rush Pro
// origem : assets/effects/gm-radial_rush.xml
// id     : gm.custom.radial_rush
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_radial_rushParams {
    float centerX;
    float centerY;
    float amount;
    float chroma;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 16;

fragment float4 fx_gm_radial_rush(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_radial_rushParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 baseUv = in.acScreenNorm;
  float2 centre = float2(u.centerX, u.centerY);
  float4 acc = float4(0.0);
  for (int i = 0; i < TAPS; i++){
    float t = (float(i) / float(TAPS - 1) - 0.5) * u.amount * u.mixAmt;
    float2 p = centre + (baseUv - centre) * (1.0 + t);
    acc += inputImg.sample(__nv_smp, p);
  }
  acc /= float(TAPS);
  float a = max(acc.a, 1e-4);
  float2 radial = (baseUv - centre) * u.amount * u.chroma * u.mixAmt;
  float r = inputImg.sample(__nv_smp, baseUv + radial).r / max(inputImg.sample(__nv_smp, baseUv + radial).a, 1e-4);
  float g = acc.rgb.g / a;
  float b = inputImg.sample(__nv_smp, baseUv - radial).b / max(inputImg.sample(__nv_smp, baseUv - radial).a, 1e-4);
  __nv_out = float4(clamp(float3(r, g, b), 0.0, 1.0) * a, a);
    return __nv_out;
}
