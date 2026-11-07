// ---------------------------------------------------------------------------
// Vaporwave
// origem : assets/effects/gm-vaporwave.xml
// id     : gm.custom.vaporwave
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_vaporwaveParams {
    float amount;
    float4 colorA;
    float4 colorB;
    float gridAmt;
    float gridRows;
    float mixAmt;
};

fragment float4 fx_gm_vaporwave(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_vaporwaveParams&  u    [[buffer(1)]],
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
  float3 grade = mix(u.colorA.rgb, u.colorB.rgb, l);
  float3 col = mix(c, c * 0.4 + grade * 0.75, u.amount * u.mixAmt);
  float g = abs(fract(uv.y * u.gridRows - eng.acTime * 0.3) - 0.5);
  float line = smoothstep(0.5, 0.46, g);
  col += u.colorB.rgb * line * u.gridAmt * smoothstep(0.4, 1.0, uv.y);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
