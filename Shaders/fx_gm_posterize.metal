// ---------------------------------------------------------------------------
// Posterize
// origem : assets/effects/gm-posterize.xml
// id     : gm.custom.posterize
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_posterizeParams {
    float steps;
    float gamma;
    float mixAmt;
};

fragment float4 fx_gm_posterize(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_posterizeParams&  u    [[buffer(1)]],
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
  c = pow(c, float3(1.0 / max(u.gamma, 0.05)));
  float n = max(u.steps, 2.0) - 1.0;
  float3 q = floor(c * n + 0.5) / n;
  float3 col = mix(c, q, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
