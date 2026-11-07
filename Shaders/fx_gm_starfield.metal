// ---------------------------------------------------------------------------
// Starfield
// origem : assets/effects/gm-starfield.xml
// id     : gm.custom.starfield
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_starfieldParams {
    float density;
    float brightness;
    float twinkle;
    float drift;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_starfield(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_starfieldParams&  u    [[buffer(1)]],
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
  float2 p = uv * float2(ar, 1.0) * u.density + float2(0.0, eng.acTime * u.drift * u.density);
  float2 g = floor(p);
  float2 f = fract(p);
  float s = 0.0;
  for (int y = 0; y <= 1; y++){
    for (int x = 0; x <= 1; x++){
      float2 o = float2(float(x), float(y));
      float h = gmHash(g + o);
      if (h > 0.72){
        float2 sp = o + float2(gmHash(g + o + 5.0), gmHash(g + o + 9.0));
        float d = length(sp - f);
        float tw = 0.6 + 0.4 * sin(eng.acTime * u.twinkle + h * 30.0);
        s += (smoothstep(0.06, 0.0, d) + 0.35 * smoothstep(0.30, 0.0, d)) * tw;
      }
    }
  }
  float3 col = c + float3(s) * u.brightness * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
