// ---------------------------------------------------------------------------
// Mono Contrast
// origem : assets/effects/gm-mono_contrast.xml
// id     : gm.custom.mono_contrast
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_mono_contrastParams {
    float contrast;
    float gamma;
    float brightness;
    float4 tint;
    float tintAmt;
    float mixAmt;
};

fragment float4 fx_gm_mono_contrast(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_mono_contrastParams&  u    [[buffer(1)]],
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
  l = clamp((l - 0.5) * u.contrast + 0.5 + u.brightness, 0.0, 1.0);
  l = pow(l, 1.0 / max(u.gamma, 0.05));
  float3 col = mix(float3(l), float3(l) * u.tint.rgb, u.tintAmt);
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
