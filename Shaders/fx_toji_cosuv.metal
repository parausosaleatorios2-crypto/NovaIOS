// ---------------------------------------------------------------------------
// texture
// origem : assets/effects/toji-cosuv.xml
// id     : com.alightcreative.effects.cos_uv_flow
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_cosuvParams {
    float speed;
    float amount;
    float freqX;
    float freqY;
    float base;
    float opacity;
};

fragment float4 fx_toji_cosuv(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_cosuvParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float2 iResolution = eng.acScreenSize;
      float iTime = eng.acTime * u.speed;

      // Shadertoy uv mapping
      float2 uv = (2.0 * fragCoord - iResolution.xy) / max(iResolution.x, iResolution.y);

      // Fixed 9 iterations like original (1..9)
      for (float i = 1.0; i < 10.0; i += 1.0) {
        uv.x += u.amount / i * cos(i * u.freqX * uv.y + iTime);
        uv.y += u.amount / i * cos(i * u.freqY * uv.x + iTime);
      }

      float3 col = float3(u.base) / max(abs(sin(iTime - uv.y - uv.x)), 1e-4);
      float4 gen = float4(col, 1.0);

      // Composite over input layer
      float4 baseCol = inputImg.sample(__nv_smp, in.acScreenNorm);
      float4 outC = gen * u.opacity;
      outC = baseCol * (1.0 - outC.a) + outC;
      __nv_out = outC;
    return __nv_out;
}
