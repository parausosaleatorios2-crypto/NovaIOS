// ---------------------------------------------------------------------------
// Parallax Depth
// origem : assets/effects/gm-parallax.xml
// id     : gm.custom.parallax
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_parallaxParams {
    float amountX;
    float amountY;
    float invert;
    float mixAmt;
};

fragment float4 fx_gm_parallax(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_parallaxParams&  u    [[buffer(1)]],
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
  float l = gmLum(src.rgb / a);
  l = mix(l, 1.0 - l, u.invert);
  float2 o = float2(u.amountX, u.amountY) * (l - 0.5) * 2.0 * u.mixAmt;
  __nv_out = inputImg.sample(__nv_smp, uv + o);
    return __nv_out;
}
