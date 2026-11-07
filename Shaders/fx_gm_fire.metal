// ---------------------------------------------------------------------------
// Procedural Fire
// origem : assets/effects/gm-fire.xml
// id     : gm.custom.fire
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_fireParams {
    float scale;
    float speed;
    float heat;
    float amount;
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
  float a = 0.5, s = 0.0;
  for (int i = 0; i < 5; i++){ s += a * gmNoise(p); p *= 2.03; a *= 0.5; }
  return s;
}

fragment float4 fx_gm_fire(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_fireParams&  u    [[buffer(1)]],
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
  float2 p = uv * u.scale;
  p.y -= eng.acTime * u.speed;
  float n = gmFbm(p + float2(0.0, -uv.y * 3.0));
  float flame = pow(clamp(1.0 - uv.y, 0.0, 1.0), 1.6) * n * u.heat;
  float3 fire = mix(float3(1.0, 0.15, 0.0), float3(1.0, 0.95, 0.4), clamp(flame, 0.0, 1.0));
  fire *= clamp(flame, 0.0, 1.5);
  float3 col = c + fire * u.amount * u.mixAmt;
  __nv_out = float4(clamp(col, 0.0, 1.0) * a, a);
    return __nv_out;
}
