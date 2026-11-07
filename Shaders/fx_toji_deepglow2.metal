// ---------------------------------------------------------------------------
// deep glow (new)
// origem : assets/effects/toji-deepglow2.xml
// id     : com.alightcreative.effects.full_image_soft_glow_mp
// passes : 8
// gerado por glsl2msl.py - NAO editar a mao; edite o XML e gere de novo
// ---------------------------------------------------------------------------
#include <metal_stdlib>
#include "NovaEngineUniforms.h"
#include "NovaShaderHelpers.h"
using namespace metal;

struct toji_deepglow2Params {
    float radius;
    float exposure;
    float softClipKnee;
    float spread;
    float glowTail;
    float glowOcclusion;
    float threshold;
    float thresholdSmooth;
    float thresholdGamma;
    int blendMode;
    float4 tint;
    float tintStrength;
    int sshadow;
    float alphaa;
    float4 shadowColor;
    float shadowAlpha;
    float direction;
    float distance;
    float softness;
    int shadowOnly;
    int quality;
    int glowOnly;
    float ditherAmount;
};

// --- funcoes auxiliares do efeito
// Multi-pass Full Image Soft Glow + Drop Shadow (no extra shadow buffer)
    // Pass 0: downsample source to downImg
    // Pass 1-2: blur u.radius r1 (H then V)
    // Pass 3-4: blur u.radius r2 (H then V)
    // Pass 5-6: blur u.radius r3 (H then V)
    // Pass 7: composite (upsample implicitly by sampling buffers at full-res UV)

    const float PI = 3.14159265358979323846;

    // sRGB <-> Linear helpers for more natural glow blending
    static float3 srgbToLinear(float3 srgb){
      float3 cut = step(float3(0.04045), srgb);
      float3 low = srgb / 12.92;
      float3 high = pow((srgb + 0.055) / 1.055, float3(2.4));
      return mix(low, high, cut);
    }
    static float3 linearToSrgb(float3 lin){
      float3 cut = step(float3(0.0031308), lin);
      float3 low = lin * 12.92;
      float3 high = 1.055 * pow(lin, float3(1.0/2.4)) - 0.055;
      return mix(low, high, cut);
    }

    // Compute blur tap using incremental Gaussian as in gaussianblur.xml
    static float4 blurInternal(sampler2D tex, float2 texOffset, float2 st, float numBlurPixelsPerSide)
    {
      if(numBlurPixelsPerSide <= 0.0) return tex.sample(__nv_smp, st);

      float3 incrementalGaussian;
      float adjSigma = numBlurPixelsPerSide / 2.14596602; // inverse of cutoff relationship
      incrementalGaussian.x = 1.0 / (sqrt(2.0 * PI) * max(adjSigma, 1e-4));
      incrementalGaussian.y = exp(-0.5 / (max(adjSigma, 1e-4) * max(adjSigma, 1e-4)));
      incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

      float4 avgValue = tex.sample(__nv_smp, st).rgba * incrementalGaussian.x;
      float coefficientSum = incrementalGaussian.x;

      // two-sample per loop step optimization
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
        avgValue += tex.sample(__nv_smp, stL) * weightL;
        avgValue += tex.sample(__nv_smp, stR) * weightL;
      }
      return avgValue / max(coefficientSum, 1e-6);
    }

    static float tapsForQualityF(float q){
      return (q < 1.5) ? 8.0 : ((q < 2.5) ? 14.0 : 20.0);
    }

    // Luminance for thresholding
    static float luminance(float3 c){ return dot(c, float3(0.2126, 0.7152, 0.0722)); }

