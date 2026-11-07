// ---------------------------------------------------------------------------
// Cinematic Punch Pro
// origem : assets/effects/gm-cinematic_punch.xml
// id     : gm.custom.cinematic_punch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_cinematic_punchParams {
    float contrast;
    float saturation;
    float split;
    float vignette;
    float mixAmt;
};

fragment float4 fx_gm_cinematic_punch(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_cinematic_punchParams&  u    [[buffer(1)]],
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
  float l = gmLum(c);
  float sh = 1.0 - smoothstep(0.0, 0.58, l);
  float hi = smoothstep(0.40, 1.0, l);
  float3 grade = c;
  grade = mix(grade, grade * float3(0.55, 1.05, 1.18) * 1.18, sh * u.split);
  grade = mix(grade, grade * float3(1.30, 0.92, 0.62) * 1.16, hi * u.split);
  grade = clamp((grade - 0.5) * u.contrast + 0.5, 0.0, 1.0);
  grade = mix(float3(l), grade, u.saturation);
  float2 p = (uv - 0.5) * float2(eng.acScreenSize.x / eng.acScreenSize.y, 1.0);
  float edge = 1.0 - smoothstep(0.42, 0.82, length(p));
  grade *= mix(1.0, edge, u.vignette);
  float3 col = mix(c, grade, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * src.a, src.a);
    return __nv_out;
}
