// ---------------------------------------------------------------------------
// Vignette Pro
// origem : assets/effects/gm-vignette_pro.xml
// id     : gm.custom.vignette_pro
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_vignette_proParams {
    float size;
    float softness;
    float roundness;
    float amount;
    float4 vigColor;
    float mixAmt;
};

fragment float4 fx_gm_vignette_pro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_vignette_proParams&  u    [[buffer(1)]],
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
  float2 p = (uv - 0.5) * 2.0;
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float d = mix(max(abs(p.x), abs(p.y)), length(p * float2(ar, 1.0) / max(ar, 1.0)), u.roundness);
  float v = smoothstep(u.size, u.size + u.softness, d) * u.amount * u.mixAmt;
  float3 col = mix(c, u.vigColor.rgb, clamp(v, 0.0, 1.0));
  __nv_out = float4(col * a, a);
    return __nv_out;
}
