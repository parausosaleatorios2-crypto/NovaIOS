// ---------------------------------------------------------------------------
// Camera Lens Blur
// origem : assets/effects/toji-Acaneralensblur.xml
// id     : com.alightcreative.effects.camera_lens_blur
// passes : 3
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_AcaneralensblurParams {
    float radius;
    int quality;
    float exposure;
    int blendMode;
    float mixAmount;
};

// --- funcoes auxiliares do efeito
const float PI = 3.14159265358979323846;

    static float4 sampleTex(sampler2D t, float2 uv){ return t.sample(__nv_smp, uv); }

    // Incremental Gaussian blur helper (separable)
    static float4 blurInternal(sampler2D tex, float2 texOffset, float2 st, float numBlurPixelsPerSide)
    {
      if(numBlurPixelsPerSide <= 0.0) return sampleTex(tex, st);

      float3 incrementalGaussian;
      float adjSigma = numBlurPixelsPerSide / 2.14596602;
      incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * max(adjSigma, 1e-4));
      incrementalGaussian.y = exp(-0.5 / (max(adjSigma, 1e-4) * max(adjSigma, 1e-4)));
      incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

      float4 avgValue = sampleTex(tex, st) * incrementalGaussian.x;
      float coefficientSum = incrementalGaussian.x;

      for (float i = 1.0; i <= 256.0; i += 2.0) {
        if (i > numBlurPixelsPerSide) break;
        float offset0 = i;
        float offset1 = i + 1.0;

        incrementalGaussian.xy *= incrementalGaussian.yz;
        coefficientSum += (2.0 * incrementalGaussian.x);
        float weight0 = incrementalGaussian.x;
        incrementalGaussian.xy *= incrementalGaussian.yz;
        coefficientSum += (2.0 * incrementalGaussian.x);
        float weight1 = incrementalGaussian.x;
        float weightL = weight0 + weight1;
        float offsetL = (offset0*weight0 + offset1*weight1) / max(weightL, 1e-6);
        float2 stL = st - offsetL * texOffset;
        float2 stR = st + offsetL * texOffset;
        avgValue += sampleTex(tex, stL) * weightL;
        avgValue += sampleTex(tex, stR) * weightL;
      }
      return avgValue / max(coefficientSum, 1e-6);
    }

    static float tapsForQualityF(float q){
      return (q < 1.5) ? 6.0 : ((q < 2.5) ? 10.0 : 14.0);
    }

fragment float4 fx_toji_Acaneralensblur(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_AcaneralensblurParams&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> h [[texture(1)]],
    texture2d<float> v [[texture(2)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& h_info [[buffer(3)]],
    constant NovaTexInfo& v_info [[buffer(4)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float2 uv = in.acScreenNorm;

      // Compute kernel based on u.radius (pixels) and u.quality
      float taps = tapsForQualityF(float(u.quality));
      float kernelSize = u.radius * 0.5 * (taps/10.0);

      if (eng.acPass == 0) {
        // Horizontal blur: input -> h
        float2 to = float2(1.0 / __nv_getTexSize(inputImg_info.size).x, 0.0);
        __nv_out = blurInternal(inputImg, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 1) {
        // Vertical blur: h -> v
        float2 to = float2(0.0, 1.0 / __nv_getTexSize(h_info.size).y);
        __nv_out = blurInternal(h, to, uv, kernelSize);
        return __nv_out;
      }

      // Composite: apply u.exposure and blend with source
      float4 src = sampleTex(inputImg, uv);
      float3 blurred = sampleTex(v, uv).rgb * u.exposure;

      int bm = int(u.blendMode);
      float3 outRGB;
      if (bm == 1) {
        // Normal: interpolate between src and blurred
        outRGB = mix(src.rgb, blurred, clamp(u.mixAmount, 0.0, 1.0));
      } else if (bm == 2) {
        // Add
        outRGB = src.rgb + blurred * clamp(u.mixAmount, 0.0, 1.0);
      } else {
        // Screen
        float3 scr = 1.0 - (1.0 - src.rgb) * (1.0 - clamp(blurred, 0.0, 100.0));
        outRGB = mix(src.rgb, scr, clamp(u.mixAmount, 0.0, 1.0));
      }

      __nv_out = float4(outRGB, src.a);
    return __nv_out;
}
