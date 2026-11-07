// ---------------------------------------------------------------------------
// Bloom
// origem : assets/effects/gm-bloom.xml
// id     : gm.custom.bloom
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_bloomParams {
    float threshold;
    float intensity;
    float radius;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 12;

fragment float4 fx_gm_bloom(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_bloomParams&  u    [[buffer(1)]],
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
    float2 o = float2(cos(ang), sin(ang)) * u.radius;
    float4 s = inputImg.sample(__nv_smp, uv + o);
    float3 sc = s.rgb / max(s.a, 1e-4);
    float l = gmLum(sc);
    acc += sc * max(l - u.threshold, 0.0);
  }
  acc /= float(TAPS);
  float3 col = c + acc * u.intensity * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
