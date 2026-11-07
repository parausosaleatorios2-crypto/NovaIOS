// ---------------------------------------------------------------------------
// Watercolor
// origem : assets/effects/gm-watercolor.xml
// id     : gm.custom.watercolor
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_watercolorParams {
    float warp;
    float steps;
    float bleed;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }
static float gmNoise(float2 p){
  float2 i = floor(p), f = fract(p);
  float2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(gmHash(i), gmHash(i + float2(1.0, 0.0)), u.x),
             mix(gmHash(i + float2(0.0, 1.0)), gmHash(i + float2(1.0, 1.0)), u.x), u.y);
}

fragment float4 fx_gm_watercolor(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_watercolorParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float n1 = gmNoise(uv * 30.0);
  float n2 = gmNoise(uv * 30.0 + 11.0);
  float2 wuv = uv + (float2(n1, n2) - 0.5) * u.warp;
  float4 src = inputImg.sample(__nv_smp, wuv);
  float a = max(src.a, 1e-4);
  float3 c = src.rgb / a;
  float3 soft = c;
  float px = 1.5 / max(eng.acScreenSize.y, 1.0);
  soft += inputImg.sample(__nv_smp, wuv + float2(px, 0.0)).rgb / max(inputImg.sample(__nv_smp, wuv + float2(px, 0.0)).a, 1e-4);
  soft += inputImg.sample(__nv_smp, wuv - float2(px, 0.0)).rgb / max(inputImg.sample(__nv_smp, wuv - float2(px, 0.0)).a, 1e-4);
  soft /= 3.0;
  float n = max(u.steps, 2.0) - 1.0;
  float3 flat = floor(soft * n + 0.5) / n;
  float3 col = mix(c, flat, u.mixAmt);
  col *= mix(1.0, 0.85 + 0.3 * gmNoise(uv * 400.0), u.bleed);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
