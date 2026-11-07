// ---------------------------------------------------------------------------
// Ring Distortion Fade
// origem : assets/effects/toji-rippledisto.xml
// id     : com.alightcreative.effects.ring_distortion_fade
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_rippledistoParams {
    int autoTime;
    float duration;
    float progress;
    float effectWidth;
    float fadeInTimeFactor;
    float maxTexelOffset;
    float centerX;
    float centerY;
};

// --- funcoes auxiliares do efeito
// Ring Distortion Fade

fragment float4 fx_toji_rippledisto(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_rippledistoParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 res = eng.acScreenSize;
      float2 uv = in.acScreenNorm; // 0..1

      // Time 0..1
      float pr = u.autoTime ? __nv_mod(eng.acTime, u.duration) / max(0.0001, u.duration) : clamp(u.progress, 0.0, 1.0);

      // Convert offset from chosen center to pixel-normalized space (preserving circularity)
      float2 center = float2(u.centerX, u.centerY);
      float minDim = min(res.x, res.y);
      float2 offsetFromCenter = (uv - center) * res / max(1.0, minDim);

      // Direction toward center; if zero length, no offset
      float lenO = length(offsetFromCenter);
      float2 offsetDir = lenO > 1e-6 ? normalize(-offsetFromCenter) : float2(0.0);

      // Band logic
      float halfWidth = u.effectWidth * 0.5;
      float lower = 1.0 - smoothstep(pr - halfWidth, pr, lenO);
      float upper = smoothstep(pr, pr + halfWidth, lenO);
      float band = 1.0 - (upper + lower);

      float strength = 1.0 - pr; // fades out over time
      float fadeStrength = smoothstep(0.0, u.fadeInTimeFactor, pr); // fades in initially
      float distortion = band * strength * fadeStrength;

      // Apply offset in texels, clamp sampling inside valid area
      float2 texelSize = 1.0 / __nv_getTexSize(inputImg_info.size);
      float2 uvOff = uv + texelSize * (offsetDir * u.maxTexelOffset * distortion);
      float2 halfTex = texelSize * 0.5;
      uvOff = clamp(uvOff, halfTex, 1.0 - halfTex);

      float4 col = inputImg.sample(__nv_smp, uvOff);
      __nv_out = col;
    return __nv_out;
}
