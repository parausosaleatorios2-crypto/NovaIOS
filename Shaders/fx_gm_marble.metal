// ---------------------------------------------------------------------------
// Marble
// origem : assets/effects/gm-marble.xml
// id     : gm.custom.marble
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_marbleParams {
    float scale;
    float veins;
    float amount;
    float4 colorA;
    float4 colorB;
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
  float a = 0.5, s = 0.0;
  for (int i = 0; i < 5; i++){ s += a * gmNoise(p); p *= 2.03; a *= 0.5; }
  return s;
}

fragment float4 fx_gm_marble(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_marbleParams&  u    [[buffer(1)]],
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
  float n = gmFbm(uv * u.scale);
  float m = 0.5 + 0.5 * sin((uv.x + n * 1.6) * u.veins * 3.14159);
  float3 marble = mix(u.colorA.rgb, u.colorB.rgb, m);
  float3 col = mix(c, marble, u.amount * u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
