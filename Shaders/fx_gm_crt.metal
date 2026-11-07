// ---------------------------------------------------------------------------
// CRT Screen
// origem : assets/effects/gm-crt.xml
// id     : gm.custom.crt
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_crtParams {
    float curvature;
    float mask;
    float scan;
    float edge;
    float mixAmt;
};

fragment float4 fx_gm_crt(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_crtParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 c = uv * 2.0 - 1.0;
  float r2 = dot(c, c);
  float2 w = c * (1.0 + u.curvature * r2 * u.mixAmt);
  uv = w * 0.5 + 0.5;
  float4 src = inputImg.sample(__nv_smp, clamp(uv, 0.0, 1.0));
  float a = max(src.a, 1e-4);
  float3 col = src.rgb / a;
  float u.mask = 1.0 - u.mask * (0.5 + 0.5 * sin(uv.x * eng.acScreenSize.x * 2.1));
  float u.scan = 1.0 - u.scan * (0.5 + 0.5 * sin(uv.y * eng.acScreenSize.y * 1.5));
  float vig = 1.0 - u.edge * smoothstep(0.4, 1.4, r2);
  col *= mix(1.0, u.mask * u.scan * vig, u.mixAmt);
  __nv_out = float4(col * src.a, src.a);
    return __nv_out;
}
