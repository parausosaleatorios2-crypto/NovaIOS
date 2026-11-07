// ---------------------------------------------------------------------------
// Soft Glow
// origem : assets/effects/gm-soft_glow.xml
// id     : gm.custom.soft_glow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_soft_glowParams {
    float intensity;
    float radius;
    float threshold;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 12;

fragment float4 fx_gm_soft_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_soft_glowParams&  u    [[buffer(1)]],
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
  float3 acc = float3(0.0);
  for (int i = 0; i < TAPS; i++){
    float ang = float(i) * 6.2831853 / float(TAPS);
    float4 s = inputImg.sample(__nv_smp, uv + float2(cos(ang), sin(ang)) * u.radius);
    acc += s.rgb / max(s.a, 1e-4);
  }
  acc /= float(TAPS);
  acc *= smoothstep(u.threshold, 1.0, gmLum(acc));
  float3 col = float3(1.0) - (float3(1.0) - c) * (float3(1.0) - acc * u.intensity * u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
