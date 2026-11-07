// ---------------------------------------------------------------------------
// Star Glow
// origem : assets/effects/gm-star_glow.xml
// id     : gm.custom.star_glow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_star_glowParams {
    float intensity;
    float length;
    float threshold;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 10;

fragment float4 fx_gm_star_glow(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_star_glowParams&  u    [[buffer(1)]],
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
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float3 acc = float3(0.0);
  for (int i = 0; i < TAPS; i++){
    float t = float(i) / float(TAPS - 1);
    float2 o = float2(t * u.length, 0.0);
    acc += inputImg.sample(__nv_smp, uv + o).rgb / max(inputImg.sample(__nv_smp, uv + o).a, 1e-4);
    acc += inputImg.sample(__nv_smp, uv - o).rgb / max(inputImg.sample(__nv_smp, uv - o).a, 1e-4);
    float2 ov = float2(0.0, t * u.length);
    acc += inputImg.sample(__nv_smp, uv + ov).rgb / max(inputImg.sample(__nv_smp, uv + ov).a, 1e-4);
    acc += inputImg.sample(__nv_smp, uv - ov).rgb / max(inputImg.sample(__nv_smp, uv - ov).a, 1e-4);
  }
  acc /= float(TAPS) * 4.0;
  acc *= smoothstep(u.threshold, 1.0, gmLum(acc));
  float3 col = c + acc * u.intensity * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
