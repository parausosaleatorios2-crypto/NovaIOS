// ---------------------------------------------------------------------------
// Solar Flare Pro
// origem : assets/effects/gm-solar_flare.xml
// id     : gm.custom.solar_flare
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_solar_flareParams {
    float threshold;
    float intensity;
    float radius;
    float streak;
    float4 tint;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
const int TAPS = 16;

fragment float4 fx_gm_solar_flare(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_solar_flareParams&  u    [[buffer(1)]],
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
  float3 ring = float3(0.0);
  float3 lineGlow = float3(0.0);
  for (int i = 0; i < TAPS; i++){
    float ang = float(i) * 6.2831853 / float(TAPS);
    float2 o = float2(cos(ang), sin(ang)) * u.radius;
    float3 s = inputImg.sample(__nv_smp, uv + o).rgb / max(inputImg.sample(__nv_smp, uv + o).a, 1e-4);
    ring += s * max(gmLum(s) - u.threshold, 0.0);
    float x = (float(i) / float(TAPS - 1) - 0.5) * u.radius * 4.0;
    float3 h = inputImg.sample(__nv_smp, uv + float2(x, 0.0)).rgb / max(inputImg.sample(__nv_smp, uv + float2(x, 0.0)).a, 1e-4);
    lineGlow += h * max(gmLum(h) - u.threshold, 0.0);
  }
  ring /= float(TAPS);
  lineGlow /= float(TAPS);
  float2 d = (uv - 0.5) * float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
  float spikes = pow(abs(cos(__nv_atan(d.y, d.x) * 4.0)), 12.0);
  float3 flare = (ring + lineGlow * u.streak) * u.intensity * (0.78 + 0.35 * spikes);
  float3 col = c + flare * u.tint.rgb * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * src.a, src.a);
    return __nv_out;
}
