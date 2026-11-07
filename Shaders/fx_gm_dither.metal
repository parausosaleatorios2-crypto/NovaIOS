// ---------------------------------------------------------------------------
// Ordered Dither
// origem : assets/effects/gm-dither.xml
// id     : gm.custom.dither
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_ditherParams {
    float scale;
    float levels;
    int color;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float bayer(float2 p){
  float2 f = floor(__nv_mod(p, 4.0));
  float m = 0.0;
  if (f.y < 0.5){ m = f.x < 0.5 ? 0.0 : 2.0; }
  else { m = f.x < 0.5 ? 3.0 : 1.0; }
  return (m + 0.5) / 4.0;
}

fragment float4 fx_gm_dither(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_ditherParams&  u    [[buffer(1)]],
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
  float th = bayer(uv * eng.acScreenSize / max(u.scale, 1.0)) - 0.5;
  float n = max(u.levels, 2.0) - 1.0;
  float3 q;
  if (u.color) q = floor(c * n + 0.5 + th) / n;
  else { float l = floor(gmLum(c) * n + 0.5 + th) / n; q = float3(l); }
  float3 col = mix(c, clamp(q, 0.0, 1.0), u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
