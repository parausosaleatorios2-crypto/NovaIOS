// ---------------------------------------------------------------------------
// bcc ripple
// origem : assets/effects/toji-bcc_ripple.xml
// id     : com.alightcreative.effects.ripplelight
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_bcc_rippleParams {
    float strength;
    float frequency;
    float speed;
    float radius;
    float decay;
    float centerX;
    float centerY;
    float lightIntensity;
    float lightSharpness;
    float4 lightColor;
    float blend;
};

fragment float4 fx_toji_bcc_ripple(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_bcc_rippleParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acLayerNorm;
      float2 center = float2(u.centerX, u.centerY);

      // Vector from center (aspect-corrected)
      float aspect = eng.acLayerSize.x / eng.acLayerSize.y;
      float2 diff = uv - center;
      float2 diffA = float2(diff.x * aspect, diff.y);
      float dist = length(diffA) * u.radius;

      // Ripple wave (animated with time)
      float ripple = sin(dist * u.frequency - eng.acTime * u.speed);

      // Decay (fade as distance increases)
      ripple *= exp(-u.decay * dist);

      // Offset in radial direction (convert back from aspect space)
      float2 dirA = diffA / max(length(diffA), 1e-6);
      float2 dirUV = float2(dirA.x / aspect, dirA.y);
      float2 displacedUV = uv + dirUV * ripple * u.strength;

      // Sample displaced image
      float4 displacedColor = inputImg.sample(__nv_smp, displacedUV);
      float4 originalColor  = inputImg.sample(__nv_smp, uv);

      float lRaw = cos(dist * u.frequency - eng.acTime * u.speed) * exp(-u.decay * dist);
      float light = max(lRaw, 0.0);
      float2 light2D = normalize(float2(0.6, 0.8));
      float orient = clamp(0.5 + 0.5 * dot(dirUV, light2D), 0.0, 1.0);
      light = pow(light, u.lightSharpness) * pow(orient, u.lightSharpness) * u.lightIntensity;

      float3 finalColor = displacedColor.rgb;
      finalColor += u.lightColor.rgb * light;

      // Blend with original
      float3 mixedColor = mix(originalColor.rgb, finalColor, u.blend);

      __nv_out = float4(mixedColor, displacedColor.a);
    return __nv_out;
}
