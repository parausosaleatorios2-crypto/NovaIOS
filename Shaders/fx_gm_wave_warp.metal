// ---------------------------------------------------------------------------
// Wave Warp
// origem : assets/effects/gm-wave_warp.xml
// id     : gm.custom.wave_warp
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_wave_warpParams {
    float ampX;
    float ampY;
    float freqX;
    float freqY;
    float speed;
    float mixAmt;
};

fragment float4 fx_gm_wave_warp(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_wave_warpParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float t = eng.acTime * u.speed * 6.2831853;
  float2 o;
  o.x = sin(uv.y * u.freqY + t) * u.ampX;
  o.y = sin(uv.x * u.freqX + t) * u.ampY;
  uv += o * u.mixAmt;
  __nv_out = inputImg.sample(__nv_smp, uv);
    return __nv_out;
}
