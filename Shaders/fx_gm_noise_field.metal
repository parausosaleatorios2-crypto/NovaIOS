// ---------------------------------------------------------------------------
// Noise Field
// origem : assets/effects/gm-noise_field.xml
// id     : gm.custom.noise_field
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_noise_fieldParams {
    float scale;
    float speed;
    float amount;
    float4 tint;
    int overlay;
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

fragment float4 fx_gm_noise_field(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_noise_fieldParams&  u    [[buffer(1)]],
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
  float n = gmFbm(uv * u.scale + eng.acTime * u.speed);
  float3 tinted = u.tint.rgb * n;
  float3 col;
  if (u.overlay) col = mix(c, 2.0 * c * tinted, u.amount * u.mixAmt);
  else col = mix(c, tinted, u.amount * u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
