// ---------------------------------------------------------------------------
// Selective Saturation
// origem : assets/effects/gm-selective_sat.xml
// id     : gm.custom.selective_sat
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_selective_satParams {
    float amount;
    float falloff;
    float protectSkin;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float3 rgb2hsv(float3 c){
  float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
  float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
  float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
  float d = q.x - min(q.w, q.y);
  float e = 1.0e-10;
  return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
static float3 hsv2rgb(float3 c){
  float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
  float3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fragment float4 fx_gm_selective_sat(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_selective_satParams&  u    [[buffer(1)]],
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
  float3 hsv = rgb2hsv(clamp(c, 0.0, 1.0));
  float sat = hsv.y;
  float boost = u.amount * (1.0 - smoothstep(0.0, u.falloff, abs(sat - 0.35)));
  hsv.y = clamp(hsv.y + boost, 0.0, 1.0);
  float3 g = hsv2rgb(hsv);
  float skin = smoothstep(0.05, 0.20, hsv.x) * (1.0 - smoothstep(0.10, 0.22, hsv.x));
  g = mix(g, c, skin * u.protectSkin);
  float3 col = mix(c, g, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
