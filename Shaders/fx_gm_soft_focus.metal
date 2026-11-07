// ---------------------------------------------------------------------------
// Soft Focus
// origem : assets/effects/gm-soft_focus.xml
// id     : gm.custom.soft_focus
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_soft_focusParams {
    float radius;
    float screenAmt;
    float desat;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 8;

fragment float4 fx_gm_soft_focus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_soft_focusParams&  u    [[buffer(1)]],
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
  float ba = max(blur.a, 1e-4);
  float3 bc = mix(blur.rgb / ba, float3(gmLum(blur.rgb / ba)), u.desat);
  float sa = max(src.a, 1e-4);
  float3 sc = src.rgb / sa;
  float3 glow = float3(1.0) - (float3(1.0) - sc) * (float3(1.0) - bc * u.screenAmt * u.mixAmt);
  float a = src.a;
  __nv_out = float4(clamp(glow, 0.0, 1.0) * a, a);
    return __nv_out;
}
