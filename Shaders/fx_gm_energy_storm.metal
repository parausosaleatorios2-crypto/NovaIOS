// ---------------------------------------------------------------------------
// Energy Storm Pro
// origem : assets/effects/gm-energy_storm.xml
// id     : gm.custom.energy_storm
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_energy_stormParams {
    float scale;
    float speed;
    float intensity;
    float4 colorA;
    float4 colorB;
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
static float gmFbm(float2 p){
  float total = 0.0, amp = 0.5;
  for (int i = 0; i < 5; i++){
    total += amp * gmNoise(p);
    p = p * 2.11 + 7.7;
    amp *= 0.5;
  }
  return total;
}

fragment float4 fx_gm_energy_storm(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_energy_stormParams&  u    [[buffer(1)]],
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
  float2 p = uv * u.scale + float2(eng.acTime * u.speed * 0.7, -eng.acTime * u.speed);
  float n = gmFbm(p);
  float veins = 1.0 - abs(n * 2.0 - 1.0);
  veins = pow(smoothstep(0.34, 1.0, veins), 3.0);
  float pulse = 0.5 + 0.5 * sin(uv.y * 34.0 - eng.acTime * u.speed * 5.0 + n * 7.0);
  float energy = clamp((veins * 0.92 + pulse * 0.22) * u.intensity, 0.0, 1.6);
  float3 storm = mix(u.colorA.rgb, u.colorB.rgb, clamp(pulse * 0.7 + n, 0.0, 1.0)) * energy;
  float3 screen = 1.0 - (1.0 - c) * (1.0 - clamp(storm, 0.0, 1.0));
  float3 col = mix(c, screen, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * src.a, src.a);
    return __nv_out;
}
