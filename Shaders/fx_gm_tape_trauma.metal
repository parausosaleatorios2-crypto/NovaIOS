// ---------------------------------------------------------------------------
// Tape Trauma Pro
// origem : assets/effects/gm-tape_trauma.xml
// id     : gm.custom.tape_trauma
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_tape_traumaParams {
    float wobble;
    float bleed;
    float noise;
    float tears;
    float speed;
    float mixAmt;
};

// --- funcoes auxiliares do efeito
static float gmHash(float2 p){ return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453123); }

fragment float4 fx_gm_tape_trauma(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_tape_traumaParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 baseUv = in.acScreenNorm;
  float4 origin = inputImg.sample(__nv_smp, baseUv);
  float t = floor(eng.acTime * u.speed);
  float2 uv = baseUv;
  float track = gmHash(float2(floor(baseUv.y * 18.0), t));
  float active = step(1.0 - u.tears, track);
  uv.x += sin(baseUv.y * 78.0 + eng.acTime * u.speed) * u.wobble * u.mixAmt;
  uv.x += (gmHash(float2(floor(baseUv.y * 18.0) * 3.1, t + 8.0)) - 0.5) * 0.13 * u.tears * active * u.mixAmt;
  float r = inputImg.sample(__nv_smp, uv + float2(u.bleed, 0.0)).r / max(inputImg.sample(__nv_smp, uv + float2(u.bleed, 0.0)).a, 1e-4);
  float4 mid = inputImg.sample(__nv_smp, uv);
  float g = mid.g / max(mid.a, 1e-4);
  float b = inputImg.sample(__nv_smp, uv - float2(u.bleed, 0.0)).b / max(inputImg.sample(__nv_smp, uv - float2(u.bleed, 0.0)).a, 1e-4);
  float3 c = float3(r, g, b);
  float grain = gmHash(floor(baseUv * eng.acScreenSize) + floor(eng.acTime * 60.0));
  c += (grain - 0.5) * u.noise * u.mixAmt;
  float scan = 1.0 - 0.13 * (0.5 + 0.5 * sin(baseUv.y * eng.acScreenSize.y * 3.1415926));
  c *= scan;
  c *= 1.0 - active * 0.34;
  float l = gmLum(c);
  c = mix(c, float3(l), 0.10);
  float3 col = mix(origin.rgb / max(origin.a, 1e-4), c, u.mixAmt);
  __nv_out = float4(clamp(col, 0.0, 1.0) * origin.a, origin.a);
    return __nv_out;
}
