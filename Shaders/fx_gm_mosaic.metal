// ---------------------------------------------------------------------------
// Mosaic Tiles
// origem : assets/effects/gm-mosaic.xml
// id     : gm.custom.mosaic
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_mosaicParams {
    float cells;
    float grout;
    float4 groutColor;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_mosaic(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_mosaicParams&  u    [[buffer(1)]],
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
  float ar = eng.acScreenSize.x / max(eng.acScreenSize.y, 1.0);
  float2 p = uv * float2(ar, 1.0) * u.cells;
  float2 g = floor(p);
  float d1 = 8.0, d2 = 8.0;
  float2 best = float2(0.5);
  for (int y = -1; y <= 1; y++){
    for (int x = -1; x <= 1; x++){
      float2 o = float2(float(x), float(y));
      float2 pt = o + 0.5;
      float d = length(pt - fract(p));
      if (d < d1){ d2 = d1; d1 = d; best = (g + o + 0.5) / (float2(ar, 1.0) * u.cells); }
      else if (d < d2){ d2 = d; }
    }
  }
  float3 fill = inputImg.sample(__nv_smp, best).rgb / max(inputImg.sample(__nv_smp, best).a, 1e-4);
  float edge = smoothstep(0.0, u.grout, d2 - d1);
  float3 col = mix(u.groutColor.rgb, fill, edge);
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
