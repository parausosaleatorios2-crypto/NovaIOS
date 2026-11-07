// ---------------------------------------------------------------------------
// Anamorphic Streak
// origem : assets/effects/gm-anamorphic.xml
// id     : gm.custom.anamorphic
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_anamorphicParams {
    float intensity;
    float length;
    float threshold;
    float4 streakColor;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 24;

fragment float4 fx_gm_anamorphic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_anamorphicParams&  u    [[buffer(1)]],
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
  float w = 1.0;
  for (int i = 0; i < TAPS; i++){
    float t = (float(i) / float(TAPS - 1) - 0.5) * u.length;
    float4 s = inputImg.sample(__nv_smp, uv + float2(t, 0.0));
    float3 sc = s.rgb / max(s.a, 1e-4);
    acc += sc * smoothstep(u.threshold, 1.0, gmLum(sc)) * w;
    w *= 0.94;
  }
  acc /= float(TAPS);
  float3 col = c + acc * u.streakColor.rgb * u.intensity * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
