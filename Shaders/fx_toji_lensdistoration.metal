// ---------------------------------------------------------------------------
// Lens Distortion
// origem : assets/effects/toji-lensdistoration.xml
// id     : com.alightcreative.effects.lensdistort
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_lensdistorationParams {
    float strength;
    float blend;
};

fragment float4 fx_toji_lensdistoration(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_lensdistorationParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm * 2.0 - 1.0; // Convert to range [-1, 1]
      float r = length(uv); // Distance from center
      
      // Lens distortion formula
      float k = u.strength; // distortion u.strength
      float distortedR = r + k * r * r;
      float2 distortedUV = uv * (distortedR / max(r, 0.0001));
      distortedUV = (distortedUV + 1.0) * 0.5; // Back to [0, 1]
      
      // Only use distorted coordinates if inside bounds
      float4 color = float4(0.0);
      if (distortedUV.x >= 0.0 && distortedUV.x <= 1.0 && distortedUV.y >= 0.0 && distortedUV.y <= 1.0) {
        color = inputImg.sample(__nv_smp, distortedUV);
      }
      
      // Blend with the original image
      float4 orig = inputImg.sample(__nv_smp, in.acScreenNorm);
      float4 finalColor = mix(orig, color, u.blend);
      
      __nv_out = finalColor;
    return __nv_out;
}