fragment float4 fx_toji_deepglow2(
    NovaVertexOut       in   [[stage_in]],
    constant EngineUniforms& eng [[buffer(0)]],
    constant toji_deepglow2Params&  u    [[buffer(1)]],
    sampler             __nv_smp [[sampler(0)]],
    texture2d<float> inputImg [[texture(0)]],
    texture2d<float> downImg [[texture(1)]],
    texture2d<float> h1 [[texture(2)]],
    texture2d<float> v1 [[texture(3)]],
    texture2d<float> h2 [[texture(4)]],
    texture2d<float> v2 [[texture(5)]],
    texture2d<float> h3 [[texture(6)]],
    texture2d<float> v3 [[texture(7)]],
    constant NovaTexInfo& inputImg_info [[buffer(2)]],
    constant NovaTexInfo& downImg_info [[buffer(3)]],
    constant NovaTexInfo& h1_info [[buffer(4)]],
    constant NovaTexInfo& v1_info [[buffer(5)]],
    constant NovaTexInfo& h2_info [[buffer(6)]],
    constant NovaTexInfo& v2_info [[buffer(7)]],
    constant NovaTexInfo& h3_info [[buffer(8)]],
    constant NovaTexInfo& v3_info [[buffer(9)]])
{
    float4 __nv_fragCoord = in.position;
    float2 __nv_pointCoord = in.uv;
    float4 __nv_out = float4(0.0);

      float taps = tapsForQualityF(float(u.quality));

      // Base radii in pixels at full res. We blur on downsampled buffers, so scale radii down.
      float r1 = u.radius;
      float r2 = u.radius * (1.8 + u.spread);
      float r3 = u.radius * (3.5 + 2.0*u.spread);

      // Sampling UV
      float2 uv = in.acScreenNorm;

      if (eng.acPass == 0) {
        // Downsample + build glow source with u.threshold/mask and gamma handling
        float4 src4 = inputImg.sample(__nv_smp, uv);
        float3 srcRGB = src4.rgb;
        // Threshold in linear light for better isolation of bright cores
        float lum = luminance(srgbToLinear(srcRGB));
        lum = pow(max(lum, 0.0), u.thresholdGamma);
        float t = (u.thresholdSmooth <= 0.0) ? step(u.threshold, lum)
                                          : smoothstep(u.threshold - u.thresholdSmooth, u.threshold + u.thresholdSmooth, lum);
        // Mask removed
        float3 glowSrc = srcRGB * t;
        // Aspect ratio scale on Y if desired
        glowSrc *= 1.0;
        // Store source alpha in A for shadow masking
        __nv_out = float4(glowSrc, src4.a);
        return __nv_out;
      }

      // Horizontal/Vertical blur per pass
      if (eng.acPass == 1) {
        // r1 horizontal on downImg -> h1
        float2 to = float2(1.0 / __nv_getTexSize(downImg_info.size).x, 0.0);
        float kernelSize = r1 * 0.5 * (taps/10.0); // empirical scaling
        __nv_out = blurInternal(downImg, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 2) {
        // r1 vertical h1 -> v1
        float2 to = float2(0.0, 1.0 / __nv_getTexSize(h1_info.size).y);
        float kernelSize = r1 * 0.5 * (taps/10.0);
        __nv_out = blurInternal(h1, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 3) {
        // r2 horizontal on downImg -> h2
        float2 to = float2(1.0 / __nv_getTexSize(downImg_info.size).x, 0.0);
        float kernelSize = r2 * 0.5 * (taps/10.0);
        __nv_out = blurInternal(downImg, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 4) {
        // r2 vertical h2 -> v2
        float2 to = float2(0.0, 1.0 / __nv_getTexSize(h2_info.size).y);
        float kernelSize = r2 * 0.5 * (taps/10.0);
        __nv_out = blurInternal(h2, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 5) {
        // r3 horizontal on downImg -> h3
        float2 to = float2(1.0 / __nv_getTexSize(downImg_info.size).x, 0.0);
        float kernelSize = r3 * 0.5 * (taps/10.0);
        __nv_out = blurInternal(downImg, to, uv, kernelSize);
        return __nv_out;
      }
      if (eng.acPass == 6) {
        // r3 vertical h3 -> v3
        float2 to = float2(0.0, 1.0 / __nv_getTexSize(h3_info.size).y);
        float kernelSize = r3 * 0.5 * (taps/10.0);
        __nv_out = blurInternal(h3, to, uv, kernelSize);
        return __nv_out;
      }

      // Final composite (pass 7)

      // Final composite at full res: sample downsampled, blurred results using same UV
      float4 src = inputImg.sample(__nv_smp, uv);
      float3 b1 = v1.sample(__nv_smp, uv).rgb;
      float3 b2 = v2.sample(__nv_smp, uv).rgb;
      float4 b3s = v3.sample(__nv_smp, uv);
      float3 b3 = b3s.rgb;

      // Combine the blurred results with u.exposure and u.tint
      float w2 = 0.6 * u.glowTail;
      float w3 = 0.3 * u.glowTail;
      float3 glowLin = srgbToLinear(b1) + srgbToLinear(b2) * w2 + srgbToLinear(b3) * w3;
      glowLin *= max(u.exposure, 0.0);
      glowLin = 1.0 - exp(-glowLin * u.softClipKnee);
      float3 glowBase = linearToSrgb(glowLin);
      float3 glow = mix(glowBase, glowBase * u.tint.rgb, clamp(u.tintStrength, 0.0, 1.0));
      float glowA = clamp(b3s.a * u.glowOcclusion, 0.0, 1.0);

      // Base starts as original
      float4 base = src;

      // Drop shadow (optional) using v3 blurred alpha
      if (u.sshadow) {
        float2 imgSize = __nv_getTexSize(inputImg_info.size);
        float px = (1.0/imgSize.x);
        float py = (1.0/imgSize.y);
        float ang = radians(u.direction);
        float2 offs = float2(cos(ang), sin(ang)) * u.distance;
        float2 shadowUV = uv + offs * float2(px, py);

        float sscale = max(u.softness, 1.0);
        float2 u.spread = float2(px, py) * sscale * 0.5;

        float a0 = v3.sample(__nv_smp, shadowUV).a;
        float a1 = v3.sample(__nv_smp, shadowUV + float2(u.spread.x, 0.0)).a;
        float a2 = v3.sample(__nv_smp, shadowUV - float2(u.spread.x, 0.0)).a;
        float a3 = v3.sample(__nv_smp, shadowUV + float2(0.0, u.spread.y)).a;
        float a4 = v3.sample(__nv_smp, shadowUV - float2(0.0, u.spread.y)).a;
        float a5 = v3.sample(__nv_smp, shadowUV + float2(u.spread.x, u.spread.y)).a;
        float a6 = v3.sample(__nv_smp, shadowUV + float2(-u.spread.x, u.spread.y)).a;
        float a7 = v3.sample(__nv_smp, shadowUV + float2(u.spread.x, -u.spread.y)).a;
        float a8 = v3.sample(__nv_smp, shadowUV + float2(-u.spread.x, -u.spread.y)).a;
        float shadowA = (a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8) / 9.0;
        shadowA = clamp(shadowA * 1.8, 0.0, 1.0);
        shadowA = 1.0 - pow(max(0.0, 1.0 - shadowA), 0.45);

        float alphaEff = clamp(u.shadowAlpha * u.alphaa, 0.0, 1.0);
        float4 outColor = float4(u.shadowColor.rgb, clamp(shadowA * alphaEff, 0.0, 1.0));

        if (u.shadowOnly) {
          __nv_out = outColor;
          return __nv_out;
        }

        float behindMask = 1.0 - step(0.001, base.a);
        base = base + outColor * behindMask;
      }

      // Blend glow with chosen blend mode, using shadowed base as source
      float3 srcLin = srgbToLinear(base.rgb);
      float3 compLin;
      float bmf = float(u.blendMode);
      if (bmf < 1.5) {
        compLin = srcLin + srgbToLinear(glow);
      } else if (bmf < 2.5) {
        float3 compS = 1.0 - (1.0 - base.rgb) * (1.0 - clamp(glow, 0.0, 100.0));
        compLin = srgbToLinear(compS);
      } else {
        compLin = max(srcLin, srgbToLinear(glow));
      }
      float3 finalColor = linearToSrgb(compLin);
      float2 imgPx = __nv_getTexSize(inputImg_info.size) * uv;
      float2 ip = floor(imgPx);
      float n1 = fract(sin(dot(ip, float2(12.9898,78.233))) * 43758.5453);
      float n2 = fract(sin(dot(ip, float2(24.1230,17.3210))) * 12345.6789);
      float n3 = fract(sin(dot(ip, float2(93.9890,67.3450))) * 98765.4321);
      float3 dn = float3(n1, n2, n3) - 0.5;
      finalColor = clamp(finalColor + dn * u.ditherAmount, 0.0, 1.0);

      if (u.glowOnly) {
        finalColor = glow;
        __nv_out = float4(finalColor, glowA);
        return __nv_out;
      }

      float finalAlpha = clamp(base.a + glowA, 0.0, 1.0);
      __nv_out = float4(finalColor, finalAlpha);
    return __nv_out;
}
