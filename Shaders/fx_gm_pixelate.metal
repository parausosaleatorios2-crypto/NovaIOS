// ---------------------------------------------------------------------------
// Pixelate
// origem : assets/effects/gm-pixelate.xml
// id     : gm.custom.pixelate
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_pixelateParams {
    float size;
    int square;
    float mixAmt;
};

fragment float4 fx_gm_pixelate(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_pixelateParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float2 sz = float2(u.size);
  if (u.square) sz = float2(u.size * (eng.acScreenSize.y / max(eng.acScreenSize.x, 1.0)), u.size);
  float2 grid = eng.acScreenSize / max(sz, float2(1.0));
  float2 p = (floor(uv * grid) + 0.5) / grid;
  float4 a = inputImg.sample(__nv_smp, uv);
  float4 b = inputImg.sample(__nv_smp, p);
  __nv_out = mix(a, b, u.mixAmt);
    return __nv_out;
}
