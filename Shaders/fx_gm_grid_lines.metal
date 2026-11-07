// ---------------------------------------------------------------------------
// Grid Lines
// origem : assets/effects/gm-grid_lines.xml
// id     : gm.custom.grid_lines
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_grid_linesParams {
    float cols;
    float rows;
    float thickness;
    float4 lineColor;
    float scroll;
    float mixAmt;
};

fragment float4 fx_gm_grid_lines(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_grid_linesParams&  u    [[buffer(1)]],
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
  float2 p = uv * float2(u.cols, u.rows) + float2(0.0, eng.acTime * u.scroll);
  float2 g = abs(fract(p) - 0.5);
  float2 l = smoothstep(0.5 - u.thickness, 0.5, g);
  float line = max(l.x, l.y);
  float3 col = mix(c, u.lineColor.rgb, line * u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
