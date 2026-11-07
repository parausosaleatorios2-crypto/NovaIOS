// ---------------------------------------------------------------------------
// Scanlines
// origem : assets/effects/gm-scanlines.xml
// id     : gm.custom.scanlines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_scanlinesParams {
    float density;
    float strength;
    float roll;
    float mixAmt;
};

fragment float4 fx_gm_scanlines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_scanlinesParams&  u    [[buffer(1)]],
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
  float y = uv.y * u.density + eng.acTime * u.roll;
  float s = 0.5 + 0.5 * sin(y * 6.2831853);
  float m = mix(1.0 - u.strength, 1.0, s);
  c *= mix(1.0, m, u.mixAmt);
  __nv_out = float4(c * src.a, src.a);
    return __nv_out;
}
