// ---------------------------------------------------------------------------
// Comic Ink
// origem : assets/effects/gm-comic_ink.xml
// id     : gm.custom.comic_ink
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_comic_inkParams {
    float steps;
    float saturation;
    float inkThickness;
    float inkThreshold;
    float mixAmt;
};

fragment float4 fx_gm_comic_ink(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_comic_inkParams&  u    [[buffer(1)]],
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
  float3 sat = mix(float3(l), c, u.saturation);
  float n = max(u.steps, 2.0) - 1.0;
  float3 flat = floor(sat * n + 0.5) / n;
  float px = u.inkThickness / max(eng.acScreenSize.y, 1.0);
  float lx = gmLum(inputImg.sample(__nv_smp, uv + float2(px, 0.0)).rgb / max(inputImg.sample(__nv_smp, uv + float2(px, 0.0)).a, 1e-4));
  float ly = gmLum(inputImg.sample(__nv_smp, uv + float2(0.0, px)).rgb / max(inputImg.sample(__nv_smp, uv + float2(0.0, px)).a, 1e-4));
  float edge = abs(l - lx) + abs(l - ly);
  float ink = smoothstep(u.inkThreshold * 0.5, u.inkThreshold, edge * 6.0);
  float3 col = mix(flat, float3(0.0), ink);
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
