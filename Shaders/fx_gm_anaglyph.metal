// ---------------------------------------------------------------------------
// Anaglyph 3D
// origem : assets/effects/gm-anaglyph.xml
// id     : gm.custom.anaglyph
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct gm_anaglyphParams {
    float depth;
    int swap;
    float mixAmt;
};

fragment float4 fx_gm_anaglyph(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant gm_anaglyphParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

  float2 uv = in.acScreenNorm;
  float4 src = inputImg.sample(__nv_smp, uv);
  float a = src.a;
  float l = gmLum(src.rgb / max(a, 1e-4));
  float o = u.depth * (l - 0.5) * 2.0 * u.mixAmt;
  if (u.swap) o = -o;
  float r = inputImg.sample(__nv_smp, uv + float2(o, 0.0)).r;
  float gb = inputImg.sample(__nv_smp, uv - float2(o, 0.0)).g;
  float bb = inputImg.sample(__nv_smp, uv - float2(o, 0.0)).b;
  __nv_out = float4(r, gb, bb, a);
    return __nv_out;
}
