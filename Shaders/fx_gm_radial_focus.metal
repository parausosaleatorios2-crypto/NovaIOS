// ---------------------------------------------------------------------------
// Radial Focus
// origem : assets/effects/gm-radial_focus.xml
// id     : gm.custom.radial_focus
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_radial_focusParams {
    float focusRadius;
    float falloff;
    float strength;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 8;

fragment float4 fx_gm_radial_focus(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_radial_focusParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float d = length((uv - float2(0.5)) * float2(ar, 1.0));
  float amt = smoothstep(u.focusRadius, u.focusRadius + u.falloff, d) * u.strength * u.mixAmt;
  float r = amt * 0.035;
  float4 sum = inputImg.sample(__nv_smp, uv);
  for (int i = 0; i < TAPS; i++){
    float ang = float(i) * 6.2831853 / float(TAPS);
    float2 o = float2(cos(ang), sin(ang)) * r;
    sum += inputImg.sample(__nv_smp, uv + o);
  }
  __nv_out = sum / float(TAPS + 1);
    return __nv_out;
}
