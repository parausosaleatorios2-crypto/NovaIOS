// ---------------------------------------------------------------------------
// Precision Glitch
// origem : assets/effects/toji-glitch_pro.xml
// id     : com.alightcreative.effects.precision_glitch
// passes : 1
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_glitch_proParams {
    float timeSpeed;
    float glitchRate;
    float flickerThreshold;
    float seed;
    float tearHeightMin;
    float tearHeightRand;
    float tearOffsetMax;
    float tearScanFreq;
    float tearScanAmp;
    float bandMix;
    float blockGridMin;
    float blockGridRand;
    float blockGridY;
    float blockAffectThr;
    float staticProbThr;
    int enableColorBands;
    float bandProbThr;
};

// --- funcoes auxiliares do efeito
// Precision Glitch (Shadertoy-style) -> Alight Motion port

    float random(float2 st) {
      return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
    }
    float2 random2(float2 st) {
      return float2( random(st), random(st + float2(1.0, 1.0)) );
    }

fragment float4 fx_toji_glitch_pro(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_glitch_proParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 fragCoord = in.acScreenNorm * eng.acScreenSize;
      float2 uv = in.acScreenNorm;
      float4 originalColor = inputImg.sample(__nv_smp, uv);

      // Timing
      float t = floor((eng.acTime * u.timeSpeed + u.seed*0.001) * u.glitchRate);
      float glitchTrigger = random(float2(t, 0.0));

      if (glitchTrigger > u.flickerThreshold) {
        // 1. Large horizontal tearing
        float tearY = random(float2(t, 2.0));
        float tearHeight = u.tearHeightMin + random(float2(t, 3.0)) * u.tearHeightRand;
        float tearOffset = (random(float2(t, 4.0)) - 0.5) * (u.tearOffsetMax*2.0);

        if (uv.y > tearY && uv.y < tearY + max(tearHeight, 0.0)) {
          float isColorBand = random(float2(t, 5.0));
          if (u.enableColorBands && isColorBand > u.bandProbThr) {
            float2 duv = uv; duv.x = fract(duv.x + tearOffset);
            float4 displacedColor = inputImg.sample(__nv_smp, duv);

            float3 bandColor = float3(
              random(float2(t, 6.0)),
              random(float2(t, 7.0)),
              random(float2(t, 8.0))
            );
            displacedColor.rgb = mix(displacedColor.rgb, bandColor, clamp(u.bandMix,0.0,1.0));

            // 5. Scan lines
            float scanLine = sin(fragCoord.y * u.tearScanFreq) * u.tearScanAmp;
            displacedColor.rgb = clamp(displacedColor.rgb - scanLine, 0.0, 1.0);
            originalColor = displacedColor;
          } else {
            float2 duv = uv; duv.x = fract(duv.x + tearOffset);
            originalColor = inputImg.sample(__nv_smp, duv);
          }
        }

        // 3 & 4. Datamosh & Static blocks
        float gridX = u.blockGridMin + random(float2(t, 9.0)) * u.blockGridRand;
        float2 blockGrid = floor(uv * float2(max(1.0, gridX), max(1.0, u.blockGridY)));
        float blockTrigger = random(blockGrid + t);
        if (blockTrigger > u.blockAffectThr) {
          float blockType = random(blockGrid + 10.0 + t);
          if (blockType > u.staticProbThr) {
            // Static block
            float2 sc = fract(uv * 10.0);
            originalColor.rgb = clamp(float3(
              random(sc),
              random(sc.yx),
              random(uv)
            ), 0.0, 1.0);
          } else {
            // Datamosh block
            float2 ro = (random2(blockGrid + 23.0) - 0.5) * 2.0;
            originalColor = inputImg.sample(__nv_smp, fract(uv + ro));
          }
        }
      }

      __nv_out = originalColor;
    return __nv_out;
}
