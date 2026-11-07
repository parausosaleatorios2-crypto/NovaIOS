// ---------------------------------------------------------------------------
// Emboss
// origem : assets/effects/gm-emboss.xml
// id     : gm.custom.emboss
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_embossParams {
    float depth;
    float angle;
    float grey;
    float mixAmt;
};

fragment float4 fx_gm_emboss(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_embossParams&  u    [[buffer(1)]],
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
  float px = 1.0 / max(eng.acScreenSize.y, 1.0);
  float l = gmLum(c);
  float lx = gmLum(inputImg.sample(__nv_smp, uv + float2(px, 0.0)).rgb) - l;
  float ly = gmLum(inputImg.sample(__nv_smp, uv + float2(0.0, px)).rgb) - l;
  float rad = radians(u.angle);
  float d = (lx * cos(rad) + ly * sin(rad)) * u.depth * 20.0;
  float3 col = float3(clamp(u.grey + d, 0.0, 1.0));
  col = mix(c, col, u.mixAmt);
  __nv_out = float4(col * a, a);
    return __nv_out;
}
