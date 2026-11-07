// ---------------------------------------------------------------------------
// VHS Tape
// origem : assets/effects/gm-vhs.xml
// id     : gm.custom.vhs
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_vhsParams {
    float wobble;
    float bleed;
    float noise;
    float speed;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_vhs(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_vhsParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float t = eng.acTime * u.speed;
  uv.x += sin(uv.y * 90.0 + t) * u.wobble * u.mixAmt;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = src.a;
  float3 c = src.rgb / max(a, 1e-4);
  float rr = inputImg.sample(__nv_smp, uv + float2(u.bleed, 0.0)).r / max(inputImg.sample(__nv_smp, uv + float2(u.bleed, 0.0)).a, 1e-4);
  float bb = inputImg.sample(__nv_smp, uv - float2(u.bleed, 0.0)).b / max(inputImg.sample(__nv_smp, uv - float2(u.bleed, 0.0)).a, 1e-4);
  c = mix(c, float3(rr, c.g, bb), 0.8);
  float n = gmHash(floor(uv * eng.acScreenSize) + floor(t * 60.0));
  c += (n - 0.5) * u.noise * 0.4;
  __nv_out = float4(clamp(c, 0.0, 1.0) * a, a);
    return __nv_out;
}
