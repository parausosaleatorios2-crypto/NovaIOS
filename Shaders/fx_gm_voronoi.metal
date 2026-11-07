// ---------------------------------------------------------------------------
// Voronoi Cells
// origem : assets/effects/gm-voronoi.xml
// id     : gm.custom.voronoi
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_voronoiParams {
    float cells;
    float speed;
    float amount;
    int edges;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }
float2 gmCell(float2 g){
  return float2(gmHash(g + floor(eng.acTime * u.speed)), gmHash(g + floor(eng.acTime * u.speed) + 3.7));
}

fragment float4 fx_gm_voronoi(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_voronoiParams&  u    [[buffer(1)]],
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
  for (int y = -1; y <= 1; y++){
    for (int x = -1; x <= 1; x++){
      float2 o = float2(float(x), float(y));
      float2 pt = o + gmCell(g + o);
      float d = length(pt - fract(p));
      d2 = min(d2, max(d1, d));
      d1 = min(d1, d);
    }
  }
  float field = d1;
  float edge = smoothstep(0.0, 0.08, d2 - d1);
  float3 col;
  if (u.edges) col = mix(float3(0.0), float3(1.0), edge);
  else col = float3(field);
  col = mix(c, col, u.amount * u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
