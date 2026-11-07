// ---------------------------------------------------------------------------
// Stained Glass
// origem : assets/effects/gm-stained_glass.xml
// id     : gm.custom.stained_glass
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_stained_glassParams {
    float cells;
    float leadWidth;
    float4 leadColor;
    float jitter;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }
static float2 gmCell(float2 g){
  return float2(gmHash(g), gmHash(g + 3.7));
}

fragment float4 fx_gm_stained_glass(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_stained_glassParams&  u    [[buffer(1)]],
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
      float2 pt = o + mix(float2(0.5), gmCell(g + o), u.jitter);
      float d = length(pt - fract(p));
      if (d < d1){ d2 = d1; d1 = d; best = (g + o + mix(float2(0.5), gmCell(g + o), u.jitter)) / (float2(ar, 1.0) * u.cells); }
      else if (d < d2){ d2 = d; }
    }
  }
  float3 fill = inputImg.sample(__nv_smp, best).rgb / max(inputImg.sample(__nv_smp, best).a, 1e-4);
  float lead = smoothstep(u.leadWidth, u.leadWidth * 0.6, d2 - d1);
  float3 col = mix(u.leadColor.rgb, fill, lead);
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
