// ---------------------------------------------------------------------------
// Channel Mixer
// origem : assets/effects/gm-channel_mixer.xml
// id     : gm.custom.channel_mixer
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_channel_mixerParams {
    float rR;
    float rG;
    float rB;
    float gR;
    float gG;
    float gB;
    float bR;
    float bG;
    float bB;
    float mixAmt;
};

fragment float4 fx_gm_channel_mixer(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_channel_mixerParams&  u    [[buffer(1)]],
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
  float3 g;
  g.r = c.r * u.rR + c.g * u.rG + c.b * u.rB;
  g.g = c.r * u.gR + c.g * u.gG + c.b * u.gB;
  g.b = c.r * u.bR + c.g * u.bG + c.b * u.bB;
  float3 col = mix(c, clamp(g, 0.0, 1.0), u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
