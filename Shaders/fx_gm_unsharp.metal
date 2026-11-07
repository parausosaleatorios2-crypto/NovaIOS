// ---------------------------------------------------------------------------
// Unsharp Mask
// origem : assets/effects/gm-unsharp.xml
// id     : gm.custom.unsharp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_unsharpParams {
    float amount;
    float radius;
    float threshold;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 8;

fragment float4 fx_gm_unsharp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_unsharpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float4 src = inputImg.sample(__nv_smp, uv);
  float4 blur = float4(0.0);
  for (int i = 0; i < TAPS; i++){
    float ang = float(i) * 6.2831853 / float(TAPS);
    blur += inputImg.sample(__nv_smp, uv + float2(cos(ang), sin(ang)) * u.radius);
  }
  blur /= float(TAPS);
  float a = max(src.a, 1e-4);
  float3 sc = src.rgb / a;
  float3 bc = blur.rgb / max(blur.a, 1e-4);
  float3 detail = sc - bc;
  float m = smoothstep(u.threshold, u.threshold + 0.05, length(detail));
  float3 g = clamp(sc + detail * u.amount * m * u.mixAmt, 0.0, 1.0);
  __nv_out = float4(g * a, a);
    return __nv_out;
}
