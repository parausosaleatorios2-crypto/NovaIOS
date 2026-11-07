// ---------------------------------------------------------------------------
// Super 8
// origem : assets/effects/gm-super8.xml
// id     : gm.custom.super8
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_super8Params {
    float weave;
    float grain;
    float warmth;
    float vignette;
    float speed;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_super8(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_super8Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float t = eng.acTime * u.speed;
  uv += float2(sin(t) * 0.5 + sin(t * 1.7) * 0.5, cos(t * 1.3)) * u.weave;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = max(src.a, 1e-4);
  float3 c = src.rgb / a;
  c *= mix(float3(1.0), float3(1.12, 0.98, 0.82), u.warmth);
  float n = gmHash(floor(uv * eng.acScreenSize) + floor(eng.acTime * 24.0)) - 0.5;
  c += n * u.grain * 0.35;
  float d = length((uv - 0.5) * float2(1.4, 1.0));
  c *= 1.0 - u.vignette * smoothstep(0.25, 0.9, d);
  __nv_out = float4(clamp(c, 0.0, 1.0) * a, a);
    return __nv_out;
}
