// ---------------------------------------------------------------------------
// Liquid Rupture Pro
// origem : assets/effects/gm-liquid_rupture.xml
// id     : gm.custom.liquid_rupture
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_liquid_ruptureParams {
    float amount;
    float scale;
    float speed;
    float chroma;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }
float gmNoise(float2 p){
  float2 i = floor(p), f = fract(p);
  float2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(gmHash(i), gmHash(i + float2(1.0, 0.0)), u.x),
             mix(gmHash(i + float2(0.0, 1.0)), gmHash(i + float2(1.0, 1.0)), u.x), u.y);
}
float gmFbm(float2 p){
  float total = 0.0, amp = 0.5;
  for (int i = 0; i < 5; i++){
    total += amp * gmNoise(p);
    p = p * 2.07 + 13.1;
    amp *= 0.5;
  }
  return total;
}

fragment float4 fx_gm_liquid_rupture(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_liquid_ruptureParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 baseUv = in.acScreenNorm;
  float t = eng.acTime * u.speed;
  float n1 = gmFbm(baseUv * u.scale + float2(t * 1.3, -t * 0.7));
  float n2 = gmFbm(baseUv.yx * u.scale + float2(-t, t * 1.4) + 17.0);
  float2 offset = (float2(n1, n2) - 0.5) * 2.0 * u.amount * u.mixAmt;
  float2 warped = baseUv + offset;
  float4 origin = inputImg.sample(__nv_smp, baseUv);
  float4 sr = inputImg.sample(__nv_smp, warped + float2(u.chroma * u.mixAmt, 0.0));
  float4 sg = inputImg.sample(__nv_smp, warped);
  float4 sb = inputImg.sample(__nv_smp, warped - float2(u.chroma * u.mixAmt, 0.0));
  float a = max(origin.a, 1e-4);
  float3 broken = float3(sr.r / max(sr.a, 1e-4), sg.g / max(sg.a, 1e-4), sb.b / max(sb.a, 1e-4));
  float4 outSrc = float4(clamp(broken, 0.0, 1.0) * a, a);
  __nv_out = mix(origin, outSrc, u.mixAmt);
    return __nv_out;
}
